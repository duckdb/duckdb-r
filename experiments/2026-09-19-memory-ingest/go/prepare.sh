#!/bin/sh
# Resolve go-duckdb (prebuilt static libraries) and build the binary into the cache.
set -e
mkdir -p /cache/src && cp /exp/go/main.go /exp/go/go.mod /cache/src/ && cd /cache/src
go get github.com/marcboeker/go-duckdb/v2@latest && go mod tidy && go build -o /cache/memingest .
grep go-duckdb go.mod; echo "ready: /cache/memingest"
