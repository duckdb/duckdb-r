# sql_query() validates connection

    Code
      sql_query("SELECT 1", conn = invalid_con)
    Condition
      Error in `sql_query()`:
      ! dbIsValid(conn) is not TRUE

# sql_exec() validates connection

    Code
      sql_exec("SELECT 1", conn = invalid_con)
    Condition
      Error in `sql_exec()`:
      ! dbIsValid(conn) is not TRUE

# error handling works correctly

    Code
      sql_exec("INVALID SQL SYNTAX")
    Condition
      Error in `dbSendQuery()`:
      ! Parser Error: syntax error at or near "INVALID"
      
      LINE 1: INVALID SQL SYNTAX
              ^
      
      LINE 1: INVALID SQL SYNTAX
              ^
      i Context: rapi_prepare
      i Error type: PARSER
      i Raw message: syntax error at or near "INVALID"
      
      LINE 1: INVALID SQL SYNTAX
              ^
      
      LINE 1: INVALID SQL SYNTAX
              ^

