# The suite

The `tests/testthat/` layout, its helpers,
and running the whole suite or one file.

```sh
R -q -e 'testthat::test_local()'                    # everything
R -q -e "testthat::test_local(filter = '^array$')"  # one file
```

`test_local()` runs the directory directly and never reads
`tests/testthat.R`, so the CRAN guard in that file
([`guards/`](/handbook/testing/guards/README.md))
gates `R CMD check` only — the local loop is never gated.
With the fast path set up
([`build/fast-paths/`](/handbook/build/fast-paths/README.md))
the edit-test loop stays in the seconds range.

**Layout.**
Tests are flat files `test-<topic>.R`,
named for the `R/` file they cover,
the DuckDB feature they round-trip,
or a shared prefix for multi-pass areas;
the file name is the unit of selection.
Beside them: `helper-*.R` (sourced before the first test),
`setup.R`,
`data/` (Parquet fixtures, reached via `test_path()` or as bare
relative paths inside SQL),
and `_snaps/`
([`snapshots/`](/handbook/testing/snapshots/README.md)).

**Helpers.**
`helper-DBItest.R` registers the DBItest context (the
`make_context()` call must stay in the helper);
`helper-skip.R` holds the shared skip predicates
(`skip_on_dev_version()`, `skip_on_flavor()`,
`skip_on_cran_except_r_universe()`);
`helper-snapshot.R` normalises the package name in captured
output; `helper-arrow.R` loads arrow early for a
garbage-collection reason it documents.
`local_con()`, the self-disconnecting connection fixture,
is package code (`R/test-fixtures.R`);
the suite runs with the namespace loaded,
so internal functions — `get_package_name()` among them —
are callable unqualified.
Always ask for the package name rather than writing it
([`branches/flavors/`](/handbook/branches/flavors/README.md)).

*To deepen: drain
[#2425](https://github.com/duckdb/duckdb-r/issues/2425)
(windows/aarch64 extension skip).*
