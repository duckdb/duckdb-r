#include "src/optimizer/build_probe_side_optimizer.cpp"

#include "src/optimizer/column_binding_replacer.cpp"

#include "src/optimizer/column_lifetime_analyzer.cpp"

#include "src/optimizer/empty_result_pullup.cpp"

#include "src/optimizer/common_aggregate_optimizer.cpp"

#include "src/optimizer/compressed_materialization.cpp"

#include "src/optimizer/cse_optimizer.cpp"

#include "src/optimizer/cte_filter_pusher.cpp"

#include "src/optimizer/deliminator.cpp"

#include "src/optimizer/expression_heuristics.cpp"

#include "src/optimizer/expression_rewriter.cpp"

#include "src/optimizer/filter_combiner.cpp"

#include "src/optimizer/filter_pullup.cpp"

#include "src/optimizer/filter_pushdown.cpp"

#include "src/optimizer/in_clause_rewriter.cpp"

#include "src/optimizer/join_filter_pushdown_optimizer.cpp"

#include "src/optimizer/late_materialization.cpp"

#include "src/optimizer/optimizer.cpp"

#include "src/optimizer/regex_range_filter.cpp"

#include "src/optimizer/remove_duplicate_groups.cpp"

#include "src/optimizer/remove_unused_columns.cpp"

#include "src/optimizer/statistics_propagator.cpp"

#include "src/optimizer/limit_pushdown.cpp"

#include "src/optimizer/topn_optimizer.cpp"

#include "src/optimizer/unnest_rewriter.cpp"

#include "src/optimizer/sampling_pushdown.cpp"

#include "src/optimizer/sum_rewriter.cpp"

