#include "src/function/scalar/string/like.cpp"

#include "src/function/scalar/string/md5.cpp"

#include "src/function/scalar/string/mismatches.cpp"

#include "src/function/scalar/string/nfc_normalize.cpp"

#include "src/function/scalar/string/pad.cpp"

#include "src/function/scalar/string/prefix.cpp"

#include "src/function/scalar/string/printf.cpp"

#include "src/function/scalar/string/regexp.cpp"

#include "src/function/scalar/string/repeat.cpp"

#include "src/function/scalar/string/replace.cpp"

#include "src/function/scalar/string/reverse.cpp"

#include "src/function/scalar/string/string_split.cpp"

#include "src/function/scalar/string/strip_accents.cpp"

#include "src/function/scalar/string/substring.cpp"

#include "src/function/scalar/string/suffix.cpp"

#include "src/function/scalar/string/trim.cpp"

#include "src/function/scalar/string_functions.cpp"

#include "src/function/scalar/struct/struct_extract.cpp"

#include "src/function/scalar/struct/struct_pack.cpp"

#include "src/function/scalar/system/system_functions.cpp"

#include "src/function/scalar/trigonometrics_functions.cpp"

#include "src/function/table/arrow.cpp"

#include "src/function/table/checkpoint.cpp"

#include "src/function/table/copy_csv.cpp"

#include "src/function/table/glob.cpp"

#include "src/function/table/pragma_detailed_profiling_output.cpp"

#include "src/function/table/pragma_last_profiling_output.cpp"

#include "src/function/table/range.cpp"

#include "src/function/table/read_csv.cpp"

#include "src/function/table/repeat.cpp"

#include "src/function/table/summary.cpp"

#include "src/function/table/system/duckdb_columns.cpp"

#include "src/function/table/system/duckdb_constraints.cpp"

#include "src/function/table/system/duckdb_dependencies.cpp"

#include "src/function/table/system/duckdb_indexes.cpp"

#include "src/function/table/system/duckdb_schemas.cpp"

#include "src/function/table/system/duckdb_sequences.cpp"

#include "src/function/table/system/duckdb_tables.cpp"

#include "src/function/table/system/duckdb_types.cpp"

#include "src/function/table/system/duckdb_views.cpp"

#include "src/function/table/system/pragma_collations.cpp"

#include "src/function/table/system/pragma_database_list.cpp"

#include "src/function/table/system/pragma_database_size.cpp"

#include "src/function/table/system/pragma_functions.cpp"

#include "src/function/table/system/pragma_storage_info.cpp"

#include "src/function/table/system/pragma_table_info.cpp"

#include "src/function/table/system_functions.cpp"

#include "src/function/table/table_scan.cpp"

#include "src/function/table/unnest.cpp"

#include "src/function/table/version/pragma_version.cpp"

#include "src/function/udf_function.cpp"

#include "src/main/appender.cpp"

#include "src/main/capi/appender-c.cpp"

#include "src/main/capi/arrow-c.cpp"

#include "src/main/capi/config-c.cpp"

#include "src/main/capi/datetime-c.cpp"

#include "src/main/capi/duckdb-c.cpp"

#include "src/main/capi/helper-c.cpp"

#include "src/main/capi/hugeint-c.cpp"

#include "src/main/capi/prepared-c.cpp"

#include "src/main/capi/result-c.cpp"

#include "src/main/capi/value-c.cpp"

#include "src/main/client_context.cpp"

#include "src/main/client_context_file_opener.cpp"

#include "src/main/config.cpp"

#include "src/main/connection.cpp"

#include "src/main/database.cpp"

#include "src/main/materialized_query_result.cpp"

#include "src/main/prepared_statement.cpp"

#include "src/main/prepared_statement_data.cpp"

#include "src/main/query_profiler.cpp"

#include "src/main/query_result.cpp"

#include "src/main/relation.cpp"

#include "src/main/relation/aggregate_relation.cpp"

#include "src/main/relation/create_table_relation.cpp"

#include "src/main/relation/create_view_relation.cpp"

#include "src/main/relation/delete_relation.cpp"

#include "src/main/relation/distinct_relation.cpp"

#include "src/main/relation/explain_relation.cpp"

#include "src/main/relation/filter_relation.cpp"

#include "src/main/relation/insert_relation.cpp"

#include "src/main/relation/join_relation.cpp"

#include "src/main/relation/limit_relation.cpp"

#include "src/main/relation/order_relation.cpp"

#include "src/main/relation/projection_relation.cpp"

#include "src/main/relation/query_relation.cpp"

#include "src/main/relation/read_csv_relation.cpp"

#include "src/main/relation/setop_relation.cpp"

#include "src/main/relation/subquery_relation.cpp"

#include "src/main/relation/table_function_relation.cpp"

#include "src/main/relation/table_relation.cpp"

#include "src/main/relation/update_relation.cpp"

#include "src/main/relation/value_relation.cpp"

#include "src/main/relation/view_relation.cpp"

#include "src/main/relation/write_csv_relation.cpp"

#include "src/main/stream_query_result.cpp"

#include "src/optimizer/column_lifetime_analyzer.cpp"

#include "src/optimizer/common_aggregate_optimizer.cpp"

#include "src/optimizer/cse_optimizer.cpp"

#include "src/optimizer/deliminator.cpp"

#include "src/optimizer/expression_heuristics.cpp"

#include "src/optimizer/expression_rewriter.cpp"

#include "src/optimizer/filter_combiner.cpp"

#include "src/optimizer/filter_pullup.cpp"

#include "src/optimizer/filter_pushdown.cpp"

#include "src/optimizer/in_clause_rewriter.cpp"

#include "src/optimizer/join_order/join_relation_set.cpp"

#include "src/optimizer/join_order/query_graph.cpp"

