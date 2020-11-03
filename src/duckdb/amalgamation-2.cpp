#include "src/execution/expression_executor/execute_comparison.cpp"

#include "src/execution/expression_executor/execute_conjunction.cpp"

#include "src/execution/expression_executor/execute_constant.cpp"

#include "src/execution/expression_executor/execute_function.cpp"

#include "src/execution/expression_executor/execute_operator.cpp"

#include "src/execution/expression_executor/execute_parameter.cpp"

#include "src/execution/expression_executor/execute_reference.cpp"

#include "src/execution/expression_executor_state.cpp"

#include "src/execution/index/art/art.cpp"

#include "src/execution/index/art/art_key.cpp"

#include "src/execution/index/art/leaf.cpp"

#include "src/execution/index/art/node.cpp"

#include "src/execution/index/art/node16.cpp"

#include "src/execution/index/art/node256.cpp"

#include "src/execution/index/art/node4.cpp"

#include "src/execution/index/art/node48.cpp"

#include "src/execution/join_hashtable.cpp"

#include "src/execution/merge_join/merge_join.cpp"

#include "src/execution/merge_join/merge_join_complex.cpp"

#include "src/execution/merge_join/merge_join_simple.cpp"

#include "src/execution/nested_loop_join/nested_loop_join_inner.cpp"

#include "src/execution/nested_loop_join/nested_loop_join_mark.cpp"

#include "src/execution/operator/aggregate/physical_hash_aggregate.cpp"

#include "src/execution/operator/aggregate/physical_simple_aggregate.cpp"

#include "src/execution/operator/aggregate/physical_window.cpp"

#include "src/execution/operator/filter/physical_filter.cpp"

#include "src/execution/operator/helper/physical_execute.cpp"

#include "src/execution/operator/helper/physical_limit.cpp"

#include "src/execution/operator/helper/physical_pragma.cpp"

#include "src/execution/operator/helper/physical_prepare.cpp"

#include "src/execution/operator/helper/physical_transaction.cpp"

#include "src/execution/operator/helper/physical_vacuum.cpp"

#include "src/execution/operator/join/physical_blockwise_nl_join.cpp"

#include "src/execution/operator/join/physical_comparison_join.cpp"

#include "src/execution/operator/join/physical_cross_product.cpp"

#include "src/execution/operator/join/physical_delim_join.cpp"

#include "src/execution/operator/join/physical_hash_join.cpp"

#include "src/execution/operator/join/physical_index_join.cpp"

#include "src/execution/operator/join/physical_join.cpp"

#include "src/execution/operator/join/physical_nested_loop_join.cpp"

#include "src/execution/operator/join/physical_piecewise_merge_join.cpp"

#include "src/execution/operator/order/physical_order.cpp"

#include "src/execution/operator/order/physical_top_n.cpp"

#include "src/execution/operator/persistent/buffered_csv_reader.cpp"

#include "src/execution/operator/persistent/physical_copy_to_file.cpp"

#include "src/execution/operator/persistent/physical_delete.cpp"

#include "src/execution/operator/persistent/physical_export.cpp"

#include "src/execution/operator/persistent/physical_insert.cpp"

#include "src/execution/operator/persistent/physical_update.cpp"

#include "src/execution/operator/projection/physical_projection.cpp"

#include "src/execution/operator/projection/physical_unnest.cpp"

#include "src/execution/operator/scan/physical_chunk_scan.cpp"

#include "src/execution/operator/scan/physical_dummy_scan.cpp"

#include "src/execution/operator/scan/physical_empty_result.cpp"

#include "src/execution/operator/scan/physical_expression_scan.cpp"

#include "src/execution/operator/scan/physical_table_scan.cpp"

#include "src/execution/operator/schema/physical_alter.cpp"

#include "src/execution/operator/schema/physical_create_index.cpp"

#include "src/execution/operator/schema/physical_create_schema.cpp"

#include "src/execution/operator/schema/physical_create_sequence.cpp"

#include "src/execution/operator/schema/physical_create_table.cpp"

#include "src/execution/operator/schema/physical_create_view.cpp"

#include "src/execution/operator/schema/physical_drop.cpp"

#include "src/execution/operator/set/physical_recursive_cte.cpp"

#include "src/execution/operator/set/physical_union.cpp"

#include "src/execution/partitionable_hashtable.cpp"

#include "src/execution/physical_operator.cpp"

#include "src/execution/physical_plan/plan_aggregate.cpp"

#include "src/execution/physical_plan/plan_any_join.cpp"

#include "src/execution/physical_plan/plan_chunk_get.cpp"

#include "src/execution/physical_plan/plan_comparison_join.cpp"

#include "src/execution/physical_plan/plan_copy_to_file.cpp"

#include "src/execution/physical_plan/plan_create.cpp"

#include "src/execution/physical_plan/plan_create_index.cpp"

#include "src/execution/physical_plan/plan_create_table.cpp"

#include "src/execution/physical_plan/plan_cross_product.cpp"

#include "src/execution/physical_plan/plan_delete.cpp"

#include "src/execution/physical_plan/plan_delim_get.cpp"

#include "src/execution/physical_plan/plan_delim_join.cpp"

