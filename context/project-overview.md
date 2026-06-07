# Project Overview

This repository deploys local AI agent platform infrastructure into Minikube using GitOps.

Local tools:

- Codex CLI
- Cursor

Cluster infrastructure:

- 9Router for OpenAI-compatible model/provider routing.
- Qdrant for vector context storage.
- Qdrant MCP server or bridge for exposing context to MCP clients.
- Optional context seeder for loading project markdown into Qdrant.
- Argo CD for GitOps reconciliation.

The target is local development only, not production cloud deployment.

## Shared context memory

Durable project knowledge is stored in repo context files and seeded into Qdrant collection `project-context`. Agents should use Qdrant MCP to retrieve shared context instead of relying on per-session chat history.
