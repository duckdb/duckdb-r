# GitHub Copilot Instructions for duckdb Package

Read and follow the development guidelines outlined in
[CLAUDE.md](https://r.duckdb.org/CLAUDE.md).

## Working Effectively

### Bootstrap, Build, and Test the Repository

- `sudo apt-get install -y r-base r-base-dev build-essential` – installs
  R and development tools
- `mkdir -p ~/R/library && echo '.libPaths("~/R/library")' > ~/.Rprofile`
  – sets up local R library
- `export MAKEFLAGS="-j$(nproc)"` – enables parallel compilation
- `UserNM=true R CMD INSTALL . --no-byte-compile` – builds and installs
  the package. NEVER CANCEL: takes 10-15 minutes on first build. Set
  timeout to 30+ minutes.

### Run Tests

- `R -q -e "testthat::test_local()"` – runs all tests. Takes about 45
  seconds. NEVER CANCEL: set timeout to 5+ minutes.
- `R -q -e "testthat::test_local(filter = '^name$')"` – runs specific
  test file by name

### Format Checking (Optional - Has Known Issues)

- `pip3 install cmake-format && export PATH="$HOME/.local/bin:$PATH"` –
  installs formatter
- `make format-check` – checks code formatting
