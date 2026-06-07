# Troubleshooting

## Wrong Kube Context

Run `make verify-cluster`. Stop if the current context or node list does not identify Minikube on `10.50.5.20`.

## Node IP Is Not 10.50.5.20

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
kubectl -n ai-platform get svc nine-router
make port-forward-9router
```

## 9Router Ollama DNS Resolution Failed

`EAI_AGAIN getaddrinfo ollama-gemma3...` means 9Router cannot resolve the Ollama service FQDN. Confirm the namespaces, services, and DNS first:

```bash
kubectl -n ai-platform get pods,svc -l app.kubernetes.io/name=ollama
kubectl -n ai-platform get svc ollama-gemma3
kubectl -n ai-platform get pods -l app.kubernetes.io/name=9router -o wide
kubectl -n ai-platform logs -l app.kubernetes.io/name=9router --tail=200
kubectl -n ai-platform exec deploy/9router -- nslookup ollama-gemma3.ai-platform.svc.cluster.local.
```

If CoreDNS is healthy but 9Router still cannot resolve the in-cluster service, verify the `ai-platform` namespace is trusting the cluster CA and the 9Router pod DNS policy is compatible with Minikube. If the fix is cluster-level, document the exact change in Git afterward.

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


## Ollama Pod Pending Or Slow

Check CPU/memory scheduling and PVC capacity:

```bash
kubectl -n ai-platform get pod,statefulset,pvc -l app.kubernetes.io/name=ollama
kubectl describe node minikube
```

CPU-only generation is expected to be slower than GPU. Reduce model size before increasing resource limits.

## Ollama Model Pull Failed

Check Job logs and network access:

```bash
make logs-ollama-models
kubectl -n ai-platform get jobs
```

Pull one model manually after Ollama is ready:

```bash
MODEL=gemma3:4b make pull-local-model
```
