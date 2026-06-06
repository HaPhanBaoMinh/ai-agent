#!/usr/bin/env python3
import argparse
import hashlib
import os
import re
from pathlib import Path

from fastembed import TextEmbedding
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, PointStruct, VectorParams


TYPE_BY_FILE = {
    "AGENTS.md": "agents",
    "project-overview.md": "overview",
    "architecture.md": "architecture",
    "coding-conventions.md": "convention",
    "api-conventions.md": "api",
    "domain-glossary.md": "domain",
}


def section_chunks(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8")
    matches = list(re.finditer(r"^#{1,3}\s+(.+)$", text, flags=re.MULTILINE))
    if not matches:
        return [{"title": path.stem, "content": text.strip()}] if text.strip() else []

    chunks = []
    for index, match in enumerate(matches):
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        content = text[start:end].strip()
        if content:
            chunks.append({"title": match.group(1).strip(), "content": content})
    return chunks


def stable_id(source_file: str, title: str, content: str) -> str:
    digest = hashlib.sha256(f"{source_file}\n{title}\n{content}".encode("utf-8")).hexdigest()
    return digest[:32]


def distance_from_env(value: str) -> Distance:
    normalized = value.strip().lower()
    if normalized == "dot":
        return Distance.DOT
    if normalized == "euclid":
        return Distance.EUCLID
    return Distance.COSINE


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed markdown context into Qdrant.")
    parser.add_argument("--context-dir", default="context")
    args = parser.parse_args()

    qdrant_url = os.environ.get("QDRANT_URL", "http://127.0.0.1:6333")
    collection = os.environ.get("COLLECTION_NAME", "project-context")
    model_name = os.environ.get("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
    vector_size = int(os.environ.get("VECTOR_SIZE", "384"))
    distance = distance_from_env(os.environ.get("DISTANCE", "Cosine"))

    context_dir = Path(args.context_dir)
    files = [context_dir / name for name in TYPE_BY_FILE if (context_dir / name).exists()]
    if not files:
        raise SystemExit(f"No known context files found in {context_dir}")

    client = QdrantClient(url=qdrant_url)
    collections = {item.name for item in client.get_collections().collections}
    if collection not in collections:
        client.create_collection(
            collection_name=collection,
            vectors_config=VectorParams(size=vector_size, distance=distance),
        )

    embedder = TextEmbedding(model_name=model_name)
    records = []
    texts = []

    for path in files:
        source_file = path.name
        for chunk in section_chunks(path):
            content = chunk["content"]
            records.append(
                {
                    "id": stable_id(source_file, chunk["title"], content),
                    "source_file": source_file,
                    "title": chunk["title"],
                    "type": TYPE_BY_FILE[source_file],
                    "content": content,
                }
            )
            texts.append(content)

    vectors = list(embedder.embed(texts))
    points = []
    for record, vector in zip(records, vectors, strict=True):
        points.append(
            PointStruct(
                id=record["id"],
                vector=vector.tolist(),
                payload={
                    "source_file": record["source_file"],
                    "title": record["title"],
                    "type": record["type"],
                    "project": "ai-agent-platform",
                    "status": "active",
                    "content": record["content"],
                },
            )
        )

    client.upsert(collection_name=collection, points=points)
    print(f"Seeded {len(points)} context chunks into {collection} at {qdrant_url}")


if __name__ == "__main__":
    main()
