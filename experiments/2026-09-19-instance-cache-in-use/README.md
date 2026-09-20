# Telling a database still in use from one shutting down

*What it measures:* which state DuckDB's `DBInstanceCache` is really in when it
finds a cache entry whose `DuckDB` handle is gone — a shutdown finishing, or an
instance nothing is shutting down — how each is reached through the public C API,
what the unpatched engine does in each, and what it costs to report the second
immediately rather than after a grace period.

*When and on what:* 2026-09-19, Linux x86_64, 4 cores.
The unpatched side is the released `libduckdb` v1.5.5 (upstream commit
`d8cdaa33fda`) that [`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh)
installs for the fast path
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
The patched side is a `RelWithDebInfo` build of `duckdb/duckdb` `main`
(v2.1.0-dev10582) carrying
[`patch/0042-Tell-a-database-still-in-use-from-a-shutdown-in-flight.patch`](/patch/0042-Tell-a-database-still-in-use-from-a-shutdown-in-flight.patch);
`src/main/db_instance_cache.cpp` is byte-identical on `main`, `v1.5-variegata`
and `v2.0-cyanoptera`, so the two sides differ in the patch and not in the code
it patches.
Method: [`run.sh`](run.sh), driving one standalone source per case --
[`in-use-connection.c`](in-use-connection.c), [`in-use-result.c`](in-use-result.c),
[`shutdown-race.c`](shutdown-race.c) and [`shutdown-race-tight.cpp`](shutdown-race-tight.cpp) --
output in [`transcript.txt`](transcript.txt).

*What it supports:* the patch above and its upstream counterpart, and the
instance-lifetime section of
[`usage/connections/`](/handbook/usage/connections/README.md).

## How it asks

`GetInstanceInternal()` finds a cache entry whose `weak_ptr<DuckDB>` has expired,
concludes another thread is shutting that database down, and spins until the
entry expires. One source per state that reaches that line, each a single file
with its own `main` and no switches, so any of them compiles and runs by hand:

* [`in-use-connection.c`](in-use-connection.c) — open through the cache,
  connect, release the handle with the connection still open.
* [`in-use-result.c`](in-use-result.c) — the same, but the connection is closed
  and a pending result holds the `ClientContext`, so no connection is registered.
* [`shutdown-race.c`](shutdown-race.c) — 200 rounds of releasing the last handle
  on a second thread while the first asks the cache for the same path. Nothing
  is in use, so every round must reopen.
* [`shutdown-race-tight.cpp`](shutdown-race-tight.cpp) — the same race, staged
  tightly.

The three C cases are the C API alone, so upstream can run them against any
`libduckdb` with a compiler and no container. The race is there twice because
the C API cannot stage it tightly: `duckdb_open_internal()` builds a `DBConfig`
and sets `duckdb_api` before it reaches the cache, and the shutdown has finished
by then. The C++ one reaches for `db_instance_cache.hpp` — which the vendored
tree carries — to put the two calls next to each other.

**Reading a run that does not finish.** Only the two in-use cases can wedge; the
race cases return, but each round pays a DuckDB startup and teardown, about
20 ms here, and a slower machine can take a race case past its budget. That is
why they count rounds as they go: a run that stops at a round is wedged, and one
still counting when it is killed was only slow. Lower `ROUNDS` before concluding
anything from a race case that ran long.

## What it found

**Both in-use states hang, and neither is a mistake.** Against the released
engine the two in-use cases spin at 100% CPU until the watchdog kills them, from a
sequence with nothing exotic in it: open, run a query, drop the handle without
clearing the result, open the same path again. `~DatabaseInstance` releases the
cache entry on its last line, and a `ClientContext` keeps a `DatabaseInstance`
alive, so the entry stays with a null handle and no shutdown to finish it.

**A `weak_ptr` to the instance tells the two apart, and the connection count says
which kind of in-use.** `~Connection` deregisters from the `ConnectionManager`
while an unfinished result does not, so a count of zero beside a live instance
names the result:

```
in-use-connection: refused: ... is still in use: 1 connection(s) are open on it
in-use-result:     refused: ... is still in use: no connections are open, but
                   something still holds it, such as an unfinished query result
```

**Reporting a live instance immediately is wrong, and measurably so.**
`~DuckDB` drops the handle before it drops the instance, so a shutdown that is
genuinely in flight also presents as a live instance with no handle. With the
grace period set to zero, the tight stager turned 2 of 200 rounds into spurious
refusals — a caller that spins today would have been told the database was in
use when nothing held it. At 100 ms it is 0 of 1000.

| variant | `shutdown-race`, tightly staged |
|---|---|
| report a live instance immediately | 198 reopened, 2 refused (200 rounds) |
| 100 ms grace period, as shipped | 1000 reopened, 0 refused (1000 rounds) |

The loose C-API stager reopens 200 of 200 under every variant, including the
unpatched engine, which is why it is not the one the table rests on.

## Replicating

```sh
scripts/install-libduckdb.sh                       # the unpatched side
experiments/2026-09-19-instance-cache-in-use/run.sh

experiments/2026-09-19-instance-cache-in-use/run.sh --lib path/to/patched/lib
```

`TIMEOUT` bounds the two in-use cases (default 15 seconds), `RACE_TIMEOUT` the
two race cases (default 300), and `ROUNDS` sets the race length (default 200).
Any single case also builds by hand against any `libduckdb`:

```sh
cc in-use-result.c -I ~/.local/include -L ~/.local/lib -lduckdb -o in-use-result
```

`shutdown-race-tight.cpp` compiles against the vendored headers, which carry the
patch's extra member once it is applied; the entry it sits in is only ever
constructed inside the library, so the layout the stager itself depends on is
the same either way.
