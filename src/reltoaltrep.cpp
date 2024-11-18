#define __STDC_FORMAT_MACROS

#include "rapi.hpp"
#include "typesr.hpp"
#include "reltoaltrep.hpp"
#include "signal.hpp"
#include "cpp11/declarations.hpp"

#include "httplib.hpp"
#include <cinttypes>

using namespace duckdb;

R_altrep_class_t RelToAltrep::rownames_class;
R_altrep_class_t RelToAltrep::logical_class;
R_altrep_class_t RelToAltrep::int_class;
R_altrep_class_t RelToAltrep::real_class;
R_altrep_class_t RelToAltrep::string_class;

#if defined(R_HAS_ALTLIST)
R_altrep_class_t RelToAltrep::list_class;
#endif

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

struct AltrepRelationWrapper {

	static AltrepRelationWrapper *Get(SEXP x) {
		return GetFromExternalPtr<AltrepRelationWrapper>(x);
	}

	AltrepRelationWrapper(rel_extptr_t rel_, bool allow_materialization_)
	    : allow_materialization(allow_materialization_), rel_eptr(rel_), rel(rel_->rel) {
	}

	bool HasQueryResult() const {
		return (bool)res;
	}

	MaterializedQueryResult *GetQueryResult() {
		if (!res) {
			if (!allow_materialization) {
				cpp11::stop("Materialization is disabled, use collect() or as_tibble() to materialize");
			}

			auto materialize_callback = Rf_GetOption(RStrings::get().materialize_callback_sym, R_BaseEnv);
			if (Rf_isFunction(materialize_callback)) {
				sexp call = Rf_lang2(materialize_callback, rel_eptr);
				Rf_eval(call, R_BaseEnv);
			}
			else if (Rf_isLogical(materialize_callback) && Rf_length(materialize_callback) == 1 && LOGICAL_ELT(materialize_callback, 0) == true) {
				// Legacy
				Rprintf("duckplyr: materializing\n");
			}

			ScopedInterruptHandler signal_handler(rel->context.GetContext());

			// We need to temporarily allow a deeper execution stack
			// https://github.com/duckdb/duckdb-r/issues/101
			auto old_depth = rel->context.GetContext()->config.max_expression_depth;
			rel->context.GetContext()->config.max_expression_depth = old_depth * 2;
			duckdb_httplib::detail::scope_exit reset_max_expression_depth(
			    [&]() { rel->context.GetContext()->config.max_expression_depth = old_depth; });

			res = rel->Execute();

			// FIXME: Use std::experimental::scope_exit
			if (rel->context.GetContext()->config.max_expression_depth != old_depth * 2) {
				Rprintf("Internal error: max_expression_depth was changed from %" PRIu64 " to %" PRIu64 "\n",
				        old_depth * 2, rel->context.GetContext()->config.max_expression_depth);
			}
			rel->context.GetContext()->config.max_expression_depth = old_depth;
			reset_max_expression_depth.release();

			if (signal_handler.HandleInterrupt()) {
				cpp11::stop("Query execution was interrupted");
			}

			signal_handler.Disable();

			if (res->HasError()) {
				cpp11::stop("Error evaluating duckdb query: %s", res->GetError().c_str());
			}
			D_ASSERT(res->type == QueryResultType::MATERIALIZED_RESULT);
		}
		D_ASSERT(res);
		return (MaterializedQueryResult *)res.get();
	}

	bool allow_materialization;

	rel_extptr_t rel_eptr;
	duckdb::shared_ptr<Relation> rel;
	duckdb::unique_ptr<QueryResult> res;
};

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

			transformed_vector = duckdb_r_allocate(res->types[column_index], res->RowCount());
			idx_t dest_offset = 0;
			for (auto &chunk : res->Collection().Chunks()) {
				SEXP dest = transformed_vector.data();
				duckdb_r_transform(chunk.data[column_index], dest, dest_offset, chunk.size(), false);
				dest_offset += chunk.size();
			}
		}
		return DATAPTR(transformed_vector);
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
	END_CPP11_EX(FALSE)
}

Rboolean RelToAltrep::RelInspect(SEXP x, int pre, int deep, int pvec, void (*inspect_subtree)(SEXP, int, int, int)) {
	BEGIN_CPP11
	auto wrapper = AltrepVectorWrapper::Get(x); // make sure this is alive
	auto &col = wrapper->rel->rel->Columns()[wrapper->column_index];
	Rprintf("DUCKDB_ALTREP_REL_VECTOR %s (%s)\n", col.Name().c_str(), col.Type().ToString().c_str());
	return TRUE;
	END_CPP11_EX(FALSE)
}

// this allows us to set row names on a data frame with an int argument without calling INTPTR on it
static void install_new_attrib(SEXP vec, SEXP name, SEXP val) {
	SEXP attrib_vec = ATTRIB(vec);
	SEXP attrib_cell = Rf_cons(val, R_NilValue);
	SET_TAG(attrib_cell, name);
	SETCDR(attrib_vec, attrib_cell);
}

