#!/bin/sh

set -e
set -x

cd `dirname $0`

echo "R: configure"
python3 rconfigure.py
