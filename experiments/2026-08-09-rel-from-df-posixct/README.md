# What `posixct` would cost the relational path

*What it measures:* what `rel_from_df()` and `rel_to_altrep()` do to a
`POSIXct` column now that `posixct` defaults to `"timestamptz"` —
which columns the strict check accepts, and whether what it accepts
comes back with the same `tzone` — for the shipped policy and the three
alternatives to it, across column label × `timezone_out` ×
session `TimeZone`, 36 cells each;
and, separately, which session zone a user gets without setting one.

*When and on what:* 2026-08-09, duckdb 1.5.5.9013
(DuckDB 1.5.5, fast-path build against the release `libduckdb`,
so icu is linked in and the session `TimeZone` exists from startup),
R 4.5.3, Linux, machine zone `Etc/UTC`.

*What it supports:*
[`usage/relational/`](/handbook/usage/relational/README.md)
and [`usage/timestamps/`](/handbook/usage/timestamps/README.md).

Run [`run.sh`](run.sh) with `DUCKDB_R_USE_SYSTEM_LIB=1` on a clean
tree; one policy's run is [`grid.R`](grid.R), the default-zone probe is
[`default-zone.R`](default-zone.R), the policies other than the shipped
one are the patches under [`patches/`](patches/),
and the recorded run is [`grid.md`](grid.md).
[`run-defaults.sh`](run-defaults.sh) asks the second question below over
[`defaults-grid.R`](defaults-grid.R), recorded in
[`defaults.md`](defaults.md).

**Why the check is in question.**
`rel_from_df()` refuses a `POSIXct` column whose `tzone` is not
`timezone_out`, so that a relation duckplyr builds from a data frame
returns that data frame and not a relabeled copy of it.
A `TIMESTAMPTZ` column is labeled with the session `TimeZone` instead,
so following the new default would leave the check comparing against a
zone the column no longer comes back in: the guard still fires, just
not on what it guards.

**The policies.**

* `baseline` — the tree before `posixct` existed, `origin/main`.
* `timestamp-rel` — what ships: the relational path pins
  `posixct = "timestamp"` and the check is left alone.
* `follow` — take the connection's setting, check unchanged.
* `session-tz` — follow, and compare against the session `TimeZone`,
  the zone the column will actually come back in.
* `relaxed` — follow, and accept every `POSIXct`, on the grounds that
  the instant survives whatever labels it.

**The verdicts.**
A cell is `ok` when the column is accepted and comes back with the same
`tzone`, `refused` when the check rejects it — duckplyr falls back to
dplyr, which is slower and correct — and `relabeled` when it is
accepted and comes back with a different `tzone`, which is a wrong
answer nothing reports. No cell moved an instant.

| policy | ok | refused | relabeled |
|---|---|---|---|
| `baseline` | 9 | 24 | 3 |
| `timestamp-rel` | 9 | 24 | 3 |
| `follow` | 2 | 24 | 10 |
| `session-tz` | 6 | 30 | 0 |
| `relaxed` | 6 | 0 | 30 |

**What the numbers say.**

`timestamp-rel` reproduces `baseline` cell for cell, which is the point
of shipping it: the relational path is the one place a `POSIXct` still
crosses as `TIMESTAMP`, so duckplyr sees no change at all. Its three
relabeled cells are the `tzone = ""` column coming back with no `tzone`
attribute, which is older than this question and pinned as expected in
[`tests/testthat/test-timezone.R`](/tests/testthat/test-timezone.R).

`follow` is the one to avoid. Taking the setting while keeping the old
check turns 7 of the baseline's refusals into silent relabels, from 3
to 10, and drops `ok` from 9 to 2. Every cell it loses, it loses
quietly.

