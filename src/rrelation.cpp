#include "rrelation.hpp"

#include "duckdb/common/enum_util.hpp"
#include "duckdb/common/string_util.hpp"
#include "duckdb/common/to_string.hpp"
#include "duckdb/main/query_parameters.hpp"
#include "duckdb/parser/common_table_expression_info.hpp"
#include "duckdb/parser/expression/columnref_expression.hpp"
#include "duckdb/parser/expression/comparison_expression.hpp"
#include "duckdb/parser/expression/conjunction_expression.hpp"
#include "duckdb/parser/expression/constant_expression.hpp"
#include "duckdb/parser/expression/function_expression.hpp"
#include "duckdb/parser/expression/star_expression.hpp"
#include "duckdb/parser/parsed_data/create_table_info.hpp"
#include "duckdb/parser/parsed_data/create_view_info.hpp"
#include "duckdb/parser/parser.hpp"
#include "duckdb/parser/query_node/select_node.hpp"
#include "duckdb/parser/query_node/set_operation_node.hpp"
#include "duckdb/parser/statement/copy_statement.hpp"
#include "duckdb/parser/statement/create_statement.hpp"
#include "duckdb/parser/statement/insert_statement.hpp"
#include "duckdb/parser/statement/select_statement.hpp"
#include "duckdb/parser/tableref/basetableref.hpp"
#include "duckdb/parser/tableref/joinref.hpp"
#include "duckdb/parser/tableref/subqueryref.hpp"
#include "duckdb/parser/tableref/table_function_ref.hpp"

