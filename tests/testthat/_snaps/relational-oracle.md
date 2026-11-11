# build error: filter on a column that does not exist

    Code
      rel_filter(rel, list(expr_reference("zz")))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Referenced column \"zz\" not found in FROM clause!\nCandidate bindings: \"a\"","name":"zz","candidates":"a","error_subtype":"COLUMN_NOT_FOUND"}

# build error: projection with an unknown function

    Code
      rel_project(rel, list(expr_function("nofunc", list(expr_reference("a")))))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Scalar Function with name nofunc does not exist!\nDid you mean \"count\"?","type":"Scalar Function","name":"nofunc","candidates":"count","error_subtype":"MISSING_ENTRY"}

# build error: aggregate

    Code
      rel_aggregate(rel, list(expr_reference("zz")), list(n = expr_function("count",
        list())))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Referenced column \"zz\" not found in FROM clause!\nCandidate bindings: \"a\"","name":"zz","candidates":"a","error_subtype":"COLUMN_NOT_FOUND"}

---

    Code
      rel_aggregate(rel, list(), list(n = expr_function("nofunc", list())))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Scalar Function with name nofunc does not exist!\nDid you mean \"count\"?","type":"Scalar Function","name":"nofunc","candidates":"count","error_subtype":"MISSING_ENTRY"}

# build error: order

    Code
      rel_order(rel, list(expr_reference("zz")))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Referenced column \"zz\" not found in FROM clause!\nCandidate bindings: \"a\"","name":"zz","candidates":"a","error_subtype":"COLUMN_NOT_FOUND"}

# build error: join with a bad condition

    Code
      rel_join(x, y, list(eq("zz", "c")))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Referenced column \"zz\" not found in FROM clause!\nCandidate bindings: \"a\"","name":"zz","candidates":"a","error_subtype":"COLUMN_NOT_FOUND"}

# build error: cross join with a bad condition

    Code
      rel_join(x, y, list(eq("zz", "c")), "cross")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Referenced column \"zz\" not found in FROM clause!\nCandidate bindings: \"a\"","name":"zz","candidates":"a","error_subtype":"COLUMN_NOT_FOUND"}

# union all of unequal widths fails at build time

    Code
      rel_union_all(x, y)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Set operations can only apply to expressions with the same number of result columns"}

# build error: intersect, except and symmetric difference of unequal widths

    Code
      rel_set_intersect(x, y)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Set operations can only apply to expressions with the same number of result columns"}

---

    Code
      rel_set_diff(x, y)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Set operations can only apply to expressions with the same number of result columns"}

---

    Code
      rel_set_symdiff(x, y)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Set operations can only apply to expressions with the same number of result columns"}

# build error: table function

    Code
      rel_from_table_function(con, "nofunc", list())
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table Function with name nofunc does not exist!\nDid you mean \"sniff_csv\"?","type":"Table Function","name":"nofunc","candidates":"sniff_csv","error_subtype":"MISSING_ENTRY"}

---

    Code
      rel_from_table_function(con, "read_csv", list("does-not-exist.csv"))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"IO","exception_message":"No files found that match the pattern \"does-not-exist.csv\""}

---

    Code
      rel_from_table_function(con, "repeat_row", list(1L), list(bogus = 3L))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Invalid named parameter \"bogus\" for function repeat_row\nFunction does not accept any named parameters."}

# build error: from sql text that does not bind

    Code
      rel_from_sql(con, "SELECT zz FROM range(3)")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Referenced column \"zz\" not found in FROM clause!\nCandidate bindings: \"range\"","name":"zz","location":"[7,2]","position":"7","candidates":"range","error_subtype":"COLUMN_NOT_FOUND"}

# build error: distinct over a dropped table

    Code
      rel_distinct(rel)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table with name oracle_dropped_distinct does not exist!\nDid you mean \"pg_catalog.pg_collation\"?","type":"Table","name":"oracle_dropped_distinct","candidates":"pg_catalog.pg_collation","error_subtype":"MISSING_ENTRY"}

# build error: alias over a dropped table

    Code
      rel_set_alias(rel, "foo")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table with name oracle_dropped_alias does not exist!\nDid you mean \"pg_catalog.pg_depend\"?","type":"Table","name":"oracle_dropped_alias","candidates":"pg_catalog.pg_depend","error_subtype":"MISSING_ENTRY"}

