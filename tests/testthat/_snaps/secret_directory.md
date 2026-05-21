# maybe_secret_directory_message text is stable

    Code
      withCallingHandlers(maybe_secret_directory_message(), packageStartupMessage = function(
        m) {
        cat(conditionMessage(m))
        invokeRestart("muffleMessage")
      })
    Output
      duckdb: stored secrets exist in two locations:
        - <R-DEFAULT> (R default)
        - <COMMON> (shared with DuckDB CLI / Python)
      Set `DUCKDB_SECRET_DIRECTORY` to the location you want to use, e.g. in
      `~/.Renviron` (open it with `usethis::edit_r_environ()` if available):
        DUCKDB_SECRET_DIRECTORY=~/.duckdb/stored_secrets   # shared with CLI/Python
        DUCKDB_SECRET_DIRECTORY=<R-DEFAULT>   # keep R-only
      Then call `duckdb::duckdb_join_secrets()` to consolidate existing secrets.
      Setting either value (or `options(duckdb.secret_directory = ...)`) also
      silences this message.

# duckdb_join_secrets reports when there is nothing to do

    Code
      duckdb_join_secrets(ask = FALSE)
    Message
      No secret files to join. Target: <TMP>/target

---

    Code
      duckdb_join_secrets(ask = FALSE)
    Message
      No secret files to join. Target: <TMP>/target

# duckdb_join_secrets moves files from common and R-default sources

    Code
      out <- duckdb_join_secrets(ask = FALSE)
    Message
      Joining secrets into: <TMP>/target
        + copy      <TMP>/target/alpha <- <COMMON>/alpha
        + copy      <TMP>/target/beta <- <R-DEFAULT>/beta
      Joined 2 secret file(s) into <TMP>/target.
    Code
      cat("returned:", redact_paths(out, dirs), "\n")
    Output
      returned: <TMP>/target 

# duckdb_join_secrets aborts on collisions unless overwrite = TRUE

    Code
      duckdb_join_secrets(ask = FALSE)
    Message
      Joining secrets into: <TMP>/target
        + copy      <TMP>/target/shared <- <COMMON>/shared
        ! overwrite <TMP>/target/shared <- <R-DEFAULT>/shared
    Condition
      Error:
      ! Some target secrets would be overwritten (see entries marked `!` above). Re-run with `overwrite = TRUE` to proceed.

# duckdb_join_secrets skips a source that equals the target

    Code
      duckdb_join_secrets(ask = FALSE)
    Message
      Joining secrets into: <COMMON>
        ! overwrite <COMMON>/stay <- <R-DEFAULT>/stay
    Condition
      Error:
      ! Some target secrets would be overwritten (see entries marked `!` above). Re-run with `overwrite = TRUE` to proceed.

