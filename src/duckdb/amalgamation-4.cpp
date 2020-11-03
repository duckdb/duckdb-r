#include "src/function/scalar/string/replace.cpp"

#include "src/function/scalar/string/reverse.cpp"

#include "src/function/scalar/string/string_split.cpp"

#include "src/function/scalar/string/strip_accents.cpp"

#include "src/function/scalar/string/substring.cpp"

#include "src/function/scalar/string/suffix.cpp"

#include "src/function/scalar/string/trim.cpp"

#include "src/function/scalar/string_functions.cpp"

#include "src/function/scalar/trigonometrics_functions.cpp"

#include "src/function/table/arrow.cpp"

#include "src/function/table/copy_csv.cpp"

#include "src/function/table/glob.cpp"

#include "src/function/table/information_schema/information_schema_columns.cpp"

#include "src/function/table/information_schema/information_schema_schemata.cpp"

#include "src/function/table/information_schema/information_schema_tables.cpp"

#include "src/function/table/information_schema_functions.cpp"

#include "src/function/table/range.cpp"

#include "src/function/table/read_csv.cpp"

#include "src/function/table/repeat.cpp"

#include "src/function/table/sqlite/pragma_collations.cpp"

#include "src/function/table/sqlite/pragma_database_list.cpp"

#include "src/function/table/sqlite/pragma_table_info.cpp"

#include "src/function/table/sqlite/sqlite_master.cpp"

#include "src/function/table/sqlite_functions.cpp"

#include "src/function/table/table_scan.cpp"

#include "src/function/table/version/pragma_version.cpp"

#include "src/function/udf_function.cpp"

#include "src/main/appender.cpp"

#include "src/main/client_context.cpp"

#include "src/main/connection.cpp"

#include "src/main/connection_manager.cpp"

#include "src/main/database.cpp"

#include "src/main/duckdb-c.cpp"

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

#include "src/optimizer/cse_optimizer.cpp"

#include "src/optimizer/expression_heuristics.cpp"

#include "src/optimizer/expression_rewriter.cpp"

#include "src/optimizer/filter_combiner.cpp"

#include "src/optimizer/filter_pushdown.cpp"

#include "src/optimizer/in_clause_rewriter.cpp"

#include "src/optimizer/join_order/query_graph.cpp"

#include "src/optimizer/join_order/relation.cpp"

#include "src/optimizer/join_order_optimizer.cpp"

#include "src/optimizer/matcher/expression_matcher.cpp"

#include "src/optimizer/optimizer.cpp"

#include "src/optimizer/pushdown/pushdown_aggregate.cpp"

#include "src/optimizer/pushdown/pushdown_cross_product.cpp"

#include "src/optimizer/pushdown/pushdown_filter.cpp"

#include "src/optimizer/pushdown/pushdown_get.cpp"

#include "src/optimizer/pushdown/pushdown_inner_join.cpp"

#include "src/optimizer/pushdown/pushdown_left_join.cpp"

