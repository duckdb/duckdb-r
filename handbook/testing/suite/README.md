# The suite

The `tests/testthat/` layout, its helpers,
and running the whole suite or any part of it.

```sh
R -q -e 'testthat::test_local()'                          # everything
R -q -e "testthat::test_local(filter = '^array$')"        # one file
R -q -e "testthat::test_local(filter = 'arrow')"          # every arrow file
R -q -e "testthat::test_local(filter = '^(array|bind)$')" # exactly these two
```

`filter` is a **regular expression**, matched against each file name with
`test-` and `.R` stripped — so a family is a substring,
several named files are an alternation,
and one file is anchored to keep it from matching its neighbours.

`test_local()` runs directly and unconditionally,
without reading `tests/testthat.R`.
With the fast path set up
([`build/fast-paths/`](/handbook/build/fast-paths/README.md))
the edit-test loop stays in the seconds range.

**The layout.**
Tests are flat files `test-<topic>.R`,
named for the `R/` file they cover,
the DuckDB feature they round-trip,
or a shared prefix for multi-pass areas;
the file name is the unit of selection.
Beside them: `helper-*.R` and `setup.R`,
then `data/` (Parquet fixtures, reached via `test_path()` or as bare
relative paths inside SQL),
and `_snaps/`
([`snapshots/`](/handbook/testing/snapshots/README.md)).

**The helpers.**
Every `helper-*.R` is sourced before the first test,
and that set is the list.
Each should open with a header saying why it exists;
`helper-DBItest.R` and `helper-skip.R` do not yet.
Two constraints are not obvious from reading one:
`helper-DBItest.R`'s `make_context()` call must stay in the helper,
and any expectation whose output can carry the package name goes
through `transform_package_name` from `helper-snapshot.R`.
`local_con()`, the self-disconnecting connection fixture,
is package code (`R/test-fixtures.R`);
the suite runs with the namespace loaded,
so internal functions — `get_package_name()` among them —
are callable unqualified.
Always ask for the package name rather than writing it
([`branches/flavors/`](/handbook/branches/flavors/README.md)).

**Extensions over the network.**
`test-duckdb-extensions.R` installs a real extension,
so it first asks what DuckDB publishes for the platform it is running on.
`PRAGMA platform` is the name to look that up under,
and `helper-extensions.R` carries the platforms with no binaries at all
([`usage/extensions/`](/handbook/usage/extensions/README.md)).
On those the install test skips —
and a canary asserts the HTTP 404 in its place,
so the skip fails the day the gap closes
rather than quietly outliving it.

*To deepen: drain
[#2425](https://github.com/duckdb/duckdb-r/issues/2425)
(an extension the Windows/arm64 build can actually install).*