# limit builds unbound over a dropped table, and reading it fails

    Code
      as.data.frame(limited)
    Condition <rlang_error>
      Error:
      ! Catalog Error: Table with name oracle_dropped_limit does not exist!
      Did you mean "pg_catalog.pg_description"?

# depth: 600 filters build and materialize lazily, but not through as.data.frame()

    Code
      as.data.frame(rel)
    Condition <rlang_error>
      Error:
      ! Parser Error: Maximum tree depth of 1000 exceeded in logical planner

# depth: 998 projections build and the 999th fails

    Code
      rel_project(rel, list(expr_reference("a")))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"Max expression depth limit of 1000 exceeded. Use \"SET max_expression_depth TO x\" to increase the maximum expression depth."}

# result mismatch: a column added after rel_from_table()

    Code
      as.data.frame(rel)
    Condition <rlang_error>
      Error:
      ! Invalid Error: Result mismatch in query!
      Expected the following columns: [a INTEGER]
      But result contained the following: [a INTEGER, y INTEGER]

# result mismatch: a lazy data frame fails on every access with the same message

    Code
      nrow(df)
    Condition <simpleError>
      Error:
      ! GetQueryResult: Error evaluating duckdb query: Invalid Error: Result mismatch in query!
      Expected the following columns: [a INTEGER]
      But result contained the following: [a INTEGER, y INTEGER]

# from sql: more than one statement, or not a SELECT

    Code
      rel_from_sql(con, "SELECT 1; SELECT 2")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Parser","exception_message":"Expected a single SELECT statement"}

---

    Code
      rel_from_sql(con, "INSERT INTO oracle_from_sql_insert VALUES (1)")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Parser","exception_message":"Expected a single SELECT statement"}

# from sql: two data frames stay usable after the function has returned

    Code
      show_rel(rel)
    Output
      Subquery
      ---------------------
      --- Relation Tree ---
      ---------------------
      Subquery
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      WITH d1 AS (SELECT * FROM r_dataframe_scan(0x...)) SELECT * FROM (WITH d2 AS (SELECT * FROM r_dataframe_scan(0x...)) SELECT * FROM (SELECT * FROM (d1 CROSS JOIN d2) ORDER BY a, b) AS query_relation) AS query_relation

# from sql: name used twice is pinned once

    Code
      writeLines(rel_to_sql(rel))
    Output
      WITH dd AS (SELECT * FROM r_dataframe_scan(0x...)) SELECT * FROM (SELECT x.a, y.a AS b FROM (dd AS x INNER JOIN dd AS y ON ((x.a = y.a))) ORDER BY x.a) AS query_relation

# from sql: the name lookup in the environment is case sensitive

    Code
      rel_from_sql(scan_con, "SELECT * FROM DD", env = upper_text)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table with name DD does not exist!","type":"Table","name":"DD","location":"[14,2]","position":"14","error_subtype":"MISSING_ENTRY"}

# from sql: R error in lookup reaches the user as that R error

    Code
      rel_from_sql(scan_con, "FROM bad", env = promise_env)
    Condition <rlang_error>
      Error:
      ! boom from promise

---

    Code
      rel_from_sql(scan_con, "FROM act", env = active_env)
    Condition <rlang_error>
      Error:
      ! boom from binding

# from table: a table that does not exist, a view, a missing schema

    Code
      rel_from_table(con, "oracle_no_such_table")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table oracle_no_such_table does not exist!"}

---

    Code
      rel_from_table(con, "oracle_from_table_view")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"oracle_from_table_view is not an table"}

---

    Code
      rel_from_table(con, "oracle_from_table_view", "oracle_no_such_schema")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table oracle_no_such_schema.oracle_from_table_view does not exist!"}

# printed tree and sql text: data frame source

    Code
      show_rel(rel)
    Output
      r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM r_dataframe_scan(0x...)

# printed tree and sql text: table

    Code
      show_rel(rel)
    Output
      Scan Table [memory.main.oracle_print_tbl]
      ---------------------
      --- Relation Tree ---
      ---------------------
      Scan Table [memory.main.oracle_print_tbl]
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM memory.main.oracle_print_tbl

# printed tree and sql text: table function with a named parameter

    Code
      show_rel(rel)
    Output
      repeat_row(v, 2)
      ---------------------
      --- Relation Tree ---
      ---------------------
      repeat_row(v, 2)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - column0 (VARCHAR)
      - column1 (INTEGER)
      
      SELECT * FROM repeat_row('v', 2, (num_rows = 3))

