"""Local sample round trip with cached grammars and fake embeddings."""

from pathlib import Path

from engine.adapters.embeddings.fake import FakeEmbedder
from engine.adapters.parsing.language_map import language_for_path
from engine.adapters.parsing.treesitter_chunker import TreeSitterChunker
from engine.adapters.source.git_scanner import FileSystemScanner
from engine.adapters.vectorstore.in_memory import InMemoryVectorStore
from engine.container import build_container
from engine.core.models import IndexRequest, JobStatus
from engine.services.indexing_service import IndexingService
from engine.settings import Settings


async def test_sample_repo_real_chunker_roundtrip() -> None:
    root = Path(__file__).parents[2] / "fixtures" / "sample_repo"
    embedder = FakeEmbedder(dimension=4)
    store = InMemoryVectorStore()
    service = IndexingService(
        FileSystemScanner(language_for_path=language_for_path), TreeSitterChunker(), embedder, store
    )
    job = await service.start(IndexRequest("sample", str(root), commit_sha="sample"))
    done = await service.run(job.job_id)
    assert done.status == JobStatus.SUCCEEDED
    assert done.stats is not None
    assert done.stats.files_changed == 10
    rows = await store.query("proj_sample", [1.0, 0.0, 0.0, 0.0], top_k=100)
    assert {r.chunk.path for r in rows} == {
        p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()
    }
    texts = [text for batch in embedder.calls for text in batch]
    for row in rows:
        chunk = row.chunk
        lines = (root / chunk.path).read_bytes().decode("utf-8").splitlines(keepends=True)
        assert chunk.raw_code == "".join(lines[chunk.start_line - 1 : chunk.end_line])
        assert chunk.search_text in texts
        assert "path:" in chunk.search_text
        assert chunk.commit_sha == "sample"
    embedder.calls.clear()
    again = await service.start(job.request)
    assert (await service.run(again.job_id)).stats.files_changed == 0
    assert embedder.calls == []


async def test_container_wires_filesystem_scanner_even_in_fake_mode() -> None:
    settings = Settings(
        _env_file=None,
        llm_provider="fake",
        embedder_provider="fake",
        vector_store="memory",
        index_max_file_bytes=100,
    )
    async with await build_container(settings) as container:
        assert isinstance(container.scanner, FileSystemScanner)
        assert isinstance(container.indexing, IndexingService)


async def test_real_parser_body_only_edit_keeps_id_and_changes_payload() -> None:
    from hashlib import sha256

    from engine.core.models import Language, SourceFile

    parser = TreeSitterChunker()
    versions = []
    for number in (1, 2):
        content = f"def f():\n    return {number}\n"
        file = SourceFile("a.py", Language.PYTHON, content, sha256(content.encode()).hexdigest())
        versions.append(parser.chunk(file, project_id="p"))
    assert len(versions[0]) == len(versions[1]) == 1
    assert versions[0][0].chunk_id == versions[1][0].chunk_id == "p:a.py::f@1-2"
    assert versions[0][0].raw_code != versions[1][0].raw_code
    assert versions[0][0].content_hash != versions[1][0].content_hash
