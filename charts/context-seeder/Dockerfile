FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir fastembed qdrant-client

COPY scripts/seed_context.py /app/seed_context.py
COPY context /app/context

ENTRYPOINT ["python", "/app/seed_context.py", "--context-dir", "/app/context"]
