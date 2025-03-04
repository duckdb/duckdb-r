//===----------------------------------------------------------------------===//
// This file is automatically generated by scripts/generate_serialization.py
// Do not edit this file manually, your changes will be overwritten
//===----------------------------------------------------------------------===//

#include "duckdb/common/serializer/serializer.hpp"
#include "duckdb/common/serializer/deserializer.hpp"
#include "duckdb/parser/query_node/list.hpp"

namespace duckdb {

void QueryNode::Serialize(Serializer &serializer) const {
	serializer.WriteProperty<QueryNodeType>(100, "type", type);
	serializer.WritePropertyWithDefault<vector<unique_ptr<ResultModifier>>>(101, "modifiers", modifiers);
	serializer.WriteProperty<CommonTableExpressionMap>(102, "cte_map", cte_map);
}

unique_ptr<QueryNode> QueryNode::Deserialize(Deserializer &deserializer) {
	auto type = deserializer.ReadProperty<QueryNodeType>(100, "type");
	auto modifiers = deserializer.ReadPropertyWithDefault<vector<unique_ptr<ResultModifier>>>(101, "modifiers");
	auto cte_map = deserializer.ReadProperty<CommonTableExpressionMap>(102, "cte_map");
	unique_ptr<QueryNode> result;
	switch (type) {
	case QueryNodeType::CTE_NODE:
		result = CTENode::Deserialize(deserializer);
		break;
	case QueryNodeType::RECURSIVE_CTE_NODE:
		result = RecursiveCTENode::Deserialize(deserializer);
		break;
	case QueryNodeType::SELECT_NODE:
		result = SelectNode::Deserialize(deserializer);
		break;
	case QueryNodeType::SET_OPERATION_NODE:
		result = SetOperationNode::Deserialize(deserializer);
		break;
	default:
		throw SerializationException("Unsupported type for deserialization of QueryNode!");
	}
	result->modifiers = std::move(modifiers);
	result->cte_map = std::move(cte_map);
	return result;
}

void CTENode::Serialize(Serializer &serializer) const {
	QueryNode::Serialize(serializer);
	serializer.WritePropertyWithDefault<string>(200, "cte_name", ctename);
	serializer.WritePropertyWithDefault<unique_ptr<QueryNode>>(201, "query", query);
	serializer.WritePropertyWithDefault<unique_ptr<QueryNode>>(202, "child", child);
	serializer.WritePropertyWithDefault<vector<string>>(203, "aliases", aliases);
}

unique_ptr<QueryNode> CTENode::Deserialize(Deserializer &deserializer) {
	auto result = duckdb::unique_ptr<CTENode>(new CTENode());
	deserializer.ReadPropertyWithDefault<string>(200, "cte_name", result->ctename);
	deserializer.ReadPropertyWithDefault<unique_ptr<QueryNode>>(201, "query", result->query);
	deserializer.ReadPropertyWithDefault<unique_ptr<QueryNode>>(202, "child", result->child);
	deserializer.ReadPropertyWithDefault<vector<string>>(203, "aliases", result->aliases);
	return std::move(result);
}

void RecursiveCTENode::Serialize(Serializer &serializer) const {
	QueryNode::Serialize(serializer);
	serializer.WritePropertyWithDefault<string>(200, "cte_name", ctename);
	serializer.WritePropertyWithDefault<bool>(201, "union_all", union_all, false);
	serializer.WritePropertyWithDefault<unique_ptr<QueryNode>>(202, "left", left);
	serializer.WritePropertyWithDefault<unique_ptr<QueryNode>>(203, "right", right);
	serializer.WritePropertyWithDefault<vector<string>>(204, "aliases", aliases);
	serializer.WritePropertyWithDefault<vector<unique_ptr<ParsedExpression>>>(205, "key_targets", key_targets);
}

unique_ptr<QueryNode> RecursiveCTENode::Deserialize(Deserializer &deserializer) {
	auto result = duckdb::unique_ptr<RecursiveCTENode>(new RecursiveCTENode());
	deserializer.ReadPropertyWithDefault<string>(200, "cte_name", result->ctename);
	deserializer.ReadPropertyWithExplicitDefault<bool>(201, "union_all", result->union_all, false);
	deserializer.ReadPropertyWithDefault<unique_ptr<QueryNode>>(202, "left", result->left);
	deserializer.ReadPropertyWithDefault<unique_ptr<QueryNode>>(203, "right", result->right);
	deserializer.ReadPropertyWithDefault<vector<string>>(204, "aliases", result->aliases);
	deserializer.ReadPropertyWithDefault<vector<unique_ptr<ParsedExpression>>>(205, "key_targets", result->key_targets);
	return std::move(result);
}

void SelectNode::Serialize(Serializer &serializer) const {
	QueryNode::Serialize(serializer);
	serializer.WritePropertyWithDefault<vector<unique_ptr<ParsedExpression>>>(200, "select_list", select_list);
	serializer.WritePropertyWithDefault<unique_ptr<TableRef>>(201, "from_table", from_table);
	serializer.WritePropertyWithDefault<unique_ptr<ParsedExpression>>(202, "where_clause", where_clause);
	serializer.WritePropertyWithDefault<vector<unique_ptr<ParsedExpression>>>(203, "group_expressions", groups.group_expressions);
	serializer.WritePropertyWithDefault<vector<GroupingSet>>(204, "group_sets", groups.grouping_sets);
	serializer.WriteProperty<AggregateHandling>(205, "aggregate_handling", aggregate_handling);
	serializer.WritePropertyWithDefault<unique_ptr<ParsedExpression>>(206, "having", having);
	serializer.WritePropertyWithDefault<unique_ptr<SampleOptions>>(207, "sample", sample);
	serializer.WritePropertyWithDefault<unique_ptr<ParsedExpression>>(208, "qualify", qualify);
}

unique_ptr<QueryNode> SelectNode::Deserialize(Deserializer &deserializer) {
	auto result = duckdb::unique_ptr<SelectNode>(new SelectNode());
	deserializer.ReadPropertyWithDefault<vector<unique_ptr<ParsedExpression>>>(200, "select_list", result->select_list);
	deserializer.ReadPropertyWithDefault<unique_ptr<TableRef>>(201, "from_table", result->from_table);
	deserializer.ReadPropertyWithDefault<unique_ptr<ParsedExpression>>(202, "where_clause", result->where_clause);
	deserializer.ReadPropertyWithDefault<vector<unique_ptr<ParsedExpression>>>(203, "group_expressions", result->groups.group_expressions);
	deserializer.ReadPropertyWithDefault<vector<GroupingSet>>(204, "group_sets", result->groups.grouping_sets);
	deserializer.ReadProperty<AggregateHandling>(205, "aggregate_handling", result->aggregate_handling);
	deserializer.ReadPropertyWithDefault<unique_ptr<ParsedExpression>>(206, "having", result->having);
	deserializer.ReadPropertyWithDefault<unique_ptr<SampleOptions>>(207, "sample", result->sample);
	deserializer.ReadPropertyWithDefault<unique_ptr<ParsedExpression>>(208, "qualify", result->qualify);
	return std::move(result);
}

void SetOperationNode::Serialize(Serializer &serializer) const {
	QueryNode::Serialize(serializer);
	serializer.WriteProperty<SetOperationType>(200, "setop_type", setop_type);
	serializer.WritePropertyWithDefault<unique_ptr<QueryNode>>(201, "left", left);
	serializer.WritePropertyWithDefault<unique_ptr<QueryNode>>(202, "right", right);
	serializer.WritePropertyWithDefault<bool>(203, "setop_all", setop_all, true);
	serializer.WritePropertyWithDefault<vector<unique_ptr<QueryNode>>>(204, "children", SerializeChildNodes());
}

unique_ptr<QueryNode> SetOperationNode::Deserialize(Deserializer &deserializer) {
	auto setop_type = deserializer.ReadProperty<SetOperationType>(200, "setop_type");
	auto left = deserializer.ReadPropertyWithDefault<unique_ptr<QueryNode>>(201, "left");
	auto right = deserializer.ReadPropertyWithDefault<unique_ptr<QueryNode>>(202, "right");
	auto setop_all = deserializer.ReadPropertyWithExplicitDefault<bool>(203, "setop_all", true);
	auto children = deserializer.ReadPropertyWithDefault<vector<unique_ptr<QueryNode>>>(204, "children");
	auto result = duckdb::unique_ptr<SetOperationNode>(new SetOperationNode(setop_type, std::move(left), std::move(right), std::move(children), setop_all));
	return std::move(result);
}

} // namespace duckdb
