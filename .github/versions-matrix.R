# Extra rcc matrix entries, appended to the base matrix derived by
# .github/workflows/versions-matrix/action.R.
# Explained in handbook/operations/ci/matrix/README.md.

list(
  # Add even earlier Windows versions
  data.frame(os = "windows-latest", r = r_versions[4:6]),
  # Build the DuckDB C++ engine with a tripwire (-DDUCKDB_R_POISON_ENGINE) and
  # force DUCKDB_R_RUN_TESTS=false. The flag travels through the generic "env"
  # matrix field, which the rcc-full job applies to the environment of all
  # steps; the custom before-install action reacts by building the tripwire
  # and opting this entry out of the tests/examples that otherwise run
  # automatically on GitHub Actions. Any test or example that reaches the C++
  # engine then aborts, so this run verifies that the CRAN guards keep the
  # engine untouched.
  data.frame(
    os = "ubuntu-24.04",
    r = r_versions[[2]],
    env = "DUCKDB_R_POISON_ENGINE=true",
    desc = "with engine poisoning, DUCKDB_R_RUN_TESTS=false"
  ),
  # Regular builds default to the fast system-libduckdb path (see the custom
  # before-install action). This dedicated entry pins DUCKDB_R_USE_SYSTEM_LIB=0
  # via the generic "env" field so that one regular matrix build actually
  # compiles the vendored DuckDB sources -- the artifact that ships to CRAN --
  # instead of linking against a prebuilt libduckdb.
  data.frame(
    os = "ubuntu-24.04",
    r = r_versions[[2]],
    env = "DUCKDB_R_USE_SYSTEM_LIB=0",
    desc = "vendored build (compiles bundled DuckDB sources)"
  ),
  # Companion macOS vendored build. Regular macOS entries default to the fast
  # system-libduckdb path (see the custom before-install action), so without
  # this entry no macOS job would actually compile the bundled DuckDB sources.
  data.frame(
    os = "macos-latest",
    r = r_versions[[2]],
    env = "DUCKDB_R_USE_SYSTEM_LIB=0",
    desc = "vendored build (compiles bundled DuckDB sources)"
  ),
  # Companion Linux arm64 vendored build. The three entries above cover a
  # source build on every OS -- Windows always builds from source, having no
  # fast path to default to -- but only on one architecture each, and the
  # source build is not architecture-neutral: ./configure probes the machine it
  # runs on to decide which allocator the engine gets
  # (handbook/architecture/engine/README.md), and aarch64 Linux takes the same
  # branch amd64 Linux does without ever having compiled it. So pin the arm64
  # runner too, and the matrix covers a source build on every OS *and*
  # architecture it carries: macOS is arm64 already, and the base matrix pairs
  # windows-11-arm with windows-latest.
  data.frame(
    os = "ubuntu-26.04-arm",
    r = r_versions[[2]],
    env = "DUCKDB_R_USE_SYSTEM_LIB=0",
    desc = "vendored build (compiles bundled DuckDB sources)"
  )
)
