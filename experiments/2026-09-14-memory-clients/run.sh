#!/bin/sh
# Runner: `./run.sh prepare <lang>` installs a language's dependencies into cache/<lang>,
# `./run.sh run <lang> <image-label> <scenario...>` runs each scenario in a fresh container.
# Proxy: honours HTTPS_PROXY and, when CA_BUNDLE points at a file, mounts it as /ca.crt for every tool.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
CACHE=${CACHE:-$HERE/../../.cache-memory-clients}
cmd=$1; lang=$2; shift 2
image_for() {
  case "$1" in
    dev)  echo ghcr.io/cynkra/docker-images/rig-ubuntu-duckdb-dev:latest ;;
    cran) echo ghcr.io/cynkra/docker-images/p3m-noble-duckdb:latest ;;
    python312) echo python:3.12-slim ;;
    julia111) echo julia:1.11 ;;
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
    for v in SSL_CERT_FILE CURL_CA_BUNDLE REQUESTS_CA_BUNDLE PIP_CERT CARGO_HTTP_CAINFO GIT_SSL_CAINFO NODE_EXTRA_CA_CERTS JULIA_SSL_CA_ROOTS_PATH; do a="$a -e $v=/ca.crt"; done
  fi
  echo "$a"
}
run() { # $1 image-label, rest: command
  label=$1; shift
  mkdir -p "$CACHE/$lang"
  sudo docker run --rm $(proxy_args) -v "$HERE:/exp:ro" -v "$CACHE/$lang:/cache" -w /tmp "$(image_for "$label")" "$@"
}
case "$cmd" in
  prepare)
    case "$lang" in
      r)      for label in dev cran; do mkdir -p "$CACHE/$lang-$label"; lang="$lang-$label" run "$label" Rscript /exp/r/prepare.R; done ;;
      python) run python312 sh /exp/python/prepare.sh ;;
      go)     run go125 env GOMODCACHE=/cache/mod GOCACHE=/cache/build GOFLAGS=-mod=mod sh /exp/go/prepare.sh ;;
      rust)   run rust env CARGO_HOME=/cache/cargo sh /exp/rust/prepare.sh ;;
      node)   run node22 env npm_config_cache=/cache/npm sh /exp/node/prepare.sh ;;
      julia)  run julia111 env JULIA_DEPOT_PATH=/cache/depot julia /exp/julia/prepare.jl ;;
    esac ;;
  run)
    label=$1; shift
    for s in "$@"; do
      case "$lang" in
        r)        lang="r-$label" run "$label" env R_LIBS=/cache/rlib Rscript /exp/r/clients.R "$label" "$s"; lang=r ;;
        findings) lang="r-$label" run "$label" env R_LIBS=/cache/rlib Rscript /exp/r/findings.R "$label" "$s"; lang=findings ;;
        python)   run python312 env PYTHONPATH=/cache/site python /exp/python/clients.py "$label" "$s" ;;
        go)       run go125 /cache/memclients "$label" "$s" ;;
        rust)     run rust /cache/memclients "$label" "$s" ;;
        node)     run node22 node --max-old-space-size=8192 /cache/app/clients.mjs "$label" "$s" ;;
        julia)    run julia111 env JULIA_DEPOT_PATH=/cache/depot julia /exp/julia/clients.jl "$label" "$s" ;;
      esac
    done ;;
esac
