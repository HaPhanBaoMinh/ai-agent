# API Conventions

9Router should be exposed locally through:

```txt
http://127.0.0.1:20128
http://127.0.0.1:20128/v1
```

Qdrant should be exposed locally through:

```txt
http://127.0.0.1:6333
```

Qdrant MCP local stdio mode should use:

```txt
QDRANT_URL=http://127.0.0.1:6333
COLLECTION_NAME=project-context
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

In-cluster service URLs:

```txt
http://qdrant.ai-platform.svc.cluster.local:6333
http://qdrant-mcp.ai-platform.svc.cluster.local:8000
```
