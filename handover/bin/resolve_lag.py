#!/usr/bin/env python3
# Resolve the conflict over the lag()/lead() default block in src/relational.cpp: keep the fix, in the incoming API.
import re, sys
p = 'src/relational.cpp'
s = open(p).read()
m = re.search(r'<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n', s, re.S)
assert m, 'no conflict'
ours, theirs = m.group(1), m.group(2)
assert 'default_offset' in ours, 'unexpected ours'
push = [l for l in theirs.splitlines() if 'default_expr->Copy()' in l]
assert len(push) == 1, theirs
push = push[0]
const = 'ConstantExpression::FromValue(Value::BIGINT(1))' if 'ConstantExpression::FromValue' in s else 'make_uniq<ConstantExpression>(Value::BIGINT(1))'
offset_push = push.replace('default_expr->Copy()', const)
lead_lag = re.search(r'bool is_lead_lag = \((function\.[A-Za-z_]+(?:\(\))?) == "lead"', s)
name = lead_lag.group(1) if lead_lag else 'function.function_name'
block = f'''		// LEAD/LAG take the default as their third argument, so without an offset the default would be read as the
		// offset: the default offset of 1 goes first
		bool default_offset = {name} == "lead" || {name} == "lag";
		if (default_offset && !constant_expression_is_not_null(offset_expr)) {{
	{offset_push}
		}}
{push}
'''
s = s[:m.start()] + block + s[m.end():]
assert '<<<<<<<' not in s
open(p, 'w').write(s)
print('resolved with', push.strip(), '/', name)
