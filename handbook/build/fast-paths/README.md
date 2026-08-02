# Fast paths

Linking a prebuilt `libduckdb` instead of compiling the vendored sources:
the `DUCKDB_R_USE_SYSTEM_LIB` opt-in and the guard that keeps it honest.
Linux and macOS only, and only for `R CMD INSTALL` and
`load_all()` — never for a tarball someone else installs.

```sh
scripts/install-libduckdb.sh           # once per vendoring bump
export DUCKDB_R_USE_SYSTEM_LIB=1
export MAKEFLAGS="-j$(nproc)"

R CMD INSTALL . --no-byte-compile      # seconds, not minutes
R -q -e 'pkgload::load_all()'          # warm reload
R -q -e 'testthat::test_local()'
```

`pkgload::load_all()` / `devtools::load_all()` —
and `testthat::test_local()`, which loads the same way —
honor the opt-in identically:
only the glue in `src/` compiles, the engine is linked.

**Only the implementation is swapped.**
The glue still compiles against the *vendored headers*
(it reaches into internal DuckDB C++ headers
absent from the released amalgamation);
that is safe only when library and headers come from the same upstream commit,
so `configure` extracts `DUCKDB_SOURCE_ID`
from the vendored tree, greps for it inside the installed library,
and aborts on a mismatch.
Re-run [`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh)
after every vendoring bump.
If no prebuilt matches (a `-dev` snapshot), drop the variable and
build from source.

**The fast path proves nothing about the engine.**
A release `libduckdb` links more extensions and defaults differently,
so engine-configuration claims are never verified
under `DUCKDB_R_USE_SYSTEM_LIB=1`
([`usage/extensions/`](/handbook/usage/extensions/README.md)).

In CI, most Linux and macOS builds default to the fast path,
via `.github/workflows/custom/before-install/action.yml` —
except on the vendoring fork, which always builds from source;
the matrix entries that compile the vendored sources instead are
[`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)'s.
