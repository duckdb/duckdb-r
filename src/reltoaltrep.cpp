#define __STDC_FORMAT_MACROS

#include "rapi.hpp"
#include "typesr.hpp"
#include "reltoaltrep.hpp"
#include "signal.hpp"
#include "cpp11/declarations.hpp"
#include "altrepdataframe_relation.hpp"

#include "httplib.hpp"
#include <cinttypes>
#include <cmath>
#include <cstddef>

#include "duckdb/common/unique_ptr.hpp"
#include "duckdb/main/materialized_query_result.hpp"
#include "duckdb/main/query_result.hpp"
#include "duckdb/main/relation/limit_relation.hpp"

#include "fmt/format.h"

#ifdef TRUE
#undef TRUE
#endif

#ifdef FALSE
#undef FALSE
#endif

using namespace duckdb;

R_altrep_class_t RelToAltrep::rownames_class;
R_altrep_class_t RelToAltrep::logical_class;
R_altrep_class_t RelToAltrep::int_class;
R_altrep_class_t RelToAltrep::real_class;
R_altrep_class_t RelToAltrep::string_class;

#if defined(R_HAS_ALTLIST)
R_altrep_class_t RelToAltrep::list_class;
R_altrep_class_t RelToAltrep::struct_class;
#endif

const size_t MAX_SIZE_T = std::numeric_limits<size_t>::max();

void RelToAltrep::Initialize(DllInfo *dll) {
	// this is a string so setting row names will not lead to materialization
	rownames_class = R_make_altinteger_class("reltoaltrep_rownames_class", "duckdb", dll);
	logical_class = R_make_altlogical_class("reltoaltrep_logical_class", "duckdb", dll);
	int_class = R_make_altinteger_class("reltoaltrep_int_class", "duckdb", dll);
	real_class = R_make_altreal_class("reltoaltrep_real_class", "duckdb", dll);
	string_class = R_make_altstring_class("reltoaltrep_string_class", "duckdb", dll);

	R_set_altrep_Inspect_method(rownames_class, RownamesInspect);
	R_set_altrep_Inspect_method(logical_class, RelInspect);
	R_set_altrep_Inspect_method(int_class, RelInspect);
	R_set_altrep_Inspect_method(real_class, RelInspect);
	R_set_altrep_Inspect_method(string_class, RelInspect);

	R_set_altrep_Length_method(rownames_class, RownamesLength);
	R_set_altrep_Length_method(logical_class, VectorLength);
	R_set_altrep_Length_method(int_class, VectorLength);
	R_set_altrep_Length_method(real_class, VectorLength);
	R_set_altrep_Length_method(string_class, VectorLength);

	R_set_altvec_Dataptr_method(rownames_class, RownamesDataptr);
	R_set_altvec_Dataptr_method(logical_class, VectorDataptr);
	R_set_altvec_Dataptr_method(int_class, VectorDataptr);
	R_set_altvec_Dataptr_method(real_class, VectorDataptr);
	R_set_altvec_Dataptr_method(string_class, VectorDataptr);

	R_set_altvec_Dataptr_or_null_method(rownames_class, RownamesDataptrOrNull);

	R_set_altstring_Elt_method(string_class, VectorStringElt);

#if defined(R_HAS_ALTLIST)
	list_class = R_make_altlist_class("reltoaltrep_list_class", "duckdb", dll);
	R_set_altrep_Inspect_method(list_class, RelInspect);
	R_set_altrep_Length_method(list_class, VectorLength);
	R_set_altvec_Dataptr_method(list_class, VectorDataptr);
	R_set_altlist_Elt_method(list_class, VectorListElt);

	struct_class = R_make_altlist_class("reltoaltrep_struct_class", "duckdb", dll);
	R_set_altrep_Inspect_method(struct_class, RelInspect);
	R_set_altrep_Length_method(struct_class, StructLength);
	R_set_altvec_Dataptr_method(struct_class, VectorDataptr);
	R_set_altlist_Elt_method(struct_class, VectorListElt);
#endif
}

