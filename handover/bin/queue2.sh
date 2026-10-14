#!/bin/bash
B=/workspace/bin/bisect.sh
sleep 30
{ $B 653 'struct|factor'; $B 1033 'dbFetchArrow|fetch_arrow'; $B 1620 'dbFetchArrow|dbSendQueryArrow|to_arrow_stream'; $B 2149 multi_statement; echo QUEUE2 DONE; } >> /workspace/bisect.log 2>&1
