#!/bin/sh
# Runner: `./run.sh prepare <lang>` installs a language's client into cache/<lang> (and, for python, writes the
# shared source files under cache/shared); `./run.sh run <lang> <image-label> <target> <scenario...>` runs each
# scenario in a fresh container, target being `file` or `memory`. Honours HTTPS_PROXY and mounts CA_BUNDLE.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
CACHE=${CACHE:-$HERE/../../.cache-memory-ingest}
cmd=$1; lang=$2; shift 2
image_for() {
  case "$1" in
    dev)  echo ghcr.io/cynkra/docker-images/rig-ubuntu-duckdb-dev:latest ;;
    cran) echo ghcr.io/cynkra/docker-images/p3m-noble-duckdb:latest ;;
    python312) echo python:3.12-slim ;;
    go125) echo golang:1.25 ;;
    node22) echo node:22-slim ;;
    rust) echo rust:slim ;;
  esac
}
proxy_args() {
  a="--network host"
  [ -n "$HTTPS_PROXY" ] && a="$a -e HTTPS_PROXY=$HTTPS_PROXY -e NO_PROXY=localhost,127.0.0.1"
  if [ -n "$CA_BUNDLE" ] && [ -f "$CA_BUNDLE" ]; then
    a="$a -v $CA_BUNDLE:/ca.crt:ro"
    for v in SSL_CERT_FILE CURL_CA_BUNDLE REQUESTS_CA_BUNDLE PIP_CERT CARGO_HTTP_CAINFO GIT_SSL_CAINFO NODE_EXTRA_CA_CERTS; do a="$a -e $v=/ca.crt"; done
  fi
  echo "$a"
}
# ROWS scales the data (50 million rows are 800 MB) and reaches every script; MEMORY, when set, caps the
# container with a cgroup limit of that size and no swap, so a run that outgrows it is killed inside the
# container rather than by the host's OOM killer.
scale_args() {
  a=""
  [ -n "$ROWS" ] && a="$a -e ROWS=$ROWS"
  [ -n "$MEMORY" ] && a="$a --memory=$MEMORY --memory-swap=$MEMORY"
  [ -n "$NODE_HEAP_MB" ] && a="$a -e NODE_HEAP_MB=$NODE_HEAP_MB"
  echo "$a"
}
run() { # $1 image-label, rest: command
  label=$1; shift
  mkdir -p "$CACHE/$lang" "$CACHE/shared"
  sudo docker run --rm $(proxy_args) $(scale_args) -v "$HERE:/exp:ro" -v "$CACHE/$lang:/cache" -v "$CACHE/shared:/data" -w /tmp "$(image_for "$label")" "$@"
}
case "$cmd" in
  prepare)
    case "$lang" in
      r)      for label in dev cran; do lang="r-$label" run "$label" Rscript /exp/r/prepare.R; done ;;
      python) run python312 sh /exp/python/prepare.sh ;;
      go)     run go125 env GOMODCACHE=/cache/mod GOCACHE=/cache/build GOFLAGS=-mod=mod sh /exp/go/prepare.sh ;;
      rust)   run rust env CARGO_HOME=/cache/cargo sh /exp/rust/prepare.sh ;;
      node)   run node22 env npm_config_cache=/cache/npm sh /exp/node/prepare.sh ;;
    esac ;;
  run)
    label=$1; target=$2; shift 2
    for s in "$@"; do
      case "$lang" in
        r)      lang="r-$label" run "$label" env R_LIBS=/cache/rlib sh /exp/r/ingest.sh "$label" "$target" "$s"; lang=r ;;
        python) run python312 env PYTHONPATH=/cache/site sh /exp/python/ingest.sh "$label" "$target" "$s" ;;
        go)     run go125 sh /exp/go/ingest.sh "$label" "$target" "$s" ;;
        rust)   run rust sh /exp/rust/ingest.sh "$label" "$target" "$s" ;;
        node)   run node22 sh /exp/node/ingest.sh "$label" "$target" "$s" ;;
      esac
    done ;;
esac
