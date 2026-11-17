# Usage: Rscript make-template.R <lib> <dir>
# Creates <dir> as an extension directory with icu INSTALLed but not loaded.
args <- commandArgs(TRUE)
.libPaths(c(args[[1]], .libPaths()))
suppressMessages(library(duckdb))
con <- dbConnect(duckdb(config = list(extension_directory = args[[2]])))
dbExecute(con, "INSTALL icu")
print(dbGetQuery(con, "SELECT extension_name, installed, loaded, extension_version FROM duckdb_extensions() WHERE extension_name = 'icu'"))
dbDisconnect(con, shutdown = TRUE)
