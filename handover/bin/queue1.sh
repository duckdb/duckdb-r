#!/bin/bash
B=/workspace/bin/bisect.sh
{ $B 1 variant test-variant.R; $B 405 relational; $B 653 'struct|factor'; $B 1033 'dbFetchArrow|fetch_arrow'; $B 1620 'dbFetchArrow|dbSendQueryArrow|to_arrow_stream'; $B 2149 multi_statement; echo QUEUE1 DONE; } >> /workspace/bisect.log 2>&1
