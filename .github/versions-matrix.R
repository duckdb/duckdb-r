list(
  # Add even earlier Windows versions
  data.frame(os = "windows-latest", r = r_versions[4:6]),
  # Build the DuckDB C++ engine with a tripwire (-DDUCKDB_R_POISON_ENGINE) and
  # force DUCKDB_R_RUN_TESTS=false. The flag travels through the generic "env"
  # matrix field and is picked up by the custom before-install action, which
  # also opts this entry out of the tests/examples that otherwise run
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
  )
)