static SEXP get_attrib(SEXP vec, SEXP name) {
	for (SEXP attrib = ATTRIB(vec); attrib != R_NilValue; attrib = CDR(attrib)) {
		if (TAG(attrib) == R_RowNamesSymbol) {
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
SEXP RelToAltrep::VectorListElt(SEXP x, R_xlen_t i) {
	BEGIN_CPP11
	return VECTOR_ELT(AltrepVectorWrapper::Get(x)->Vector(), i);
	END_CPP11
}
#endif

static R_altrep_class_t LogicalTypeToAltrepType(const LogicalType &type) {
	switch (type.id()) {
	case LogicalTypeId::BOOLEAN:
		return RelToAltrep::logical_class;
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::INTEGER:
	case LogicalTypeId::ENUM:
		return RelToAltrep::int_class;
	case LogicalTypeId::UINTEGER:
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UBIGINT:
	case LogicalTypeId::HUGEINT:
	case LogicalTypeId::UHUGEINT:
	case LogicalTypeId::FLOAT:
	case LogicalTypeId::DOUBLE:
	case LogicalTypeId::DECIMAL:
	case LogicalTypeId::TIMESTAMP_SEC:
	case LogicalTypeId::TIMESTAMP_MS:
	case LogicalTypeId::TIMESTAMP:
	case LogicalTypeId::TIMESTAMP_TZ:
	case LogicalTypeId::TIMESTAMP_NS:
	case LogicalTypeId::DATE:
	case LogicalTypeId::TIME:
	case LogicalTypeId::INTERVAL:
		return RelToAltrep::real_class;
	case LogicalTypeId::VARCHAR:
	case LogicalTypeId::UUID:
		return RelToAltrep::string_class;

#if defined(R_HAS_ALTLIST)
	case LogicalTypeId::LIST:
		return RelToAltrep::list_class;
#endif

	default:
		cpp11::stop("rel_to_altrep: Unknown column type for altrep: %s", type.ToString().c_str());
	}
}

[[cpp11::register]] SEXP rapi_rel_to_altrep(duckdb::rel_extptr_t rel, bool allow_materialization) {
	D_ASSERT(rel && rel->rel);
	auto drel = rel->rel;
	auto ncols = drel->Columns().size();

	auto relation_wrapper = make_shared_ptr<AltrepRelationWrapper>(rel, allow_materialization);

	cpp11::writable::list data_frame;
	data_frame.reserve(ncols);

	for (size_t col_idx = 0; col_idx < ncols; col_idx++) {
		auto &column_type = drel->Columns()[col_idx].Type();
		cpp11::external_pointer<AltrepVectorWrapper> ptr(new AltrepVectorWrapper(relation_wrapper, col_idx));
		R_SetExternalPtrTag(ptr, RStrings::get().duckdb_vector_sym);

		cpp11::sexp vector_sexp = R_new_altrep(LogicalTypeToAltrepType(column_type), ptr, rel);
		duckdb_r_decorate(column_type, vector_sexp, false);
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

	// Row names
	cpp11::external_pointer<AltrepRownamesWrapper> ptr(new AltrepRownamesWrapper(relation_wrapper));
	R_SetExternalPtrTag(ptr, RStrings::get().duckdb_row_names_sym);
	cpp11::sexp row_names_sexp = R_new_altrep(RelToAltrep::rownames_class, ptr, rel);
	install_new_attrib(data_frame, R_RowNamesSymbol, row_names_sexp);

	// Class
	data_frame.attr(R_ClassSymbol) = RStrings::get().dataframe_str;

	return data_frame;
}

[[cpp11::register]] SEXP rapi_rel_from_altrep_df(SEXP df, bool strict, bool allow_materialized) {
	if (!Rf_inherits(df, "data.frame")) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not a data.frame");
		} else {
			return R_NilValue;
		}
	}

	auto row_names = get_attrib(df, R_RowNamesSymbol);
	if (row_names == R_NilValue || !ALTREP(row_names)) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not a 'special' data.frame, row names are not ALTREP");
		} else {
			return R_NilValue;
		}
	}

	auto altrep_data = R_altrep_data1(row_names);
	if (TYPEOF(altrep_data) != EXTPTRSXP) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not our 'special' data.frame, data1 is not external pointer");
		} else {
			return R_NilValue;
		}
	}

	auto tag = R_ExternalPtrTag(altrep_data);
	if (tag != RStrings::get().duckdb_row_names_sym) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: Not our 'special' data.frame, tag missing");
		} else {
			return R_NilValue;
		}
	}

	auto wrapper = GetFromExternalPtr<AltrepRownamesWrapper>(row_names);
	if (!allow_materialized) {
		if (wrapper->rel->res.get()) {
			// We return NULL here even for strict = true
			// because this is expected from df_is_materialized()
			return R_NilValue;
		}
	}

	auto res = R_altrep_data2(row_names);
	if (res == R_NilValue) {
		if (strict) {
			cpp11::stop("rapi_rel_from_altrep_df: NULL in data2?");
		} else {
			return R_NilValue;
		}
	}

	return res;
}

// exception required as long as r-lib/decor#6 remains
// clang-format off
[[cpp11::init]] void RelToAltrep_Initialize(DllInfo* dll) {
	// clang-format on
	RelToAltrep::Initialize(dll);
}
