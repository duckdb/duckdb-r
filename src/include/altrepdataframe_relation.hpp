#include "duckdb/main/relation.hpp"

namespace duckdb {

class AltrepDataFrameRelation final : public Relation {
public:
	AltrepDataFrameRelation(shared_ptr<Relation> parent);

	shared_ptr<Relation> parent;
	vector<ColumnDefinition> columns;
public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	bool IsReadOnly() override;
};

}
