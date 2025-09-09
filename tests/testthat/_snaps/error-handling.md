# rapi_error functions accept additional parameters

    Code
      rapi_error("test_context", "test message")
    Condition
      [1m[33mError[39m in `rapi_error()`:[22m
      [33m![39m test message
      ℹ Context: test_context

---

    Code
      rapi_error("test_context", "test message", "PARSER")
    Condition
      [1m[33mError[39m in `rapi_error()`:[22m
      [33m![39m test message
      ℹ Context: test_context
      ℹ Error type: PARSER

---

    Code
      rapi_error("test_context", "test message", "PARSER", "raw message")
    Condition
      [1m[33mError[39m in `rapi_error()`:[22m
      [33m![39m test message
      ℹ Context: test_context
      ℹ Error type: PARSER
      ℹ Raw message: raw message

---

    Code
      rapi_error("test_context", "test message", "PARSER", "raw message", list(key = "value"))
    Condition
      [1m[33mError[39m in `rapi_error()`:[22m
      [33m![39m test message
      ℹ Context: test_context
      ℹ Error type: PARSER
      ℹ Raw message: raw message
      ℹ key: value