namespace duckdb {

static const char *KindName(RRelationKind kind) {
	switch (kind) {
	case RRelationKind::TABLE_FUNCTION_RELATION:
		return "TABLE_FUNCTION_RELATION";
	case RRelationKind::TABLE_RELATION:
		return "TABLE_RELATION";
	case RRelationKind::QUERY_RELATION:
		return "QUERY_RELATION";
	case RRelationKind::SUBQUERY_RELATION:
		return "SUBQUERY_RELATION";
	case RRelationKind::PROJECTION_RELATION:
		return "PROJECTION_RELATION";
	case RRelationKind::FILTER_RELATION:
		return "FILTER_RELATION";
	case RRelationKind::AGGREGATE_RELATION:
		return "AGGREGATE_RELATION";
	case RRelationKind::ORDER_RELATION:
		return "ORDER_RELATION";
	case RRelationKind::JOIN_RELATION:
		return "JOIN_RELATION";
	case RRelationKind::CROSS_PRODUCT_RELATION:
		return "CROSS_PRODUCT_RELATION";
	case RRelationKind::SET_OPERATION_RELATION:
		return "SET_OPERATION_RELATION";
	case RRelationKind::LIMIT_RELATION:
		return "LIMIT_RELATION";
	case RRelationKind::DISTINCT_RELATION:
		return "DISTINCT_RELATION";
	case RRelationKind::EXTENSION_RELATION:
		return "EXTENSION_RELATION";
	}
	throw InternalException("Unknown relation kind");
}

static string CreateRelationAlias(RRelationKind kind, const string &alias) {
	if (!alias.empty()) {
		return alias;
	}
	return StringUtil::Format("%s_%s", KindName(kind), StringUtil::GenerateRandomName());
}

RRelation::RRelation(const weak_ptr<ClientContext> &context_p, RRelationKind kind_p, const string &alias_p)
    : context(context_p), kind(kind_p), alias(CreateRelationAlias(kind_p, alias_p)) {
}

shared_ptr<ClientContext> RRelation::GetContext() const {
	auto actual_context = context.lock();
	if (!actual_context) {
		throw ConnectionException("Connection has already been closed");
	}
	return actual_context;
}

unique_ptr<TableRef> RRelation::GetTableRef() {
	auto select = make_uniq<SelectStatement>();
	select->node = GetQueryNode();
	return make_uniq<SubqueryRef>(std::move(select), GetAlias());
}

Identifier RRelation::GetAlias() {
	return Identifier(alias);
}

string RRelation::GetQuery() {
	return GetQueryNode()->ToString();
}

string RRelation::RenderWhitespace(idx_t depth) {
	return string(depth * 2, ' ');
}

string RRelation::ToString() {
	string str;
	str += "---------------------\n";
	str += "--- Relation Tree ---\n";
	str += "---------------------\n";
	str += ToString(0);
	str += "\n\n";
	str += "---------------------\n";
	str += "-- Result Columns  --\n";
	str += "---------------------\n";
	auto &cols = Columns();
	for (idx_t i = 0; i < cols.size(); i++) {
		str += "- " + cols[i].Name() + " (" + cols[i].Type().ToString() + ")\n";
	}
	return str;
}

static void AppendColumns(const StatementSignature &signature, vector<ColumnDefinition> &columns) {
	D_ASSERT(signature.names.size() == signature.types.size());
	columns.reserve(columns.size() + signature.names.size());
	for (idx_t i = 0; i < signature.names.size(); i++) {
		columns.emplace_back(signature.names[i], signature.types[i]);
	}
}

void RRelation::BindColumns(vector<ColumnDefinition> &columns) {
	auto context_ref = GetContext();
	auto statement = make_uniq<SelectStatement>();
	statement->node = GetQueryNode();
	AppendColumns(context_ref->BindStatement(std::move(statement)), columns);
}

unique_ptr<QueryResult> RRunStatement(ClientContext &context, const vector<ColumnDefinition> &expected_columns,
                                      unique_ptr<SQLStatement> statement) {
	auto result = context.Query(std::move(statement), QueryParameters());
	if (result->HasError()) {
		return result;
	}
	if (result->GetTypes().size() == expected_columns.size()) {
		bool mismatch = false;
		for (idx_t i = 0; i < result->GetTypes().size(); i++) {
			if (result->GetTypes()[i] != expected_columns[i].Type() ||
			    result->ColumnName(i) != expected_columns[i].Name()) {
				mismatch = true;
				break;
			}
		}
		if (!mismatch) {
			return result;
		}
	}
	string err_str = "Result mismatch in query!\nExpected the following columns: [";
	for (idx_t i = 0; i < expected_columns.size(); i++) {
		if (i > 0) {
			err_str += ", ";
		}
		err_str += expected_columns[i].Name() + " " + expected_columns[i].Type().ToString();
	}
	err_str += "]\nBut result contained the following: ";
	for (idx_t i = 0; i < result->GetTypes().size(); i++) {
		err_str += i == 0 ? "[" : ", ";
		err_str += result->ColumnName(i) + " " + result->GetTypes()[i].ToString();
	}
	err_str += "]";
	ErrorData error(err_str);
	context.ProcessError(error, string());
	return make_uniq<QueryResult>(std::move(error));
}

unique_ptr<QueryResult> RRunRelation(RRelation &relation) {
	auto context = relation.GetContext();
	auto &expected_columns = relation.Columns();
	auto statement = make_uniq<SelectStatement>();
	statement->query = relation.GetQuery();
	statement->node = relation.GetQueryNode();
	return RRunStatement(*context, expected_columns, std::move(statement));
}

template <class BUILD>
static unique_ptr<QueryResult> BindAndRun(RRelation &child, BUILD build) {
	auto context = child.GetContext();
	vector<ColumnDefinition> columns;
	AppendColumns(context->BindStatement(build()), columns);
	return RRunStatement(*context, columns, build());
}

static unique_ptr<SQLStatement> MakeCreateTableStatement(RRelation &child, const Identifier &schema_name,
                                                         const Identifier &table_name, bool temporary) {
	auto select = make_uniq<SelectStatement>();
	select->node = child.GetQueryNode();

	auto statement = make_uniq<CreateStatement>();
	auto info = make_uniq<CreateTableInfo>();
	info->SetQualifiedName(QualifiedName(Identifier::InvalidCatalog(), schema_name, table_name));
	info->query = std::move(select);
	info->on_conflict = OnCreateConflict::ERROR_ON_CONFLICT;
	info->temporary = temporary;
	statement->info = std::move(info);
	return std::move(statement);
}

void RRelationCreateTable(RRelation &child, const Identifier &schema_name, const Identifier &table_name,
                          bool temporary) {
	if (table_name.empty()) {
		throw ParserException("Empty table name not supported");
	}
	auto result =
	    BindAndRun(child, [&]() { return MakeCreateTableStatement(child, schema_name, table_name, temporary); });
	result->ThrowIfError("Failed to create table '" + table_name + "': ");
}

static unique_ptr<SQLStatement> MakeCreateViewStatement(RRelation &child, const Identifier &schema_name,
                                                        const Identifier &view_name, bool replace, bool temporary) {
	auto select = make_uniq<SelectStatement>();
	select->node = child.GetQueryNode();

	auto statement = make_uniq<CreateStatement>();
	auto info = make_uniq<CreateViewInfo>();
	info->query = std::move(select);
	info->temporary = temporary;
	info->SetQualifiedName(QualifiedName(Identifier(), schema_name, view_name));
	info->on_conflict = replace ? OnCreateConflict::REPLACE_ON_CONFLICT : OnCreateConflict::ERROR_ON_CONFLICT;
	statement->info = std::move(info);
	return std::move(statement);
}

void RRelationCreateView(RRelation &child, const Identifier &schema_name, const Identifier &view_name, bool replace,
                         bool temporary) {
	auto result =
	    BindAndRun(child, [&]() { return MakeCreateViewStatement(child, schema_name, view_name, replace, temporary); });
	result->ThrowIfError("Failed to create view '" + view_name + "': ");
}

static unique_ptr<SQLStatement> MakeInsertStatement(RRelation &child, const Identifier &schema_name,
                                                    const Identifier &table_name) {
	auto statement = make_uniq<InsertStatement>();
	auto &node = *statement->node;
	auto select = make_uniq<SelectStatement>();
	select->node = child.GetQueryNode();

	node.qualified_name = QualifiedName(Identifier::InvalidCatalog(), schema_name, table_name);
	node.select_statement = std::move(select);
	return std::move(statement);
}

void RRelationInsert(RRelation &child, const Identifier &schema_name, const Identifier &table_name) {
	auto result = BindAndRun(child, [&]() { return MakeInsertStatement(child, schema_name, table_name); });
	result->ThrowIfError("Failed to insert into table '" + table_name + "': ");
}

static unique_ptr<SQLStatement> MakeCopyStatement(RRelation &child, const string &file_name, const string &format,
                                                  const identifier_map_t<vector<Value>> &options) {
	auto statement = make_uniq<CopyStatement>();
	auto info = make_uniq<CopyInfo>();
	info->select_statement = child.GetQueryNode();
	info->is_from = false;
	info->file_path = file_name;
	info->format = format;
	info->options = options;
	statement->info = std::move(info);
	return std::move(statement);
}

void RRelationWriteCSV(RRelation &child, const string &csv_file, identifier_map_t<vector<Value>> options) {
	auto result = BindAndRun(child, [&]() { return MakeCopyStatement(child, csv_file, "csv", options); });
	result->ThrowIfError("Failed to write '" + csv_file + "': ");
}

void RRelationWriteParquet(RRelation &child, const string &parquet_file, identifier_map_t<vector<Value>> options) {
	auto result = BindAndRun(child, [&]() { return MakeCopyStatement(child, parquet_file, "parquet", options); });
	result->ThrowIfError("Failed to write '" + parquet_file + "': ");
}

unique_ptr<QueryResult> RRelationExplain(RRelation &child, ExplainType type, const ProfilerPrintFormat &format) {
	return BindAndRun(child, [&]() -> unique_ptr<SQLStatement> {
		auto select = make_uniq<SelectStatement>();
		select->node = child.GetQueryNode();
		return make_uniq<ExplainStatement>(std::move(select), type, format);
	});
}

unique_ptr<QueryResult> RRelationQuery(RRelation &child, const Identifier &name, const string &sql) {
	RRelationCreateView(child, Identifier::InvalidSchema(), name, true, child.IsReadOnly());
	return child.GetContext()->Query(sql, QueryParameters());
}

RTableFunctionRelation::RTableFunctionRelation(const weak_ptr<ClientContext> &context_p, Identifier name_p,
                                               vector<Value> parameters_p, named_parameter_map_t named_parameters_p,
                                               bool auto_init, shared_ptr<TableFunctionInfo> bind_info_p)
    : RRelation(context_p, RRelationKind::TABLE_FUNCTION_RELATION), name(std::move(name_p)),
      parameters(std::move(parameters_p)), named_parameters(std::move(named_parameters_p)),
      bind_info(std::move(bind_info_p)) {
	if (auto_init) {
		BindColumns(columns);
	}
}

unique_ptr<QueryNode> RTableFunctionRelation::GetQueryNode() {
	auto result = make_uniq<SelectNode>();
	result->select_list.push_back(make_uniq<StarExpression>());
	result->from_table = GetTableRef();
	return std::move(result);
}

unique_ptr<TableRef> RTableFunctionRelation::GetTableRef() {
	vector<unique_ptr<ParsedExpression>> children;
	for (auto &parameter : parameters) {
		children.push_back(ConstantExpression::FromValue(parameter));
	}

	// A named parameter travels as a comparison of a bare column reference with its value, which is the form the
	// function binder reads it in
	for (auto &parameter : named_parameters) {
		auto column_ref = make_uniq<ColumnRefExpression>(parameter.first);
		auto constant_value = ConstantExpression::FromValue(parameter.second);
		auto comparison = make_uniq<ComparisonExpression>(ExpressionType::COMPARE_EQUAL, std::move(column_ref),
		                                                  std::move(constant_value));
		children.push_back(std::move(comparison));
	}

	auto table_function = make_uniq<TableFunctionRef>();
	table_function->function = make_uniq<FunctionExpression>(name, std::move(children));
	table_function->bind_info = bind_info;
	return std::move(table_function);
}

Identifier RTableFunctionRelation::GetAlias() {
	return name;
}

const vector<ColumnDefinition> &RTableFunctionRelation::Columns() {
	return columns;
}

string RTableFunctionRelation::ToString(idx_t depth) {
	string function_call = name + "(";
	for (idx_t i = 0; i < parameters.size(); i++) {
		if (i > 0) {
			function_call += ", ";
		}
		function_call += parameters[i].ToString();
	}
	function_call += ")";
	return RenderWhitespace(depth) + function_call;
}

RTableRelation::RTableRelation(const weak_ptr<ClientContext> &context_p, unique_ptr<TableDescription> description_p)
    : RRelation(context_p, RRelationKind::TABLE_RELATION), description(std::move(description_p)) {
}

unique_ptr<QueryNode> RTableRelation::GetQueryNode() {
	auto result = make_uniq<SelectNode>();
	result->select_list.push_back(make_uniq<StarExpression>());
	result->from_table = GetTableRef();
	return std::move(result);
}

unique_ptr<TableRef> RTableRelation::GetTableRef() {
	auto table_ref = make_uniq<BaseTableRef>();
	table_ref->SetQualifiedName(description->qualified_name);
	return std::move(table_ref);
}

Identifier RTableRelation::GetAlias() {
	return description->qualified_name.Name();
}

const vector<ColumnDefinition> &RTableRelation::Columns() {
	return description->columns;
}

string RTableRelation::ToString(idx_t depth) {
	return RenderWhitespace(depth) + "Scan Table [" +
	       description->qualified_name.ToString(QualifiedNameToStringMode::HIDE_DEFAULT_SCHEMA) + "]";
}

RQueryRelation::RQueryRelation(const weak_ptr<ClientContext> &context_p, unique_ptr<SelectStatement> select_stmt_p,
                               string alias_p)
    : RRelation(context_p, RRelationKind::QUERY_RELATION, alias_p), select_stmt(std::move(select_stmt_p)) {
	query = select_stmt->ToString();
	BindColumns(columns);
}

unique_ptr<SelectStatement> RQueryRelation::ParseStatement(ClientContext &context, const string &query,
                                                           const string &error) {
	Parser parser(context);
	parser.ParseQuery(query);
	if (parser.statements.size() != 1) {
		throw ParserException(error);
	}
	if (parser.statements[0]->type != StatementType::SELECT_STATEMENT) {
		throw ParserException(error);
	}
	return unique_ptr_cast<SQLStatement, SelectStatement>(std::move(parser.statements[0]));
}

unique_ptr<SelectStatement> RQueryRelation::GetSelectStatement() {
	return unique_ptr_cast<SQLStatement, SelectStatement>(select_stmt->Copy());
}

unique_ptr<QueryNode> RQueryRelation::GetQueryNode() {
	auto select = GetSelectStatement();
	return std::move(select->node);
}

unique_ptr<TableRef> RQueryRelation::GetTableRef() {
	return make_uniq<SubqueryRef>(GetSelectStatement(), GetAlias());
}

string RQueryRelation::GetQuery() {
	return query;
}

const vector<ColumnDefinition> &RQueryRelation::Columns() {
	return columns;
}

string RQueryRelation::ToString(idx_t depth) {
	return RenderWhitespace(depth) + "Subquery";
}

void RQueryRelation::PinTableRefs(identifier_map_t<unique_ptr<TableRef>> &refs) {
	for (auto &kv : refs) {
		auto &name = kv.first;
		auto &tableref = kv.second;

		auto select_node = make_uniq<SelectNode>();
		select_node->select_list.push_back(make_uniq<StarExpression>());
		select_node->from_table = std::move(tableref);

		auto cte_info = make_uniq<CommonTableExpressionInfo>();
		cte_info->query_node = std::move(select_node);

		auto subquery = make_uniq<SubqueryRef>(std::move(select_stmt), "query_relation");
		auto top_level_select = make_uniq<SelectStatement>();
		auto top_level_select_node = make_uniq<SelectNode>();
		top_level_select_node->select_list.push_back(make_uniq<StarExpression>());
		top_level_select_node->from_table = std::move(subquery);
		auto &cte_map = top_level_select_node->cte_map;
		top_level_select->node = std::move(top_level_select_node);
		cte_map.map[name] = std::move(cte_info);
		select_stmt = std::move(top_level_select);
	}
}

RSubqueryRelation::RSubqueryRelation(shared_ptr<RRelation> child_p, const string &alias_p)
    : RRelation(child_p->context, RRelationKind::SUBQUERY_RELATION, alias_p), child(std::move(child_p)) {
	D_ASSERT(child.get() != this);
	vector<ColumnDefinition> dummy_columns;
	BindColumns(dummy_columns);
}

unique_ptr<QueryNode> RSubqueryRelation::GetQueryNode() {
	return child->GetQueryNode();
}

const vector<ColumnDefinition> &RSubqueryRelation::Columns() {
	return child->Columns();
}

string RSubqueryRelation::ToString(idx_t depth) {
	return child->ToString(depth);
}

RProjectionRelation::RProjectionRelation(shared_ptr<RRelation> child_p,
                                         vector<unique_ptr<ParsedExpression>> parsed_expressions,
                                         vector<Identifier> aliases)
    : RRelation(child_p->context, RRelationKind::PROJECTION_RELATION), expressions(std::move(parsed_expressions)),
      child(std::move(child_p)) {
	if (!aliases.empty()) {
		if (aliases.size() != expressions.size()) {
			throw ParserException("Aliases list length must match expression list length!");
		}
		for (idx_t i = 0; i < aliases.size(); i++) {
			expressions[i]->SetAlias(aliases[i]);
		}
	}
	BindColumns(columns);
}

//! A step over a join writes itself into the join's own SELECT, so that a reference qualified by either side
//! stays in scope.
static bool ReachesJoin(RRelation &child) {
	auto child_ptr = &child;
	while (child_ptr->InheritsColumnBindings()) {
		child_ptr = child_ptr->ChildRelation();
	}
	return child_ptr->kind == RRelationKind::JOIN_RELATION;
}

static unique_ptr<QueryNode> SelectNodeOver(RRelation &child) {
	unique_ptr<QueryNode> result;
	if (ReachesJoin(child)) {
		result = child.GetQueryNode();
	} else {
		auto select = make_uniq<SelectNode>();
		select->from_table = child.GetTableRef();
		result = std::move(select);
	}
	D_ASSERT(result->type == QueryNodeType::SELECT_NODE);
	return result;
}

unique_ptr<QueryNode> RProjectionRelation::GetQueryNode() {
	auto result = SelectNodeOver(*child);
	auto &select_node = result->Cast<SelectNode>();
	select_node.aggregate_handling = AggregateHandling::NO_AGGREGATES_ALLOWED;
	select_node.select_list.clear();
	for (auto &expr : expressions) {
		select_node.select_list.push_back(expr->Copy());
	}
	return result;
}

Identifier RProjectionRelation::GetAlias() {
	return child->GetAlias();
}

const vector<ColumnDefinition> &RProjectionRelation::Columns() {
	return columns;
}

string RProjectionRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth) + "Projection [";
	for (idx_t i = 0; i < expressions.size(); i++) {
		if (i != 0) {
			str += ", ";
		}
		str += expressions[i]->ToString() + " as " + expressions[i]->GetAlias();
	}
	str += "]\n";
	return str + child->ToString(depth + 1);
}

