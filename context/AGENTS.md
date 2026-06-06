# Agent Instructions

Read all files under `context/` before making architecture, deployment, or operational changes.

Only act on the local Minikube cluster. In this workspace, the expected Kubernetes context is `minikube`. Before any Kubernetes write command, verify:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

Stop if the context is not `minikube`, is unclear, or points to another cluster. Do not switch contexts unless explicitly instructed.

Follow GitOps-first:

- Update code before changing cluster state.
- Argo CD and this repository are the source of truth.
- Avoid `kubectl edit`, workload `kubectl patch`, and `helm upgrade --set` drift.
- If a direct bootstrap change is required, document it and codify the desired state immediately.

Follow Helm-first:

- Components live in `charts/`.
- Minikube values live in `values-minikube.yaml`.
- Wrap good public charts as local dependencies.
- Use custom local charts when public charts are unsuitable.
- Validate with `helm lint` and `helm template`.

Never commit real secrets. Use placeholders, `existingSecret`, or documented local `kubectl create secret` commands.

Do not fake MCP transport. If the selected MCP server only supports local stdio, document local stdio mode instead of creating an invalid Kubernetes service.


## Local model hosting

Ollama is the default CPU-first local model runtime in this workspace. Keep Ollama and model pull changes GitOps-first under `charts/ollama`, `charts/ollama-models`, and `clusters/argo/applications`. Route through 9Router when possible; do not expose Ollama publicly.

## 9Router config-as-code

Use `charts/9router-config` to seed 9Router providers, custom provider nodes, and model aliases. Store API keys only in Kubernetes Secrets such as `9router-provider-secrets`; keep Git values limited to provider names, priorities, aliases, and non-secret endpoints. The default Minikube provider is `ollama-local` pointing to `http://ollama.ai-platform.svc.cluster.local:11434`.
