list(
  # Add even earlier Windows versions
  data.frame(os = "windows-latest", r = r_versions[4:6]),
  # Build with the DuckDB C++ engine poisoned (-DDUCKDB_R_POISON) and *without*
  # DUCKDB_R_RUN_TESTS. Any test or example that reaches the C++ engine aborts,
  # so this run verifies that the CRAN guards keep the engine untouched.
  data.frame(
    os = "ubuntu-24.04",
    r = r_versions[[2]],
    poison = "true",
    desc = "with poisoning, without DUCKDB_R_RUN_TESTS"
  )
)