RFilterRelation::RFilterRelation(shared_ptr<RRelation> child_p, unique_ptr<ParsedExpression> condition_p)
    : RRelation(child_p->context, RRelationKind::FILTER_RELATION), condition(std::move(condition_p)),
      child(std::move(child_p)) {
	D_ASSERT(child.get() != this);
	vector<ColumnDefinition> dummy_columns;
	BindColumns(dummy_columns);
}

unique_ptr<QueryNode> RFilterRelation::GetQueryNode() {
	if (ReachesJoin(*child)) {
		auto child_node = child->GetQueryNode();
		D_ASSERT(child_node->type == QueryNodeType::SELECT_NODE);
		auto &select_node = child_node->Cast<SelectNode>();
		if (!select_node.where_clause) {
			select_node.where_clause = condition->Copy();
		} else {
			select_node.where_clause = make_uniq<ConjunctionExpression>(
			    ExpressionType::CONJUNCTION_AND, std::move(select_node.where_clause), condition->Copy());
		}
		return child_node;
	}
	auto result = make_uniq<SelectNode>();
	result->select_list.push_back(make_uniq<StarExpression>());
	result->from_table = child->GetTableRef();
	result->where_clause = condition->Copy();
	return std::move(result);
}

Identifier RFilterRelation::GetAlias() {
	return child->GetAlias();
}

