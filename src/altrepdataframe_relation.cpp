#include "altrepdataframe_relation.hpp"

namespace duckdb {

AltrepDataFrameRelation::AltrepDataFrameRelation(shared_ptr<Relation> parent)
// TODO: which RelationType should be used?
	: Relation(parent->context, RelationType::AGGREGATE_RELATION), parent(std::move(parent)) {
}

const vector<ColumnDefinition> &AltrepDataFrameRelation::Columns() {
	return parent->Columns();
}

string AltrepDataFrameRelation::ToString(idx_t depth) {
	return parent->ToString(depth);
}

bool AltrepDataFrameRelation::IsReadOnly() {
	return parent->IsReadOnly();
}

}
