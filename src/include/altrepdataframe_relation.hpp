#include "rapi.hpp"
#include "reltoaltrep.hpp"
#include "rrelation.hpp"
#include <exception>

namespace duckdb {

class AltrepDataFrameRelation final : public RRelation {
public:
	AltrepDataFrameRelation(duckdb::shared_ptr<RRelation> p, cpp11::list df,
	                        duckdb::shared_ptr<AltrepRelationWrapper> altrep);

	cpp11::list dataframe;
	duckdb::shared_ptr<AltrepRelationWrapper> altrep;
	duckdb::shared_ptr<RRelation> parent;

	shared_ptr<RRelation> table_function_relation;
	vector<ColumnDefinition> columns;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	bool IsReadOnly() override;

	void BuildTableRelation();

private:
	RRelation &GetTableRelation();

	RRelation &GetParent();
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
