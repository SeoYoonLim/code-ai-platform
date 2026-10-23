"""Service failure injection includes body edits with unchanged chunk IDs."""

import pytest

from engine.core.models import JobStatus
from tests.unit.services.indexing_fakes import Harness


@pytest.mark.parametrize("failure", ["embedding", "replace"])
async def test_service_second_file_failure_same_id_and_retry(failure: str) -> None:
    h = Harness()
    assert (await h.run()).status == JobStatus.SUCCEEDED
    before = await h.rows()
    hashes = await h.store.get_file_hashes("proj_p")
    h.scanner.files.update(dict.fromkeys(["a.py", "b.py"], "def f():\n    return 2\n"))
    if failure == "embedding":
        h.embedder.fail_path = "b.py"
    else:
        h.store.fail_path = "b.py"
    failed = await h.run()
    assert failed.status == JobStatus.FAILED
    assert failed.stats is not None
    assert failed.stats.files_changed == 1
    rows = await h.rows()
    assert rows["a.py"].chunk_id == before["a.py"].chunk_id
    assert rows["a.py"].raw_code == "def f():\n    return 2\n"
    assert rows["b.py"] == before["b.py"]  # exact payload, hash, ID, search text, metadata
    after_hashes = await h.store.get_file_hashes("proj_p")
    assert after_hashes["b.py"] == hashes["b.py"]
    assert after_hashes["a.py"] != hashes["a.py"]
    h.embedder.fail_path = h.store.fail_path = None
    assert (await h.run()).status == JobStatus.SUCCEEDED
    clean = Harness()
    clean.scanner.files = dict(h.scanner.files)
    assert (await clean.run()).status == JobStatus.SUCCEEDED
    assert await h.rows() == await clean.rows()
    assert await h.store.get_file_hashes("proj_p") == await clean.store.get_file_hashes("proj_p")


async def test_service_deletion_failure_keeps_replacements_consistent() -> None:
    h = Harness()
    await h.run()
    before = await h.rows()
    del h.scanner.files["b.py"]
    h.scanner.files["a.py"] = "def f():\n    return 2\n"
    h.store.fail_delete = True
    assert (await h.run()).status == JobStatus.FAILED
    rows = await h.rows()
    assert rows["a.py"].raw_code == h.scanner.files["a.py"]
    assert rows["b.py"] == before["b.py"]
    h.store.fail_delete = False
    done = await h.run()
    assert done.stats is not None
    assert done.stats.files_deleted == 1
    assert set(await h.rows()) == {"a.py"}


async def test_service_too_large_skips_one_file_and_continues() -> None:
    h = Harness()
    await h.run()
    before = await h.rows()
    h.scanner.files.update(dict.fromkeys(["a.py", "b.py"], "def f():\n    return 2\n"))
    h.store.fail_path, h.store.too_large = "a.py", True
    done = await h.run()
    assert done.status == JobStatus.SUCCEEDED
    assert done.stats is not None
    assert (done.stats.files_changed, done.stats.files_skipped) == (1, 1)
    rows = await h.rows()
    assert rows["a.py"] == before["a.py"]
    assert rows["b.py"].raw_code == h.scanner.files["b.py"]


async def test_service_parse_error_skips_only_bad_file() -> None:
    h = Harness()
    h.chunker.fail_path = "a.py"
    done = await h.run()
    assert done.status == JobStatus.SUCCEEDED
    assert done.stats is not None
    assert done.stats.files_skipped == 1
    assert set(await h.rows()) == {"b.py"}