# printed tree and sql text: from sql

    Code
      show_rel(rel)
    Output
      Subquery
      ---------------------
      --- Relation Tree ---
      ---------------------
      Subquery
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      
      SELECT 1 AS a

# printed tree and sql text: alias

    Code
      show_rel(rel)
    Output
      r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM r_dataframe_scan(0x...)

# printed tree and sql text: projection

    Code
      show_rel(rel)
    Output
      Projection [a as a, "+"(a, 1) as a1]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Projection [a as a, "+"(a, 1) as a1]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - a1 (INTEGER)
      
      SELECT a AS a, "+"(a, 1) AS a1 FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id>

# printed tree and sql text: filter

    Code
      show_rel(one)
    Output
      Filter [(a > 1)]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Filter [(a > 1)]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id> WHERE (a > 1)
    Code
      show_rel(two)
    Output
      Filter [((a > 1) AND (b = 'y'))]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Filter [((a > 1) AND (b = 'y'))]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id> WHERE ((a > 1) AND (b = 'y'))

# printed tree and sql text: aggregate with and without groups

    Code
      show_rel(grouped)
    Output
      Aggregate [b, count()]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Aggregate [b, count()]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - b (VARCHAR)
      - n (BIGINT)
      
      SELECT b, count() AS n FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id> GROUP BY b
    Code
      show_rel(ungrouped)
    Output
      Aggregate [sum(a)]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Aggregate [sum(a)]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - s (HUGEINT)
      
      SELECT sum(a) AS s FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id> GROUP BY ALL

# printed tree and sql text: order

    Code
      show_rel(rel)
    Output
      Order [a DESC, b ASC]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Order [a DESC, b ASC]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id> ORDER BY a DESC NULLS FIRST, b ASC NULLS LAST

# printed tree and sql text: limit and distinct

    Code
      show_rel(limited)
    Output
      Limit 1
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Limit 1
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM r_dataframe_scan(0x...) LIMIT 1
    Code
      show_rel(distinct)
    Output
      Distinct
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Distinct
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT DISTINCT * FROM r_dataframe_scan(0x...)

# printed tree and sql text: regular join of each join type

    Code
      for (rel in joins) show_rel(rel)
    Output
      Join REGULAR INNER (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR INNER (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))
      Join REGULAR LEFT (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR LEFT (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs LEFT JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))
      Join REGULAR RIGHT (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR RIGHT (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs RIGHT JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))
      Join REGULAR FULL (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR FULL (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs FULL JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))
      Join REGULAR SEMI (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR SEMI (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs SEMI JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))
      Join REGULAR ANTI (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR ANTI (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs ANTI JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))

# printed tree and sql text: asof join

    Code
      show_rel(inner)
    Output
      Join ASOF INNER (a >= c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join ASOF INNER (a >= c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs ASOF INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a >= c)))
    Code
      show_rel(left)
    Output
      Join ASOF LEFT (a >= c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join ASOF LEFT (a >= c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs ASOF LEFT JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a >= c)))

# printed tree and sql text: cross join, with and without a condition

    Code
      show_rel(plain)
    Output
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs CROSS JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs)
    Code
      show_rel(filtered)
    Output
      Filter [(a = c)]
      Cross Product
          r_dataframe_scan(0x...)    r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Filter [(a = c)]
      Cross Product
          r_dataframe_scan(0x...)    r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs CROSS JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs) WHERE (a = c)

# printed tree and sql text: a cross join with another ref type warns and is a cross product

    Code
      rel <- rel_join(x, y, list(), "cross", "natural")
    Condition
      Warning:
      Using `rel_join(join_ref_type = "cross")`
    Code
      writeLines(rel_tostring(rel, "tree"))
    Output
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)

# printed tree and sql text: positional join

    Code
      show_rel(cross)
    Output
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs POSITIONAL JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs)
    Code
      show_rel(inner)
    Output
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Cross Product
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs POSITIONAL JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs)
    Code
      show_rel(left)
    Output
      Join POSITIONAL LEFT (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join POSITIONAL LEFT (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs POSITIONAL JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))

# printed tree and sql text: natural is a regular join

    Code
      show_rel(rel)
    Output
      Join REGULAR INNER (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Join REGULAR INNER (a = c)
        r_dataframe_scan(0x...)
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))

