# Architecture

```txt
Codex CLI / Cursor
    -> MCP
Qdrant MCP
    -> Qdrant

Codex CLI / Cursor
    -> OpenAI-compatible API
9Router
    -> model providers
```

Codex CLI and Cursor run locally. Kubernetes hosts only infrastructure that is useful to local agents: 9Router, Qdrant, optional Qdrant MCP, and optional context seeding.

9Router routes model/provider traffic. It is not a semantic memory store.

Qdrant stores vectorized project context. It runs with persistent storage on Minikube.

MCP is the bridge that exposes Qdrant-backed tools to local agent clients.

The repository is Helm-first. Components live under `charts/` because chart values provide a single, explicit configuration surface for local Minikube. Kustomize overlays are intentionally not used.

Argo CD reconciles the desired state from Git. Manual cluster changes must not remain as drift.

The only Kubernetes target is Minikube on `10.50.1.20`.
