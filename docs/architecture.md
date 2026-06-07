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

Codex CLI and Cursor run locally. Kubernetes hosts infrastructure useful to local agents: 9Router, Qdrant, optional Qdrant MCP, optional context seeding, and Ollama for local model serving.

9Router routes model/provider traffic. It is not a semantic memory store.

Qdrant stores vectorized project context. It runs with persistent storage on Minikube.

MCP is the bridge that exposes Qdrant-backed tools to local agent clients.

The repository is Helm-first. Components live under `charts/` because chart values provide a single, explicit configuration surface for local Minikube. Kustomize overlays are intentionally not used.

Argo CD reconciles the desired state from Git. Manual cluster changes must not remain as drift.

The only Kubernetes target is Minikube on `10.50.5.20`.


Ollama runs local open-weight models inside Minikube with CPU-first defaults and one instance per model. `ollama-qwen-coder` is active; `ollama-deepseek-r1` and `ollama-gemma3` are defined but scaled to zero. 9Router remains the main gateway for local, free, and paid providers.

`charts/9router-config` is the GitOps-owned 9Router configuration layer. It seeds durable provider settings through the 9Router management API while keeping actual API keys in Kubernetes Secrets.
