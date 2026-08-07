# The August 2026 forward of all three series

*A record, not a leaf.*
On 2026-08-06 all three live series were forwarded onto the current
mainline at once — `v1.4-andium`, then `v1.5-variegata`, then `main` —
and this file is the list of glue-code changes that took,
where each one was placed, and what the run found out about the routine.
The routine itself is owned by
[`.claude/skills/series-forward.md`](/.claude/skills/series-forward.md)
and [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md);
what a glue adaptation may be is
[`architecture/glue/`](/handbook/architecture/glue/README.md)'s.
Where one of those and this record disagree, they are right —
this describes one run, on the day it happened, and nothing keeps it
current.

The twelve `-fwd-*` refs were built locally and deliberately **not
pushed**: the CI/CD side was not in a state to judge them,
and a forward series that nothing is verifying is better as four local
refs than as four refs consumers can see.
Every SHA quoted below names a commit that already exists —
on `main` here, or on the series refs in the fork —
so the list can be re-derived without the local build.

## What each forward took

* **`v1.4-andium-fwd`** — base `v1.4-andium` @ `2b5afce5a`,
  1 vendor commit replayed, no conflict, no glue change.
  A frozen series seeds from its own release line rather than from
  `main`, so the base moved only by the two commits that line gained
  since the old seed
  ([#2433](https://github.com/duckdb/duckdb-r/pull/2433) and the
  `each-rcc` race fix beneath it).
  The seed was **replayed**, not regenerated — see the second finding
  below.
* **`v1.5-variegata-fwd`** — base `main` @ `faa1610b5`,
  14 vendor commits replayed, no conflict, no glue change.
* **`main-fwd`** — base `main` @ `faa1610b5`,
  1133 vendor commits replayed, no conflict,
  plus three `patch/` entries folded into the commits that first need
  them (below).

For all three, the whole glue delta between the old buffer tip and the
new one is exactly what `main` gained in the window —
`src/rfuns.cpp`'s handbook backreference, the flavored
`src/duckdb.<flavor>-win.def`, the removal of `src/CMakeLists.txt`, and
the R-side documentation work.
Nothing upstream had moved under the glue since the buffers were built,
which is why the replay was quiet.
That is the expected shape of a forward run soon after the last one,
not a claim about forwards in general.

## The glue set `main-fwd-build` carries

39 of the 1133 replayed vendor commits carry a hand-written glue
adaptation.
The replay is a cherry-pick of each commit's diff, so every one of them
rides in the commit that made it, by construction —
there was nothing to place and nothing to decide.
The list is here because it is the only place the *shape* of the range is
visible: upstream spent this window making the engine's C++ API
narrower, and the same call sites were adapted repeatedly as it did.
Read it before the next forward:
resolving one conflict against one upstream change rederives work a later
commit in the same range already did.
[`scripts/series-glue.sh`](/scripts/series-glue.sh) prints it from the
branch; what the script cannot say is which entries belong together.

**Members become accessors.**
The largest strand: upstream privatised member after member and migrated
its own call sites in the same change, so the glue followed each time.

* `duckdb#22351` (`b43ded70e`) — `(Base)Expression`:
  `expr->alias` → `SetAlias()`, `expr->type` → `GetExpressionType()`,
  `->return_type` → `GetReturnType()`.
* `duckdb#22463` (`f514c965b`) — `ConstantExpression::value` →
  `GetValue()`.
* `duckdb#22942` (`8b29d243a`) — `FunctionExpression` and
  `WindowExpression`: `order_bys`, `filter`, `start`, `end`,
  `start_expr`, `end_expr`, `partitions`, `children` all become
  `…Mutable()` accessors.
* `duckdb#22985` (`960f2313b`) — the bound expressions:
  `BoundConstantExpression::value` → `GetValue()`,
  `conj.children` → `GetChildren()`.
* `duckdb#24273` (`29de1cde1`) — `PreparedStatement`:
  `named_param_map.size()` → `GetParameterCount()`,
  `stmt->context` → `TryGetContext()`.
* `duckdb#24351` (`4d43cb0cd`) — `PreparedStatement::error` →
  `GetErrorObject()`, which keeps the type and extra info that
  `rapi_error_with_context()` reports.
* `duckdb#24357` (`d4729fda1`) — `BaseQueryResult`: `type`, `types`,
  `names` → `GetResultType()`, `GetTypes()`, `GetNames()`.

**Const and mutable split apart.**
Reading a vector and writing one stopped being the same call.

* `duckdb#21978` (`49c5ca9a0`) — `FlatVector::GetData<T>` returns
  `const`; every write site takes `GetDataMutable<T>`.
* `duckdb#22122` (`2c5e70ae4`) — the same for
  `FlatVector::Validity` → `ValidityMutable`.
* `duckdb#22157` (`6fd32a9fa`) — `ListVector::GetEntry` → `GetChild` /
  `GetChildMutable`, and `ArrayVector` likewise.
* `duckdb#21612` (`85cdd4637`) — `Vector` lost its implicit copy, so
  `auto input = args.data[0]` became `auto &input`.
* `duckdb#21534` (`91e259775`) — `StructVector::GetEntries()` hands back
  references rather than `unique_ptr`s; one `*` dropped at each site.
* `duckdb#21526` (`081843d28`) — vector helpers moved to their own
  headers; four glue units gained includes.
* `duckdb#22268` (`ddb56a47a`) — `Vector::Reference(Value &)` requires a
  count.
* `duckdb#22377` (`27ced7204`) — `DataChunk::SetCardinality` →
  `SetChildCardinality`.
* `duckdb#22493` (`0c812b11a`) — the `count` overloads of
  `ToUnifiedFormat` and friends are deprecated.
* `duckdb#21679` (`f1a8e3410`) — `ValidityMask::AllValid` →
  `CannotHaveNull`.

**`Identifier` replaces `string` for every name.**
The single widest change in the range: names in the parser, the catalog
and the result stopped being strings.

* `duckdb#23161` (`bec92045d`) — the type arrives.
  Seven glue units promote R names to `Identifier` explicitly and read
  them back through `GetIdentifierName()`;
  whole vectors go through upstream's own `StringsToIdentifiers()` and
  `IdentifiersToStrings()`.
  The explicitness is the point: the conversion discards the
  case-insensitive semantics the type carries.
* `duckdb#24269` (`4ece94def`) — COPY and scan options:
  `ListToVectorOfValue()` returns `identifier_map_t<vector<Value>>`.
  Option-name lookup stays case-insensitive, because `Identifier`
  compares and hashes case-insensitively just as `case_insensitive_map_t`
  did.
* `duckdb#24278` (`419eca006`) — `table_function_bind_t` hands back
  `vector<Identifier>`; `DataFrameScanBind()` is the one glue call site.

**Table filters become expressions.**
The Arrow pushdown translation in `src/register.cpp` was rewritten under
us in five steps, and only the last spelling survives the range.

* `duckdb#21229` (`58b9ba197`) — `TableFilterSet` members go private;
  iterate the set, ask `HasFilters()`.
* `duckdb#21497` (`646d546f2`) — `ColumnIndex()` → `GetIndex()`.
* `duckdb#22005` (`bed8c8fde`) — `EXPRESSION_FILTER` arrives;
  the glue gains `TransformExpression()` for bound comparisons and
  conjunctions.
* `duckdb#22514` (`5f41c3726`) — `BoundComparisonExpression` becomes a
  `BoundFunctionExpression`; read sides via `Left()` / `Right()`.
* `duckdb#22617` (`cad2a51c3`) — the remaining filter types are renamed
  `LEGACY_*`, their classes `Legacy…Filter`, and
  `TableFilter::ToString(column_name)` goes away —
  replaced here by a local `FilterDescription()` over `EnumUtil`.

**Function binding grew a parameter object.**

* `duckdb#22034` (`8b15c103d`) — bind callbacks take
  `BindAggregateFunctionInput &` / `BindScalarFunctionInput &` instead of
  three loose parameters.
* `duckdb#22428` (`099b43986`) — assigning the bound function is
  replaced by `ReplaceImplementation()`.
* `duckdb#22400` (`cd1e356f7`) — `ExecuteWithNulls` retires;
  the executors take a lambda returning `optional<T>`, so `rfuns`'
  overflow and NaN paths return `nullopt` instead of poking a
  `ValidityMask`.
* `duckdb#22941` and `duckdb#23059` (`c00bd841f`, `f3cdc78fd`) —
  function children become `FunctionArgument`s, for window functions too.
* `duckdb#21562` (`dc12f181d`) — the `WindowExpression` constructor
  loses its window-type argument, and `LEAD`/`LAG` offsets move into the
  children; the glue casts the offset to `BIGINT` there, which is the one
  entry in this list that is a fix rather than a translation.

**New types and renamed fields.**

* `duckdb#22412` (`efadbcbb1`) — `TIMESTAMP_TZ_NS`, carried through
  `duckdb_r_typeof()`, `duckdb_r_decorate()`, `duckdb_r_transform()` and
  `DetectLogicalType()`.
* `duckdb#23017` (`80916e01c`) — `SQLNULL` becomes a result type;
  mapped to `INTSXP`.
* `duckdb#23493` (`c7f37720c`) — `dtime_t::micros` → `.value`.
* `duckdb#23222` and `duckdb#23470` (`4089414d1`, `db677d3ea`) —
  `ExplainFormat` folds into `ProfilerPrintFormat`, then the renderer
  registry keys on the lowercase name, so `rapi_rel_explain()` lowercases
  what R passes.
* `duckdb#23579` (`2beb9245d`) — an include the cleanup stopped
  providing transitively.

**Two entries that are not upstream's doing.**
`a361d748f` and `1a2b23e10` are the rewind pair at the foot of the
buffer: the range starts at the fork point of the mainline rewind, so
`src/reltoaltrep.cpp`'s `max_expression_depth` handling is first rewound
to the fork-point spelling and then re-adapted to the settings API by the
merge commit that brings it back.
They cancel out over the range and mean nothing on their own.

## Where the modifications were placed

**The 39 glue adaptations: nowhere new.**
Each rides in the vendor commit that made it, because that is what
replaying a diff does.
No conflict arose in any of the three replays, so no resolution had to be
routed anywhere.

**Three `patch/` entries: folded into the commit that first needs each.**
Above its seed, `main-build` carries five commits that vendor nothing,
and [`series-forward-build.sh`](/scripts/series-forward-build.sh) replays
only `vendor:` subjects, so all five were dropped.
Two of them were harmless — their content had since reached `main`
(`fix(rconfigure)` as
[`8b5eb9c88`](https://github.com/duckdb/duckdb-r/commit/8b5eb9c88), the
`patch/0034` carry as part of
[`e54313d7f`](https://github.com/duckdb/duckdb-r/commit/e54313d7f)) and
the regenerated seed brings it.
The other three had not, and each was folded into the vendor commit that
brings in the code its patch answers:

* `patch/0035`, silencing the deprecated `Catalog::GetEntry()`
  self-delegation, into `duckdb/duckdb@6d4f53284` —
  the commit that puts the 14 `[[deprecated]]` attributes into
  `catalog.hpp`; its parent has none.
* `patch/0037`, casting to `void *` in the default aggregate state
  initializer, into `duckdb/duckdb@2daa4fc9a` —
  the eager-aggregation change that introduces the `memset` over a
  non-trivial state.
* `patch/0036`, guarding the assert-only plan verifiers, into
  `duckdb/duckdb@8956cec9b` —
  the correlated-join change that adds them, growing `planner.cpp` from
  268 lines to 339.

Not the position each held in the buffer.
The rule those three answer to is
[`vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)'s;
what this run adds is the size of the span it governs.
The entries were written when r-universe reported the diagnostics, and
the upstream changes that raised them sit far below:
312 commits below for `patch/0035`, 292 for `patch/0037`, 77 for
`patch/0036`.
Every one of those commits carried a warning the same branch already knew
how to silence, on exactly the platforms no verdict covers.

Verified per commit rather than at the tip:
every commit from each fold point to the buffer tip carries the patched
hunk and the `patch/` file, the fold commit's parent carries neither, and
the tip's `src/duckdb/` and `patch/` match `main-build`'s byte for byte.
The last of those is what the first pass failed silently —
a vendor diff taken after a patch landed is patch-neutral in the patched
region, so replaying it onto a tree that lacks the patch applies cleanly
and leaves the region unpatched
([#2545](https://github.com/duckdb/duckdb-r/issues/2545)).

**`main-fwd-dev`: nothing placed, but something to mine.**
All four refs start equal at the seed tip, as the day-one rule requires.
What the next firing must know is that `main-dev` holds glue its buffer
never had, and the forward's `-dev` starts without it:

* `duckdb/duckdb@b5e4f5bec` — `main-build` (`29de1cde1`) adapts
  `src/statement.cpp` to `GetParameterCount()` and `TryGetContext()`;
  `main-dev` (`3312fa9e9`) additionally introduces `RCallbackScope` in
  `src/include/rapi.hpp` and arms it at the three sites where duckdb runs
  R code under the client-context lock.
  That is the crash-class fix
  [`architecture/glue/`](/handbook/architecture/glue/README.md) states as
  a rule, and it exists only on `-dev`.
* `duckdb/duckdb@0f0cd4fb6` — `main-dev` (`ba9cb11cc`) only:
  `LogicalType::TUPLE` travels with `STRUCT`, and
  `RApiTypes::StructLikeChildTypes()` synthesises the positional member
  names a data frame needs.
* `duckdb/duckdb@24c543706` — `main-dev` (`e740a81ff`) only:
  `rel_to_parquet()` rejects an empty `file_name` on the R side, because
  upstream stopped erroring on it.

The other 39 glue adaptations are identical on both branches.
Neither `v1.5-variegata` nor `v1.4-andium` has any `-dev`-only glue: for
those two the `-build`↔`-dev` delta is exactly the forward-ports from
`main`, which the new seed already carries.

## What the run found out

**A forward silently loses a buffer's non-vendor commits, and `-build`
has them.**
`series-forward.md` justifies replaying `vendor:` subjects only by saying
that a `-dev` branch's other commits belong to `main` and are already in
the seed.
That holds for `-dev`.
It does not hold for `-build`, which by design takes no ports and
therefore carries its own `patch/` commits — the ones stage 3 requires be
committed onto the buffer as well as onto `-dev`.
The failure is quiet: the first `main-fwd-build` came out with zero
conflicts and a vendored tree differing from the buffer's by 20 lines
across three files, plus three missing `patch/` entries.
Only a tree comparison against the source buffer showed it.
Fixed in this change
([#2545](https://github.com/duckdb/duckdb-r/issues/2545)):
the replay classifies every non-vendor commit above the buffer's first
vendor commit, and refuses to start while one carries a change the new
base does not have.
Two tests decide it — the commit's diff reverse-applying to the new
base, and patch-id equality against what that base gained — because each
catches what the other misses on the five commits this run had to judge,
and a false alarm costs one `--placed` where a miss costs the forward.

**The seed needs `krlmlr/cpp11` installed, and the run did not have it.**
`scripts/flavor.sh` runs `cpp11::cpp_register()`, whose symbol names come
from the cpp11 in the library rather than from the vendored headers.
CRAN's spells the `.Call` prefix with `sub("[.]", "_", package)`, first
dot only, so `flavor.sh 1.5.dev` on current `main` generated
`_duckdb_1.5.dev_rapi_connect`, which is not a C identifier;
`flavor.sh dev` came out byte-identical to the seed the `main` series was
built on, because `duckdb.dev` has one dot.
The first pass read that as an unavoidable trap and worked around it,
taking `R/cpp11.R` and `src/cpp11.cpp` from the old seed for `1.5.dev`
after checking that `main` had not touched their unflavored originals.
It is not unavoidable.
[`krlmlr/cpp11`](https://github.com/krlmlr/cpp11) spells that `gsub`,
and installing it from GitHub makes `flavor.sh 1.5.dev` generate the
correct `_duckdb_1_5_dev_` prefix directly —
byte-identical to what the workaround produced, which is the check that
the workaround had been right and is now unnecessary.
Two things hid it.
The fork was named in
[`architecture/glue/`](/handbook/architecture/glue/README.md), but as the
origin of the *vendored headers*, with multi-dot support listed among
what they carry; the generator is neither vendored nor a declared
dependency, and no page said which one to install —
`scripts/VENDORING.md` asked for "the `cpp11` and `decor` R packages"
flat.
And `krlmlr.r-universe.dev` does not build cpp11, so
`install.packages("cpp11", repos = c(krlmlr, CRAN))` falls through to
CRAN and reports installing cpp11 0.5.5, which reads like success.
Corrected in this change, mostly by a check rather than by prose:
[`scripts/flavor.sh`](/scripts/flavor.sh) now refuses a generated binding
whose entry points are not C identifiers, so the failure this run took
for unavoidable cannot be reached quietly again.
The script also prepares the whole rename before committing any of it,
and restores the tree when it cannot finish,
so the half-applied flavor a missing prerequisite used to leave —
its first commit lands before `cpp_register()` runs — is not reachable
either.
The pages keep only what neither can say:
[`architecture/glue/`](/handbook/architecture/glue/README.md) that the
generator is a second, unvendored half of cpp11 and has to be the fork.
The `v1.4-andium` seed is still replayed rather than regenerated, for an
unrelated reason: a frozen series regenerates on its own release branch,
and `v1.4-andium`'s `scripts/flavor.sh` predates the GNU-sed fix
[#2510](https://github.com/duckdb/duckdb-r/pull/2510) that `main` has.

**A frozen series' forward hands its tooling back.**
`v1.4-andium-fwd`'s seed comes from the `v1.4-andium` release line, which
is 93 files behind `main` on `.github/`, `scripts/` and `.claude/`.
`v1.4-andium-dev` was level with `main` through stage 4's sync commits;
`v1.4-andium-fwd-dev` starts at the seed, so it is 93 files behind again
until the next firing's stage 4 re-ports them.
Nothing is lost and no judgement is needed — the port is mechanical — but
the forward is only free of that churn if the release line is brought
level first, which is what
[#2429](https://github.com/duckdb/duckdb-r/pull/2429),
[#2430](https://github.com/duckdb/duckdb-r/pull/2430) and
[#2433](https://github.com/duckdb/duckdb-r/pull/2433) did for the
previous one.

**One of the three carried patches belongs on `main`.**
Stage 3's routing rule is that a fix is series-specific only when the
code it touches is not on `main`.
Tested against `main`'s tree: `patch/0036` and `patch/0037` do not apply
— their code arrived after the engine `main` vendors — so they are
correctly the series'.
`patch/0035` **does** apply.
Landing it on `main` would put it in every future seed and end its
per-forward carry;
until then every forward of every series has to place it by hand.

**`patch/0034` is two files.**
`main-build` carries both
`patch/0034-Guard-explicit-producer-token-in-concurrent-queue.patch`
(minted inside a vendor commit, `704336470`) and
`patch/0034-Undef-ERROR-for-the-unity-build.patch` (from `main`).
`vendor-one.sh` globs the directory, so both apply and nothing
misbehaves; the collision is in the naming only, and it predates this
run.
