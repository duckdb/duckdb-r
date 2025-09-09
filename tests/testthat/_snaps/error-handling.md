# rapi_error functions accept additional parameters

    Code
      rapi_error("test_context", "test message")
    Condition
      Error in `rapi_error()`:
      ! test message
      ℹ Context: test_context

---

    Code
      rapi_error("test_context", "test message", "PARSER")
    Condition
      Error in `rapi_error()`:
      ! test message
      ℹ Context: test_context
      ℹ Error type: PARSER

---

    Code
      rapi_error("test_context", "test message", "PARSER", "raw message")
    Condition
      Error in `rapi_error()`:
      ! test message
      ℹ Context: test_context
      ℹ Error type: PARSER
      ℹ Raw message: raw message

---

    Code
      rapi_error("test_context", "test message", "PARSER", "raw message", list(key = "value"))
    Condition
      Error in `rapi_error()`:
      ! test message
      ℹ Context: test_context
      ℹ Error type: PARSER
      ℹ Raw message: raw message
      ℹ key: value