const vector<ColumnDefinition> &RFilterRelation::Columns() {
	return child->Columns();
}

string RFilterRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth) + "Filter [" + condition->ToString() + "]\n";
	return str + child->ToString(depth + 1);
}

RAggregateRelation::RAggregateRelation(shared_ptr<RRelation> child_p,
                                       vector<unique_ptr<ParsedExpression>> parsed_expressions,
                                       vector<unique_ptr<ParsedExpression>> groups_p)
    : RRelation(child_p->context, RRelationKind::AGGREGATE_RELATION), expressions(std::move(parsed_expressions)),
      child(std::move(child_p)) {
	if (!groups_p.empty()) {
		GroupingSet grouping_set;
		for (idx_t i = 0; i < groups_p.size(); i++) {
			groups.group_expressions.push_back(std::move(groups_p[i]));
			grouping_set.emplace(i);
		}
		groups.grouping_sets.push_back(std::move(grouping_set));
	}
	BindColumns(columns);
}

unique_ptr<QueryNode> RAggregateRelation::GetQueryNode() {
	auto result = SelectNodeOver(*child);
	auto &select_node = result->Cast<SelectNode>();
	if (!groups.group_expressions.empty()) {
		select_node.aggregate_handling = AggregateHandling::STANDARD_HANDLING;
		select_node.groups = groups.Copy();
	} else {
		select_node.aggregate_handling = AggregateHandling::FORCE_AGGREGATES;
	}
	select_node.select_list.clear();
	for (auto &expr : expressions) {
		select_node.select_list.push_back(expr->Copy());
	}
	return result;
}

