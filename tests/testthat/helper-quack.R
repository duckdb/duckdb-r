# A Quack server and client inside the test process.
#
# Quack is DuckDB's remote protocol: one database serves itself with
# `quack_serve()`, another ATTACHes it as a catalog.
# Both ends are extension code, so the tests that need them download the
# `quack` extension, under the same conditions as `skip_if_no_icu()`.
# The server is a second in-memory database in the same R process, listening
# on a port the system picks, so no DuckDB CLI and no fixed port are needed.

# Skip unless the quack extension can be installed and loaded into `con`.
#
# Beyond the conditions every downloaded extension is subject to,
# the download itself can fail (no network, an extension not yet built for a
# release), and that is not what the tests calling this are about.
skip_if_no_quack <- function(con) {
  skip_if_no_icu()
  ok <- tryCatch(
    {
      dbExecute(con, "INSTALL quack")
      dbExecute(con, "LOAD quack")
      TRUE
    },
    error = function(e) conditionMessage(e)
  )
  if (!isTRUE(ok)) {
    skip(paste0("quack extension unavailable: ", ok))
  }
}

# Serve a fresh in-memory database over Quack until the calling frame exits.
#
# Returns the server's connection, to create fixtures on,
# and the URI and token a client ATTACHes with.
local_quack_server <- function(.local_envir = parent.frame()) {
  server <- dbConnect(duckdb())
  withr::defer(dbDisconnect(server, shutdown = TRUE), envir = .local_envir)
  skip_if_no_quack(server)

  token <- "duckdb-r-test-token"
  uri <- dbGetQuery(
    server,
    "SELECT listen_uri FROM quack_serve('quack:localhost:0', token = ?)",
    params = list(token)
  )$listen_uri
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
