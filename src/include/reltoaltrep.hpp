#pragma once

#include "rapi.hpp"

#include "duckdb/main/query_result.hpp"

namespace duckdb {

struct AltrepRelationWrapper {
	static AltrepRelationWrapper *Get(SEXP x);

	AltrepRelationWrapper(rel_extptr_t rel_, size_t n_rows_, size_t n_cells_);

	bool Materialized() const;

	MaterializedQueryResult *GetQueryResult();

	void Materialize();

	idx_t RowCount();

	void RegisterAltrepColumn();
	void MarkColumnAsTransformed();

	const size_t n_rows;
	const size_t n_cells;

	rel_extptr_t rel_eptr;
	duckdb::shared_ptr<Relation> rel;
	duckdb::unique_ptr<QueryResult> mat_result;
	std::string mat_error;

	// True once the relation has been materialized,
	// remains true after the materialized result has been released
	bool materialized = false;
	// Row count of the materialized result, valid once materialized is true
	idx_t row_count = 0;
	// Number of ALTREP vectors backed by this relation
	idx_t altrep_columns = 0;
	// Number of ALTREP vectors already transformed to their R representation
	idx_t transformed_columns = 0;
};

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
	static Rboolean RelInspect(SEXP x, int pre, int deep, int pvec, void (*inspect_subtree)(SEXP, int, int, int));

	static SEXP VectorStringElt(SEXP x, R_xlen_t i);

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
