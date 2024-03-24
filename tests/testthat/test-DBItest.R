skip_on_cran()

if (rlang::is_installed("DBItest")) DBItest::test_all(c(
  if (!TEST_RE2) c(
    "list_tables",
    "list_tables_quote",
    "list_fields_object",
    "list_objects",
    "list_objects_quote",
    "list_objects_features",
    "remove_table_list",
    "remove_table_other_con",
    "exists_table_list"
  ),

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
  NULL
))
