# Reverse dependencies

Checking the packages that depend on this one before a release.

revdepcheck runs against the `.dev` build at the pinned release
candidate, twice per release:
an early pass with time to act on what it finds,
and a second pass (≈ T−7) that is the go/no-go gate —
CRAN policy requires contacting affected maintainers *well before*
a breaking release, which is why both runs precede the tag.

```r
revdepcheck::revdep_check(num_workers = 8, env = c(MAKEVARS = "-j8"))
```

Results live under [`revdep/`](/revdep/README.md);
[`revdep.yaml`](/.github/workflows/revdep.yaml) runs the check on
push to `revdep*` branches, never on `main`.
Where the runs sit in the release sequence is
[`operations/releases/process/`](/handbook/operations/releases/process/README.md);
duckplyr, the closest downstream, also gates individual changes
(for instance the typed-`NA` flip,
[#155](https://github.com/duckdb/duckdb-r/issues/155)).

*To deepen: state what blocks a release versus what is noted and
waved through, from the last release's record.*
