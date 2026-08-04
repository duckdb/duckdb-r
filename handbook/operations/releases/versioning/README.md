# Versioning

The package version — `Version:` in `DESCRIPTION`, the one place
it lives — its components, and the tools that advance them.
The full version handling inside the release sequence is in
[`process/`](/handbook/operations/releases/process/README.md).

Up to five dot-separated components; two are independent counters
that advance on different strands and never interfere:

| Component | Example | Meaning | Advanced by |
|---|---|---|---|
| 1–3 | `1.5.5` | release-line identity — the upstream DuckDB tag | set explicitly at release |
| 4th | `1.5.5.9004` | R-client counter | fledge, on `main` |
| 5th | `1.5.5.9004.42` | vendor counter | `scripts/vendor-one.sh`, once per vendor commit |

The 4th free-runs on `main`,
where every glue and R change is born,
and is inherited frozen on a `-dev` branch —
frozen at the value the series was seeded with,
because [`scripts/series-port.sh`](/scripts/series-port.sh) classifies a
version bump `VERSION` and does not port it
([#2496](https://github.com/duckdb/duckdb-r/issues/2496)).
A `-dev` version says which release line the series was seeded from
and how far its own vendoring has run;
what `main` is at today is read from `main`.
The 5th exists only on `-dev` branches, making every vendor commit
installable as a distinct version on r-universe.
Each strand owns one counter and freezes the other,
which is what lets the `DESCRIPTION` merge driver
([`scripts/merge-version.sh`](/scripts/merge-version.sh))
resolve the `Version:` line without a conflict:
it takes the component-wise **maximum** of the two sides,
gated on an equal `major.minor.patch` prefix,
so the fourth stays the R-client strand's and the fifth the vendor strand's,
and a cross-release forward-port never inherits a foreign prefix.
Every other line of `DESCRIPTION` still goes through a normal three-way merge.

On a `-dev` branch the vendor counter **orders, it does not count**:
gaps from folded repairs are accepted,
but it must rise strictly across a series' vendor commits —
r-universe installs by version,
so two commits sharing one are two it cannot tell apart.
Taking the maximum is what keeps that true through a replay,
but only while both strands share a `major.minor.patch` prefix.
Where they do not, the gate keeps our side verbatim,
so a replayed vendor commit arrives with its parent's counter
and the series stops being orderable —
the loop restamps by hand
([`.claude/skills/series-loop.md`](/.claude/skills/series-loop.md)).
`main-dev` carries the preview prefix `1.5.99`
and its buffer `main-build` carries `1.5.5`,
which is that state.
Aligning a series' two strands is the fix.

The prefix gate has a consequence worth knowing:
because the driver keeps *ours* verbatim when the prefixes differ,
it does **not** renumber a `-dev` branch when the base moves to a new
patch release.
Rebasing from `1.5.4.9005.N` onto a `1.5.5.9000` base leaves every commit
at the base version rather than producing `…9000.1`, `…2`, `…3`;
the vendor counter has to be re-applied as part of the rebase.
The gate is doing its job — this is the one case where it does less than
a reader might assume.

A **forward rebuild** is the exception.
[`scripts/series-forward-build.sh`](/scripts/series-forward-build.sh)
renumbers the fifth component as a true counter, one per replayed commit,
so the new chain counts itself rather than carrying the old one's numbering —
and the counter is read back from `HEAD` at each step,
which is what makes the replay restartable after a conflict.

A released version is the bare three-component prefix, matching
the upstream tag, set explicitly with
`fledge::bump_version("X.Y.Z")` —
never derived from git; the tag follows `DESCRIPTION`.
[`fledge.yaml`](/.github/workflows/fledge.yaml) runs fledge on `main`,
writing `NEWS.md` from commit messages
and merging its bump PR by squash — which is why commit messages on `main` are
written to be read as changelog entries.
