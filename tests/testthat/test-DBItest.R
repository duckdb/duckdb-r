skip_on_cran()

if (rlang::is_installed("DBItest")) {
  DBItest::test_all(c(
    # `dbDataType()` says TIME for `hms` and `difftime`, the write routes INTERVAL,
    # so DBI's Arrow methods create a table they cannot append to
    # (handbook/usage/types/README.md).
    "arrow_write_table_arrow_roundtrip_time",
    "arrow_append_table_arrow_roundtrip_time",

    "package_name", # wontfix
    "package_dependencies", # wontfix
    "reexport", # wontfix

    "constructor", # wontfix
    "send_query_only_one_result_set", # wontfix
    "send_statement_only_one_result_set", # wontfix
    "send_query_stale_warning", # wontfix
    "send_statement_stale_warning", # wontfix

    if (packageVersion("DBItest") < "1.7.0.9004") "roundtrip_timestamp", # broken test

    "data_64_bit_numeric_warning", # 64 bit, not now
    "data_64_bit_lossless",
    "roundtrip_64_bit_character",
    "connect_bigint_integer",
    "connect_bigint_character",
    "connect_bigint_integer64",
    "append_roundtrip_64_bit_numeric",
    "append_roundtrip_64_bit_character",
    "append_roundtrip_64_bit_roundtrip",
    #
    "column_info_consistent", # won't fix: https://github.com/r-dbi/DBItest/issues/181

    "read_table", # these are temporarily skipped because factors can be round tripped
    "read_table_empty",
    "read_table_row_names_na_missing",
    "write_table_error",
    "overwrite_table",
    "overwrite_table_missing",
    "append_table",
    "append_table_new",
    "table_visible_in_other_connection",
    "roundtrip_character",
    "roundtrip_factor",
    "write_table_row_names_true_missing",
    "write_table_row_names_string_missing",
    "write_table_row_names_na_missing",
    "append_roundtrip_factor",
    "bind_factor",
    "arrow_bind_factor",
    "arrow_send_query_stale_warning", # wontfix
    "arrow_send_query_only_one_result_set", # wontfix
    "arrow_write_table_arrow_roundtrip_timestamp_extended", # precision
    "arrow_append_table_arrow_roundtrip_timestamp_extended", # precision

    # DBItest >= 1.8.3 uses lubridate::with_tz(tzone = "PST8PDT"), which warns
    # with "Unrecognized time zone" on systems whose tz database lacks that zone
    # (e.g. without tzdata-legacy). Skip only when the zone cannot be resolved.
    if (!"PST8PDT" %in% OlsonNames()) {
      c(
        "append_roundtrip_timestamp",
        "append_roundtrip_timestamp_extended",
        "arrow_append_table_arrow_roundtrip_timestamp",
        NULL
      )
    },

    # https://github.com/duckdb/duckdb/pull/15125
    "data_date_current_typed",
    "data_time_current",
    "data_date_current",

    if (!rlang::is_installed("vctrs")) {
      c(
        "arrow_append_table_arrow_roundtrip_blob",
        "data_type_driver",
        "data_type_connection",
        "data_time",
        "data_time_current",
        "data_timestamp_current",
        "data_timestamp_current_typed",
        "append_roundtrip_raw",
        "append_roundtrip_blob",
        "bind_blob",
        "arrow_bind_blob",
        "stream_bind_blob",
        "arrow_stream_bind_blob",
        NULL
      )
    },
    NULL
  ))
}
