#include "altrepdataframe_relation.hpp"

namespace duckdb {

AltrepDataFrameRelation::AltrepDataFrameRelation(shared_ptr<Relation> parent)
// TODO: which RelationType should be used?
	: Relation(parent->context, RelationType::AGGREGATE_RELATION), parent(std::move(parent)) {
	TryBindRelation(columns);
}

const vector<ColumnDefinition> &AltrepDataFrameRelation::Columns() {
	return columns;
}

string AltrepDataFrameRelation::ToString(idx_t depth) {
	return parent->ToString(depth);
}

bool AltrepDataFrameRelation::IsReadOnly() {
	return parent->IsReadOnly();
}

unique_ptr<QueryNode> AltrepDataFrameRelation::GetQueryNode() {
	return parent->GetQueryNode();
}

}
