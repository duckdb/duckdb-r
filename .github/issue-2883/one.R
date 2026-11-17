.libPaths(c(Sys.getenv("RLIB"), .libPaths()))
suppressMessages(library(duckdb))
ext <- Sys.getenv("EXTDIR"); q <- Sys.getenv("Q"); pre <- Sys.getenv("PRE")
con <- dbConnect(duckdb(config = list(extension_directory = ext)))
before <- dbGetQuery(con, "SELECT loaded FROM duckdb_extensions() WHERE extension_name='icu'")$loaded
if (nzchar(pre)) dbExecute(con, pre)
res <- tryCatch(format(dbGetQuery(con, q)[[1]][1], digits = 15), error = function(e) paste("ERROR:", gsub("\n", " | ", conditionMessage(e))))
after <- dbGetQuery(con, "SELECT loaded FROM duckdb_extensions() WHERE extension_name='icu'")$loaded
cat(sprintf("RESULT\t%s\tbefore=%s\tafter=%s\n", res, before, after))
dbDisconnect(con, shutdown = TRUE)