Identifier RAggregateRelation::GetAlias() {
	return child->GetAlias();
}

const vector<ColumnDefinition> &RAggregateRelation::Columns() {
	return columns;
}

string RAggregateRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth) + "Aggregate [";
	for (idx_t i = 0; i < expressions.size(); i++) {
		if (i != 0) {
			str += ", ";
		}
		str += expressions[i]->ToString();
	}
	str += "]\n";
	return str + child->ToString(depth + 1);
}

ROrderRelation::ROrderRelation(shared_ptr<RRelation> child_p, vector<OrderByNode> orders_p)
    : RRelation(child_p->context, RRelationKind::ORDER_RELATION), orders(std::move(orders_p)),
      child(std::move(child_p)) {
	D_ASSERT(child.get() != this);
	BindColumns(columns);
}

unique_ptr<QueryNode> ROrderRelation::GetQueryNode() {
	auto select = make_uniq<SelectNode>();
	select->from_table = child->GetTableRef();
	select->select_list.push_back(make_uniq<StarExpression>());
	auto order_node = make_uniq<OrderModifier>();
	for (idx_t i = 0; i < orders.size(); i++) {
		order_node->orders.emplace_back(orders[i].type, orders[i].null_order, orders[i].expression->Copy());
	}
	select->modifiers.push_back(std::move(order_node));
	return std::move(select);
}

