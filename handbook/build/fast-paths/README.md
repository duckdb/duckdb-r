# Fast paths

Linking a prebuilt `libduckdb` instead of compiling the vendored sources:
the `DUCKDB_R_USE_SYSTEM_LIB` opt-in and the guard that keeps it honest.
Linux and macOS only, and a development convenience throughout —
never how the package reaches someone who installs it.

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

**`R CMD check` honors it too,**
which is what removes the tens of minutes
its "can be installed" step otherwise spends compiling the engine
([#22](https://github.com/duckdb/duckdb-r/issues/22)).
By then `R CMD build` has compressed the vendored tree into
`src/duckdb.tar.xz`, so `configure` extracts it first:
the glue needs those headers, and so does the commit-match guard,
which reads the expected commit out of them.

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

**No prefix needs root.**
The script escalates only for a prefix it cannot write to,
which the default `/usr/local` usually is;
`--prefix ~/.local` puts the library and headers somewhere the caller
can already write, and `DUCKDB_R_LIB_DIR` then points `configure` at it
([`configuration/`](/handbook/build/configuration/README.md)).
That directory is written into the link line as an `-Wl,-rpath` entry,
so the installed package resolves the library
with nothing set in the environment.

**The fast path proves nothing about the engine.**
A release `libduckdb` links more extensions and defaults differently,
so engine-configuration claims are never verified
under `DUCKDB_R_USE_SYSTEM_LIB=1`
([`usage/extensions/`](/handbook/usage/extensions/README.md)).

**No user installs this way.**
For the same reason, and because the installation would then need the
library present at run time, nothing fetches a `libduckdb` on an
installer's behalf: a platform with no published package binary
compiles the vendored sources
([#22](https://github.com/duckdb/duckdb-r/issues/22#issuecomment-1746995401)).
The short route for a user is a binary of the whole package
([`usage/installation/`](/handbook/usage/installation/README.md)).

In CI, most Linux and macOS builds default to the fast path,
via `.github/workflows/custom/before-install/action.yml` —
except on the vendoring fork, which always builds from source;
the matrix entries that compile the vendored sources instead are
[`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)'s.
