#!/bin/sh
# Compile the bundled engine and the binary into the cache (the long step).
set -e
apt-get update -qq && apt-get install -y -qq --no-install-recommends build-essential > /dev/null
mkdir -p /cache/src && cp -r /exp/rust/. /cache/src/ && cd /cache/src
CARGO_TARGET_DIR=/cache/target cargo build --release --quiet && cp /cache/target/release/memclients /cache/memclients
grep -A1 'name = "duckdb"' /cache/src/Cargo.lock | head -2; echo "ready: /cache/memclients"
