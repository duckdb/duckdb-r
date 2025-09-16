# query() validates connection

    Code
      query("SELECT 1", conn = invalid_con)
    Condition
      Error in `query()`:
      ! dbIsValid(conn) is not TRUE

# exec() validates connection

    Code
      exec("SELECT 1", conn = invalid_con)
    Condition
      Error in `exec()`:
      ! dbIsValid(conn) is not TRUE

# error handling works correctly

    Code
      query("SELECT * FROM nonexistent_table_xyz")
    Condition
      Error in `dbSendQuery()`:
      ! Catalog Error: Table with name nonexistent_table_xyz does not exist!
      Did you mean "pg_constraint"?
      
      LINE 1: SELECT * FROM nonexistent_table_xyz
                            ^
      ℹ Context: rapi_prepare
      ℹ Error type: CATALOG
      ℹ Raw message: Table with name nonexistent_table_xyz does not exist!
      Did you mean "pg_constraint"?
      
      LINE 1: SELECT * FROM nonexistent_table_xyz
                            ^

---

    Code
      exec("INVALID SQL SYNTAX")
    Condition
      Error in `dbSendQuery()`:
      ! Parser Error: syntax error at or near "INVALID"
      
      LINE 1: INVALID SQL SYNTAX
              ^
      
      LINE 1: INVALID SQL SYNTAX
              ^
      ℹ Context: rapi_prepare
      ℹ Error type: PARSER
      ℹ Raw message: syntax error at or near "INVALID"
      
      LINE 1: INVALID SQL SYNTAX
              ^
      
      LINE 1: INVALID SQL SYNTAX
              ^

