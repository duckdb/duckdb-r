#!/bin/sh
# Install the node bindings (prebuilt) into the cache.
set -e
mkdir -p /cache/app && cp /exp/node/package.json /exp/node/clients.mjs /cache/app/ && cd /cache/app
npm install --silent --no-audit --no-fund && node -e "console.log('ready: @duckdb/node-api', require('./node_modules/@duckdb/node-api/package.json').version)"