# printed tree and sql text: set operations

    Code
      show_rel(union_all)
    Output
      Union
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Union
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      (SELECT * FROM r_dataframe_scan(0x...)) UNION ALL (SELECT * FROM r_dataframe_scan(0x...))
    Code
      show_rel(intersect)
    Output
      Intersect
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Intersect
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      (SELECT * FROM r_dataframe_scan(0x...)) INTERSECT (SELECT * FROM r_dataframe_scan(0x...))
    Code
      show_rel(except)
    Output
      Except
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Except
        r_dataframe_scan(0x...)  r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      (SELECT * FROM r_dataframe_scan(0x...)) EXCEPT (SELECT * FROM r_dataframe_scan(0x...))
    Code
      show_rel(symdiff)
    Output
      Union
        Except
          r_dataframe_scan(0x...)    r_dataframe_scan(0x...)  Except
          r_dataframe_scan(0x...)    r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Union
        Except
          r_dataframe_scan(0x...)    r_dataframe_scan(0x...)  Except
          r_dataframe_scan(0x...)    r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      
      ((SELECT * FROM r_dataframe_scan(0x...)) EXCEPT (SELECT * FROM r_dataframe_scan(0x...))) UNION ((SELECT * FROM r_dataframe_scan(0x...)) EXCEPT (SELECT * FROM r_dataframe_scan(0x...)))

# sql text: over a join, a filter, a projection and an aggregate are written into the join's SELECT

    Code
      show_rel(filtered)
    Output
      Filter [(d > CAST(3.0 AS DOUBLE))]
        Join REGULAR INNER (a = c)
          r_dataframe_scan(0x...)
          r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Filter [(d > CAST(3.0 AS DOUBLE))]
        Join REGULAR INNER (a = c)
          r_dataframe_scan(0x...)
          r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - b (VARCHAR)
      - c (INTEGER)
      - d (DOUBLE)
      
      SELECT * FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c))) WHERE (d > CAST(3.0 AS DOUBLE))
    Code
      show_rel(projected)
    Output
      Projection [a as a, d as d]
        Join REGULAR INNER (a = c)
          r_dataframe_scan(0x...)
          r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Projection [a as a, d as d]
        Join REGULAR INNER (a = c)
          r_dataframe_scan(0x...)
          r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - d (DOUBLE)
      
      SELECT a AS a, d AS d FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c)))
    Code
      show_rel(aggregated)
    Output
      Aggregate [b, count()]
        Join REGULAR INNER (a = c)
          r_dataframe_scan(0x...)
          r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Aggregate [b, count()]
        Join REGULAR INNER (a = c)
          r_dataframe_scan(0x...)
          r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - b (VARCHAR)
      - n (BIGINT)
      
      SELECT b, count() AS n FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c))) GROUP BY b

# sql text: over a join, a projection over a filter or an order

    Code
      show_rel(over_filter)
    Output
      Projection [a as a, d as d]
        Filter [(d > CAST(3.0 AS DOUBLE))]
          Join REGULAR INNER (a = c)
            r_dataframe_scan(0x...)
            r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Projection [a as a, d as d]
        Filter [(d > CAST(3.0 AS DOUBLE))]
          Join REGULAR INNER (a = c)
            r_dataframe_scan(0x...)
            r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      - d (DOUBLE)
      
      SELECT a AS a, d AS d FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c))) WHERE (d > CAST(3.0 AS DOUBLE))
    Code
      show_rel(over_order)
    Output
      Projection [a as a]
        Order [a ASC]
          Join REGULAR INNER (a = c)
            r_dataframe_scan(0x...)
            r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Projection [a as a]
        Order [a ASC]
          Join REGULAR INNER (a = c)
            r_dataframe_scan(0x...)
            r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      
      SELECT a AS a FROM ((SELECT * FROM r_dataframe_scan(0x...)) AS lhs INNER JOIN (SELECT * FROM r_dataframe_scan(0x...)) AS rhs ON ((a = c))) ORDER BY a ASC NULLS LAST

# printed tree and sql text: wrapped lazy data frame before and after materialization

    Code
      show_rel(wrapped)
    Output
      AltrepDataFrame [0x...]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      AltrepDataFrame [0x...]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      
      SELECT * FROM r_dataframe_scan(0x...)

---

    Code
      show_rel(wrapped_after)
    Output
      AltrepDataFrame [0x...]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      AltrepDataFrame [0x...]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - a (INTEGER)
      
      SELECT * FROM r_dataframe_scan(0x...)

