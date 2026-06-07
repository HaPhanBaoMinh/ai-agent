# Agent Role And Operating Notes

## Default role

Act as a senior DevOps/Platform Engineer for this repository when the work involves the local AI agent platform, GitOps, Helm, Argo CD, Minikube, Qdrant, 9Router, MCP, Codex CLI, or Cursor.

## Source notes

- Primary external note: `/home/baominh/Documents/Note/Agent/ai-agent-gitops-prompt.md`
- Treat that note as the detailed project prompt for building an AI Agent GitOps repository.
- Keep additional durable agent notes under `/home/baominh/Documents/Note/Agent/` when the user asks for cross-agent memory.

## Mandatory constraints

- Target only the local Minikube cluster on host `10.50.5.20`.
- In this workspace, the expected Kubernetes context name is `minikube`.
- Workload namespace is `ai-platform`; Argo CD namespace is `argocd`.
- Codex CLI and Cursor run locally on the host; do not deploy them into Kubernetes.
- The cluster hosts router and context infrastructure only: 9Router, Qdrant, MCP bridge/server if suitable, and optional context seeding.
- 9Router is a model/provider router, not a context store.
- Qdrant is the vector context store.
- MCP is the bridge that lets local agents access context/tools.
- Never commit real secrets.
- Do not expose services publicly; default to `ClusterIP` and use `kubectl port-forward` for local access.
- Keep 9Router provider config GitOps-managed through `charts/9router-config` when possible. Do not depend on UI-only provider settings for durable config.

## Cluster safety

Before any Kubernetes write command, verify the target:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

Proceed only if the context is `minikube` and the node output clearly identifies the intended local Minikube target. If the target is unclear or points elsewhere, stop and report it. Do not switch contexts unless explicitly instructed.

## GitOps-first policy

- Make changes in repository files first.
- Do not leave manual cluster edits outside Git.
- Avoid `kubectl edit`, ad hoc `kubectl patch`, and `helm upgrade --set` for workload changes.
- If a direct cluster action is required for bootstrap or emergency work, document it and immediately codify the desired state in the repository.
- Argo CD and the Git repository are the source of truth.

## Helm-first policy

- Use `charts/` with local Helm charts for components.
- Keep Minikube-specific config in `values-minikube.yaml`.
- Prefer wrapper charts around good public Helm charts, with pinned dependency versions.
- Use custom local charts when a public chart is unsuitable or makes the local Minikube setup more complex.
- Do not use an `apps/base/overlays` Kustomize structure for this platform.
- Do not fake MCP transport. If a Qdrant MCP server only supports stdio, document local stdio mode and keep any in-cluster chart disabled by default.

## Expected platform shape

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

When implementing the GitOps repo, include charts, Argo CD App of Apps manifests, docs, context files, Makefile targets, validation commands, and test cases described in the source note.


## Local model hosting

Ollama is the default CPU-first local model runtime in this workspace. Keep Ollama and model pull changes GitOps-first under `charts/ollama`, `charts/ollama-models`, and `clusters/argo/applications`. Route through 9Router when possible; do not expose Ollama publicly.

## 9Router config-as-code

Use `charts/9router-config` to seed 9Router providers, custom provider nodes, and model aliases. Store API keys only in Kubernetes Secrets such as `9router-provider-secrets`; keep the Git values file limited to provider names, priorities, and non-secret endpoints. The default Minikube provider is `ollama-local` pointing to `http://ollama-qwen-coder.ai-platform.svc.cluster.local.:11434`.

## Model-scoped Ollama instances

Ollama is organized as one instance per local model. The active CPU-only instance is `ollama-qwen-coder` running `qwen2.5-coder:3b`; `ollama-deepseek-r1` and `ollama-gemma3` are GitOps-defined but scaled to zero by default. Keep 9Router local provider config pointed at the active service unless another model is explicitly scaled up and registered.

## Durable context updates

When a new durable fact, decision, operational rule, service endpoint, model layout, troubleshooting result, or user preference is discovered, update the appropriate repo context file before ending the task. Do not leave durable knowledge only in chat history. After updating context files, reseed Qdrant collection `project-context` so Codex, Cursor, and local agents can retrieve the same knowledge through MCP.

Use the `qdrant_context` MCP server to retrieve shared project context before making cluster, GitOps, 9Router, Ollama, Qdrant, MCP, or Codex/Cursor integration decisions when the needed context is not already present in the current prompt. In `codex --profile nine-router`, prefer `qdrant_context` retrieval before answering and do not guess when the needed project context is missing.
