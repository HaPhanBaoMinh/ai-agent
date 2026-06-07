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

Codex CLI and Cursor run locally on the operator workstation. Kubernetes on host `10.50.5.20` hosts router, context, and local model infrastructure.

9Router is responsible for routing model requests and provider fallback. It does not store semantic project context.

Qdrant stores vectorized project context. MCP exposes Qdrant-backed tools to local agents.

Argo CD syncs the desired state from this repository into Minikube.


Ollama hosts CPU-first local open-weight models in Kubernetes. The active model-scoped instance is `ollama-gemma3` with `gemma3:4b`; `ollama-qwen-coder` and `ollama-deepseek-r1` are defined but scaled to zero. 9Router remains the primary gateway.
