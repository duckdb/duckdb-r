#include "src/optimizer/pullup/pullup_filter.cpp"

#include "src/optimizer/pullup/pullup_from_left.cpp"

#include "src/optimizer/pullup/pullup_projection.cpp"

#include "src/optimizer/pullup/pullup_set_operation.cpp"

#include "src/optimizer/pushdown/pushdown_aggregate.cpp"

#include "src/optimizer/pushdown/pushdown_cross_product.cpp"

#include "src/optimizer/pushdown/pushdown_filter.cpp"

#include "src/optimizer/pushdown/pushdown_get.cpp"

#include "src/optimizer/pushdown/pushdown_inner_join.cpp"

#include "src/optimizer/pushdown/pushdown_left_join.cpp"

#include "src/optimizer/pushdown/pushdown_mark_join.cpp"

#include "src/optimizer/pushdown/pushdown_projection.cpp"

#include "src/optimizer/pushdown/pushdown_set_operation.cpp"

#include "src/optimizer/pushdown/pushdown_single_join.cpp"

#include "src/optimizer/regex_range_filter.cpp"

#include "src/optimizer/remove_unused_columns.cpp"

#include "src/optimizer/rule/arithmetic_simplification.cpp"

#include "src/optimizer/rule/case_simplification.cpp"

#include "src/optimizer/rule/comparison_simplification.cpp"

#include "src/optimizer/rule/conjunction_simplification.cpp"

#include "src/optimizer/rule/constant_folding.cpp"

#include "src/optimizer/rule/date_part_simplification.cpp"

#include "src/optimizer/rule/distributivity.cpp"

#include "src/optimizer/rule/empty_needle_removal.cpp"

#include "src/optimizer/rule/enum_comparison.cpp"

#include "src/optimizer/rule/in_clause_simplification_rule.cpp"

#include "src/optimizer/rule/like_optimizations.cpp"

#include "src/optimizer/rule/move_constants.cpp"

#include "src/optimizer/statistics/expression/propagate_aggregate.cpp"

#include "src/optimizer/statistics/expression/propagate_and_compress.cpp"

#include "src/optimizer/statistics/expression/propagate_between.cpp"

#include "src/optimizer/statistics/expression/propagate_case.cpp"

#include "src/optimizer/statistics/expression/propagate_cast.cpp"

#include "src/optimizer/statistics/expression/propagate_columnref.cpp"

#include "src/optimizer/statistics/expression/propagate_comparison.cpp"

#include "src/optimizer/statistics/expression/propagate_conjunction.cpp"

#include "src/optimizer/statistics/expression/propagate_constant.cpp"

#include "src/optimizer/statistics/expression/propagate_function.cpp"

#include "src/optimizer/statistics/expression/propagate_operator.cpp"

#include "src/optimizer/statistics/operator/propagate_aggregate.cpp"

#include "src/optimizer/statistics/operator/propagate_cross_product.cpp"

#include "src/optimizer/statistics/operator/propagate_filter.cpp"

#include "src/optimizer/statistics/operator/propagate_get.cpp"

#include "src/optimizer/statistics/operator/propagate_join.cpp"

#include "src/optimizer/statistics/operator/propagate_limit.cpp"

#include "src/optimizer/statistics/operator/propagate_order.cpp"

