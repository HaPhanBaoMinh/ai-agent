# AI Agent GitOps Platform

GitOps repository for deploying local AI agent infrastructure into Minikube.

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

Codex CLI and Cursor run locally. The cluster hosts router, context, and local model-serving infrastructure.

## Cluster Scope

The only allowed Kubernetes target is local Minikube on host `10.50.1.20`.

- Workload namespace: `ai-platform`
- Argo CD namespace: `argocd`
- Do not act on any other cluster.
- Do not switch Kubernetes contexts unless explicitly instructed.

Before any Kubernetes write command:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

If the context or node/IP output is not clearly the intended Minikube target, stop.

## GitOps-First Policy

All desired state lives in this repository. Update code first, then sync through Argo CD.

Avoid workload drift:

- Do not use `kubectl edit` for workload/config changes.
- Do not use ad hoc `kubectl patch` for workload/config changes.
- Do not use manual `helm upgrade --set` changes.
- If a bootstrap/manual change is required, document it and codify desired state immediately.

## Helm-First Design

Components live under `charts/`. Minikube-specific configuration lives in `values-minikube.yaml`.

Public charts are wrapped locally when suitable. Custom components use local charts. Argo CD syncs local chart paths.

## Prerequisites

- Docker
- kubectl
- minikube
- helm
- optional argocd CLI
- Python 3.12 or a virtual environment for local seeding
- uv/uvx for local Qdrant MCP stdio/SSE workflows

## Quick Start

Argo CD manifests are configured to use `https://github.com/HaPhanBaoMinh/ai-agent.git` on branch `main`.

```bash
make minikube-start
make verify-cluster
make argocd-install
make helm-deps
make helm-lint
make helm-template
make deploy
make status
make port-forward-9router
make port-forward-qdrant
```

## Helm Chart Decision Log

| Component | Deployment method | Public chart used | Chart repo | Chart name | Chart version | Reason |
|---|---|---|---|---|---|---|
| qdrant | Wrapper Helm chart | Yes | `https://qdrant.github.io/qdrant-helm` | `qdrant` | `1.17.1` | Official chart exists and supports Kubernetes persistence/resources for the vector database. |
| 9router | Custom local Helm chart | No | N/A | N/A | N/A | Docker image and port/data layout are documented, but no reliable public Helm chart was found. |
| qdrant-mcp | Custom local Helm chart, disabled by default | No | N/A | N/A | N/A | Official MCP server supports stdio, SSE, and streamable HTTP; chart uses a local image build to avoid assuming a registry image. |
| context-seeder | Custom local Helm chart, disabled by default | No | N/A | N/A | N/A | Project-specific idempotent seeding job. Local seeding is usually simpler for development. |
| ollama | Custom local Helm chart | No | N/A | N/A | N/A | CPU-first single-node local model hosting in Minikube. |
| ollama-models | Custom local Helm chart | No | N/A | N/A | N/A | Argo CD managed Job pulls default local models after Ollama is available. |
| 9router-config | Custom local Helm chart | No | N/A | N/A | N/A | Argo CD managed Job seeds 9Router provider settings from Git without committing real API keys. |

## Secrets

Do not commit real secrets.

Create local 9Router secrets manually if API key enforcement is enabled:

```bash
kubectl -n ai-platform create secret generic 9router-secret \
  --from-literal=API_KEY='replace-me'
```

Create optional provider API key secrets before enabling hosted providers in `charts/9router-config/values-minikube.yaml`:

```bash
kubectl -n ai-platform create secret generic 9router-provider-secrets \
  --from-literal=GEMINI_API_KEY='replace-me' \
  --from-literal=OPENROUTER_API_KEY='replace-me' \
  --from-literal=OPENAI_API_KEY='replace-me' \
  --from-literal=GROQ_API_KEY='replace-me'
```

If the 9Router dashboard password is changed from the local default, create the admin password secret and set `auth.existingSecret: 9router-config-secret` in `charts/9router-config/values-minikube.yaml`:

```bash
kubectl -n ai-platform create secret generic 9router-config-secret \
  --from-literal=ADMIN_PASSWORD='replace-me'
```

## Helm Commands

```bash
helm dependency update charts/qdrant
helm template qdrant charts/qdrant -f charts/qdrant/values-minikube.yaml
helm template 9router charts/9router -f charts/9router/values-minikube.yaml
helm template qdrant-mcp charts/qdrant-mcp -f charts/qdrant-mcp/values-minikube.yaml
helm template context-seeder charts/context-seeder -f charts/context-seeder/values-minikube.yaml
helm template ollama-qwen-coder charts/ollama -f charts/ollama/values-qwen-coder.yaml
helm template ollama-deepseek-r1 charts/ollama -f charts/ollama/values-deepseek-r1.yaml
helm template ollama-gemma3 charts/ollama -f charts/ollama/values-gemma3.yaml
helm template ollama-models-qwen-coder charts/ollama-models -f charts/ollama-models/values-qwen-coder.yaml
helm template 9router-config charts/9router-config -f charts/9router-config/values-minikube.yaml
helm lint charts/qdrant
helm lint charts/9router
helm lint charts/qdrant-mcp
helm lint charts/context-seeder
helm lint charts/ollama
helm lint charts/ollama-models
helm lint charts/9router-config
```