# alias: a reference qualified by a relation resolves through projection, filter and order

    Code
      writeLines(rel_to_sql(final))
    Output
      SELECT foo.b AS b FROM (SELECT * FROM (SELECT * FROM (SELECT a AS a, b AS b FROM (SELECT * FROM r_dataframe_scan(0x...)) AS foo) AS foo WHERE (foo.a > 1)) AS foo ORDER BY foo.a DESC NULLS LAST) AS foo

# write: insert into an existing table and into a missing one

    Code
      rel_insert(rel, "main", "oracle_insert_missing")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Table with name oracle_insert_missing does not exist!\nDid you mean \"oracle_insert\"?","type":"Table","name":"oracle_insert_missing","candidates":"oracle_insert","error_subtype":"MISSING_ENTRY"}

---

    Code
      rel_insert(rel_from_df(con, data.frame(a = 1L)), "main", "oracle_insert")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Binder","exception_message":"table \"oracle_insert\" has 2 columns but 1 values were supplied"}

# write: to table, temporary and not, and onto an existing table

    Code
      rel_to_table(rel, "", "oracle_to_table", FALSE)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Failed to create table 'oracle_to_table': Table with name \"oracle_to_table\" already exists!","type":"Table","name":"oracle_to_table","error_subtype":"ENTRY_ALREADY_EXISTS"}

# write: to view over a data frame, queried repeatedly

    Code
      rel_to_view(rel, "", "oracle_to_view", FALSE)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Catalog","exception_message":"Failed to create view 'oracle_to_view': View with name \"oracle_to_view\" already exists!","type":"View","name":"oracle_to_view","error_subtype":"ENTRY_ALREADY_EXISTS"}

# write: to csv and to parquet, and an unknown option

    Code
      rel_to_csv(rel, file.path(dir, "bogus.csv"), list(bogus = 1L))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Not implemented","exception_message":"Unrecognized option \"bogus\" for csv\n\nCandidate options: \"row_group_size\", \"row_groups_per_file\", \"row_group_size_bytes\", \"thousands\", \"buffer_size\""}

---

    Code
      rel_to_parquet(rel, file.path(dir, "bogus.parquet"), list(bogus = 1L))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Not implemented","exception_message":"Unrecognized option \"bogus\" for parquet\n\nCandidate options: \"row_group_size\", \"row_groups_per_file\", \"row_group_size_bytes\", \"debug_use_openssl\", \"bloom_filter_false_positive_ratio\""}

# write: into a database attached read-only

    Code
      rel_insert(rel, "main", "ro")
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Invalid Input","exception_message":"Failed to insert into table 'ro': Cannot execute statement of type \"INSERT\" on database \"rodb\" which is attached in read-only mode!"}

---

    Code
      rel_to_table(rel, "main", "ro2", FALSE)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Invalid Input","exception_message":"Failed to create table 'ro2': Cannot execute statement of type \"CREATE\" on database \"rodb\" which is attached in read-only mode!"}

---

    Code
      rel_to_view(rel, "main", "rov", FALSE)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Invalid Input","exception_message":"Failed to create view 'rov': Cannot execute statement of type \"CREATE\" on database \"rodb\" which is attached in read-only mode!"}

# an aggregate function with order_bys

    Code
      show_rel(agg)
    Output
      Aggregate [g, string_agg(b, ',' ORDER BY a ASC NULLS LAST)]
        r_dataframe_scan(0x...)
      ---------------------
      --- Relation Tree ---
      ---------------------
      Aggregate [g, string_agg(b, ',' ORDER BY a ASC NULLS LAST)]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - g (INTEGER)
      - s (VARCHAR)
      
      SELECT g, string_agg(b, ',' ORDER BY a ASC NULLS LAST) AS s FROM (SELECT * FROM r_dataframe_scan(0x...)) AS dataframe_<id> GROUP BY g

# after disconnect: reading, building and lazy data frames

    Code
      as.data.frame(rel)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Connection","exception_message":"Connection has already been closed"}

---

    Code
      rel_filter(rel, list(gt("a", 1L)))
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Connection","exception_message":"Connection has already been closed"}

---

    Code
      rel_to_altrep(rel)
    Condition <rlang_error>
      Error:
      ! {"exception_type":"Connection","exception_message":"Connection has already been closed"}

---

    Code
      nrow(lazy)
    Condition <simpleError>
      Error:
      ! {"exception_type":"Connection","exception_message":"Connection has already been closed"}

# aborted transaction: a step builds, and reading it fails until the rollback

    Code
      as.data.frame(filtered)
    Condition <rlang_error>
      Error:
      ! TransactionContext Error: Current transaction is aborted (please ROLLBACK)

