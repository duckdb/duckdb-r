# How far Ctrl+C reaches, in R and in the DuckDB CLI

*What it measures:* which running DuckDB work a Ctrl+C stops in the R
package and in the DuckDB CLI, what each host's handler actually does,
and where the two stop differing —
answering
[#202](https://github.com/duckdb/duckdb-r/issues/202),
which reports `ATTACH 'md:'` as uncancellable from R
while the same key works in the shell.

*When and on what:* 2026-08-08.
The scripted cases on Linux x86_64, with the R package built from this
tree against the prebuilt `libduckdb` v1.5.5 (upstream commit
`d8cdaa33fda`) via the fast path
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
the CLI the official `duckdb_cli-linux-amd64` build of that same version
and commit, so both hosts run one engine, and `httpfs` v1.5.5 from
`extensions.duckdb.org`.
Method: [`run.sh`](run.sh), output in [`transcript.txt`](transcript.txt).
The MotherDuck pair on macOS aarch64, R 4.5.3 against a Homebrew CLI of
the same DuckDB version, recorded in
[`transcript-motherduck.md`](transcript-motherduck.md).

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

## What `ATTACH 'md:'` does differently

MotherDuck's sign-in wait *is* cancellable in the shell, with one
Ctrl+C, and the reason is not the flag.
Sampled in both hosts on macOS —
full record in [`transcript-motherduck.md`](transcript-motherduck.md),
which is where MotherDuck itself was exercised, this machine having
neither an account nor a route to it:

* **CLI.** The handler is the shell's `InterruptHandler` until the
  sign-in prompt prints, then `md::login::detail::sighandler` in
  MotherDuck's implementation extension for the whole wait, then the
  shell's again once the statement ends.
  MotherDuck installs a handler of its own around the wait, with
  `SA_SIGINFO` and — the working part — without `SA_RESTART`, so a
  blocking call in that wait returns `EINTR` instead of resuming.
* **R.** The handler is `ScopedInterruptHandler::signal_handler` for the
  entire wait, across three Ctrl+C. MotherDuck's never appears.

So the difference is that MotherDuck makes its wait cancellable, and
declines to do so under the R client.
Nothing was displaced: there is no handler of MotherDuck's to displace
in the R process, and the CLI run shows it installing over the shell's
handler without difficulty, so an already-installed handler is no
obstacle to it.
Neither is the flag a route in: this package sets
`ClientContext::interrupted` exactly as the shell does, and the sign-in
wait does not read it in either host.

The condition MotherDuck tests is the name the client announces.
This package announces `duckdb_api = r-dbi`
([`src/database.cpp`](/src/database.cpp)) where the shell announces
`cli`, and user config is applied after that default, so
`MD_PROBE_DUCKDB_API=cli` in [`md-probe.R`](md-probe.R) overrides it.
Run that way, Ctrl+C cancels the sign-in wait from R.
One switch, one behaviour: nothing else about the connection changed,
so the client's name is what MotherDuck branches on.
The reported case, and the line that changes its outcome:

```r
library(duckdb)

# Ctrl+C does not reach the sign-in wait
con <- dbConnect(duckdb())
dbExecute(con, "ATTACH 'md:'")

# ... and does, when the connection answers to the shell's name
con <- dbConnect(duckdb(config = list(duckdb_api = "cli")))
dbExecute(con, "ATTACH 'md:'")
```

Which is a diagnosis, not a remedy to pass on.
The name is not a private channel to MotherDuck, so a connection
claiming to be the shell is answered as the shell by everything else
that asks;
and what ends the wait is then MotherDuck's handler rather than the
package's, so the statement fails with MotherDuck's own error and raises
no R interrupt condition —
`HandleInterrupt()` ([`src/signal.cpp`](/src/signal.cpp)) raises only
for a signal the package's own handler took.

## Running the probe

Build with [`build-sigprobe.sh`](build-sigprobe.sh), then
[`md-probe.R`](md-probe.R) for the R side;
the same library preloads into the CLI, where its constructor starts the
same sampler.
It reads the disposition through `sigaction(2)` and names the owning
library through `dladdr(3)` from a sampling thread, so it reports while
the host is blocked, needs no debugger, and carries no per-platform
struct offsets — a debugger is awkward to attach on macOS, and
`struct sigaction` is not laid out the same way there.
