#pragma once

#include "rapi.hpp"

#include "duckdb/main/query_result.hpp"

#include <functional>
#include <unordered_map>

namespace duckdb {

struct AltrepRelationWrapper {
	static AltrepRelationWrapper *Get(SEXP x);

	AltrepRelationWrapper(rel_extptr_t rel_, size_t n_rows_, size_t n_cells_);

	bool Materialized() const;

	QueryResult *GetQueryResult();

	void Materialize();

	idx_t RowCount();

	// Column-wise mode (#2891): the relation reads a stored table,
	// so every execution returns the same rows in the same order,
	// and a column is fetched by a query of its own when it is first read.
	bool ColumnWise() const;
	// The engine result that holds top-level column `column_index`, and the position of the column in it
	QueryResult *GetColumnResult(idx_t column_index, idx_t &result_index);
	// Whether reading top-level column `column_index` would execute a query now
	bool ColumnQueryPending(idx_t column_index) const;

	void RegisterAltrepColumn(idx_t column_index);
	void MarkColumnAsTransformed(idx_t column_index);

	const size_t n_rows;
	const size_t n_cells;

	rel_extptr_t rel_eptr;
	duckdb::shared_ptr<Relation> rel;
	// Released once every ALTREP column has been converted,
	// see MarkColumnAsTransformed(): handbook/usage/memory/reading/README.md.
	duckdb::unique_ptr<QueryResult> mat_result;
	std::string mat_error;

	// True once the relation has been materialized,
	// remains true after the materialized result has been released
	bool materialized = false;
	// Row count of the materialized result, valid once materialized is true,
	// or in column-wise mode once row_count_known is true
	idx_t row_count = 0;
	// Number of ALTREP vectors backed by this relation
	idx_t altrep_columns = 0;
	// Number of ALTREP vectors already transformed to their R representation
	idx_t transformed_columns = 0;

	// Column-wise mode only, see ColumnWise()
	bool column_wise = false;
	// Set once the materialize callback and message have announced the first execution
	bool announced = false;
	// Set once row_count holds the result of count(*) over the relation
	bool row_count_known = false;
	// Cells fetched so far, counted against n_cells
	idx_t fetched_cells = 0;
	// The result of each top-level column fetched and not yet converted by every ALTREP vector it backs
	std::unordered_map<idx_t, duckdb::unique_ptr<QueryResult>> column_results;
	// Per top-level column, the number of ALTREP vectors it backs that are not yet converted
	std::unordered_map<idx_t, idx_t> pending_vectors;

private:
	// Every execution goes through here: the checks, the options and the engine state it needs
	void Execute(const std::function<void()> &run);
	// Runs `run`, storing an exception it throws in mat_error
	void StoreErrors(const std::function<void()> &run);
	void CountRows();
	void FetchColumn(idx_t column_index);
};

// Whether `rel` is a plain scan of a table stored by DuckDB,
// possibly under projections of bare column references
bool IsStoredTableScan(Relation &rel);

} // namespace duckdb

struct RelToAltrep {
	static void Initialize(DllInfo *dll);
	static R_xlen_t RownamesLength(SEXP x);
	static void *RownamesDataptr(SEXP x, Rboolean writeable);
	static const void *RownamesDataptrOrNull(SEXP x);
	static void *DoRownamesDataptrGet(SEXP x);
	static Rboolean RownamesInspect(SEXP x, int pre, int deep, int pvec, void (*inspect_subtree)(SEXP, int, int, int));
	static int RownamesElt(SEXP x, R_xlen_t i);
	static R_xlen_t RownamesGetRegion(SEXP x, R_xlen_t start, R_xlen_t size, int *buf);
	static int RownamesIsSorted(SEXP x);
	static int RownamesNoNA(SEXP x);
	static SEXP RownamesSum(SEXP x, Rboolean na_rm);
	static SEXP RownamesMin(SEXP x, Rboolean na_rm);
	static SEXP RownamesMax(SEXP x, Rboolean na_rm);
	static SEXP RownamesDuplicate(SEXP x, Rboolean deep);
	static SEXP MakeRowNamesSexp(duckdb::shared_ptr<duckdb::AltrepRelationWrapper> rel);

	static R_xlen_t VectorLength(SEXP x);
	static void *VectorDataptr(SEXP x, Rboolean writeable);
	static const void *VectorDataptrOrNull(SEXP x);
	static Rboolean RelInspect(SEXP x, int pre, int deep, int pvec, void (*inspect_subtree)(SEXP, int, int, int));

	static SEXP VectorStringElt(SEXP x, R_xlen_t i);
	static R_xlen_t VectorAtomicLength(SEXP x);
	static void *VectorAtomicDataptr(SEXP x, Rboolean writeable);
	static int VectorLogicalElt(SEXP x, R_xlen_t i);
	static int VectorIntegerElt(SEXP x, R_xlen_t i);
	static double VectorRealElt(SEXP x, R_xlen_t i);
	static R_xlen_t VectorLogicalGetRegion(SEXP x, R_xlen_t start, R_xlen_t size, int *out);
	static R_xlen_t VectorIntegerGetRegion(SEXP x, R_xlen_t start, R_xlen_t size, int *out);
	static R_xlen_t VectorRealGetRegion(SEXP x, R_xlen_t start, R_xlen_t size, double *out);

	static R_altrep_class_t rownames_class;
	static R_altrep_class_t logical_class;
	static R_altrep_class_t int_class;
	static R_altrep_class_t real_class;
	static R_altrep_class_t string_class;

#if defined(R_HAS_ALTLIST)
	static R_xlen_t StructLength(SEXP x);
	static SEXP VectorListElt(SEXP x, R_xlen_t i);
	static R_altrep_class_t list_class;
	static R_altrep_class_t struct_class;
#endif
};
