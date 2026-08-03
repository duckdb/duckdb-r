# Reverse dependencies

Checking the packages that depend on this one before a release.

Two routes, and they produce different things.

**revdepcheck, run locally**, against the `.dev` build at the pinned
release candidate.
It installs each reverse dependency twice, old engine and new,
and writes the comparison under [`revdep/`](/revdep/README.md),
which is what gets committed and read.
That directory carries no backreference to this leaf and cannot:
revdepcheck writes it, and the generator is upstream's
([`meta/handbook/`](/handbook/meta/handbook/README.md)).

```r
revdepcheck::revdep_check(
  num_workers = 8,
  env = c(revdepcheck::revdep_env_vars(), MAKEFLAGS = "-j8")
)
```

**[`revdep.yaml`](/.github/workflows/revdep.yaml)**, on push to a
`revdep*` branch and never on `main`.
It builds one job per reverse dependency, runs
`rcmdcheck::rcmdcheck()` against the old and the new build,
compares the two with `rcmdcheck::compare_checks()`,
and uploads the pair as an artifact only when they differ.
It commits nothing.

When the runs happen — an early pass and a go/no-go gate before the
tag — is
[`operations/releases/process/`](/handbook/operations/releases/process/README.md)'s.
duckplyr, the closest downstream, also gates individual changes
(for instance the typed-`NA` flip,
[#155](https://github.com/duckdb/duckdb-r/issues/155)).

*To deepen: state what blocks a release versus what is noted and
waved through, from the last release's record.*
