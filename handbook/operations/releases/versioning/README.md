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
and is inherited frozen on a `-dev` branch;
the 5th exists only on `-dev` branches, making every vendor commit
installable as a distinct version on r-universe.
Each strand owns one counter and freezes the other —
the property the `DESCRIPTION` merge driver depends on
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
The vendor counter orders, it does not count:
gaps from folded repairs are accepted,
but it must rise strictly across a series' vendor commits —
r-universe installs by version,
so two commits sharing one are two it cannot tell apart.
A replayed chain does not inherit that for free:
the merge driver keeps the replay target's `Version:` line
through every cherry-pick,
so [`scripts/series-advance.sh`](/scripts/series-advance.sh)
restamps the chain before pushing it.

A released version is the bare three-component prefix, matching
the upstream tag, set explicitly with
`fledge::bump_version("X.Y.Z")` —
never derived from git; the tag follows `DESCRIPTION`.
[`fledge.yaml`](/.github/workflows/fledge.yaml) runs fledge on `main`,
writing `NEWS.md` from commit messages
and merging its bump PR by squash — which is why commit messages on `main` are
written to be read as changelog entries.
