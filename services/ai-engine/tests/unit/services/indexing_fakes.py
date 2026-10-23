"""Port fakes and deterministic indexing harness."""

from collections.abc import Sequence

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.adapters.parsing.language_map import language_for_path
from engine.adapters.source.fake import InMemoryScanner
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.core.errors import EmbeddingError, ParseError, VectorStoreError
from engine.core.models import ChunkKind, CodeChunk, IndexJob, IndexRequest, Language, SourceFile
from engine.services.indexing_service import IndexingService


class Chunker:
    fail_path: str | None = None

    def supports(self, language: Language) -> bool:
        return True

    def chunk(self, file: SourceFile, *, project_id: str, commit_sha: str | None = None) -> list[CodeChunk]:
        if file.path == self.fail_path:
            raise ParseError("injected parse")
        if not file.content:
            return []
        return [
            CodeChunk(
                f"{project_id}:{file.path}::f@1-2",
                project_id,
                file.path,
                file.language,
                ChunkKind.FUNCTION,
                "f",
                file.content,
                "# path: " + file.path + "\n" + file.content,
                1,
                2,
                file.content_hash,
                commit_sha,
            )
        ]


class Embedder(FakeEmbedder):
    fail_path: str | None = None

    async def embed_documents(self, texts: Sequence[str]) -> list[list[float]]:
        if self.fail_path and any(self.fail_path in t for t in texts):
            raise EmbeddingError("injected embedding")
        return await super().embed_documents(texts)


class Store(InMemoryVectorStore):
    fail_path: str | None = None
    too_large: bool = False
    fail_delete: bool = False
    fail_ensure: bool = False
    drops: int = 0

    async def replace_file(
        self, collection: str, path: str, chunks: Sequence[CodeChunk], embeddings: Sequence[Sequence[float]]
    ) -> None:
        if path == self.fail_path:
            raise VectorStoreError(
                "injected replace", detail={"reason": "replace_too_large"} if self.too_large else {}
            )
        await super().replace_file(collection, path, chunks, embeddings)

    async def delete_by_paths(self, collection: str, paths: Sequence[str]) -> int:
        if self.fail_delete:
            raise VectorStoreError("injected delete")
        return await super().delete_by_paths(collection, paths)

    async def ensure_collection(self, collection: str, *, dimension: int) -> None:
        if self.fail_ensure:
            raise VectorStoreError("injected ensure")
        await super().ensure_collection(collection, dimension=dimension)

    async def drop_collection(self, collection: str) -> None:
        self.drops += 1
        await super().drop_collection(collection)


class Harness:
    def __init__(self) -> None:
        self.scanner = InMemoryScanner(
            dict.fromkeys(["a.py", "b.py"], "def f():\n    return 1\n"), language_for_path=language_for_path
        )
        self.embedder = Embedder(dimension=2)
        self.store = Store()
        self.chunker = Chunker()
        self.service = IndexingService(self.scanner, self.chunker, self.embedder, self.store)

    async def run(self, request: IndexRequest | None = None) -> IndexJob:
        job = await self.service.start(request or IndexRequest("p", "memory"))
        return await self.service.run(job.job_id)

    async def rows(self) -> dict[str, CodeChunk]:
        return {r.chunk.path: r.chunk for r in await self.store.query("proj_p", [1.0, 0.0], top_k=100)}