Identifier ROrderRelation::GetAlias() {
	return child->GetAlias();
}

const vector<ColumnDefinition> &ROrderRelation::Columns() {
	return columns;
}

string ROrderRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth) + "Order [";
	for (idx_t i = 0; i < orders.size(); i++) {
		if (i != 0) {
			str += ", ";
		}
		str += orders[i].expression->ToString() + (orders[i].type == OrderType::ASCENDING ? " ASC" : " DESC");
	}
	str += "]\n";
	return str + child->ToString(depth + 1);
}

RJoinRelation::RJoinRelation(shared_ptr<RRelation> left_p, shared_ptr<RRelation> right_p,
                             unique_ptr<ParsedExpression> condition_p, JoinType type, JoinRefType join_ref_type_p)
    : RRelation(left_p->context, RRelationKind::JOIN_RELATION), left(std::move(left_p)), right(std::move(right_p)),
      condition(std::move(condition_p)), join_type(type), join_ref_type(join_ref_type_p) {
	if (left->GetContext() != right->GetContext()) {
		throw InvalidInputException("Cannot combine LEFT and RIGHT relations of different connections!");
	}
	BindColumns(columns);
}

unique_ptr<QueryNode> RJoinRelation::GetQueryNode() {
	auto result = make_uniq<SelectNode>();
	result->select_list.push_back(make_uniq<StarExpression>());
	result->from_table = GetTableRef();
	return std::move(result);
}