## Local Image Builds

Qdrant MCP and context-seeder charts are disabled by default and use local images if enabled. Ollama uses the public `ollama/ollama` image and is enabled by default for CPU-first local model hosting.

```bash
make build-qdrant-mcp-image
make build-context-seeder-image
```

## Connect Codex CLI To 9Router

```bash
make port-forward-9router
export OPENAI_BASE_URL="http://127.0.0.1:20128"
export OPENAI_API_KEY="<9router-api-key>"
codex
```

If the client expects the versioned API base:

```bash
export OPENAI_BASE_URL="http://127.0.0.1:20128/v1"
```

## Connect Codex CLI To MCP/Qdrant

Local stdio mode:

```bash
make port-forward-qdrant
```

`~/.codex/config.toml`:

```toml
[mcp_servers.qdrant_context]
command = "uvx"
args = ["mcp-server-qdrant"]

[mcp_servers.qdrant_context.env]
QDRANT_URL = "http://127.0.0.1:6333"
COLLECTION_NAME = "project-context"
EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
```

SSE mode for clients that support remote MCP:

```bash
QDRANT_URL="http://127.0.0.1:6333" \
COLLECTION_NAME="project-context" \
EMBEDDING_MODEL="sentence-transformers/all-MiniLM-L6-v2" \
uvx mcp-server-qdrant --transport sse
```

Client URL:

```txt
http://127.0.0.1:8000/sse
```

## Connect Cursor

- 9Router base URL: `http://127.0.0.1:20128/v1`
- MCP SSE URL when running local SSE: `http://127.0.0.1:8000/sse`
- Cursor rules should reference `AGENTS.md` and `context/*.md`.

## Local Ollama Models

This repository runs model-scoped Ollama instances inside Minikube using CPU-first defaults. The active service is internal only:

```txt
http://ollama-qwen-coder.ai-platform.svc.cluster.local:11434
```

Local access to the active instance:

```bash
make port-forward-ollama
make test-ollama
make status-models
```

Configured local model instances:

| Instance | Model | Replicas | Service |
|---|---|---:|---|
| `ollama-qwen-coder` | `qwen2.5-coder:7b` | 1 | `ollama-qwen-coder:11434` |
| `ollama-deepseek-r1` | `deepseek-r1:8b` | 0 | `ollama-deepseek-r1:11434` |
| `ollama-gemma3` | `gemma3:4b` | 0 | `ollama-gemma3:11434` |

Only `qwen2.5-coder:7b` is pulled by default. Scale another model by changing its `replicaCount` in the matching `charts/ollama/values-*.yaml`, adding or enabling a matching `ollama-models` value/app, committing, pushing, and letting Argo CD sync.

To pull another model manually after Ollama is running:

```bash
MODEL=gemma3:12b make pull-local-model
```

CPU-only inference is useful but slower than GPU. Keep larger 14B/32B models opt-in until Kubernetes exposes GPU resources.

## 9Router Config As Code

`charts/9router-config` seeds 9Router through its management API. It is managed by the Argo CD app `9router-config`.

Default Minikube config creates the `ollama-local` provider and points it at:

```txt
http://ollama-qwen-coder.ai-platform.svc.cluster.local:11434
```

Hosted providers are defined but disabled by default. To enable Gemini/OpenRouter/OpenAI/Groq, create `9router-provider-secrets`, change the provider entry to `enabled: true`, commit, push, and let Argo CD sync. Do not configure providers manually in the UI unless the same desired state is added to Git.

9Router stores UI changes in its PVC, so normal pod restarts do not erase UI settings. The GitOps seed Job prevents important provider config from depending on UI-only state.

## Free And Existing Providers

Recommended provider order for this local platform:

- Local Ollama for private/offline and cheap tasks.
- Gemini API free/paid key from Google AI Studio for Gemini models.
- OpenRouter `:free` models for broad free-provider experiments.
- Groq free plan for fast hosted open models within free quotas.
- Kiro when you create its key/provider entry.

ChatGPT Plus is useful in the ChatGPT app, but OpenAI API usage is billed separately and is not included in ChatGPT Plus.

## Seed Context

Local mode:

```bash
make port-forward-qdrant
python3 -m venv .venv
. .venv/bin/activate
pip install fastembed qdrant-client
make seed-context-local
```

The seeder upserts stable IDs derived from source file, title, and content hash.

## Tests

```bash
make verify-cluster
make helm-deps
make helm-lint
make helm-template
kubectl get ns ai-platform
kubectl -n argocd get applications
kubectl -n ai-platform get pods
make port-forward-qdrant
make test-qdrant
make port-forward-9router
make test-9router
```

For idempotency, run `make seed-context-local` twice and confirm the Qdrant collection count does not grow due to duplicate IDs.

## Operations

See:

- `docs/architecture.md`
- `docs/operations.md`
- `docs/troubleshooting.md`

GitOps-first policy is enforced by `context/AGENTS.md`, this README, and `make deploy` depending on `make verify-cluster`.
