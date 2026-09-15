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

## The build with no icu in it

Neither run above can reach a session without icu: the fast path links
a release `libduckdb`, which has it. [`run-no-icu.sh`](run-no-icu.sh)
builds the vendored engine from source instead — `parquet` and
`core_functions` and nothing else
([`usage/extensions/`](/handbook/usage/extensions/README.md)) — and runs
[`no-icu.R`](no-icu.R) against it, recorded in
[`no-icu.md`](no-icu.md).

**Without icu the writing default has no machine to follow.**
`dbWriteTable()` still writes `TIMESTAMP WITH TIME ZONE`, the instant
still round-trips, and the label is `"UTC"` under `TZ=UTC` and under
`TZ=Europe/Zurich` alike — `GetClientProperties()` falls back to a
hardcoded `"UTC"` when the setting does not exist. So the machine
dependence measured above is not a property of the change; it is a
property of having icu.

**Asking about the zone in SQL is not free, and not safe.**
`current_setting('TimeZone')` and `SET TimeZone` both reach for icu.
With no icu installed, both raise an Extension Autoloading Error rather
than blocking — `autoinstall_known_extensions` is `false`, so autoload
loads a local extension but never downloads one, and the failure costs
0.2s, not a network timeout. `duckdb_extensions()` is the safe way to
ask: it reported icu without loading it in every cell.

**The label is order-dependent within one session.**
Where icu is installed but not loaded — which is what running
`INSTALL icu` once leaves behind — a `TIMESTAMPTZ` column is labeled
`"UTC"` until something touches the setting, and the machine's zone
afterwards. On `TZ=Europe/Zurich`, `current_setting('TimeZone')`
autoloads icu in 0.05s, and the same query that returned `"UTC"` before
it returns `"Europe/Zurich"` after. Nothing announces the switch, and
the toucher need not be the caller's own code.

That last one is what decides the pin. Guarding it on "icu is already
loaded" is *necessary* — an unguarded `SET` at connect raises on a
build without icu — but it is also *ineffective exactly where the
machine dependence lives*, because in the installed-but-not-loaded
state the guard skips and the first later touch of the setting brings
the machine's zone back. A pin that closed that hole would have to
`LOAD icu` at connect for everyone who has it cached, which is a much
larger change than a default.

**What none of these runs covers.**
Windows, where icu cannot be installed at all on the arm64 build
([`usage/extensions/`](/handbook/usage/extensions/README.md)), and any
platform where the extension exists but the machine zone is one R does
not know.
