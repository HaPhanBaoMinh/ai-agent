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