template <class T>
static T *GetFromExternalPtr(SEXP x) {
	if (!x) {
		cpp11::stop("GetFromExternalPtr: need a SEXP pointer");
	}
	if (!ALTREP(x)) {
		cpp11::stop("GetFromExternalPtr: not an ALTREP");
	}
	auto ptr = R_altrep_data1(x);
	if (TYPEOF(ptr) != EXTPTRSXP) {
		cpp11::stop("GetFromExternalPtr: data1 is not an external pointer");
	}
	auto wrapper = (T *)R_ExternalPtrAddr(ptr);
	if (!wrapper) {
		cpp11::stop("GetFromExternalPtr: This looks like it has been freed");
	}
	return wrapper;
}

AltrepRelationWrapper *AltrepRelationWrapper::Get(SEXP x) {
	return GetFromExternalPtr<AltrepRelationWrapper>(x);
}

AltrepRelationWrapper::AltrepRelationWrapper(rel_extptr_t rel_, size_t n_rows_, size_t n_cells_)
    : n_rows(n_rows_), n_cells(n_cells_), rel_eptr(rel_), rel(rel_->rel) {
}

bool AltrepRelationWrapper::HasQueryResult() const {
	return (bool)mat_result;
}

MaterializedQueryResult *AltrepRelationWrapper::GetQueryResult() {
	if (!mat_error.empty()) {
		cpp11::stop(mat_error);
	}

	if (!mat_result) {
		if (n_cells == 0) {
			cpp11::stop("Materialization is disabled, use collect() or as_tibble() to materialize.");
		}

		auto materialize_callback = Rf_GetOption1(RStrings::get().materialize_callback_sym);
		if (Rf_isFunction(materialize_callback)) {
			sexp call = Rf_lang2(materialize_callback, rel_eptr);
			Rf_eval(call, R_BaseEnv);
		}

		auto materialize_message = Rf_GetOption1(RStrings::get().materialize_message_sym);
		if (Rf_isLogical(materialize_message) && Rf_length(materialize_message) == 1 &&
		    LOGICAL_ELT(materialize_message, 0) == true) {
			// Legacy
			Rprintf("duckplyr: materializing\n");
		}

		ScopedInterruptHandler signal_handler(rel->context->GetContext());

		// We need to temporarily allow a deeper execution stack
		// https://github.com/duckdb/duckdb-r/issues/101
		auto old_depth = rel->context->GetContext()->config.max_expression_depth;
		rel->context->GetContext()->config.max_expression_depth = old_depth * 2;
		duckdb_httplib::detail::scope_exit reset_max_expression_depth(
		    [&]() { rel->context->GetContext()->config.max_expression_depth = old_depth; });

		Materialize();

		if (!mat_error.empty()) {
			cpp11::stop(mat_error);
		}

		// FIXME: Use std::experimental::scope_exit
		if (rel->context->GetContext()->config.max_expression_depth != old_depth * 2) {
			Rprintf("Internal error: max_expression_depth was changed from %" PRIu64 " to %" PRIu64 "\n", old_depth * 2,
			        rel->context->GetContext()->config.max_expression_depth);
		}
		rel->context->GetContext()->config.max_expression_depth = old_depth;
		reset_max_expression_depth.release();

		if (signal_handler.HandleInterrupt()) {
			cpp11::stop("Query execution was interrupted");
		}

		signal_handler.Disable();
	}
	D_ASSERT(mat_result);
	return (MaterializedQueryResult *)mat_result.get();
}

void AltrepRelationWrapper::Materialize() {
	// Init with max value
	size_t max_rows = MAX_SIZE_T;

	// Number of cells limited?
	if (n_cells < MAX_SIZE_T) {
		max_rows = n_cells / rel->Columns().size();
	}

	// Number of rows limited?
	if (n_rows < max_rows) {
		max_rows = n_rows;
	}

	// For tethered, we push a limit relation and check the number of output rows
	auto local_rel = rel;
	if (max_rows < MAX_SIZE_T) {
		local_rel = make_shared_ptr<LimitRelation>(rel, max_rows + 1, 0);
	}

	auto local_res = local_rel->Execute();

	if (local_res->HasError()) {
		mat_error = duckdb_fmt::format("Error evaluating duckdb query: {}", local_res->GetError().c_str());
		return;
	}
	D_ASSERT(local_res->type == QueryResultType::MATERIALIZED_RESULT);

	if (max_rows < MAX_SIZE_T) {
		auto local_mat_res = (MaterializedQueryResult *)local_res.get();
		if (local_mat_res->RowCount() > max_rows) {
			mat_error = duckdb_fmt::format(
			    "Materialization would result in more than {} rows. Use collect() or as_tibble() to materialize.",
			    max_rows);
			return;
		}
	}

	mat_result = std::move(local_res);
}

