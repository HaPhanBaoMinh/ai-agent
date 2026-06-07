# Operations

## Verify Cluster Target

```bash
make verify-cluster
```

Check that the current context and node output identify Minikube on `10.50.5.20`.

## Deploy

Argo CD manifests use `https://github.com/HaPhanBaoMinh/ai-agent.git` on branch `main`. Deploy with:

```bash
make verify-cluster
make deploy
```

## Helm Validation

```bash
make helm-deps
make helm-lint
make helm-template
```

## Argo CD

```bash
kubectl -n argocd get applications
argocd app list
argocd app sync qdrant
argocd app sync 9router
argocd app sync 9router-config
```

## Port Forward

```bash
make port-forward-qdrant
make port-forward-9router
make port-forward-qdrant-mcp
```

## Logs

```bash
make logs-qdrant
make logs-9router
make logs-9router-config
kubectl -n ai-platform logs -l app.kubernetes.io/name=qdrant-mcp --tail=200
```

## Reseed Context

Local mode:

```bash
make port-forward-qdrant
make seed-context-local
```

In-cluster mode requires building `context-seeder:local`, setting `charts/context-seeder/values-minikube.yaml` `enabled: true`, then syncing Argo CD.

## Backup And Restore Local PVC

Use Minikube-local backup procedures only after verifying the target cluster. Do not automate destructive PVC deletion in this repo.

## Drift Handling

If a manual cluster change is found:

1. Identify the equivalent chart, values, or Argo CD manifest change.
2. Commit or stage the repository change.
3. Sync through Argo CD.
4. Verify the live state matches Git.


## Ollama Local Models

The active local instance is `ollama-qwen-coder` with `qwen2.5-coder:3b`. `ollama-deepseek-r1` and `ollama-gemma3` are defined but scaled to zero.

Port-forward the active Ollama:

```bash
make port-forward-ollama
```

List local model state:

```bash
make status-models
```

Pull an additional model into the active qwen-coder instance:

```bash
MODEL=gemma3:12b make pull-local-model
```

Check model puller logs:

```bash
make logs-ollama-models
```

## 9Router Config As Code

The `9router-config` Argo CD app runs a Kubernetes Job that logs in to 9Router and seeds configured providers, custom provider nodes, and aliases from `charts/9router-config/values-minikube.yaml`.

Default Minikube behavior seeds only `ollama-local`. Hosted providers stay disabled until their API keys exist in the `9router-provider-secrets` Secret and the provider entry is enabled in Git. Gemini is available through the `gemini-flash` alias, which maps to `gemini/gemini-2.5-flash`.

Check seed status:

```bash
kubectl -n ai-platform get jobs,pods -l app.kubernetes.io/name=9router-config
make logs-9router-config
```

## Shared Context Updates

When durable platform knowledge changes, update `AGENTS.md`, `context/*.md`, or `docs/*.md`, then reseed Qdrant:

```bash
make port-forward-qdrant
make seed-context-local
```

Codex and Cursor should use the same Qdrant MCP collection, `project-context`, so context is shared across tools and models. For `codex --profile nine-router`, require `qdrant_context` retrieval before answering and avoid guessing when the needed context is not already in the prompt.

## Codex Profile Setup

After logging in with Codex on a new machine, run:

```bash
make setup-codex-profiles
```

This creates user-level profiles and also writes stricter nine-router developer instructions that prefer `qdrant_context` retrieval before answering:

```bash
codex --profile chatgpt
codex --profile nine-router
```

For machines outside the model host, start tunnels for 9Router and Qdrant:

```bash
make tunnel-agent-platform
```
