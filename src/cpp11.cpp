// Generated by cpp11: do not edit by hand
// clang-format off

#include "duckdb_types.hpp"
#include "cpp11/declarations.hpp"
#include <R_ext/Visibility.h>

// connection.cpp
duckdb::conn_eptr_t rapi_connect(duckdb::db_eptr_t dual);
extern "C" SEXP _duckdb_rapi_connect(SEXP dual) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_connect(cpp11::as_cpp<cpp11::decay_t<duckdb::db_eptr_t>>(dual)));
  END_CPP11
}
// connection.cpp
void rapi_disconnect(duckdb::conn_eptr_t conn);
extern "C" SEXP _duckdb_rapi_disconnect(SEXP conn) {
  BEGIN_CPP11
    rapi_disconnect(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn));
    return R_NilValue;
  END_CPP11
}
// database.cpp
duckdb::db_eptr_t rapi_startup(std::string dbdir, bool readonly, cpp11::list configsexp);
extern "C" SEXP _duckdb_rapi_startup(SEXP dbdir, SEXP readonly, SEXP configsexp) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_startup(cpp11::as_cpp<cpp11::decay_t<std::string>>(dbdir), cpp11::as_cpp<cpp11::decay_t<bool>>(readonly), cpp11::as_cpp<cpp11::decay_t<cpp11::list>>(configsexp)));
  END_CPP11
}
// database.cpp
bool rapi_lock(duckdb::db_eptr_t dual);
extern "C" SEXP _duckdb_rapi_lock(SEXP dual) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_lock(cpp11::as_cpp<cpp11::decay_t<duckdb::db_eptr_t>>(dual)));
  END_CPP11
}
// database.cpp
void rapi_unlock(duckdb::db_eptr_t dual);
extern "C" SEXP _duckdb_rapi_unlock(SEXP dual) {
  BEGIN_CPP11
    rapi_unlock(cpp11::as_cpp<cpp11::decay_t<duckdb::db_eptr_t>>(dual));
    return R_NilValue;
  END_CPP11
}
// database.cpp
bool rapi_is_locked(duckdb::db_eptr_t dual);
extern "C" SEXP _duckdb_rapi_is_locked(SEXP dual) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_is_locked(cpp11::as_cpp<cpp11::decay_t<duckdb::db_eptr_t>>(dual)));
  END_CPP11
}
// database.cpp
void rapi_shutdown(duckdb::db_eptr_t dbsexp);
extern "C" SEXP _duckdb_rapi_shutdown(SEXP dbsexp) {
  BEGIN_CPP11
    rapi_shutdown(cpp11::as_cpp<cpp11::decay_t<duckdb::db_eptr_t>>(dbsexp));
    return R_NilValue;
  END_CPP11
}
// register.cpp
void rapi_register_df(duckdb::conn_eptr_t conn, std::string name, cpp11::data_frame value, bool integer64, bool overwrite, bool experimental);
extern "C" SEXP _duckdb_rapi_register_df(SEXP conn, SEXP name, SEXP value, SEXP integer64, SEXP overwrite, SEXP experimental) {
  BEGIN_CPP11
    rapi_register_df(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(name), cpp11::as_cpp<cpp11::decay_t<cpp11::data_frame>>(value), cpp11::as_cpp<cpp11::decay_t<bool>>(integer64), cpp11::as_cpp<cpp11::decay_t<bool>>(overwrite), cpp11::as_cpp<cpp11::decay_t<bool>>(experimental));
    return R_NilValue;
  END_CPP11
}
// register.cpp
void rapi_unregister_df(duckdb::conn_eptr_t conn, std::string name);
extern "C" SEXP _duckdb_rapi_unregister_df(SEXP conn, SEXP name) {
  BEGIN_CPP11
    rapi_unregister_df(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(name));
    return R_NilValue;
  END_CPP11
}
// register.cpp
void rapi_register_arrow(duckdb::conn_eptr_t conn, std::string name, cpp11::list export_funs, cpp11::sexp valuesexp);
extern "C" SEXP _duckdb_rapi_register_arrow(SEXP conn, SEXP name, SEXP export_funs, SEXP valuesexp) {
  BEGIN_CPP11
    rapi_register_arrow(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(name), cpp11::as_cpp<cpp11::decay_t<cpp11::list>>(export_funs), cpp11::as_cpp<cpp11::decay_t<cpp11::sexp>>(valuesexp));
    return R_NilValue;
  END_CPP11
}
// register.cpp
void rapi_unregister_arrow(duckdb::conn_eptr_t conn, std::string name);
extern "C" SEXP _duckdb_rapi_unregister_arrow(SEXP conn, SEXP name) {
  BEGIN_CPP11
    rapi_unregister_arrow(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(name));
    return R_NilValue;
  END_CPP11
}
// register.cpp
cpp11::strings rapi_list_arrow(duckdb::conn_eptr_t conn);
extern "C" SEXP _duckdb_rapi_list_arrow(SEXP conn) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_list_arrow(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn)));
  END_CPP11
}
// relational.cpp
SEXP rapi_expr_reference(r_vector<r_string> rnames);
extern "C" SEXP _duckdb_rapi_expr_reference(SEXP rnames) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_expr_reference(cpp11::as_cpp<cpp11::decay_t<r_vector<r_string>>>(rnames)));
  END_CPP11
}
// relational.cpp
SEXP rapi_expr_constant(sexp val);
extern "C" SEXP _duckdb_rapi_expr_constant(SEXP val) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_expr_constant(cpp11::as_cpp<cpp11::decay_t<sexp>>(val)));
  END_CPP11
}
// relational.cpp
SEXP rapi_expr_comparison(std::string cmp_op, list exprs);
extern "C" SEXP _duckdb_rapi_expr_comparison(SEXP cmp_op, SEXP exprs) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_expr_comparison(cpp11::as_cpp<cpp11::decay_t<std::string>>(cmp_op), cpp11::as_cpp<cpp11::decay_t<list>>(exprs)));
  END_CPP11
}
// relational.cpp
SEXP rapi_expr_function(std::string name, list args, list order_bys, list filter_bys);
extern "C" SEXP _duckdb_rapi_expr_function(SEXP name, SEXP args, SEXP order_bys, SEXP filter_bys) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_expr_function(cpp11::as_cpp<cpp11::decay_t<std::string>>(name), cpp11::as_cpp<cpp11::decay_t<list>>(args), cpp11::as_cpp<cpp11::decay_t<list>>(order_bys), cpp11::as_cpp<cpp11::decay_t<list>>(filter_bys)));
  END_CPP11
}
// relational.cpp
void rapi_expr_set_alias(duckdb::expr_extptr_t expr, std::string alias);
extern "C" SEXP _duckdb_rapi_expr_set_alias(SEXP expr, SEXP alias) {
  BEGIN_CPP11
    rapi_expr_set_alias(cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(expr), cpp11::as_cpp<cpp11::decay_t<std::string>>(alias));
    return R_NilValue;
  END_CPP11
}
// relational.cpp
std::string rapi_expr_tostring(duckdb::expr_extptr_t expr);
extern "C" SEXP _duckdb_rapi_expr_tostring(SEXP expr) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_expr_tostring(cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(expr)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_from_df(duckdb::conn_eptr_t con, data_frame df, bool experimental);
extern "C" SEXP _duckdb_rapi_rel_from_df(SEXP con, SEXP df, SEXP experimental) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_from_df(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(con), cpp11::as_cpp<cpp11::decay_t<data_frame>>(df), cpp11::as_cpp<cpp11::decay_t<bool>>(experimental)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_filter(duckdb::rel_extptr_t rel, list exprs);
extern "C" SEXP _duckdb_rapi_rel_filter(SEXP rel, SEXP exprs) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_filter(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<list>>(exprs)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_project(duckdb::rel_extptr_t rel, list exprs);
extern "C" SEXP _duckdb_rapi_rel_project(SEXP rel, SEXP exprs) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_project(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<list>>(exprs)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_aggregate(duckdb::rel_extptr_t rel, list groups, list aggregates);
extern "C" SEXP _duckdb_rapi_rel_aggregate(SEXP rel, SEXP groups, SEXP aggregates) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_aggregate(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<list>>(groups), cpp11::as_cpp<cpp11::decay_t<list>>(aggregates)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_order(duckdb::rel_extptr_t rel, list orders, r_vector<r_bool> ascending);
extern "C" SEXP _duckdb_rapi_rel_order(SEXP rel, SEXP orders, SEXP ascending) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_order(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<list>>(orders), cpp11::as_cpp<cpp11::decay_t<r_vector<r_bool>>>(ascending)));
  END_CPP11
}
// relational.cpp
SEXP rapi_expr_window(duckdb::expr_extptr_t window_function, list partitions, list order_bys, std::string window_boundary_start, std::string window_boundary_end, duckdb::expr_extptr_t start_expr, duckdb::expr_extptr_t end_expr, duckdb::expr_extptr_t offset_expr, duckdb::expr_extptr_t default_expr);
extern "C" SEXP _duckdb_rapi_expr_window(SEXP window_function, SEXP partitions, SEXP order_bys, SEXP window_boundary_start, SEXP window_boundary_end, SEXP start_expr, SEXP end_expr, SEXP offset_expr, SEXP default_expr) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_expr_window(cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(window_function), cpp11::as_cpp<cpp11::decay_t<list>>(partitions), cpp11::as_cpp<cpp11::decay_t<list>>(order_bys), cpp11::as_cpp<cpp11::decay_t<std::string>>(window_boundary_start), cpp11::as_cpp<cpp11::decay_t<std::string>>(window_boundary_end), cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(start_expr), cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(end_expr), cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(offset_expr), cpp11::as_cpp<cpp11::decay_t<duckdb::expr_extptr_t>>(default_expr)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_join(duckdb::rel_extptr_t left, duckdb::rel_extptr_t right, list conds, std::string join, std::string join_ref_type);
extern "C" SEXP _duckdb_rapi_rel_join(SEXP left, SEXP right, SEXP conds, SEXP join, SEXP join_ref_type) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_join(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(left), cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(right), cpp11::as_cpp<cpp11::decay_t<list>>(conds), cpp11::as_cpp<cpp11::decay_t<std::string>>(join), cpp11::as_cpp<cpp11::decay_t<std::string>>(join_ref_type)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_union_all(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b);
extern "C" SEXP _duckdb_rapi_rel_union_all(SEXP rel_a, SEXP rel_b) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_union_all(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_a), cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_b)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_limit(duckdb::rel_extptr_t rel, int64_t n);
extern "C" SEXP _duckdb_rapi_rel_limit(SEXP rel, SEXP n) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_limit(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<int64_t>>(n)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_distinct(duckdb::rel_extptr_t rel);
extern "C" SEXP _duckdb_rapi_rel_distinct(SEXP rel) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_distinct(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_to_df(duckdb::rel_extptr_t rel);
extern "C" SEXP _duckdb_rapi_rel_to_df(SEXP rel) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_to_df(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel)));
  END_CPP11
}
// relational.cpp
std::string rapi_rel_tostring(duckdb::rel_extptr_t rel, std::string format);
extern "C" SEXP _duckdb_rapi_rel_tostring(SEXP rel, SEXP format) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_tostring(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<std::string>>(format)));
  END_CPP11
}
// relational.cpp
std::string rapi_rel_to_sql(duckdb::rel_extptr_t rel);
extern "C" SEXP _duckdb_rapi_rel_to_sql(SEXP rel) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_to_sql(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_explain(duckdb::rel_extptr_t rel, std::string type, std::string format);
extern "C" SEXP _duckdb_rapi_rel_explain(SEXP rel, SEXP type, SEXP format) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_explain(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<std::string>>(type), cpp11::as_cpp<cpp11::decay_t<std::string>>(format)));
  END_CPP11
}
// relational.cpp
std::string rapi_rel_alias(duckdb::rel_extptr_t rel);
extern "C" SEXP _duckdb_rapi_rel_alias(SEXP rel) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_alias(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel)));
  END_CPP11
}
// relational.cpp
SEXP rapi_get_null_SEXP_ptr();
extern "C" SEXP _duckdb_rapi_get_null_SEXP_ptr() {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_get_null_SEXP_ptr());
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_set_alias(duckdb::rel_extptr_t rel, std::string alias);
extern "C" SEXP _duckdb_rapi_rel_set_alias(SEXP rel, SEXP alias) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_set_alias(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<std::string>>(alias)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_sql(duckdb::rel_extptr_t rel, std::string sql);
extern "C" SEXP _duckdb_rapi_rel_sql(SEXP rel, SEXP sql) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_sql(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<std::string>>(sql)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_names(duckdb::rel_extptr_t rel);
extern "C" SEXP _duckdb_rapi_rel_names(SEXP rel) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_names(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_set_intersect(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b);
extern "C" SEXP _duckdb_rapi_rel_set_intersect(SEXP rel_a, SEXP rel_b) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_set_intersect(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_a), cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_b)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_set_diff(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b);
extern "C" SEXP _duckdb_rapi_rel_set_diff(SEXP rel_a, SEXP rel_b) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_set_diff(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_a), cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_b)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_set_symdiff(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b);
extern "C" SEXP _duckdb_rapi_rel_set_symdiff(SEXP rel_a, SEXP rel_b) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_set_symdiff(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_a), cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel_b)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_from_sql(duckdb::conn_eptr_t con, const std::string sql);
extern "C" SEXP _duckdb_rapi_rel_from_sql(SEXP con, SEXP sql) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_from_sql(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(con), cpp11::as_cpp<cpp11::decay_t<const std::string>>(sql)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_from_table(duckdb::conn_eptr_t con, const std::string schema_name, const std::string table_name);
extern "C" SEXP _duckdb_rapi_rel_from_table(SEXP con, SEXP schema_name, SEXP table_name) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_from_table(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(con), cpp11::as_cpp<cpp11::decay_t<const std::string>>(schema_name), cpp11::as_cpp<cpp11::decay_t<const std::string>>(table_name)));
  END_CPP11
}
// relational.cpp
SEXP rapi_rel_from_table_function(duckdb::conn_eptr_t con, const std::string function_name, list positional_parameters_sexps, list named_parameters_sexps);
extern "C" SEXP _duckdb_rapi_rel_from_table_function(SEXP con, SEXP function_name, SEXP positional_parameters_sexps, SEXP named_parameters_sexps) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_from_table_function(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(con), cpp11::as_cpp<cpp11::decay_t<const std::string>>(function_name), cpp11::as_cpp<cpp11::decay_t<list>>(positional_parameters_sexps), cpp11::as_cpp<cpp11::decay_t<list>>(named_parameters_sexps)));
  END_CPP11
}
// reltoaltrep.cpp
SEXP rapi_get_last_rel();
extern "C" SEXP _duckdb_rapi_get_last_rel() {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_get_last_rel());
  END_CPP11
}
// reltoaltrep.cpp
SEXP rapi_rel_to_altrep(duckdb::rel_extptr_t rel, bool allow_materialization);
extern "C" SEXP _duckdb_rapi_rel_to_altrep(SEXP rel, SEXP allow_materialization) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_to_altrep(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<bool>>(allow_materialization)));
  END_CPP11
}
// reltoaltrep.cpp
SEXP rapi_rel_from_altrep_df(SEXP df, bool strict, bool allow_materialized);
extern "C" SEXP _duckdb_rapi_rel_from_altrep_df(SEXP df, SEXP strict, SEXP allow_materialized) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_rel_from_altrep_df(cpp11::as_cpp<cpp11::decay_t<SEXP>>(df), cpp11::as_cpp<cpp11::decay_t<bool>>(strict), cpp11::as_cpp<cpp11::decay_t<bool>>(allow_materialized)));
  END_CPP11
}
// statement.cpp
void rapi_release(duckdb::stmt_eptr_t stmt);
extern "C" SEXP _duckdb_rapi_release(SEXP stmt) {
  BEGIN_CPP11
    rapi_release(cpp11::as_cpp<cpp11::decay_t<duckdb::stmt_eptr_t>>(stmt));
    return R_NilValue;
  END_CPP11
}
// statement.cpp
SEXP rapi_get_substrait(duckdb::conn_eptr_t conn, std::string query, bool enable_optimizer);
extern "C" SEXP _duckdb_rapi_get_substrait(SEXP conn, SEXP query, SEXP enable_optimizer) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_get_substrait(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(query), cpp11::as_cpp<cpp11::decay_t<bool>>(enable_optimizer)));
  END_CPP11
}
// statement.cpp
SEXP rapi_get_substrait_json(duckdb::conn_eptr_t conn, std::string query, bool enable_optimizer);
extern "C" SEXP _duckdb_rapi_get_substrait_json(SEXP conn, SEXP query, SEXP enable_optimizer) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_get_substrait_json(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(query), cpp11::as_cpp<cpp11::decay_t<bool>>(enable_optimizer)));
  END_CPP11
}
// statement.cpp
cpp11::list rapi_prepare_substrait(duckdb::conn_eptr_t conn, cpp11::sexp query);
extern "C" SEXP _duckdb_rapi_prepare_substrait(SEXP conn, SEXP query) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_prepare_substrait(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<cpp11::sexp>>(query)));
  END_CPP11
}
// statement.cpp
cpp11::list rapi_prepare_substrait_json(duckdb::conn_eptr_t conn, std::string json);
extern "C" SEXP _duckdb_rapi_prepare_substrait_json(SEXP conn, SEXP json) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_prepare_substrait_json(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(json)));
  END_CPP11
}
// statement.cpp
cpp11::list rapi_prepare(duckdb::conn_eptr_t conn, std::string query);
extern "C" SEXP _duckdb_rapi_prepare(SEXP conn, SEXP query) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_prepare(cpp11::as_cpp<cpp11::decay_t<duckdb::conn_eptr_t>>(conn), cpp11::as_cpp<cpp11::decay_t<std::string>>(query)));
  END_CPP11
}
// statement.cpp
cpp11::list rapi_bind(duckdb::stmt_eptr_t stmt, cpp11::list params, bool arrow, bool integer64);
extern "C" SEXP _duckdb_rapi_bind(SEXP stmt, SEXP params, SEXP arrow, SEXP integer64) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_bind(cpp11::as_cpp<cpp11::decay_t<duckdb::stmt_eptr_t>>(stmt), cpp11::as_cpp<cpp11::decay_t<cpp11::list>>(params), cpp11::as_cpp<cpp11::decay_t<bool>>(arrow), cpp11::as_cpp<cpp11::decay_t<bool>>(integer64)));
  END_CPP11
}
// statement.cpp
SEXP rapi_execute_arrow(duckdb::rqry_eptr_t qry_res, int chunk_size);
extern "C" SEXP _duckdb_rapi_execute_arrow(SEXP qry_res, SEXP chunk_size) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_execute_arrow(cpp11::as_cpp<cpp11::decay_t<duckdb::rqry_eptr_t>>(qry_res), cpp11::as_cpp<cpp11::decay_t<int>>(chunk_size)));
  END_CPP11
}
// statement.cpp
SEXP rapi_record_batch(duckdb::rqry_eptr_t qry_res, int chunk_size);
extern "C" SEXP _duckdb_rapi_record_batch(SEXP qry_res, SEXP chunk_size) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_record_batch(cpp11::as_cpp<cpp11::decay_t<duckdb::rqry_eptr_t>>(qry_res), cpp11::as_cpp<cpp11::decay_t<int>>(chunk_size)));
  END_CPP11
}
// statement.cpp
SEXP rapi_execute(duckdb::stmt_eptr_t stmt, bool arrow, bool integer64);
extern "C" SEXP _duckdb_rapi_execute(SEXP stmt, SEXP arrow, SEXP integer64) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_execute(cpp11::as_cpp<cpp11::decay_t<duckdb::stmt_eptr_t>>(stmt), cpp11::as_cpp<cpp11::decay_t<bool>>(arrow), cpp11::as_cpp<cpp11::decay_t<bool>>(integer64)));
  END_CPP11
}
// statement.cpp
void rapi_rel_to_parquet(duckdb::rel_extptr_t rel, std::string file_name);
extern "C" SEXP _duckdb_rapi_rel_to_parquet(SEXP rel, SEXP file_name) {
  BEGIN_CPP11
    rapi_rel_to_parquet(cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rel), cpp11::as_cpp<cpp11::decay_t<std::string>>(file_name));
    return R_NilValue;
  END_CPP11
}
// utils.cpp
SEXP rapi_adbc_init_func();
extern "C" SEXP _duckdb_rapi_adbc_init_func() {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_adbc_init_func());
  END_CPP11
}
// utils.cpp
cpp11::r_string rapi_ptr_to_str(SEXP extptr);
extern "C" SEXP _duckdb_rapi_ptr_to_str(SEXP extptr) {
  BEGIN_CPP11
    return cpp11::as_sexp(rapi_ptr_to_str(cpp11::as_cpp<cpp11::decay_t<SEXP>>(extptr)));
  END_CPP11
}
// utils.cpp
void rapi_load_rfuns(duckdb::db_eptr_t dual);
extern "C" SEXP _duckdb_rapi_load_rfuns(SEXP dual) {
  BEGIN_CPP11
    rapi_load_rfuns(cpp11::as_cpp<cpp11::decay_t<duckdb::db_eptr_t>>(dual));
    return R_NilValue;
  END_CPP11
}