`session-tz` is the principled fix and the surprising loser. It never
relabels — by construction, since it accepts exactly the columns whose
label already matches the session's — but which columns those are is
decided by the machine the code runs on. An icu-linked build echoes the
machine's `TZ` as the session zone verbatim, so a column labeled
`"UTC"`, which is what `timezone_out`'s own default produces, is
accepted where `TZ=UTC` and refused where `TZ=Etc/UTC` or
`TZ=Europe/Zurich`: the check compares strings, and two of those name
the same zone. A build with no icu reports `"UTC"` whatever the machine
says. So duckplyr's fast path would work in a `TZ=UTC` container and
fall back on the laptop that pushed to it, which is worse than the 6
refusals it buys back — and worse than a difference a build flag would
at least make visible.

`relaxed` is worst: 30 of 36 cells silently relabeled.

So the relational path keeps `TIMESTAMP`
([`R/relational.R`](/R/relational.R)), and the setting reaches it only
when a caller passes `convert_opts` themselves.
What would let it follow the default is a per-column zone on the
result — the label is per session in DuckDB's model
([`plan/history/2026-05-timestamptz-icu.md`](/plan/history/2026-05-timestamptz-icu.md)) —
or duckplyr deciding a session-zone label is one it can live with
([#2574](https://github.com/duckdb/duckdb-r/issues/2574)).

**Why the machine zone is not a grid dimension.**
Every cell sets the session zone explicitly, so the machine's `TZ`
cannot reach the measurement. It decides only which row a user lands in
by default, and that is what the default-zone probe records: five
machine zones, five session zones, echoed verbatim. `Etc/UTC` in the
run above is this container's `TZ`, not a DuckDB default.

## What the defaults do

The grid above sets the session zone in every cell. Setting nothing is
the commoner case, and it asks a different question: is the answer the
same on every machine? [`defaults.md`](defaults.md) runs column label ×
`timezone_out` against three machine zones, for the shipped tree and
for `pin-session` — a patch that issues `SET TimeZone = timezone_out`
at connect when icu is already loaded.

**The shipped default DBI round trip follows the machine.**
`dbWriteTable()` then `dbReadTable()` of a column labeled `"UTC"`
returns `"UTC"` where `TZ=UTC`, `"Etc/UTC"` where `TZ=Etc/UTC`, and
`"Europe/Zurich"` where `TZ=Europe/Zurich`. The instant is right in all
three; the label is the machine's. Under `TZ=UTC` three of the twelve
cells round-trip unchanged, under either other zone none of them do.
This is the writing direction inheriting what
[#2401](https://github.com/duckdb/duckdb-r/pull/2401) established for
reading, and it is why a package whose tests compare timestamps can
pass in a `TZ=UTC` runner and fail on a contributor's laptop.

**Pinning the session zone removes the machine from the answer.**
Under `pin-session`, `dbi_back` is `timezone_out` in all nine
non-empty-`timezone_out` cells of every machine zone, and the
`"UTC"`/`"UTC"` cell round-trips unchanged everywhere. Only
`timezone_out = ""` still varies, which is what it asks for. The same
pin makes the relational check correct again — the round-trip label
becomes `timezone_out`, which is the zone the check already compares
against — so `rel_from_df()` could follow the default with no new
relabeling, rather than pinning `TIMESTAMP`.

Two cells get worse under the patch as written: `timezone_out = ""`
with an unlabeled column comes back labeled with the machine's zone
where the shipped tree leaves it unlabeled. Matching what plain
`TIMESTAMP` already does — no label at all when `timezone_out` is
empty — would settle those.

**What neither run covers.**
Whether the connect-time `SET` can be issued safely on a build without
icu. The guard is to ask `duckdb_extensions()` first and skip when icu
is not loaded, since `SET TimeZone` is an icu setting and asking for it
otherwise attempts an autoload; on the fast path icu is linked in, so
the skip branch is never exercised here.

**What this run does not cover.**
A build without icu, where `SET TimeZone` fails for every value and the
session zone reads `"UTC"`: on the fast path icu is linked in and its
absence cannot be produced. The grid reaches that zone by setting it
(`session = UTC`), which is the same label, so only the inability to
change it is missing.
