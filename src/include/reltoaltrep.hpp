#pragma once

#include "rapi.hpp"

#include "duckdb/main/query_result.hpp"

namespace duckdb {

struct AltrepRelationWrapper {
	static AltrepRelationWrapper *Get(SEXP x);

	AltrepRelationWrapper(rel_extptr_t rel_, bool allow_materialization_, size_t n_rows_, size_t n_cells_);

	bool HasQueryResult() const;

	MaterializedQueryResult *GetQueryResult();

	duckdb::unique_ptr<QueryResult> Materialize();

	const bool allow_materialization;
	const size_t n_rows;
	const size_t n_cells;

	rel_extptr_t rel_eptr;
	duckdb::shared_ptr<Relation> rel;
	duckdb::unique_ptr<QueryResult> res;
};

}

struct RelToAltrep {
	static void Initialize(DllInfo *dll);
	static R_xlen_t RownamesLength(SEXP x);
	static void *RownamesDataptr(SEXP x, Rboolean writeable);
	static const void *RownamesDataptrOrNull(SEXP x);
	static void *DoRownamesDataptrGet(SEXP x);
	static Rboolean RownamesInspect(SEXP x, int pre, int deep, int pvec, void (*inspect_subtree)(SEXP, int, int, int));

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
	static SEXP VectorListElt(SEXP x, R_xlen_t i);
	static R_altrep_class_t list_class;
#endif
};
