"""Raw source and embedding document must survive independently."""

from collections.abc import Callable
from dataclasses import replace

import pytest

from engine.adapters.vectorstore.chroma_codec import decode, encode
from engine.core.errors import VectorStoreError
from engine.core.models import ChunkKind, CodeChunk


@pytest.mark.parametrize("kind", [ChunkKind.CLASS, ChunkKind.MODULE])
def test_t105_codec_distinct_payloads(chunk_factory: Callable[[int], CodeChunk], kind: ChunkKind) -> None:
    chunk = replace(
        chunk_factory(1),
        kind=kind,
        raw_code="source body\r\n",
        search_text="# path: file1.py\nrendered ...",
        metadata={"raw_code": "user value", "spans": "1-1,7-7"},
    )
    metadata = encode(chunk)
    assert metadata["raw_code"] == chunk.raw_code
    assert metadata["m_raw_code"] == "user value"
    assert decode(chunk.chunk_id, chunk.search_text, metadata) == chunk


@pytest.mark.parametrize("raw", [None, 1, True, 1.5])
def test_t105_codec_invalid_raw(
    chunk_factory: Callable[[int], CodeChunk], raw: int | float | bool | None
) -> None:
    chunk = chunk_factory(1)
    metadata = encode(chunk)
    if raw is None:
        del metadata["raw_code"]
    else:
        metadata["raw_code"] = raw
    with pytest.raises(VectorStoreError, match="metadata"):
        decode(chunk.chunk_id, chunk.search_text, metadata)
