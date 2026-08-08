# How far Ctrl+C reaches, in R and in the DuckDB CLI

*What it measures:* which running DuckDB work a Ctrl+C stops in the R
package and in the DuckDB CLI, what each host's handler actually does,
and where the two stop differing —
narrowing
[#202](https://github.com/duckdb/duckdb-r/issues/202),
which reports `ATTACH 'md:'` as uncancellable from R
while the same key works in the shell.

*When and on what:* 2026-08-08, Linux x86_64.
The R package built from this tree against the prebuilt
`libduckdb` v1.5.5 (upstream commit `d8cdaa33fda`) via the fast path
([`build/fast-paths/`](/handbook/build/fast-paths/README.md));
the CLI the official `duckdb_cli-linux-amd64` build of that same
version and commit, so both hosts run one engine.
`httpfs` v1.5.5 from `extensions.duckdb.org`.
Method: [`run.sh`](run.sh), output in [`transcript.txt`](transcript.txt).

*What it supports:* the interrupt section of
[`usage/interactive/`](/handbook/usage/interactive/README.md),
and the problem statement of
[`plan/PLAN-query-cancellation.md`](/plan/PLAN-query-cancellation.md).

## How it asks

Each case drives a real prompt on a pty
([`ctrlc.py`](ctrlc.py)): the script types the SQL or R,
then writes a literal `0x03`, so the tty line discipline raises SIGINT
for the foreground process group the way a keypress does —
not `kill(2)` aimed at a pid, which would bypass the terminal entirely.
It then types a marker statement.
**The marker running is the verdict**: it means the prompt came back,
so the user has control again.

Two workloads stand for the two kinds of waiting:

* Work the engine executes itself —
  `SELECT count(*) FROM range(1000000000000)`.
* A wait blocked inside an extension —
  `ATTACH` over HTTP against a server that accepts the connection and
  never answers ([`hangserver.py`](hangserver.py)),
  with `http_timeout` long and `http_retries` zero
  so nothing but the interrupt can end it.

MotherDuck itself is not exercised here: the artifact
`extensions.duckdb.org` serves for v1.5.5 on `linux_amd64` refuses to
initialize, reporting that version and platform unsupported, and the
machine had no route to MotherDuck either.
The `httpfs` stand-in blocks at the same place in the engine —
inside `PhysicalAttach`, under a network wait an extension owns.

Two further cases fix R's own ceiling, in plain C
([`blocking_poll.c`](blocking_poll.c)):
the same `poll()` loop, once without and once with
`R_CheckUserInterrupt()`.

## What it found

| host | workload | Ctrl+C | outcome |
|---|---|---|---|
| CLI | engine-executed scan | 1 | prompt returns |
| R | engine-executed scan | 1 | prompt returns |
| CLI | wait blocked in `httpfs` | 1 | nothing |
| CLI | wait blocked in `httpfs` | 3 | shell exits, status 1 |
| R | wait blocked in `httpfs` | 5 | nothing, ever |
| R | C `poll()` loop, no interrupt check | 2 | nothing |
| R | C `poll()` loop, `R_CheckUserInterrupt()` | 1 | prompt returns |

**A wait blocked in `httpfs` is cancellable in neither host.**
Both handlers do the same one thing —
`ClientContext::Interrupt()`, which sets a flag the engine reads
between executor tasks — and a task blocked in a network request never
reaches the next read.
The shell's third Ctrl+C calls `ShellState::Exit(1)`
(`tools/shell/shell.cpp`), which is the `EXITED status 1` above:
what returned control there was the process ending, not the wait.
R has no counterpart, which is why its column never changes.

**The R handler is armed, and does set the flag.**
A build instrumented to report from inside the handler shows it running
on every Ctrl+C of the blocked `ATTACH`, with
`ClientContext::IsInterrupted()` reading true immediately after —
so the package asks the engine to stop exactly as the shell does.
[`sigprobe.c`](sigprobe.c) confirms it from outside the handler, and
says the same of the shell:

```
R, before loading the package   lib=…/lib/R/lib/libR.so
R, during the blocked ATTACH    sym=duckdb::ScopedInterruptHandler::signal_handler
                                lib=…/duckdb/libs/duckdb.so   SA_RESTART=1
CLI, during the blocked ATTACH  lib=./duckdb                  SA_RESTART=1
```

Same restart semantics on both sides, which is not a coincidence:
each reaches its handler through the same `signal@GLIBC_2.2.5` binding.

**R's own interrupt has the same ceiling.**
C code that never calls `R_CheckUserInterrupt()` is uninterruptible
whoever wrote it; the last two rows show the ceiling and the escape.

Once a wait ends by itself, the recorded interrupt is delivered:
dropping the server makes the `ATTACH` fail, and R raises the interrupt
rather than the connection error —
`rapi_execute_impl` calls `HandleInterrupt()` before it inspects the
result ([`src/statement.cpp`](/src/statement.cpp)).
That is the shape [#202](https://github.com/duckdb/duckdb-r/issues/202)
describes as cancelling in the browser breaking out.

## Where the wait sits

`gdb` on the stuck R process, main thread, inner frames outward:

```
poll(timeout=1000)
curl_easy_perform
duckdb::HTTPFSCurlClient::Head
duckdb::HTTPUtil::RunRequestWithRetry
duckdb::HTTPFileSystem::HeadRequest
duckdb::MagicBytes::CheckMagicBytes
duckdb::DatabaseManager::AttachDatabase
duckdb::PhysicalAttach::GetDataInternal
duckdb::PipelineExecutor::Execute
duckdb::PreparedStatement::Execute
```

The wait is inside `rapi_execute_impl`'s armed window, and inside a
pipeline task — so the engine's flag would be read the moment the task
returned.
It does not return because nothing below reads the flag:
`RunRequestWithRetry` (`src/main/http/http_util.cpp` upstream) checks it
neither while a request is in flight nor between retries.
The extension is resolved here rather than earlier —
`Binder::Bind(AttachStatement)` does not touch the database type, and
`DatabaseManager::GetDatabaseType` is reached only from
`AttachDatabase` — so an extension `ATTACH` pulls in is loaded during
this same window.

## What is still open

MotherDuck's wait behaves differently from the `httpfs` one, and the
difference is not yet pinned down.
Reported by the maintainer, DuckDB CLI, 2026-08-08: a single Ctrl+C
during the `ATTACH 'md:'` sign-in wait prints MotherDuck's own
`Interrupted, aborting.` and the statement then fails with
`no token provided` — neither string is core DuckDB's.
So that wait does notice an interrupt, in the shell.

It cannot be noticing it through the flag both handlers set, because
R sets that flag identically and nothing happens there.
What is left is the process-wide SIGINT disposition — what MotherDuck
sees installed, and when it installed anything of its own.

[`sigprobe.c`](sigprobe.c) is the measurement that settles it, and it
answers on a timeline rather than in one snapshot, which is the part
that matters: the question is not only who owns the handler while the
sign-in wait runs, but whether MotherDuck ever owned it and stopped.
Build it with [`build-sigprobe.sh`](build-sigprobe.sh) and run
[`md-probe.R`](md-probe.R) for the R side;
the same library preloads into the CLI, where its constructor starts
the same sampler.
It reads the disposition through `sigaction(2)` and names the owning
library through `dladdr(3)`, so it needs no debugger and no per-platform
struct offsets — a debugger is awkward to attach on macOS, and
`struct sigaction` is not laid out the same way there.
What it still needs is a MotherDuck account and a route to it,
which this run had neither of.
