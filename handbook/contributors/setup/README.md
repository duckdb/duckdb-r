# Setup

From a fresh clone to a running test suite, in order;
each step is explained by the leaf that owns it, not here.

```sh
git clone https://github.com/duckdb/duckdb-r.git
cd duckdb-r
R -q -e 'pak::pak()'                    # R-level dependencies

scripts/install-libduckdb.sh            # prebuilt engine, matching
export DUCKDB_R_USE_SYSTEM_LIB=1        # the vendored commit

R -q -e 'pkgload::load_all()'           # seconds
R -q -e 'testthat::test_local()'        # the suite
```

The default build would compile the vendored engine for many
minutes, so the fast path is the second step, not an
optimization to discover later:
what it costs and guards — and the re-install every vendoring bump
requires — is
[`build/fast-paths/`](/handbook/build/fast-paths/README.md).
It assumes Linux or macOS and a working toolchain;
on Windows, and when no prebuilt matches, the full build applies
([`build/source-build/`](/handbook/build/source-build/README.md)).
The suite's layout and running one file:
[`testing/suite/`](/handbook/testing/suite/README.md).
Parallelism and ccache:
[`build/configuration/`](/handbook/build/configuration/README.md).
Making a change once the environment works:
[`workflow/`](/handbook/contributors/workflow/README.md).
