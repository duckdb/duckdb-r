# What this repository decides

The choices the shared rules ([`meta/handbook/`](/handbook/meta/handbook/README.md)) leave open, answered for this repository,
and the rules it adopts beyond the shared ones.
This is the one page under `meta/` that answers for this repository;
the shared pages beside it point to their home, [`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools),
and [`.handbook-source`](/.handbook-source) names the state of the source this handbook was last checked against.

**Intent and status.**
Intent lives in [`plan/`](/plan/README.md), one `PLAN-<topic>.md` per open design.
[`meta/plans/`](/handbook/meta/plans/README.md) owns the conventions there, including which way a plan leaves the directory.
Status lives in the issue tracker, and the verdicts an item can close under are
[`operations/triage/`](/handbook/operations/triage/README.md)'s.

**Evidence.**
Measurements live under [`experiments/`](/experiments/README.md), in the shared shape,
and the registry there names every record.

**What this repository does not author.**
The vendored engine under `src/duckdb/` is upstream's, and the patch stack under `patch/` is what this repository changes about it
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
Generated here are `man/*.Rd` from the roxygen blocks under `R/`,
the root [`README.md`](/README.md) and `.github/README.md` from [`README.Rmd`](/README.Rmd) through `make readme`,
the [`scripts/`](/scripts/README.md) index from the scripts' own headers,
and the flavor table [`branches/flavors/`](/handbook/branches/flavors/README.md) carries, from
[`scripts/series.yaml`](/scripts/series.yaml).
A generated file's prose is edited in its generator, never in its output,
and [`.handbook-ignore`](/.handbook-ignore) keeps the checks off what the generators own.

**The comment budget.**
R code is formatted by air, and a comment aims for the `line-width` that [`air.toml`](/air.toml) sets,
which is air's default of 80 characters today.
The C++ glue is formatted by clang-format, whose `ColumnLimit` [`.clang-format`](/.clang-format) sets to 120 today.

**Rules adopted beyond the shared ones.**

* **No em dashes**, in prose and code alike.
  A comma, a colon, a semicolon, or a parenthesis says the same thing.
  The rule binds what is written from now on; the tree predates it, so the check is off until a sweep clears what is there,
  and [`.handbook-ignore`](/.handbook-ignore) records that.
* **Verify a behavioural claim on a build that can show it.**
  A claim the fast path's release library could distort needs a vendored build
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)); for everything the two builds share, either will do.

**Documents shipped without the tree.**
`handbook/` is `.Rbuildignore`d, so a link into it is broken for the readers who arrive from CRAN or from a reference page.
A reference page's backreference therefore lives in a plain comment in its roxygen source under `R/`, never in a `#'` line,
and the root `README.md`'s lives in a Documentation section rather than above the first sentence,
edited in `README.Rmd` because both rendered files come from it.
`man/*.Rd` is auto-linked to the source it derives from and takes no backreference of its own.

**Enforcement.**
[`.github/workflows/handbook.yaml`](/.github/workflows/handbook.yaml) runs the check script on every pull request,
and, in a job of its own, holds the carried files against their source.
The generated documents are held to their sources by the generators that write them,
each invoked with `--check` and each named by the leaf that owns what it generates:
[`docs-readme.R`](/.claude/skills/docs-consistency/docs-readme.R) for the `scripts/` index,
[`scripts/series-table.R`](/scripts/series-table.R) for the flavor table,
and [`scripts/pull-config.sh`](/scripts/pull-config.sh) for the fork's mirror rules.
