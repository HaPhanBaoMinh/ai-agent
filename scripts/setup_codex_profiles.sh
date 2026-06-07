#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
MODEL_HOST="${MODEL_HOST:-10.50.5.20}"
NINE_ROUTER_BASE_URL="${NINE_ROUTER_BASE_URL:-http://127.0.0.1:20128/v1}"
QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
QDRANT_COLLECTION="${QDRANT_COLLECTION:-project-context}"
QDRANT_EMBEDDING_MODEL="${QDRANT_EMBEDDING_MODEL:-sentence-transformers/all-MiniLM-L6-v2}"
CHATGPT_MODEL="${CHATGPT_MODEL:-gpt-5.5}"
NINE_ROUTER_MODEL="${NINE_ROUTER_MODEL:-ollama-local/gemma3:4b}"

mkdir -p "$CODEX_HOME"

UVX_COMMAND="$(command -v uvx || true)"
if [ -z "$UVX_COMMAND" ]; then
  echo "uvx is not installed. Installing uv user-level with pip."
  python3 -m pip install --user --break-system-packages uv
  hash -r
  UVX_COMMAND="$(command -v uvx || true)"
fi

if [ -z "$UVX_COMMAND" ] && [ -x "$HOME/.local/bin/uvx" ]; then
  UVX_COMMAND="$HOME/.local/bin/uvx"
fi

if [ -z "$UVX_COMMAND" ]; then
  echo "Could not find uvx after installing uv. Add ~/.local/bin to PATH or install uv manually." >&2
  exit 1
fi

cat > "$CODEX_HOME/chatgpt.config.toml" <<EOF
model = "$CHATGPT_MODEL"
model_provider = "openai"
EOF

cat > "$CODEX_HOME/nine-router.config.toml" <<EOF
model = "$NINE_ROUTER_MODEL"
model_provider = "nine_router"
model_context_window = 4096
model_auto_compact_token_limit = 3000
model_supports_reasoning_summaries = false

developer_instructions = """
You are in nine-router mode for the ai-agent GitOps workspace.
When the user asks about project facts, cluster facts, service endpoints, or shared memory, you must call qdrant_context to retrieve the relevant context before answering.
Do not answer from memory when the needed project fact is not already present in the prompt.
If retrieval is unavailable or returns no relevant context, say the context was not found rather than guessing.
Use the shared context files and Qdrant-backed MCP memory as the source of truth for workspace facts.
"""

[model_providers.nine_router]
name = "9Router"
base_url = "$NINE_ROUTER_BASE_URL"
wire_api = "responses"
EOF

CONFIG_FILE="$CODEX_HOME/config.toml"
touch "$CONFIG_FILE"

if ! grep -q '^\[mcp_servers\.qdrant_context\]' "$CONFIG_FILE"; then
  cat >> "$CONFIG_FILE" <<EOF

[mcp_servers.qdrant_context]
command = "$UVX_COMMAND"
args = ["mcp-server-qdrant"]

[mcp_servers.qdrant_context.env]
QDRANT_URL = "$QDRANT_URL"
COLLECTION_NAME = "$QDRANT_COLLECTION"
EMBEDDING_MODEL = "$QDRANT_EMBEDDING_MODEL"
EOF
else
  echo "qdrant_context MCP already exists in $CONFIG_FILE; leaving it unchanged."
fi

cat <<EOF
Codex profiles configured in $CODEX_HOME:

  codex --profile chatgpt
  codex --profile nine-router

For nine-router and qdrant_context MCP, expose remote services from the model host first:

  scripts/tunnel_agent_platform.sh

Or manually:

  ssh -L 20128:127.0.0.1:20128 -L 6333:127.0.0.1:6333 $MODEL_HOST \\
    'kubectl -n ai-platform port-forward --address 127.0.0.1 svc/nine-router 20128:20128 & kubectl -n ai-platform port-forward --address 127.0.0.1 svc/qdrant 6333:6333'
EOF
