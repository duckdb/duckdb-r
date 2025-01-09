#include "duckdb/main/relation.hpp"
#include "rapi.hpp"
#include "reltoaltrep.hpp"

namespace duckdb {

class AltrepDataFrameRelation final : public Relation {
public:
	AltrepDataFrameRelation(duckdb::shared_ptr<Relation> p, cpp11::sexp df, duckdb::conn_eptr_t con, duckdb::shared_ptr<AltrepRelationWrapper> altrep);

	shared_ptr<Relation> table_function_relation;
	cpp11::sexp dataframe;
	duckdb::conn_eptr_t connection;
	duckdb::shared_ptr<AltrepRelationWrapper> altrep;
	duckdb::shared_ptr<Relation> parent;
	vector<ColumnDefinition> columns;
public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	bool IsReadOnly() override;

	void BuildTableRelation();

private:
	Relation& GetTableRelation();

	Relation& GetParent();
};

class RebuildRelationException : public std::exception {
public:
	RebuildRelationException(AltrepDataFrameRelation* target_) : target(target_) {
	}

public:
	AltrepDataFrameRelation* target;
};

} // namespace duckdb