struct AltrepRownamesWrapper {

	AltrepRownamesWrapper(duckdb::shared_ptr<AltrepRelationWrapper> rel_p) : rel(rel_p) {
		rowlen_data[0] = NA_INTEGER;
	}

	static AltrepRownamesWrapper *Get(SEXP x) {
		return GetFromExternalPtr<AltrepRownamesWrapper>(x);
	}

	int32_t rowlen_data[2];
	duckdb::shared_ptr<AltrepRelationWrapper> rel;
};

struct AltrepVectorWrapper {
	AltrepVectorWrapper(duckdb::shared_ptr<AltrepRelationWrapper> rel_p, idx_t column_index_p)
	    : rel(rel_p), column_index(column_index_p) {
	}

	static AltrepVectorWrapper *Get(SEXP x) {
		return GetFromExternalPtr<AltrepVectorWrapper>(x);
	}

	void *Dataptr() {
		if (transformed_vector.data() == R_NilValue) {
			auto res = rel->GetQueryResult();
			const auto &name = res->names[column_index];

			transformed_vector = duckdb_r_allocate(res->types[column_index], res->RowCount(), name, duckdb::ConvertOpts(),"Dataptr");
			idx_t dest_offset = 0;
			for (auto &chunk : res->Collection().Chunks()) {
				SEXP dest = transformed_vector.data();
				duckdb_r_transform(chunk.data[column_index], dest, dest_offset, chunk.size(), duckdb::ConvertOpts(), name);
				dest_offset += chunk.size();
			}
		}
		return const_cast<void *>(DATAPTR_RO(transformed_vector));
	}

	SEXP Vector() {
		Dataptr();
		return transformed_vector;
	}

	duckdb::shared_ptr<AltrepRelationWrapper> rel;
	idx_t column_index;
	cpp11::sexp transformed_vector;
};

Rboolean RelToAltrep::RownamesInspect(SEXP x, int pre, int deep, int pvec,
                                      void (*inspect_subtree)(SEXP, int, int, int)) {
	BEGIN_CPP11
	AltrepRownamesWrapper::Get(x); // make sure this is alive
	Rprintf("DUCKDB_ALTREP_REL_ROWNAMES\n");
	return TRUE;
	END_CPP11_EX(Rboolean::FALSE)
}

Rboolean RelToAltrep::RelInspect(SEXP x, int pre, int deep, int pvec, void (*inspect_subtree)(SEXP, int, int, int)) {
	BEGIN_CPP11
	auto wrapper = AltrepVectorWrapper::Get(x); // make sure this is alive
	auto &col = wrapper->rel->rel->Columns()[wrapper->column_index];
	Rprintf("DUCKDB_ALTREP_REL_VECTOR %s (%s)\n", col.Name().c_str(), col.Type().ToString().c_str());
	return TRUE;
	END_CPP11_EX(Rboolean::FALSE)
}

SEXP get_attrib(SEXP vec, SEXP name) {
	for (SEXP attrib = ATTRIB(vec); attrib != R_NilValue; attrib = CDR(attrib)) {
		if (TAG(attrib) == name) {
			return CAR(attrib);
		}
	}

	return R_NilValue;
}

R_xlen_t RelToAltrep::RownamesLength(SEXP x) {
	// The BEGIN_CPP11 isn't strictly necessary here, but should be optimized away.
	// It will become important if we ever support row names.
	BEGIN_CPP11
	// row.names vector has length 2 in the "compact" case which we're using
	// see https://stat.ethz.ch/R-manual/R-devel/library/base/html/row.names.html
	return 2;
	END_CPP11_EX(0)
}

