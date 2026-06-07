#!/usr/bin/env bash
set -euo pipefail

MODEL_HOST="${MODEL_HOST:-10.50.5.20}"
LOCAL_9ROUTER_PORT="${LOCAL_9ROUTER_PORT:-20128}"
LOCAL_QDRANT_PORT="${LOCAL_QDRANT_PORT:-6333}"

REMOTE_COMMAND='
set -e
kubectl -n ai-platform port-forward --address 127.0.0.1 svc/nine-router 20128:20128 &
nine_router_pid=$!
kubectl -n ai-platform port-forward --address 127.0.0.1 svc/qdrant 6333:6333 &
qdrant_pid=$!
trap "kill $nine_router_pid $qdrant_pid 2>/dev/null || true" INT TERM EXIT
wait
'

ssh \
  -L "${LOCAL_9ROUTER_PORT}:127.0.0.1:20128" \
  -L "${LOCAL_QDRANT_PORT}:127.0.0.1:6333" \
  "$MODEL_HOST" \
  "$REMOTE_COMMAND"
