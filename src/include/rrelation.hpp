#pragma once

#include "duckdb/common/enums/join_type.hpp"
#include "duckdb/common/enums/joinref_type.hpp"
#include "duckdb/common/enums/on_create_conflict.hpp"
#include "duckdb/common/enums/set_operation_type.hpp"
#include "duckdb/common/named_parameter_map.hpp"
#include "duckdb/main/client_context.hpp"
#include "duckdb/main/profiler/profiler_print_format.hpp"
#include "duckdb/main/query_result.hpp"
#include "duckdb/main/table_description.hpp"
#include "duckdb/parser/column_definition.hpp"
#include "duckdb/parser/group_by_node.hpp"
#include "duckdb/parser/parsed_expression.hpp"
#include "duckdb/parser/result_modifier.hpp"
#include "duckdb/parser/statement/explain_statement.hpp"

namespace duckdb {

struct TableFunctionInfo;
class QueryNode;
class SelectStatement;
class SQLStatement;
class TableRef;

enum class RRelationKind : uint8_t {
	TABLE_FUNCTION_RELATION,
	TABLE_RELATION,
	QUERY_RELATION,
	SUBQUERY_RELATION,
	PROJECTION_RELATION,
	FILTER_RELATION,
	AGGREGATE_RELATION,
	ORDER_RELATION,
	JOIN_RELATION,
	CROSS_PRODUCT_RELATION,
	SET_OPERATION_RELATION,
	LIMIT_RELATION,
	DISTINCT_RELATION,
	EXTENSION_RELATION
};

//! One step of a query the R client builds. A step composes parser nodes, caches the columns it was bound with,
//! and renders itself as a tree and as SQL.
class RRelation {
public:
	RRelation(const weak_ptr<ClientContext> &context, RRelationKind kind, const string &alias = string());
	virtual ~RRelation() = default;

	//! The connection's context, or a refusal once the connection has been closed
	shared_ptr<ClientContext> GetContext() const;

	weak_ptr<ClientContext> context;
	RRelationKind kind;
	const string alias;

public:
	virtual const vector<ColumnDefinition> &Columns() = 0;
	virtual unique_ptr<QueryNode> GetQueryNode() = 0;
	virtual unique_ptr<TableRef> GetTableRef();
	virtual Identifier GetAlias();
	//! The text a query of this step is labelled with
	virtual string GetQuery();
	virtual bool IsReadOnly() {
		return true;
	}
	//! Whether a step over this one reaches past it when it looks for a join
	virtual bool InheritsColumnBindings() {
		return false;
	}
	virtual RRelation *ChildRelation() {
		return nullptr;
	}

	virtual string ToString(idx_t depth) = 0;
	string ToString();

protected:
	static string RenderWhitespace(idx_t depth);
	void BindColumns(vector<ColumnDefinition> &columns);
};

//! A result whose columns differ from `expected_columns` comes back as an error result, not as an exception, so
//! that a lazy data frame stores it like any other error of the query.
unique_ptr<QueryResult> RRunStatement(ClientContext &context, const vector<ColumnDefinition> &expected_columns,
                                      unique_ptr<SQLStatement> statement);

unique_ptr<QueryResult> RRunRelation(RRelation &relation);

void RRelationCreateTable(RRelation &child, const Identifier &schema_name, const Identifier &table_name,
                          bool temporary);
void RRelationCreateView(RRelation &child, const Identifier &schema_name, const Identifier &view_name, bool replace,
                         bool temporary);
void RRelationInsert(RRelation &child, const Identifier &schema_name, const Identifier &table_name);
void RRelationWriteCSV(RRelation &child, const string &csv_file, identifier_map_t<vector<Value>> options);
void RRelationWriteParquet(RRelation &child, const string &parquet_file, identifier_map_t<vector<Value>> options);
unique_ptr<QueryResult> RRelationExplain(RRelation &child, ExplainType type, const ProfilerPrintFormat &format);
unique_ptr<QueryResult> RRelationQuery(RRelation &child, const Identifier &name, const string &sql);

class RTableFunctionRelation : public RRelation {
public:
	RTableFunctionRelation(const weak_ptr<ClientContext> &context_p, Identifier name, vector<Value> parameters,
	                       named_parameter_map_t named_parameters, bool auto_init = true,
	                       shared_ptr<TableFunctionInfo> bind_info = nullptr);

	Identifier name;
	vector<Value> parameters;
	named_parameter_map_t named_parameters;
	vector<ColumnDefinition> columns;
	shared_ptr<TableFunctionInfo> bind_info;

public:
	unique_ptr<QueryNode> GetQueryNode() override;
	unique_ptr<TableRef> GetTableRef() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;
};

class RTableRelation : public RRelation {
public:
	RTableRelation(const weak_ptr<ClientContext> &context_p, unique_ptr<TableDescription> description);

	unique_ptr<TableDescription> description;

public:
	unique_ptr<QueryNode> GetQueryNode() override;
	unique_ptr<TableRef> GetTableRef() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;
};

class RQueryRelation : public RRelation {
public:
	RQueryRelation(const weak_ptr<ClientContext> &context_p, unique_ptr<SelectStatement> select_stmt, string alias);

