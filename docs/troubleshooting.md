# Troubleshooting

## Wrong Kube Context

Run `make verify-cluster`. Stop if the current context or node list does not identify Minikube on `10.50.1.20`.

## Node IP Is Not 10.50.1.20

Do not deploy. Confirm whether Minikube is running on the intended host before any write command.

## Helm Dependency Update Failed

Check network access and the Qdrant chart repository:

```bash
helm repo add qdrant https://qdrant.github.io/qdrant-helm
helm repo update
helm dependency update charts/qdrant
```

## Helm Template Failed

Run the specific template command for the failing chart and inspect YAML around the reported line.

## Argo CD App OutOfSync

Check:

```bash
argocd app diff <app>
argocd app sync <app>
kubectl -n argocd describe application <app>
```

## Cluster Drift From Git

Do not patch the workload live as the final fix. Update the chart or values file, then sync through Argo CD.

## ImagePullBackOff

For local images, build into Minikube:

```bash
make build-qdrant-mcp-image
make build-context-seeder-image
```

Ensure `imagePullPolicy: IfNotPresent`.

## 9Router Connection Refused

Check pod readiness and port-forward:

```bash
kubectl -n ai-platform get pods -l app.kubernetes.io/name=9router
kubectl -n ai-platform get svc 9router
make port-forward-9router
```

## 9Router Auth Failed

Verify the local secret:

```bash
kubectl -n ai-platform get secret 9router-secret
```

Recreate it with a placeholder replaced by the real local key.

## Qdrant Pod Pending Due To PVC

Check storage class and PVC events:

```bash
kubectl -n ai-platform get pvc
kubectl -n ai-platform describe pvc
```

## Qdrant Collection Not Found

Run the seeder:

```bash
make port-forward-qdrant
make seed-context-local
```

## MCP Server Not Visible In Codex

Check `~/.codex/config.toml`, ensure Qdrant is port-forwarded, and start Codex after updating MCP config.

## Port-Forward Conflict

Use a different local port:

```bash
kubectl -n ai-platform port-forward svc/qdrant 16333:6333
```

## Minikube Docker Env Issue

Run:

```bash
minikube status
eval "$(minikube docker-env)"
docker images
```
