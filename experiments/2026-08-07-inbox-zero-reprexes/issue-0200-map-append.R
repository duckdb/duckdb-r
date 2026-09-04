## duckdb-r#200 -- the issue's reprex, run unchanged on 1.5.5
packageVersion("duckdb")

con <- DBI::dbConnect(duckdb::duckdb())

DBI::dbExecute(con, "CREATE TABLE tbl (mp MAP(VARCHAR, VARCHAR));")
DBI::dbExecute(con, "INSERT INTO tbl VALUES (MAP {'a': 'b'})")

DBI::dbGetQuery(con, "DESCRIBE tbl")

DBI::dbReadTable(con, "tbl") |> str()

df <- data.frame(
  mp = I(list(data.frame(key = "page", value = "1")))
)
str(df) # same structure as the returned tbl data

DBI::dbAppendTable(con, "tbl", df)

# The appended row reads back as the same structure it was written from --
# no map_from_entries() detour needed
DBI::dbReadTable(con, "tbl") |> str()

# Round trip: read a MAP column, write it straight back
back <- DBI::dbReadTable(con, "tbl")
DBI::dbAppendTable(con, "tbl", back)
DBI::dbGetQuery(con, "SELECT count(*) AS n FROM tbl")

DBI::dbDisconnect(con)
