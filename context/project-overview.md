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
