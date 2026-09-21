#!/bin/sh
# Resolve duckdb-go (prebuilt static libraries) and arrow-go, and build the binary with the Arrow route compiled in.
set -e
mkdir -p /cache/src && cp /exp/go/main.go /exp/go/go.mod /cache/src/ && cd /cache/src
go get github.com/duckdb/duckdb-go/v2@latest github.com/apache/arrow-go/v18@latest && go mod tidy && go build -tags=duckdb_arrow -o /cache/memingest .
grep -E "duckdb-go|arrow-go" go.mod; echo "ready: /cache/memingest"
