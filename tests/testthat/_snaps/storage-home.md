# storage message wording is stable

    Code
      cat("# non-interactive, temporary directory:\n")
    Output
      # non-interactive, temporary directory:
    Code
      cat(storage_location_message(tempdir_home), sep = "\n")
    Output
      duckdb keeps downloaded extensions and secrets in a temporary directory:
      /tmp/Rtmpxx/duckdb
      This is removed when the R session ends.
      Extensions are re-downloaded each session.
      Secrets are lost.
      Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
      Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
      See ?duckdb_storage for details and alternatives.
    Code
      cat("\n\n# non-interactive, existing ~/.duckdb:\n")
    Output
      
      
      # non-interactive, existing ~/.duckdb:
    Code
      cat(storage_location_message(shared_home), sep = "\n")
    Output
      duckdb is storing downloaded extensions and secrets under ~/.duckdb:
      /home/alice/.duckdb
      This persists across sessions and is shared with the DuckDB CLI and other clients.
      Run duckdb(shared_home = FALSE) to use a temporary directory instead.
      See ?duckdb_storage for details and alternatives.
    Code
      cat("\n\n# cancelled interactive prompt (error text):\n")
    Output
      
      
      # cancelled interactive prompt (error text):
    Code
      cat(storage_location_message(tempdir_home, interactive = TRUE), sep = "\n")
    Output
      duckdb keeps downloaded extensions and secrets in a temporary directory:
      /tmp/Rtmpxx/duckdb
      This is removed when the R session ends.
      Extensions are re-downloaded each session.
      Secrets are lost.
      Answer "yes" at the prompt to create ~/.duckdb and keep them (suitable for most users).
      Answer "no" to use a temporary directory for this session.
      See ?duckdb_storage for details and alternatives.
    Code
      cat("\n\n# confirmation after creating ~/.duckdb:\n")
    Output
      
      
      # confirmation after creating ~/.duckdb:
    Code
      cat(home_created_message("/home/alice/.duckdb"), sep = "\n")
    Output
      duckdb: created /home/alice/.duckdb.
      Extensions and secrets are kept here across sessions, and shared with the DuckDB CLI and other clients.
      See ?duckdb_storage; run duckdb(shared_home = FALSE) for a temporary directory instead.

# a cancelled prompt aborts with a stable error

    Code
      resolve_storage_home()
    Condition
      Error:
      ! duckdb keeps downloaded extensions and secrets in a temporary directory:
      /tmp/Rtmpxx/duckdb
      This is removed when the R session ends.
      Extensions are re-downloaded each session.
      Secrets are lost.
      Answer "yes" at the prompt to create ~/.duckdb and keep them (suitable for most users).
      Answer "no" to use a temporary directory for this session.
      See ?duckdb_storage for details and alternatives.