void *RelToAltrep::RownamesDataptr(SEXP x, Rboolean writeable) {
	BEGIN_CPP11
	return DoRownamesDataptrGet(x);
	END_CPP11
}

const void *RelToAltrep::RownamesDataptrOrNull(SEXP x) {
	BEGIN_CPP11
	auto rownames_wrapper = AltrepRownamesWrapper::Get(x);
	if (!rownames_wrapper->rel->HasQueryResult()) {
		return nullptr;
	}
	return DoRownamesDataptrGet(x);
	END_CPP11
}

void *RelToAltrep::DoRownamesDataptrGet(SEXP x) {
	auto rownames_wrapper = AltrepRownamesWrapper::Get(x);
	auto row_count = rownames_wrapper->rel->GetQueryResult()->RowCount();
	if (row_count > (idx_t)NumericLimits<int32_t>::Maximum()) {
		cpp11::stop("Integer overflow for row.names attribute");
	}
	rownames_wrapper->rowlen_data[1] = -row_count;
	return rownames_wrapper->rowlen_data;
}

R_xlen_t RelToAltrep::VectorLength(SEXP x) {
	BEGIN_CPP11
	return AltrepVectorWrapper::Get(x)->rel->GetQueryResult()->RowCount();
	END_CPP11_EX(0)
}

void *RelToAltrep::VectorDataptr(SEXP x, Rboolean writeable) {
	BEGIN_CPP11
	return AltrepVectorWrapper::Get(x)->Dataptr();
	END_CPP11
}

SEXP RelToAltrep::VectorStringElt(SEXP x, R_xlen_t i) {
	BEGIN_CPP11
	return STRING_ELT(AltrepVectorWrapper::Get(x)->Vector(), i);
	END_CPP11
}

#if defined(R_HAS_ALTLIST)
R_xlen_t RelToAltrep::StructLength(SEXP x) {
	BEGIN_CPP11
	auto const *wrapper = AltrepVectorWrapper::Get(x);
	auto const column_index = wrapper->column_index;
	auto const &res = wrapper->rel->GetQueryResult();
	auto const &type = res->types[column_index];

	return static_cast<R_xlen_t>(StructType::GetChildTypes(type).size());
	END_CPP11_EX(0)
}

SEXP RelToAltrep::VectorListElt(SEXP x, R_xlen_t i) {
	BEGIN_CPP11
	return VECTOR_ELT(AltrepVectorWrapper::Get(x)->Vector(), i);
	END_CPP11
}
#endif

static R_altrep_class_t LogicalTypeToAltrepType(const LogicalType &type, const duckdb::string &name) {
	auto rtype = duckdb_r_typeof(type, name, "LogicalTypeToAltrepType");
	switch (rtype) {
	case LGLSXP:
		return RelToAltrep::logical_class;
	case INTSXP:
		return RelToAltrep::int_class;
	case REALSXP:
		return RelToAltrep::real_class;
	case STRSXP:
		return RelToAltrep::string_class;
#if defined(R_HAS_ALTLIST)
	case VECSXP:
		if (type.id() == LogicalTypeId::STRUCT) {
			return RelToAltrep::struct_class;
		} else {
			return RelToAltrep::list_class;
		}
#endif

	default:
		cpp11::stop("LogicalTypeToAltrepType: Column `%s` has no type for altrep: %s", name.c_str(), type.ToString().c_str());
	}
}

size_t DoubleToSize(double d) {
	if (d < 0) {
		cpp11::stop("rel_to_altrep: Negative size");
	}
	if (!std::isfinite(d)) {
		// Return maximum size_t for Inf
		return MAX_SIZE_T;
	}
	if (d >= (double)MAX_SIZE_T) {
		cpp11::stop("rel_to_altrep: Size overflow");
	}
	return (size_t)d;
}

