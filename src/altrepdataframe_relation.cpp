#include "altrepdataframe_relation.hpp"

#include "duckdb/main/relation/table_function_relation.hpp"

namespace duckdb {

AltrepDataFrameRelation::AltrepDataFrameRelation(duckdb::shared_ptr<Relation> p, cpp11::list df,
                                                 duckdb::shared_ptr<AltrepRelationWrapper> altrep_)
    // An explicit alias keeps the base class from naming the relation by its type:
    // that passes RelationType::EXTENSION_RELATION, a one-byte 255, to the engine's EnumUtil,
    // which a GCC-built glue may pass with the upper bits set (here 0xffffffff),
    // and a clang-built libduckdb reads all 32 bits (#2955)
    : Relation(p->context, RelationType::EXTENSION_RELATION, "EXTENSION_RELATION_" + StringUtil::GenerateRandomName()),
      dataframe(df), altrep(std::move(altrep_)), parent(std::move(p)) {
	TryBindRelation(columns);
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

Relation &AltrepDataFrameRelation::GetParent() {
	if (altrep->Materialized()) {
		// here context mutex locked
		return GetTableRelation();
	} else {
		return *parent;
	}
}

void AltrepDataFrameRelation::BuildTableRelation() {
	if (!table_function_relation) {
		vector<Value> params = {Value::POINTER((uintptr_t)(SEXP)dataframe)};

		// Without `integer64`, as in rel_from_df() (handbook/usage/relational/README.md)
		named_parameter_map_t other_params;

		// Can't do an alias here and need auto_init = false
		// to avoid a recursive lock
		table_function_relation = make_shared_ptr<TableFunctionRelation>(context->GetContext(), "r_dataframe_scan",
		                                                                 params, other_params, nullptr, false);
	}
}

Relation &AltrepDataFrameRelation::GetTableRelation() {
	if (!table_function_relation) {
		BuildTableRelation();
	}

	return *table_function_relation;
}

} // namespace duckdb
