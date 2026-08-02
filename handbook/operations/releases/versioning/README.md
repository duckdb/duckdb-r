# Versioning

The package version lives in exactly one place —
`Version:` in `DESCRIPTION`.
Versioning owns what its components mean,
which of them advance on their own,
how `fledge` advances one of them and writes `NEWS.md`,
and what number a release finally carries.

The version has up to five dot-separated components.
Two of them are independent counters
that advance on different strands and never interfere:

| Component | Example | Meaning | Advanced by |
|-----------|---------|---------|-------------|
| 1–3 (`major.minor.patch`) | `1.5.5` | release-line identity — the upstream DuckDB tag | set explicitly at release |
| 4th | `1.5.5.9004` | **R-client counter** | `fledge`, on the glue source of truth (`main`) |
| 5th | `1.5.3.9006.42` | **vendor counter** | `scripts/vendor-one.sh`, once per vendor commit |

`main`'s `Version: 1.5.5.9004` is exactly that shape:
the released prefix `1.5.5`,
the R-client counter at `9004`,
and no fifth component at all,
because vendor commits do not land on `main`.

## The R-client counter

The 4th component free-runs on `main`,
which is where every glue, R, test, and CI change is born.
It counts development on the R side of the package
and says nothing about the engine.

On a `-dev` branch the 4th component is inherited and then frozen:
each strand owns one counter and freezes the other,
which is the property the merge driver below depends on.
The per-branch statements of this
— what each branch's version must look like at any moment —
are the version invariants at
[`branches/invariants/`](/handbook/branches/invariants/README.md).

## The vendor counter

`scripts/vendor-one.sh` bumps the 5th component once per vendor commit,
filling any missing intermediate component with zero:
`1.2.3` becomes `1.2.3.0.1`,
`1.2.3.9000` becomes `1.2.3.9000.1`,
and `1.2.3.9000.4` becomes `1.2.3.9000.5`.
The point is that every vendor commit is installable
as a distinct version on r-universe.

The 5th component is a dev-branch affair.
`scripts/flavor.sh` never stamps it,
and a regular LTS flavor keeps a four-component version.
Under the series loop the seed carries a separate
`chore: Add fifth version component` commit
that stamps the counter's zero,
so every commit on the series is orderable by version
from the first one onward.
It orders, it does not count:
when a broken vendor commit is folded into the commit that fixes it,
the gap it leaves in the counter is accepted.

## What a release carries

A released version is normally the bare three-component prefix,
matching the upstream tag.
It is **not** derived from git —
the tag follows `DESCRIPTION`, never the other way round —
so it is set explicitly when the tagged content reaches the stable branch:

```r
fledge::bump_version("X.Y.Z")
```

Where that happens in the release sequence is
[`process/`](/handbook/operations/releases/process/README.md)'s;
what happens afterwards is versioning's.
`main` moves on to its next development version
(the prefix plus a fresh 4th component, e.g. `X.Y.Z.9000`) via `fledge`,
and the series' dev branches resume the vendor counter
from the new baseline.

The bare prefix is the rule, not a guarantee.
When the R layer needs a fix and upstream has not tagged,
the package ships a release carrying a low 4th component instead:
`v1.5.4.1`, `v1.5.4.2`, and `v1.5.4.3` were cut that way,
and `NEWS.md` records them as releases between `1.5.4` and `1.5.5`.
Such a number is below the 9000 block the R-client counter uses,
so it never collides with a development version.

