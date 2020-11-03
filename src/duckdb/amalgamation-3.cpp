#include "src/execution/physical_plan/plan_distinct.cpp"

#include "src/execution/physical_plan/plan_dummy_scan.cpp"

#include "src/execution/physical_plan/plan_empty_result.cpp"

#include "src/execution/physical_plan/plan_execute.cpp"

#include "src/execution/physical_plan/plan_explain.cpp"

#include "src/execution/physical_plan/plan_export.cpp"

#include "src/execution/physical_plan/plan_expression_get.cpp"

#include "src/execution/physical_plan/plan_filter.cpp"

#include "src/execution/physical_plan/plan_get.cpp"

#include "src/execution/physical_plan/plan_insert.cpp"

#include "src/execution/physical_plan/plan_limit.cpp"

#include "src/execution/physical_plan/plan_order.cpp"

#include "src/execution/physical_plan/plan_pragma.cpp"

#include "src/execution/physical_plan/plan_prepare.cpp"

#include "src/execution/physical_plan/plan_projection.cpp"

#include "src/execution/physical_plan/plan_recursive_cte.cpp"

#include "src/execution/physical_plan/plan_set_operation.cpp"

#include "src/execution/physical_plan/plan_simple.cpp"

#include "src/execution/physical_plan/plan_top_n.cpp"

#include "src/execution/physical_plan/plan_unnest.cpp"

#include "src/execution/physical_plan/plan_update.cpp"

#include "src/execution/physical_plan/plan_window.cpp"

#include "src/execution/physical_plan_generator.cpp"

#include "src/execution/window_segment_tree.cpp"

#include "src/function/aggregate/algebraic/avg.cpp"

#include "src/function/aggregate/algebraic/covar.cpp"

#include "src/function/aggregate/algebraic/stddev.cpp"

#include "src/function/aggregate/algebraic_functions.cpp"

#include "src/function/aggregate/distributive/bitagg.cpp"

#include "src/function/aggregate/distributive/count.cpp"

#include "src/function/aggregate/distributive/first.cpp"

#include "src/function/aggregate/distributive/minmax.cpp"

#include "src/function/aggregate/distributive/string_agg.cpp"

#include "src/function/aggregate/distributive/sum.cpp"

#include "src/function/aggregate/distributive_functions.cpp"

#include "src/function/aggregate/nested/list.cpp"

#include "src/function/aggregate/nested_functions.cpp"

#include "src/function/cast_rules.cpp"

#include "src/function/function.cpp"

#include "src/function/pragma/pragma_functions.cpp"

#include "src/function/pragma/pragma_queries.cpp"

#include "src/function/pragma_function.cpp"

#include "src/function/scalar/date/age.cpp"

#include "src/function/scalar/date/current.cpp"

#include "src/function/scalar/date/date_part.cpp"

#include "src/function/scalar/date/date_trunc.cpp"

#include "src/function/scalar/date/epoch.cpp"

#include "src/function/scalar/date/strftime.cpp"

#include "src/function/scalar/date_functions.cpp"

#include "src/function/scalar/generic/least.cpp"

#include "src/function/scalar/generic_functions.cpp"

#include "src/function/scalar/math/numeric.cpp"

#include "src/function/scalar/math/random.cpp"

#include "src/function/scalar/math/setseed.cpp"

#include "src/function/scalar/math_functions.cpp"

#include "src/function/scalar/nested/list_value.cpp"

#include "src/function/scalar/nested/struct_extract.cpp"

#include "src/function/scalar/nested/struct_pack.cpp"

#include "src/function/scalar/nested_functions.cpp"

#include "src/function/scalar/operators.cpp"

#include "src/function/scalar/operators/arithmetic.cpp"

#include "src/function/scalar/operators/bitwise.cpp"

#include "src/function/scalar/pragma_functions.cpp"

#include "src/function/scalar/sequence/nextval.cpp"

#include "src/function/scalar/sequence_functions.cpp"

#include "src/function/scalar/string/caseconvert.cpp"

#include "src/function/scalar/string/concat.cpp"

#include "src/function/scalar/string/contains.cpp"

#include "src/function/scalar/string/instr.cpp"

#include "src/function/scalar/string/left_right.cpp"

#include "src/function/scalar/string/length.cpp"

#include "src/function/scalar/string/like.cpp"

#include "src/function/scalar/string/md5.cpp"

#include "src/function/scalar/string/nfc_normalize.cpp"

#include "src/function/scalar/string/pad.cpp"

#include "src/function/scalar/string/prefix.cpp"

#include "src/function/scalar/string/printf.cpp"

#include "src/function/scalar/string/regexp.cpp"

#include "src/function/scalar/string/repeat.cpp"

