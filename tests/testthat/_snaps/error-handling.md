# rapi_error functions accept additional parameters

    Code
      rapi_error("test_context", "test message")
    Condition
      Error in `rapi_error()`:
      ! test message
      i Context: test_context

---

    Code
      rapi_error("test_context", "test message", "PARSER")
    Condition
      Error in `rapi_error()`:
      ! test message
      i Context: test_context
      i Error type: PARSER

---

    Code
      rapi_error("test_context", "test message", "PARSER", "raw message", c(key = "value"))
    Condition
      Error in `rapi_error()`:
      ! test message
      i Context: test_context
      i Error type: PARSER

# the rethrow names the caller and keeps the message readable

    Code
      dbGetQuery(con, "SELECT missing_column")
    Condition
      Error in `dbSendQuery()`:
      ! Binder Error: Referenced column "missing_column" was not found because the FROM clause is missing
      
      LINE 1: SELECT missing_column
                     ^^^^^^^^^^^^^^
      i Context: rapi_prepare
      i Error type: BINDER

