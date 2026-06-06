# Domain Glossary

9Router:
Model/provider router with an OpenAI-compatible API and dashboard.

Qdrant:
Vector database used as the project context store.

MCP:
Model Context Protocol, used to expose tools and context to agents.

GitOps:
Operational model where Git is the source of truth and Argo CD reconciles cluster state.

Helm-first:
Repository pattern where Kubernetes resources are managed through local Helm charts and values files.

Context seeder:
Script or Job that chunks markdown context files, embeds them locally, and upserts them into Qdrant.
