#!/bin/bash
# Usage: run-all.sh <lib> <template> [n]
# The main query n times (default 120), then the 11 variants 20 times each.
F=$(cd "$(dirname "$0")" && pwd); lib=$1; T=$2; N=${3:-120}
Q1="SELECT epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') + 2.5 AS x"
Q2="SELECT 2.5 + epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') AS x"
Q3="SELECT epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') - 2.5 AS x"
Q4="SELECT year(TIMESTAMPTZ '2001-09-09 01:46:40+00') + 2.5 AS x"
Q5="SELECT sum(epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00')) + 1 AS x"
Q6="SELECT max(epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00')) AS x"
Q7="SELECT count(*) AS x FROM range(epoch(TIMESTAMPTZ '1970-01-01 00:00:02+00')::BIGINT)"
Q8="SELECT list_sum(list_transform([1, 2], lambda x: x + epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00'))) AS x"
Q9="SELECT sum(epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00')) OVER () + 1 AS x"
Q10="SELECT strftime(date_trunc('day', TIMESTAMPTZ '2001-09-09 01:46:40+00') + INTERVAL 1 DAY, '%Y-%m-%d') AS x"
Q11="SELECT count(*) AS x FROM range(date_trunc('day', TIMESTAMPTZ '2001-09-09 01:46:40+00'), TIMESTAMPTZ '2001-09-10 00:00:00+00', INTERVAL 1 HOUR)"
Q12="WITH RECURSIVE t(k, v) USING KEY (k, max(epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00')) AS v) AS (SELECT 1, 0::DOUBLE UNION SELECT k, v + 1 FROM t WHERE v < 3) SELECT max(v) AS x FROM t"
"$F/run-many.sh" "$lib" "$T" "$N" q1 "$Q1"
for i in 2 3 4 5 6 7 8 9 10 11 12; do eval q=\$Q$i; "$F/run-many.sh" "$lib" "$T" 20 q$i "$q"; done