extern "C" {
static const R_CallMethodDef CallEntries[] = {
    {"_duckdb_rapi_adbc_init_func",          (DL_FUNC) &_duckdb_rapi_adbc_init_func,          0},
    {"_duckdb_rapi_bind",                    (DL_FUNC) &_duckdb_rapi_bind,                    4},
    {"_duckdb_rapi_connect",                 (DL_FUNC) &_duckdb_rapi_connect,                 1},
    {"_duckdb_rapi_disconnect",              (DL_FUNC) &_duckdb_rapi_disconnect,              1},
    {"_duckdb_rapi_execute",                 (DL_FUNC) &_duckdb_rapi_execute,                 3},
    {"_duckdb_rapi_execute_arrow",           (DL_FUNC) &_duckdb_rapi_execute_arrow,           2},
    {"_duckdb_rapi_expr_comparison",         (DL_FUNC) &_duckdb_rapi_expr_comparison,         2},
    {"_duckdb_rapi_expr_constant",           (DL_FUNC) &_duckdb_rapi_expr_constant,           1},
    {"_duckdb_rapi_expr_function",           (DL_FUNC) &_duckdb_rapi_expr_function,           4},
    {"_duckdb_rapi_expr_reference",          (DL_FUNC) &_duckdb_rapi_expr_reference,          1},
    {"_duckdb_rapi_expr_set_alias",          (DL_FUNC) &_duckdb_rapi_expr_set_alias,          2},
    {"_duckdb_rapi_expr_tostring",           (DL_FUNC) &_duckdb_rapi_expr_tostring,           1},
    {"_duckdb_rapi_expr_window",             (DL_FUNC) &_duckdb_rapi_expr_window,             9},
    {"_duckdb_rapi_get_last_rel",            (DL_FUNC) &_duckdb_rapi_get_last_rel,            0},
    {"_duckdb_rapi_get_null_SEXP_ptr",       (DL_FUNC) &_duckdb_rapi_get_null_SEXP_ptr,       0},
    {"_duckdb_rapi_get_substrait",           (DL_FUNC) &_duckdb_rapi_get_substrait,           3},
    {"_duckdb_rapi_get_substrait_json",      (DL_FUNC) &_duckdb_rapi_get_substrait_json,      3},
    {"_duckdb_rapi_is_locked",               (DL_FUNC) &_duckdb_rapi_is_locked,               1},
    {"_duckdb_rapi_list_arrow",              (DL_FUNC) &_duckdb_rapi_list_arrow,              1},
    {"_duckdb_rapi_load_rfuns",              (DL_FUNC) &_duckdb_rapi_load_rfuns,              1},
    {"_duckdb_rapi_lock",                    (DL_FUNC) &_duckdb_rapi_lock,                    1},
    {"_duckdb_rapi_prepare",                 (DL_FUNC) &_duckdb_rapi_prepare,                 2},
    {"_duckdb_rapi_prepare_substrait",       (DL_FUNC) &_duckdb_rapi_prepare_substrait,       2},
    {"_duckdb_rapi_prepare_substrait_json",  (DL_FUNC) &_duckdb_rapi_prepare_substrait_json,  2},
    {"_duckdb_rapi_ptr_to_str",              (DL_FUNC) &_duckdb_rapi_ptr_to_str,              1},
    {"_duckdb_rapi_record_batch",            (DL_FUNC) &_duckdb_rapi_record_batch,            2},
    {"_duckdb_rapi_register_arrow",          (DL_FUNC) &_duckdb_rapi_register_arrow,          4},
    {"_duckdb_rapi_register_df",             (DL_FUNC) &_duckdb_rapi_register_df,             6},
    {"_duckdb_rapi_rel_aggregate",           (DL_FUNC) &_duckdb_rapi_rel_aggregate,           3},
    {"_duckdb_rapi_rel_alias",               (DL_FUNC) &_duckdb_rapi_rel_alias,               1},
    {"_duckdb_rapi_rel_distinct",            (DL_FUNC) &_duckdb_rapi_rel_distinct,            1},
    {"_duckdb_rapi_rel_explain",             (DL_FUNC) &_duckdb_rapi_rel_explain,             3},
    {"_duckdb_rapi_rel_filter",              (DL_FUNC) &_duckdb_rapi_rel_filter,              2},
    {"_duckdb_rapi_rel_from_altrep_df",      (DL_FUNC) &_duckdb_rapi_rel_from_altrep_df,      3},
    {"_duckdb_rapi_rel_from_df",             (DL_FUNC) &_duckdb_rapi_rel_from_df,             3},
    {"_duckdb_rapi_rel_from_sql",            (DL_FUNC) &_duckdb_rapi_rel_from_sql,            2},
    {"_duckdb_rapi_rel_from_table",          (DL_FUNC) &_duckdb_rapi_rel_from_table,          3},
    {"_duckdb_rapi_rel_from_table_function", (DL_FUNC) &_duckdb_rapi_rel_from_table_function, 4},
    {"_duckdb_rapi_rel_join",                (DL_FUNC) &_duckdb_rapi_rel_join,                5},
    {"_duckdb_rapi_rel_limit",               (DL_FUNC) &_duckdb_rapi_rel_limit,               2},
    {"_duckdb_rapi_rel_names",               (DL_FUNC) &_duckdb_rapi_rel_names,               1},
    {"_duckdb_rapi_rel_order",               (DL_FUNC) &_duckdb_rapi_rel_order,               3},
    {"_duckdb_rapi_rel_project",             (DL_FUNC) &_duckdb_rapi_rel_project,             2},
    {"_duckdb_rapi_rel_set_alias",           (DL_FUNC) &_duckdb_rapi_rel_set_alias,           2},
    {"_duckdb_rapi_rel_set_diff",            (DL_FUNC) &_duckdb_rapi_rel_set_diff,            2},
    {"_duckdb_rapi_rel_set_intersect",       (DL_FUNC) &_duckdb_rapi_rel_set_intersect,       2},
    {"_duckdb_rapi_rel_set_symdiff",         (DL_FUNC) &_duckdb_rapi_rel_set_symdiff,         2},
    {"_duckdb_rapi_rel_sql",                 (DL_FUNC) &_duckdb_rapi_rel_sql,                 2},
    {"_duckdb_rapi_rel_to_altrep",           (DL_FUNC) &_duckdb_rapi_rel_to_altrep,           2},
    {"_duckdb_rapi_rel_to_df",               (DL_FUNC) &_duckdb_rapi_rel_to_df,               1},
    {"_duckdb_rapi_rel_to_parquet",          (DL_FUNC) &_duckdb_rapi_rel_to_parquet,          2},
    {"_duckdb_rapi_rel_to_sql",              (DL_FUNC) &_duckdb_rapi_rel_to_sql,              1},
    {"_duckdb_rapi_rel_tostring",            (DL_FUNC) &_duckdb_rapi_rel_tostring,            2},
    {"_duckdb_rapi_rel_union_all",           (DL_FUNC) &_duckdb_rapi_rel_union_all,           2},
    {"_duckdb_rapi_release",                 (DL_FUNC) &_duckdb_rapi_release,                 1},
    {"_duckdb_rapi_shutdown",                (DL_FUNC) &_duckdb_rapi_shutdown,                1},
    {"_duckdb_rapi_startup",                 (DL_FUNC) &_duckdb_rapi_startup,                 3},
    {"_duckdb_rapi_unlock",                  (DL_FUNC) &_duckdb_rapi_unlock,                  1},
    {"_duckdb_rapi_unregister_arrow",        (DL_FUNC) &_duckdb_rapi_unregister_arrow,        2},
    {"_duckdb_rapi_unregister_df",           (DL_FUNC) &_duckdb_rapi_unregister_df,           2},
    {NULL, NULL, 0}
};
}

void RelToAltrep_Initialize(DllInfo* dll);

extern "C" attribute_visible void R_init_duckdb(DllInfo* dll){
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  RelToAltrep_Initialize(dll);
  R_forceSymbols(dll, TRUE);
}
