# Cluster Runbook

## Target Host And Context

The current local AI platform runs on SSH host `10.50.5.20`.

Use Kubernetes context `minikube` for this workspace. When operating from a different terminal or machine, verify whether `kubectl` is pointed at the model host's Minikube cluster before making changes.

Workload namespace: `ai-platform`.
Argo CD namespace: `argocd`.

Before any Kubernetes write command, verify:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

If operating through SSH to the model host, use:

```bash
ssh 10.50.5.20 "kubectl config current-context"
ssh 10.50.5.20 "kubectl -n argocd get applications"
ssh 10.50.5.20 "kubectl -n ai-platform get pods,svc,pvc"
```

## Current Platform Services

9Router service: `nine-router` on port `20128`.

Qdrant service: `qdrant` on port `6333`.

Active Ollama service: `ollama-qwen-coder` on port `11434`.

Defined but scaled down Ollama services:

- `ollama-deepseek-r1`
- `ollama-gemma3`

The old PVC `data-ollama-0` was deleted after moving to model-scoped Ollama. The active model PVC is `data-ollama-qwen-coder-0`.

## 9Router Model Routing

9Router local provider is `ollama-local` and points to:

```txt
http://ollama-qwen-coder.ai-platform.svc.cluster.local:11434
```

The active Codex-compatible route is:

```txt
ollama-local/qwen2.5-coder:7b
```

The 9Router alias `local-coder` maps to:

```txt
ollama-local/qwen2.5-coder:7b
```

`local-coder` works for OpenAI-compatible Chat Completions clients. Codex CLI currently works more reliably with the full model route because Codex uses the Responses API path.

## Codex CLI Modes

Use normal ChatGPT/Codex mode:

```bash
codex --profile chatgpt
```

Use local 9Router mode:

```bash
codex --profile nine-router
```

The `nine-router` profile is user-level in `~/.codex/nine-router.config.toml`; provider configuration must not be stored in project `.codex/config.toml` because Codex ignores provider/auth keys in project-scoped config.

After `codex login` on a new machine, run:

```bash
make setup-codex-profiles
```

This writes user-level Codex profiles and configures the `qdrant_context` MCP server. On machines outside the model host, keep this tunnel open before using `nine-router` or Qdrant MCP:

```bash
make tunnel-agent-platform
```

## Hardware And Performance

The model host `10.50.5.20` is an ASUS desktop with AMD Ryzen 7 5700G, 16 logical CPUs, and about 62 GiB RAM.

Detected GPU: integrated AMD/ATI Cezanne Radeon Vega iGPU. No NVIDIA driver was found (`nvidia-smi` is unavailable), and Kubernetes does not advertise GPU resources.

Ollama reports `qwen2.5-coder:7b` is running with `PROCESSOR 100% CPU`. Local model latency is expected to be high for Codex because Codex injects large prompts and the model is CPU-only.

For faster local Codex responses, prefer a smaller model instance such as `qwen2.5-coder:3b` or add a supported discrete GPU and expose it to Kubernetes.

## Shared Context Policy

Durable context belongs in repo files, not only in chat history. When a new durable fact, decision, operational rule, service endpoint, model layout, troubleshooting result, or user preference is discovered, update the appropriate file under `AGENTS.md`, `context/*.md`, or `docs/*.md`, then reseed Qdrant collection `project-context`.

Qdrant is the shared vector context store. Codex, Cursor, and local agents should retrieve context through Qdrant MCP instead of requiring repeated manual chat updates.
