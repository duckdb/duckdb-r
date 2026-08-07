# Setup

From a fresh clone to a running test suite, in order;
each step is explained by the leaf that owns it, not here.

```sh
git clone https://github.com/duckdb/duckdb-r.git
cd duckdb-r
R -q -e 'pak::pak()'                    # R-level dependencies

scripts/install-libduckdb.sh            # prebuilt engine, matching
export DUCKDB_R_USE_SYSTEM_LIB=1        # the vendored commit;
                                        # the script sudos if it must

R -q -e 'pkgload::load_all()'           # seconds
R -q -e 'testthat::test_local()'        # the suite
```

The default build would compile the vendored engine for tens of minutes,
so the fast path comes before the first build,
not as an optimization to discover later:
what it costs and guards —
and the re-install every vendoring bump requires — is
[`build/fast-paths/`](/handbook/build/fast-paths/README.md).
It assumes Linux or macOS and a working toolchain,
and the default prefix (`/usr/local`, set in
[`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh))
needs privileges the script escalates for —
constraints to be relaxed
([#22](https://github.com/duckdb/duckdb-r/issues/22#issuecomment-5158085048));
on Windows, and when no prebuilt matches, the full build applies
([`build/source-build/`](/handbook/build/source-build/README.md)).
The suite's layout and running one file:
[`testing/suite/`](/handbook/testing/suite/README.md).
Parallelism and ccache:
[`build/configuration/`](/handbook/build/configuration/README.md).
Making a change once the environment works:
[`workflow/`](/handbook/contributors/workflow/README.md).
Installing a published build rather than this source tree:
[`usage/installation/`](/handbook/usage/installation/README.md).