The vendored engine's own version string is a separate surface:
`R/version.R` is generated and carries `duckdb_version`.
It belongs to
[`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md),
not here.

## fledge

[fledge](https://fledge.cynkra.com) owns the 4th component and `NEWS.md`.
`.github/workflows/fledge.yaml` runs it daily at 00:30 UTC,
on manual dispatch,
and on any push to `main` that touches the workflow file itself.

Two guards run before anything is bumped.
The workflow skips forks outright,
and skips `krlmlr/duckdb-r` by name —
so no branch in the CI/CD fork ever receives a version bump
or a `NEWS.md` entry from it.
It also skips unless the first line of `NEWS.md` mentions fledge,
which is what the maintenance banner at the top of that file is for:
remove the banner and the automation stops.

The bump itself is
`fledge::bump_version(which = "dev", no_change_behavior = "noop")`
followed by `fledge::finalize_version(push = TRUE)`.
`noop` means a day with nothing new produces nothing.
Because `main` is protected,
the run pushes a `fledge` branch instead of committing to `main`,
opens a pull request,
triggers the `rcc` workflow on the head commit,
and enables squash auto-merge;
what lands reads `fledge: Bump version to 1.5.5.9004 (#2448)`.
A final step calls `fledge:::release_after_cran_built_binaries()`,
fledge's own post-CRAN hook —
its behavior belongs to fledge, not to this repository.

## `NEWS.md`

`NEWS.md` is generated, not written.
Its first line says so and tells contributors not to edit it.
The way to influence an entry is therefore to word the commit well:
fledge reads Conventional Commits subjects from `main` and maps
the type to a `##` section,
the scope to a `###` sub-heading,
and the subject to a bullet.
`ci(each): Queue the shards oldest first (#2445)` arrives as
`- Queue the shards oldest first (#2445).`
under `## Continuous integration` → `### each`.

Each bump opens a heading for the new development version.
Those headings are provisional:
at release they fold into the release's own heading.
Below the current development block
`NEWS.md` therefore carries release headings only,
even though every intermediate bump was also tagged
(`v1.5.4.9000` through `v1.5.4.9013` exist as tags
with no heading of their own).

The `-dev` branches never touch `NEWS.md`.
Between the strands only `DESCRIPTION:Version` differs,
which is what makes the merge driver a complete answer
to the recurring conflict.

## Why the counters need a merge driver

Both counters live on the same `Version:` line,
and both strands advance constantly:
`main` bumps the 4th daily,
every vendor commit bumps the 5th.
So a forward-port, a rebase, or a release merge
conflicts on that one line at essentially every commit —
replaying a pending window of hundreds of commits
would stop hundreds of times,
on a line whose correct value is mechanical.

The resolution is a git merge driver on `DESCRIPTION`.
It takes the component-wise maximum of the two sides,
gated on an equal `major.minor.patch` prefix.
Within a release line each strand keeps the counter it owns,
because it freezes the other:
`1.5.3.9008` merged with `1.5.3.9006.42` gives `1.5.3.9008.42`,
in either direction.
Across release lines —
forward-porting a `1.5.x` fix onto the `1.4.x` LTS —
the prefix gate keeps ours,
so a foreign prefix is never inherited.
The rest of `DESCRIPTION` still gets a normal three-way merge,
so two branches genuinely editing `Imports:` still conflict.

The driver never decides a release version.
Its only job is to stop the version line from halting a rebase;
the authoritative number is set by `fledge::bump_version()`
at the tip once the operation completes.

The mechanism — `scripts/merge-version.sh`,
the `merge=ours-version` attribute in `.gitattributes`,
and `scripts/setup-git.sh`,
which registers the driver per clone
and must run first in any job that rebases, cherry-picks, or merges —
belongs to
[`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Limits

* There is no automatic path from an upstream tag to `DESCRIPTION`.
  A release version is typed out once, by hand, through `fledge`.
* The counters carry no meaning beyond ordering.
  Neither the 4th nor the 5th component is a change count,
  and gaps in either are expected.
* fledge is an external tool.
  What this repository configures is the workflow file and the banner;
  how a bump or a `NEWS.md` entry is computed is fledge's own behavior.
* The version invariants that make the scheme checkable per branch —
  prefix lock, patch ordering, counter ownership, release shape —
  are stated at [`branches/invariants/`](/handbook/branches/invariants/README.md),
  not here.
