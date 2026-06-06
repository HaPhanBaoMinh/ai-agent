---
name: ai-agent-gitops-platform
description: Use when creating, reviewing, or operating the local AI agent GitOps platform for Minikube on 10.50.1.20 with Helm-first charts, Argo CD App of Apps, 9Router, Qdrant, Qdrant MCP, context seeding, Codex CLI, or Cursor integration.
metadata:
  short-description: GitOps/Helm guardrails for the local AI agent platform
---

# AI Agent GitOps Platform

## Canonical prompt

Detailed source note:

```txt
/home/baominh/Documents/Note/Agent/ai-agent-gitops-prompt.md
```

Read that note when implementing the full repository or when details about chart layout, docs, Makefile targets, tests, or acceptance criteria are needed.

## Role

Act as a senior DevOps/Platform Engineer. Build and operate a GitOps repository for the local AI agent platform using Helm-first Kubernetes manifests and Argo CD.

## Non-negotiable scope

- Only target the Minikube cluster on host `10.50.1.20`.
- In `/home/baominh/code/ai-agent`, the expected Kubernetes context name is `minikube`.
- Use workload namespace `ai-platform`.
- Use Argo CD namespace `argocd`.
- Codex CLI and Cursor run locally; never deploy them into the cluster.
- The cluster hosts router/context infrastructure only.
- 9Router routes model/provider API requests; it is not a context store.
- Qdrant stores vector context.
- MCP bridges local agents to context/tools.
- Do not commit real secrets.
- Do not expose services publicly; use `ClusterIP` and port-forwarding.

## Required cluster verification

Before any command that may modify Kubernetes state, run:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

Proceed only if the context is `minikube` and the node output clearly identifies the intended local Minikube target. If not, stop. Do not switch Kubernetes contexts unless the user explicitly instructs it.

Read-only diagnostics are allowed before verification, including namespace, pod, service, node, and Argo CD Application listing commands.

## GitOps-first workflow

1. Update repository files first: Helm charts, values, Argo CD Applications, docs, and context.
2. Validate locally with `helm dependency update`, `helm lint`, `helm template`, and dry runs where appropriate.
3. Sync through Argo CD or apply bootstrap manifests only after target verification.
4. Verify cluster state.

Avoid `kubectl edit`, workload `kubectl patch`, and manual `helm upgrade --set` changes that create drift. If a direct bootstrap or emergency change is unavoidable, document it and codify the desired state immediately.

## Helm-first design

- Put components under `charts/<component>/`.
- Each chart must have `Chart.yaml`, `values.yaml`, `values-minikube.yaml`, and `templates/`.
- Argo CD Applications must point to local chart paths.
- Wrap good public Helm charts as pinned dependencies.
- Use custom local charts when no suitable public chart exists.
- Keep Minikube-specific configuration in `values-minikube.yaml`.
- Avoid Kustomize `apps/base/overlays` for this platform.

## Components

- `9router`: service `nine-router`, port `20128`, persistent data at `/app/data`, local access through `kubectl -n ai-platform port-forward svc/nine-router 20128:20128`.
- `qdrant`: service `qdrant`, HTTP port `6333`, optional gRPC `6334`, persistent data at `/qdrant/storage`.
- `qdrant-mcp`: verify actual transport. Deploy in-cluster only if HTTP/SSE/Streamable HTTP is supported. If stdio-only, keep chart disabled by default and document local stdio config for Codex/Cursor.
- `context-seeder`: seed `context/*.md` into Qdrant collection `project-context` idempotently with stable IDs and metadata.

## Required repository shape

```txt
charts/
clusters/argo/
clusters/argo/applications/
context/
docs/
Makefile
README.md
```

Use Argo CD App of Apps with `clusters/argo/root-app.yaml` and child Applications for `9router`, `qdrant`, `qdrant-mcp`, and `context-seeder`.

## Documentation expectations

Ensure README and docs cover:

- Architecture and component roles.
- Cluster scope and verification.
- GitOps-first policy.
- Helm-first design and chart decision log.
- Prerequisites, quick start, operations, troubleshooting, and tests.
- Secret creation with placeholders only.
- Port-forwarding and local connection examples for Codex CLI and Cursor.
- MCP mode selected based on real transport support.

## Validation

Prefer these checks before declaring work complete:

```bash
helm dependency update charts/qdrant
helm dependency update charts/9router
helm dependency update charts/qdrant-mcp
helm dependency update charts/context-seeder
helm lint charts/qdrant charts/9router charts/qdrant-mcp charts/context-seeder
helm template qdrant charts/qdrant -f charts/qdrant/values-minikube.yaml
helm template 9router charts/9router -f charts/9router/values-minikube.yaml
helm template qdrant-mcp charts/qdrant-mcp -f charts/qdrant-mcp/values-minikube.yaml
helm template context-seeder charts/context-seeder -f charts/context-seeder/values-minikube.yaml
```

Run cluster-changing validation only after the Minikube target is verified.


## Local model hosting

Ollama is the default CPU-first local model runtime in this workspace. Keep Ollama and model pull changes GitOps-first under `charts/ollama`, `charts/ollama-models`, and `clusters/argo/applications`. Route through 9Router when possible; do not expose Ollama publicly.

## 9Router config-as-code

Use `charts/9router-config` to seed 9Router providers, custom provider nodes, and model aliases. Store API keys only in Kubernetes Secrets such as `9router-provider-secrets`; keep Git values limited to provider names, priorities, aliases, and non-secret endpoints. The default Minikube provider is `ollama-local` pointing to `http://ollama-qwen-coder.ai-platform.svc.cluster.local:11434`.

## Model-scoped Ollama instances

Ollama is organized as one instance per local model. The active CPU-only instance is `ollama-qwen-coder` running `qwen2.5-coder:7b`; `ollama-deepseek-r1` and `ollama-gemma3` are GitOps-defined but scaled to zero by default. Keep 9Router local provider config pointed at the active service unless another model is explicitly scaled up and registered.
