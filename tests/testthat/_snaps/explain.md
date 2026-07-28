# EXPLAIN gives reasonable output

    Code
      DBI::dbGetQuery(con, "EXPLAIN SELECT 1;")
    Output
      physical_plan
      ╭─ Projection ───╮
      │ Projections: 1 │
      │ ~1 row         │
      ╰────────┬───────╯
      ╭─ Dummy Scan ───╮
      ╰────────────────╯

# EXPLAIN shows logical, optimized and physical plan

    Code
      DBI::dbExecute(con, "PRAGMA explain_output='all';")
    Output
      [1] 0
    Code
      DBI::dbGetQuery(con, "EXPLAIN SELECT 1;")
    Output
      logical_plan
      ╭─ Projection ───╮
      │ Expressions: 1 │
      ╰────────┬───────╯
      ╭─ Dummy Scan ───╮
      ╰────────────────╯
      logical_opt
      ╭─ Projection ───╮
      │ Expressions: 1 │
      │ ~1 row         │
      ╰────────┬───────╯
      ╭─ Dummy Scan ───╮
      │ ~1 row         │
      ╰────────────────╯
      physical_plan
      ╭─ Projection ───╮
      │ Projections: 1 │
      │ ~1 row         │
      ╰────────┬───────╯
      ╭─ Dummy Scan ───╮
      ╰────────────────╯

# zero length input is smoothly skipped

    Code
      rs <- DBI::dbGetQuery(con, "SELECT 1;")
      rs[FALSE, ]
    Output
      integer(0)

# wrong type of input forwards handling to the next method

    Code
      rs <- DBI::dbGetQuery(con, "SELECT 1;")
      class(rs) <- c("duckdb_explain", class(rs))
      rs
    Output
        1
      1 1
      

