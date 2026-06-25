# GitHub Copilot Instructions for duckdb Package

Read and follow the development guidelines outlined in [AGENTS.md](../AGENTS.md).

## Working Effectively

The agent's environment should already contain the necessary tools.
If tools are missing, adapt `.github/workflows/copilot-setup-steps.yaml` in addition to these instructions.

### Bootstrap, Build, and Test the Repository

- `sudo apt-get install -y r-base r-base-dev build-essential` -- installs R and development tools
- `mkdir -p ~/R/library && echo '.libPaths("~/R/library")' > ~/.Rprofile` -- sets up local R library
- `export MAKEFLAGS="-j$(nproc)"` -- enables parallel compilation
- `UserNM=true R CMD INSTALL . --no-byte-compile` -- builds and installs the package. NEVER CANCEL: takes 10-15 minutes on first build. Set timeout to 30+ minutes.

#### Fast path: build/test against prebuilt DuckDB (recommended)

For an interactive edit-build-test loop, link against a prebuilt libduckdb instead of compiling the ~1700 vendored `.cpp` files. This turns the first build from 10-15 minutes into seconds, and is exactly what CI does by default (see `.github/workflows/custom/before-install/action.yml`).

- `sudo scripts/install-libduckdb.sh` -- one-time, downloads the libduckdb matching the vendored DuckDB version (re-run after every vendoring bump)
- `export DUCKDB_R_USE_SYSTEM_LIB=1` -- in every shell that builds or tests the package

With `DUCKDB_R_USE_SYSTEM_LIB=1` set, `R CMD INSTALL .`, `pkgload::load_all()`, `devtools::load_all()`, and `testthat::test_local()` all compile only the glue code and link the prebuilt library. See AGENTS.md for the full details, caveats, and the commit-match guard.

### Run Tests

- `R -q -e "testthat::test_local()"` -- runs all tests. Takes about 45 seconds. NEVER CANCEL: set timeout to 5+ minutes. With the prebuilt fast path above, `load_all()` is ~1 second warm.
- `R -q -e "testthat::test_local(filter = '^name$')"` -- runs specific test file by name

### Format Checking (Optional - Has Known Issues)

- `pip3 install cmake-format && export PATH="$HOME/.local/bin:$PATH"` -- installs formatter
- `make format-check` -- checks code formatting
