FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

ENV UV_SYSTEM_PYTHON=1 \
    PYTHONUNBUFFERED=1

RUN uv tool install mcp-server-qdrant

ENV PATH="/root/.local/bin:${PATH}"

EXPOSE 8000

ENTRYPOINT ["mcp-server-qdrant"]
