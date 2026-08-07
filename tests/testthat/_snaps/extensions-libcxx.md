# extensions message wording is stable

    Code
      rlang::inform(extensions_disabled_message())
    Message
      duckdb was built with libc++ (not libstdc++) on Linux, so DuckDB extensions are disabled:
      * Loading a prebuilt (libstdc++) extension could crash R (https://github.com/duckdb/duckdb-r/issues/1107).
      * INSTALL/LOAD of an extension will error, and automatic extension loading is off.
      i Pass duckdb(allow_extensions = FALSE) to accept this and silence this message.
      i Pass duckdb(allow_extensions = TRUE) to attempt loading anyway (may crash R).
      i See ?duckdb for details.

---

    Code
      rlang::inform(extensions_disabled_message())
    Message
      duckdb was built with <an unknown C++ library> (not libstdc++) on Linux, so DuckDB extensions are disabled:
      * Loading a prebuilt (libstdc++) extension could crash R (https://github.com/duckdb/duckdb-r/issues/1107).
      * INSTALL/LOAD of an extension will error, and automatic extension loading is off.
      i Pass duckdb(allow_extensions = FALSE) to accept this and silence this message.
      i Pass duckdb(allow_extensions = TRUE) to attempt loading anyway (may crash R).
      i See ?duckdb for details.

---

    Code
      rapi_error("load_extension", "")
    Condition
      Error in `rapi_error()`:
      ! DuckDB extension loading (INSTALL / LOAD) is disabled for this driver.
      i Recreate the driver with duckdb(allow_extensions = TRUE) to enable it (this may crash R on a Linux build not compiled with libstdc++; see https://github.com/duckdb/duckdb-r/issues/1107).
      i See ?duckdb for details.
      i Context: load_extension

