# Operations

## Verify Cluster Target

```bash
make verify-cluster
```

Check that the current context and node output identify Minikube on `10.50.1.20`.

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

Port-forward Ollama:

```bash
make port-forward-ollama
```

List local models:

```bash
make status-models
```

Pull an additional model:

```bash
MODEL=gemma3:12b make pull-local-model
```

Check model puller logs:

```bash
make logs-ollama-models
```
