# Setup

Getting from a fresh clone to a running test suite,
in the order a first-time contributor needs it —
each knob named below is explained by the leaf that owns it,
not here.

Start with the clone:

```sh
git clone https://github.com/duckdb/duckdb-r.git
cd duckdb-r
```

The R-level dependencies are the ones `DESCRIPTION` declares;
`pak::pak()` run inside the clone installs them,
`testthat` among them.

The default build compiles the vendored DuckDB sources,
which takes far too long for an edit-test loop,
so the next step is to opt out of it.
`scripts/install-libduckdb.sh` downloads the prebuilt libduckdb
that matches the vendored sources —
into `/usr/local`,
or into a user-writable location with `--prefix "$HOME/.local"` —
and `DUCKDB_R_USE_SYSTEM_LIB=1` makes the build link against it
instead of compiling the engine:

```sh
scripts/install-libduckdb.sh
export DUCKDB_R_USE_SYSTEM_LIB=1
```

From there the loop is two calls:

```sh
R -q -e 'pkgload::load_all()'
R -q -e 'testthat::test_local()'
```

`load_all()` compiles only the glue sources in `src/`,
and `test_local()` loads the package the same way before running
the suite,
so both stay in the seconds range.

What the fast path costs and guards —
the check that the installed library was built from the same commit
as the vendored sources,
and the re-install that every vendoring bump therefore requires —
is [`build/fast-paths/`](/handbook/build/fast-paths/README.md).
The suite's layout,
and running one file rather than all of them,
is [`testing/suite/`](/handbook/testing/suite/README.md).
The remaining build knobs,
parallelism and `ccache` among them,
are [`build/configuration/`](/handbook/build/configuration/README.md).

The sequence assumes a toolchain that is already working —
the R version `DESCRIPTION` names in `Depends`,
a C++ compiler, `make` —
and installs none of it.
It also assumes Linux or macOS:
`configure` rejects `DUCKDB_R_USE_SYSTEM_LIB` on any other system,
and `configure.win` has no such branch at all.
On Windows,
and whenever no prebuilt libduckdb matches the vendored commit,
the only route is the full build from the vendored sources,
which [`build/source-build/`](/handbook/build/source-build/README.md)
documents together with the toolchain bootstrap.
Making the change once the environment works —
branching, style, what a pull request needs —
is [`contributors/workflow/`](/handbook/contributors/workflow/README.md).