[[cpp11::register]] SEXP rapi_rel_to_altrep(duckdb::rel_extptr_t rel, double n_rows, double n_cells, duckdb::ConvertOpts convert_opts) {
	D_ASSERT(rel && rel->rel);
	auto drel = rel->rel;
	auto ncols = drel->Columns().size();

	auto relation_wrapper = make_shared_ptr<AltrepRelationWrapper>(rel, DoubleToSize(n_rows), DoubleToSize(n_cells));

	// Row names
	cpp11::external_pointer<AltrepRownamesWrapper> ptr(new AltrepRownamesWrapper(relation_wrapper));
	R_SetExternalPtrTag(ptr, RStrings::get().duckdb_row_names_sym);
	cpp11::sexp row_names_sexp = R_new_altrep(RelToAltrep::rownames_class, ptr, R_NilValue);

	// Data
	cpp11::writable::list data_frame;
	data_frame.reserve(ncols);

	for (size_t col_idx = 0; col_idx < ncols; col_idx++) {
		auto &col = drel->Columns()[col_idx];
		auto &col_name = col.Name();
		auto &col_type = col.Type();
		cpp11::external_pointer<AltrepVectorWrapper> ptr(new AltrepVectorWrapper(relation_wrapper, col_idx));
		R_SetExternalPtrTag(ptr, RStrings::get().duckdb_vector_sym);

		cpp11::sexp vector_sexp = R_new_altrep(LogicalTypeToAltrepType(col_type, col_name), ptr, R_NilValue);
		duckdb_r_decorate(col_type, vector_sexp, convert_opts);

		// Special case: Only STRUCTs have a redundant row names attribute
		// Moving this logic into duckdb_r_decorate() would add too much noise elsewhere
		if (col_type.id() == LogicalTypeId::STRUCT) {
			// FIXME: The exact class of nested columns can be a property
			// of the relation object, determined by the data on input
			duckdb_r_df_decorate_impl(vector_sexp, row_names_sexp, RStrings::get().dataframe_str);
		}

		data_frame.push_back(vector_sexp);
	}

	// convert to SEXP, with potential side effect of truncation and removal of attributes
	(void)(SEXP)data_frame;

	// Names
	vector<string> names;
	for (auto &col : drel->Columns()) {
		names.push_back(col.Name());
	}
	SET_NAMES(data_frame, StringsToSexp(names));

	// Class and row names
	duckdb_r_df_decorate_impl(data_frame, row_names_sexp, RStrings::get().dataframe_str);

	return data_frame;
}

shared_ptr<AltrepRelationWrapper> rapi_rel_wrapper_from_altrep_df(SEXP df, bool strict, bool allow_materialized) {
	if (!Rf_inherits(df, "data.frame")) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not a data.frame");
		} else {
			return nullptr;
		}
	}

	auto row_names = get_attrib(df, R_RowNamesSymbol);
	if (row_names == R_NilValue || !ALTREP(row_names)) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not a 'special' data.frame, row names are not ALTREP");
		} else {
			return nullptr;
		}
	}

	auto altrep_data = R_altrep_data1(row_names);
	if (TYPEOF(altrep_data) != EXTPTRSXP) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not our 'special' data.frame, data1 is not external pointer");
		} else {
			return nullptr;
		}
	}

	auto tag = R_ExternalPtrTag(altrep_data);
	if (tag != RStrings::get().duckdb_row_names_sym) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not our 'special' data.frame, tag missing");
		} else {
			return nullptr;
		}
	}

	auto wrapper = GetFromExternalPtr<AltrepRownamesWrapper>(row_names);
	if (!allow_materialized) {
		if (wrapper->rel->mat_result.get()) {
			// We return NULL here even for strict = true
			// because this is expected from df_is_materialized()
			return nullptr;
		}
	}

	return wrapper->rel;
}

[[cpp11::register]] SEXP rapi_rel_from_altrep_df(SEXP df, bool strict, bool allow_materialized, bool wrap) {
	auto wrapper = rapi_rel_wrapper_from_altrep_df(df, strict, allow_materialized);
	if (!wrapper) {
		return R_NilValue;
	}
	if (!wrap) {
		return wrapper->rel_eptr;
	}

	return make_external<RelationWrapper>("duckdb_relation", make_shared_ptr<duckdb::AltrepDataFrameRelation>(wrapper->rel, df, wrapper));
}

// exception required as long as r-lib/decor#6 remains
// clang-format off
[[cpp11::init]] void RelToAltrep_Initialize(DllInfo* dll) {
	// clang-format on
	RelToAltrep::Initialize(dll);
}