unique_ptr<TableRef> RJoinRelation::GetTableRef() {
	auto join_ref = make_uniq<JoinRef>(join_ref_type);
	join_ref->left = left->GetTableRef();
	join_ref->right = right->GetTableRef();
	if (condition) {
		join_ref->condition = condition->Copy();
	}
	join_ref->type = join_type;
	return std::move(join_ref);
}

const vector<ColumnDefinition> &RJoinRelation::Columns() {
	return columns;
}

string RJoinRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth);
	str += "Join " + EnumUtil::ToString(join_ref_type) + " " + EnumUtil::ToString(join_type);
	if (condition) {
		str += " " + condition->GetName();
	}

	return str + "\n" + left->ToString(depth + 1) + "\n" + right->ToString(depth + 1);
}

RCrossProductRelation::RCrossProductRelation(shared_ptr<RRelation> left_p, shared_ptr<RRelation> right_p,
                                             JoinRefType ref_type_p)
    : RRelation(left_p->context, RRelationKind::CROSS_PRODUCT_RELATION), left(std::move(left_p)),
      right(std::move(right_p)), ref_type(ref_type_p) {
	if (left->GetContext() != right->GetContext()) {
		throw InvalidInputException("Cannot combine LEFT and RIGHT relations of different connections!");
	}
	BindColumns(columns);
}

unique_ptr<QueryNode> RCrossProductRelation::GetQueryNode() {
	auto result = make_uniq<SelectNode>();
	result->select_list.push_back(make_uniq<StarExpression>());
	result->from_table = GetTableRef();
	return std::move(result);
}

