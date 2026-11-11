#include "altrepdataframe_relation.hpp"

namespace duckdb {

AltrepDataFrameRelation::AltrepDataFrameRelation(duckdb::shared_ptr<RRelation> p, cpp11::list df,
                                                 duckdb::shared_ptr<AltrepRelationWrapper> altrep_)
    : RRelation(p->context, RRelationKind::EXTENSION_RELATION), dataframe(df), altrep(std::move(altrep_)),
      parent(std::move(p)) {
	BindColumns(columns);
}

const vector<ColumnDefinition> &AltrepDataFrameRelation::Columns() {
	return columns;
}

string AltrepDataFrameRelation::ToString(idx_t depth) {
	string str =
	    RenderWhitespace(depth) + "AltrepDataFrame [" + Value::POINTER((uintptr_t)(SEXP)dataframe).ToString() + "]\n";
	return str + GetParent().ToString(depth + 1);
}

bool AltrepDataFrameRelation::IsReadOnly() {
	return GetParent().IsReadOnly();
}

unique_ptr<QueryNode> AltrepDataFrameRelation::GetQueryNode() {
	return GetParent().GetQueryNode();
}

RRelation &AltrepDataFrameRelation::GetParent() {
	if (altrep->Materialized()) {
		return GetTableRelation();
	} else {
		return *parent;
	}
}

void AltrepDataFrameRelation::BuildTableRelation() {
	if (!table_function_relation) {
		vector<Value> params = {Value::POINTER((uintptr_t)(SEXP)dataframe)};

		named_parameter_map_t other_params;

		// Left unbound: rendering can happen in R code that runs while this connection's context lock is held, such
		// as a materialize callback under a scan, where a bind would wait for that lock forever.
		table_function_relation = make_shared_ptr<RTableFunctionRelation>(GetContext(), Identifier("r_dataframe_scan"),
		                                                                  params, other_params, false);
	}
}

RRelation &AltrepDataFrameRelation::GetTableRelation() {
	if (!table_function_relation) {
		BuildTableRelation();
	}

	return *table_function_relation;
}

} // namespace duckdb