	unique_ptr<SelectStatement> select_stmt;
	string query;
	vector<ColumnDefinition> columns;

public:
	//! Parses one SELECT statement, refusing anything else with `error`
	static unique_ptr<SelectStatement> ParseStatement(ClientContext &context, const string &query, const string &error);
	unique_ptr<QueryNode> GetQueryNode() override;
	unique_ptr<TableRef> GetTableRef() override;
	string GetQuery() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;

	//! Wraps the stored statement in a common table expression per recorded table reference, so that later binds
	//! resolve those names without the caller's environment
	void PinTableRefs(identifier_map_t<unique_ptr<TableRef>> &refs);

private:
	unique_ptr<SelectStatement> GetSelectStatement();
};

class RSubqueryRelation : public RRelation {
public:
	RSubqueryRelation(shared_ptr<RRelation> child, const string &alias);

	shared_ptr<RRelation> child;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;

	bool InheritsColumnBindings() override {
		return child->InheritsColumnBindings();
	}
	RRelation *ChildRelation() override {
		return child->ChildRelation();
	}
};

class RProjectionRelation : public RRelation {
public:
	RProjectionRelation(shared_ptr<RRelation> child, vector<unique_ptr<ParsedExpression>> expressions,
	                    vector<Identifier> aliases);

	vector<unique_ptr<ParsedExpression>> expressions;
	vector<ColumnDefinition> columns;
	shared_ptr<RRelation> child;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;
};

class RFilterRelation : public RRelation {
public:
	RFilterRelation(shared_ptr<RRelation> child, unique_ptr<ParsedExpression> condition);

	unique_ptr<ParsedExpression> condition;
	shared_ptr<RRelation> child;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;

	bool InheritsColumnBindings() override {
		return true;
	}
	RRelation *ChildRelation() override {
		return child.get();
	}
};

class RAggregateRelation : public RRelation {
public:
	RAggregateRelation(shared_ptr<RRelation> child, vector<unique_ptr<ParsedExpression>> expressions,
	                   vector<unique_ptr<ParsedExpression>> groups);

	vector<unique_ptr<ParsedExpression>> expressions;
	GroupByNode groups;
	vector<ColumnDefinition> columns;
	shared_ptr<RRelation> child;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;
};

class ROrderRelation : public RRelation {
public:
	ROrderRelation(shared_ptr<RRelation> child, vector<OrderByNode> orders);

	vector<OrderByNode> orders;
	shared_ptr<RRelation> child;
	vector<ColumnDefinition> columns;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;

	bool InheritsColumnBindings() override {
		return true;
	}
	RRelation *ChildRelation() override {
		return child.get();
	}
};

class RJoinRelation : public RRelation {
public:
	RJoinRelation(shared_ptr<RRelation> left, shared_ptr<RRelation> right, unique_ptr<ParsedExpression> condition,
	              JoinType type, JoinRefType join_ref_type);

	shared_ptr<RRelation> left;
	shared_ptr<RRelation> right;
	unique_ptr<ParsedExpression> condition;
	JoinType join_type;
	JoinRefType join_ref_type;
	vector<ColumnDefinition> columns;

public:
	unique_ptr<QueryNode> GetQueryNode() override;
	unique_ptr<TableRef> GetTableRef() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
};

class RCrossProductRelation : public RRelation {
public:
	RCrossProductRelation(shared_ptr<RRelation> left, shared_ptr<RRelation> right, JoinRefType join_ref_type);

	shared_ptr<RRelation> left;
	shared_ptr<RRelation> right;
	JoinRefType ref_type;
	vector<ColumnDefinition> columns;

public:
	unique_ptr<QueryNode> GetQueryNode() override;
	unique_ptr<TableRef> GetTableRef() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
};

class RSetOpRelation : public RRelation {
public:
	RSetOpRelation(shared_ptr<RRelation> left, shared_ptr<RRelation> right, SetOperationType setop_type,
	               bool setop_all = false);

	shared_ptr<RRelation> left;
	shared_ptr<RRelation> right;
	SetOperationType setop_type;
	vector<ColumnDefinition> columns;
	bool setop_all;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;
};

class RLimitRelation : public RRelation {
public:
	RLimitRelation(shared_ptr<RRelation> child, int64_t limit, int64_t offset);

	int64_t limit;
	int64_t offset;
	shared_ptr<RRelation> child;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;

	bool InheritsColumnBindings() override {
		return true;
	}
	RRelation *ChildRelation() override {
		return child.get();
	}
};

class RDistinctRelation : public RRelation {
public:
	explicit RDistinctRelation(shared_ptr<RRelation> child);

	shared_ptr<RRelation> child;

public:
	unique_ptr<QueryNode> GetQueryNode() override;

	const vector<ColumnDefinition> &Columns() override;
	string ToString(idx_t depth) override;
	Identifier GetAlias() override;

	bool InheritsColumnBindings() override {
		return true;
	}
	RRelation *ChildRelation() override {
		return child.get();
	}
};

} // namespace duckdb