unique_ptr<TableRef> RCrossProductRelation::GetTableRef() {
	auto cross_product_ref = make_uniq<JoinRef>(ref_type);
	cross_product_ref->left = left->GetTableRef();
	cross_product_ref->right = right->GetTableRef();
	return std::move(cross_product_ref);
}

const vector<ColumnDefinition> &RCrossProductRelation::Columns() {
	return columns;
}

string RCrossProductRelation::ToString(idx_t depth) {
	string str = "Cross Product";
	return str + "\n" + left->ToString(depth + 1) + right->ToString(depth + 1);
}

RSetOpRelation::RSetOpRelation(shared_ptr<RRelation> left_p, shared_ptr<RRelation> right_p,
                               SetOperationType setop_type_p, bool setop_all_p)
    : RRelation(left_p->context, RRelationKind::SET_OPERATION_RELATION), left(std::move(left_p)),
      right(std::move(right_p)), setop_type(setop_type_p), setop_all(setop_all_p) {
	if (left->GetContext() != right->GetContext()) {
		throw InvalidInputException("Cannot combine LEFT and RIGHT relations of different connections!");
	}
	BindColumns(columns);
}

unique_ptr<QueryNode> RSetOpRelation::GetQueryNode() {
	auto result = make_uniq<SetOperationNode>();
	if (!setop_all) {
		result->modifiers.push_back(make_uniq<DistinctModifier>());
	}
	result->children.push_back(left->GetQueryNode());
	result->children.push_back(right->GetQueryNode());
	result->setop_type = setop_type;
	result->setop_all = setop_all;
	return std::move(result);
}

Identifier RSetOpRelation::GetAlias() {
	return left->GetAlias();
}

const vector<ColumnDefinition> &RSetOpRelation::Columns() {
	return columns;
}

string RSetOpRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth);
	switch (setop_type) {
	case SetOperationType::UNION:
		str += "Union";
		break;
	case SetOperationType::EXCEPT:
		str += "Except";
		break;
	case SetOperationType::INTERSECT:
		str += "Intersect";
		break;
	default:
		throw InternalException("Unknown setop type");
	}
	return str + "\n" + left->ToString(depth + 1) + right->ToString(depth + 1);
}

RLimitRelation::RLimitRelation(shared_ptr<RRelation> child_p, int64_t limit_p, int64_t offset_p)
    : RRelation(child_p->context, RRelationKind::LIMIT_RELATION), limit(limit_p), offset(offset_p),
      child(std::move(child_p)) {
	D_ASSERT(child.get() != this);
}

unique_ptr<QueryNode> RLimitRelation::GetQueryNode() {
	auto child_node = child->GetQueryNode();
	auto limit_node = make_uniq<LimitModifier>();
	if (limit >= 0) {
		limit_node->limit = ConstantExpression::Integer(limit);
	}
	if (offset > 0) {
		limit_node->offset = ConstantExpression::Integer(offset);
	}

	child_node->modifiers.push_back(std::move(limit_node));
	return child_node;
}

Identifier RLimitRelation::GetAlias() {
	return child->GetAlias();
}

const vector<ColumnDefinition> &RLimitRelation::Columns() {
	return child->Columns();
}

string RLimitRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth) + "Limit " + to_string(limit);
	if (offset > 0) {
		str += " Offset " + to_string(offset);
	}
	str += "\n";
	return str + child->ToString(depth + 1);
}

RDistinctRelation::RDistinctRelation(shared_ptr<RRelation> child_p)
    : RRelation(child_p->context, RRelationKind::DISTINCT_RELATION), child(std::move(child_p)) {
	D_ASSERT(child.get() != this);
	vector<ColumnDefinition> dummy_columns;
	BindColumns(dummy_columns);
}

unique_ptr<QueryNode> RDistinctRelation::GetQueryNode() {
	auto child_node = child->GetQueryNode();
	child_node->AddDistinct();
	return child_node;
}

Identifier RDistinctRelation::GetAlias() {
	return child->GetAlias();
}

const vector<ColumnDefinition> &RDistinctRelation::Columns() {
	return child->Columns();
}

string RDistinctRelation::ToString(idx_t depth) {
	string str = RenderWhitespace(depth) + "Distinct\n";
	return str + child->ToString(depth + 1);
}

} // namespace duckdb
