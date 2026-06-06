# Architecture

```txt
Codex CLI / Cursor
    -> MCP
Qdrant MCP
    -> Qdrant

Codex CLI / Cursor
    -> OpenAI-compatible API
9Router
    -> Kiro / OpenAI-compatible / Claude-compatible providers
```

Codex CLI and Cursor run locally on the host. Kubernetes hosts only router and context infrastructure.

9Router is responsible for routing model requests and provider fallback. It does not store semantic project context.

Qdrant stores vectorized project context. MCP exposes Qdrant-backed tools to local agents.

Argo CD syncs the desired state from this repository into Minikube.


Ollama hosts CPU-first local open-weight models in Kubernetes. The default local model set is qwen2.5-coder:7b, deepseek-r1:8b, and gemma3:4b. 9Router remains the primary gateway.
