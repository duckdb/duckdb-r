#include "duckdb/main/relation.hpp"
#include "rapi.hpp"
#include "reltoaltrep.hpp"
#include <exception>

namespace duckdb {

class AltrepDataFrameRelation final : public Relation {
public:
	AltrepDataFrameRelation(duckdb::shared_ptr<Relation> p, cpp4r::list df,
	                        duckdb::shared_ptr<AltrepRelationWrapper> altrep);

	cpp4r::list dataframe;
	duckdb::shared_ptr<AltrepRelationWrapper> altrep;
	duckdb::shared_ptr<Relation> parent;

	shared_ptr<Relation> table_function_relation;
	vector<ColumnDefinition> columns;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	bool IsReadOnly() override;

	void BuildTableRelation();

private:
	Relation &GetTableRelation();

	Relation &GetParent();
};

class RebuildRelationException : public std::runtime_error {
public:
	RebuildRelationException(AltrepDataFrameRelation *target_)
	    : std::runtime_error("RebuildRelationException"), target(target_) {
	}

public:
	AltrepDataFrameRelation *target;
};

} // namespace duckdb
