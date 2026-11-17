# A Quack server and client inside the test process.
#
# Quack is DuckDB's remote protocol: one database serves itself with
# `quack_serve()`, another ATTACHes it as a catalog.
# Both ends are extension code, so the tests that need them download the
# `quack` extension, under the same conditions as `skip_if_no_icu()`.
# The server is a second in-memory database in the same R process, listening
# on a port the system picks, so no DuckDB CLI and no fixed port are needed.

# The rows the server returns inline in its answer to a PREPARE.
#
# The server drains whole batches into that answer until it holds at least
# this many rows, and leaves the rest of the result to FETCH requests.
# Both settings below are read by the server only;
# the client does not ask for a count of its own when it reads.
quack_inline_rows <- 2048L

# Skip unless the quack extension can be installed, then load it into `con`.
#
# Beyond the conditions every downloaded extension is subject to,
# the download itself can fail (no network, an extension not built for this
# release or platform), and that is not what the tests calling this are about.
# Any other failure, LOAD included, is an error.
# INSTALL uses the engine's own HTTP client, which `http_timeout` (an httpfs
# setting) does not reach, so an offline run waits for its default timeout.
skip_if_no_quack <- function(con) {
  skip_if_no_icu()
  tryCatch(
    dbExecute(con, "INSTALL quack"),
    error = function(e) {
      if (!grepl("Failed to download extension", conditionMessage(e))) {
        stop(e)
      }
      skip(paste0("quack extension unavailable: ", conditionMessage(e)))
    }
  )
  dbExecute(con, "LOAD quack")
}

# Serve a fresh in-memory database over Quack until the calling frame exits.
#
# The server cuts its result into batches of one vector
# (`quack_target_batch_bytes` is a byte budget, and one byte is less than any
# vector) and inlines `quack_inline_rows` rows,
# so a small table already needs a FETCH, and always at the same row count.
# With the defaults, a table scan's batch is a whole row group.
#
# Returns the server's connection, to create fixtures on,
# and the URI and token a client ATTACHes with.
local_quack_server <- function(.local_envir = parent.frame()) {
  server <- dbConnect(duckdb())
  withr::defer(dbDisconnect(server, shutdown = TRUE), envir = .local_envir)
  skip_if_no_quack(server)
  dbExecute(
    server,
    paste0("SET GLOBAL quack_prepare_inline_rows = ", quack_inline_rows)
  )
  dbExecute(server, "SET GLOBAL quack_target_batch_bytes = 1")

  token <- "duckdb-r-test-token"
  uri <- tryCatch(
    dbGetQuery(
      server,
      "SELECT listen_uri FROM quack_serve('quack:localhost:0', token = ?)",
      params = list(token)
    )$listen_uri,
    error = function(e) {
      skip(paste0("cannot start a Quack server: ", conditionMessage(e)))
    }
  )
  withr::defer(
    dbGetQuery(server, "FROM quack_stop(?)", params = list(uri)),
    envir = .local_envir
  )
  list(con = server, uri = uri, token = token)
}

# A client connection with `server` attached as `rem`,
# disconnected when the calling frame exits.
local_quack_client <- function(server, .local_envir = parent.frame()) {
  con <- dbConnect(duckdb())
  withr::defer(dbDisconnect(con, shutdown = TRUE), envir = .local_envir)
  skip_if_no_quack(con)
  dbExecute(
    con,
    paste0(
      "ATTACH ",
      dbQuoteString(con, server$uri),
      " AS rem (TOKEN ",
      dbQuoteString(con, server$token),
      ")"
    )
  )
  con
}
