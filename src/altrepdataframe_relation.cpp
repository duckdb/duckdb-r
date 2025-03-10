#include "altrepdataframe_relation.hpp"

#include "R_ext/Random.h"

namespace duckdb {

AltrepDataFrameRelation::AltrepDataFrameRelation(duckdb::shared_ptr<Relation> p, cpp11::sexp df, duckdb::conn_eptr_t con, duckdb::shared_ptr<AltrepRelationWrapper> altrep)
	: Relation(p->context, RelationType::EXTENSION_RELATION)
	, dataframe(df)
	, connection(std::move(con))
	, altrep(std::move(altrep))
	, parent(std::move(p)) {
	TryBindRelation(columns);
}

const vector<ColumnDefinition> &AltrepDataFrameRelation::Columns() {
	return columns;
}

string AltrepDataFrameRelation::ToString(idx_t depth) {
	return GetParent().ToString(depth);
}

bool AltrepDataFrameRelation::IsReadOnly() {
	return GetParent().IsReadOnly();
}

unique_ptr<QueryNode> AltrepDataFrameRelation::GetQueryNode() {
	return GetParent().GetQueryNode();
}

Relation& AltrepDataFrameRelation::GetParent() {
	if (altrep->HasQueryResult()) {
		// here context mutex locked
		return GetTableRelation();
	} else {
		return *parent;
	}
}

void AltrepDataFrameRelation::BuildTableRelation() {
	if (!table_function_relation) {
		named_parameter_map_t other_params;
		other_params["experimental"] = Value::BOOLEAN(false);
		auto alias = StringUtil::Format("dataframe_%d_%d", (uintptr_t)(SEXP)dataframe,
										(int32_t)(NumericLimits<int32_t>::Maximum() * unif_rand()));

		table_function_relation = connection->conn->TableFunction("r_dataframe_scan", {Value::POINTER((uintptr_t)(SEXP)dataframe)}, other_params, false)->Alias(alias);
	}
}

Relation& AltrepDataFrameRelation::GetTableRelation() {
	if (!table_function_relation) {
		BuildTableRelation();
	}

	return *table_function_relation;
}

}
