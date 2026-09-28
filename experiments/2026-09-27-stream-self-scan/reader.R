## What else the reader from to_arrow_stream() cannot do on its own connection:
## the statements dplyr and dbplyr run without being asked, a second read,
## writing the reader back, and what a second connection to the same
## database changes. None of these cases waits, so they run in one session.
library(DBI)
library(duckdb)

msg <- function(e) conditionMessage(e)

con <- dbConnect(duckdb(shared_home = FALSE))
dbWriteTable(con, "t", data.frame(i = seq_len(3e6)))
dbWriteTable(con, "u", data.frame(j = 1:3))
lazy <- dplyr::tbl(con, "t")

## Statements that dplyr and dbplyr run -----------------------------------------
# dbplyr asks for the columns of a new lazy table.
reader <- to_arrow_stream(lazy)
other <- dplyr::tbl(con, "u")
tryCatch(reader$read_next_batch()$num_rows, error = msg)

# Printing a lazy table queries its first rows.
reader <- to_arrow_stream(lazy)
print(other)
tryCatch(reader$read_next_batch()$num_rows, error = msg)

# So does collect().
reader <- to_arrow_stream(lazy)
invisible(dplyr::collect(other))
tryCatch(reader$read_next_batch()$num_rows, error = msg)

## A second connection to the same database is independent --------------------
# con@driver holds the database, so a connection from it sees the same tables.
other_con <- dbConnect(con@driver)
reader <- to_arrow_stream(lazy)
dplyr::collect(dplyr::tbl(other_con, "u"))
reader$read_table()$num_rows

## The reader is read once -----------------------------------------------------
reader <- to_arrow_stream(lazy)
reader$read_table()$num_rows
reader$read_table()$num_rows

## Writing the reader back to its own connection --------------------------------
# The reader knows its schema, so DBI's dbWriteTableArrow() creates the table
# before the first read fails, and leaves it empty.
reader <- to_arrow_stream(lazy)
tryCatch(dbWriteTableArrow(con, "copy", reader), error = msg)
dbGetQuery(con, "SELECT count(*) AS n FROM copy")$n

# DBI's dbAppendTableArrow() appends batch by batch, and keeps the first.
dbExecute(con, "CREATE TABLE copy2 (i INTEGER)")
reader <- to_arrow_stream(lazy)
tryCatch(dbAppendTableArrow(con, "copy2", reader), error = msg)
dbGetQuery(con, "SELECT count(*) AS n FROM copy2")$n

# To a second connection, dbWriteTableArrow() writes every row.
reader <- to_arrow_stream(lazy)
dbWriteTableArrow(other_con, "copy3", reader)
dbGetQuery(other_con, "SELECT count(*) AS n FROM copy3")$n

## The reader outlives its connection ------------------------------------------
reader <- to_arrow_stream(lazy)
dbDisconnect(other_con)
dbDisconnect(con)
reader$read_table()$num_rows
