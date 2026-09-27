#!/bin/sh
set -e
mkdir -p /cache/app && cp /exp/node/package.json /cache/app/ && cd /cache/app
npm install --silent --no-audit --no-fund && node -e "console.log('ready: @duckdb/node-api', require('./node_modules/@duckdb/node-api/package.json').version)"
