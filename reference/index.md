# Package index

## Getting started

- [`sql_query()`](https://r.duckdb.org/reference/sql_query.md)
  [`sql_exec()`](https://r.duckdb.org/reference/sql_query.md)
  **\[experimental\]** : Run an SQL query or statement
- [`default_conn()`](https://r.duckdb.org/reference/default_conn.md)
  **\[experimental\]** : Get the default connection

## Driver

- [`duckdb()`](https://r.duckdb.org/reference/duckdb.md)
  [`duckdb_shutdown()`](https://r.duckdb.org/reference/duckdb.md)
  [`duckdb_adbc()`](https://r.duckdb.org/reference/duckdb.md)
  [`dbConnect(`*`<duckdb_driver>`*`)`](https://r.duckdb.org/reference/duckdb.md)
  [`dbDisconnect(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb.md)
  : Connect to a DuckDB database instance
- [`dbDataType(`*`<duckdb_driver>`*`)`](https://r.duckdb.org/reference/duckdb_driver-class.md)
  [`dbGetInfo(`*`<duckdb_driver>`*`)`](https://r.duckdb.org/reference/duckdb_driver-class.md)
  [`dbIsValid(`*`<duckdb_driver>`*`)`](https://r.duckdb.org/reference/duckdb_driver-class.md)
  [`show(`*`<duckdb_driver>`*`)`](https://r.duckdb.org/reference/duckdb_driver-class.md)
  : DuckDB driver class

## Connection

- [`dbAppendTable(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbBegin(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbCommit(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbDataType(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbExistsTable(`*`<duckdb_connection>`*`,`*`<ANY>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbGetInfo(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbIsValid(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbListFields(`*`<duckdb_connection>`*`,`*`<character>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbListTables(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbQuoteIdentifier(`*`<duckdb_connection>`*`,`*`<ANY>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbQuoteLiteral(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbRemoveTable(`*`<duckdb_connection>`*`,`*`<character>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbRollback(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbSendQuery(`*`<duckdb_connection>`*`,`*`<character>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`dbWriteTable(`*`<duckdb_connection>`*`,`*`<character>`*`,`*`<data.frame>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  [`show(`*`<duckdb_connection>`*`)`](https://r.duckdb.org/reference/duckdb_connection-class.md)
  : DuckDB connection class

## Result

- [`duckdb_fetch_arrow()`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`duckdb_fetch_record_batch()`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbBind(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbClearResult(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbColumnInfo(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbFetch(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbGetInfo(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbGetRowCount(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbGetRowsAffected(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbGetStatement(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbHasCompleted(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`dbIsValid(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  [`show(`*`<duckdb_result>`*`)`](https://r.duckdb.org/reference/duckdb_result-class.md)
  : DuckDB Result Set

## Interfaces

- [`tbl_file()`](https://r.duckdb.org/reference/backend-duckdb.md)
  [`tbl_function()`](https://r.duckdb.org/reference/backend-duckdb.md)
  [`tbl_query()`](https://r.duckdb.org/reference/backend-duckdb.md)
  [`simulate_duckdb()`](https://r.duckdb.org/reference/backend-duckdb.md)
  : DuckDB SQL backend for dbplyr
- [`duckdb_register()`](https://r.duckdb.org/reference/duckdb_register.md)
  [`duckdb_unregister()`](https://r.duckdb.org/reference/duckdb_register.md)
  : Register a data frame as a virtual table
- [`duckdb_register_arrow()`](https://r.duckdb.org/reference/duckdb_register_arrow.md)
  [`duckdb_unregister_arrow()`](https://r.duckdb.org/reference/duckdb_register_arrow.md)
  [`duckdb_list_arrow()`](https://r.duckdb.org/reference/duckdb_register_arrow.md)
  : Register an Arrow data source as a virtual table
- [`duckdb_read_csv()`](https://r.duckdb.org/reference/duckdb_read_csv.md)
  : Reads a CSV file into DuckDB
- [`duckdb_explain-class`](https://r.duckdb.org/reference/duckdb_explain-class.md)
  [`duckdb_explain`](https://r.duckdb.org/reference/duckdb_explain-class.md)
  [`print.duckdb_explain`](https://r.duckdb.org/reference/duckdb_explain-class.md)
  : DuckDB EXPLAIN query tree
