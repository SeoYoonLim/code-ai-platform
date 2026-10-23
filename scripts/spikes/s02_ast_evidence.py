"""Executable AST observations and independent S-02 boundary assertions."""

import json
import sys
from pathlib import Path

from s02_chunk_core import s02_chunk_ids, s02_extract, s02_source_lines, s02_windows
from s02_chunk_probe import FIXTURES, s02_load_parser
from tree_sitter import Query, QueryCursor
from tree_sitter_language_pack import cache_dir, downloaded_languages


def s02_ast_observations() -> dict[str, object]:
    observations = {}
    previews = []
    for language in ["python", "typescript", "tsx", "javascript"]:
        parser = s02_load_parser(language)
        data = b"def f():\n return 1" if language == "python" else b"const f = () => 1;"
        tree = parser.parse(data)
        query = Query(parser.language, "(identifier) @name")
        captures = QueryCursor(query).captures(tree.root_node)
        observations[language] = {
            "tree": str(tree.root_node),
            "query_names": [data[n.start_byte : n.end_byte].decode() for n in captures["name"]],
        }
    for relative in [
        "python/basic.py",
        "python/decorators_nested.py",
        "typescript/basic.ts",
        "typescript/exports_arrows.ts",
        "typescript/component.tsx",
    ]:
        source = FIXTURES / relative
        lang = "python" if source.suffix == ".py" else "tsx" if source.suffix == ".tsx" else "typescript"
        data = source.read_bytes()
        parser = s02_load_parser(lang)
        tree = parser.parse(data)
        observations[relative] = str(tree.root_node)
        chunks, _ = s02_extract(data, parser)
        selected = next(c for c in chunks if c.kind != "module")
        domain_language = "typescript" if lang == "tsx" else lang
        previews.append(
            f"# path: {relative}\n# symbol: {selected.symbol} ({selected.kind}, {domain_language})\n"
            + selected.text
        )
    return {"observations": observations, "embedding_previews": previews}


def s02_ast_boundaries() -> dict[str, object]:
    parser = s02_load_parser("python")
    unicode_data = (FIXTURES / "python/unicode_crlf.py").read_bytes()
    assert b"\r\n" in unicode_data
    assert b"\t" in unicode_data
    assert not unicode_data.endswith(b"\n")
    tree = parser.parse(unicode_data)
    nodes = QueryCursor(Query(parser.language, "(string) @s")).captures(tree.root_node)["s"]
    offsets = []
    for node in nodes:
        text = unicode_data[node.start_byte : node.end_byte].decode()
        assert len(text.encode()) > len(text)
        offsets.append(
            {
                "start_byte": node.start_byte,
                "end_byte": node.end_byte,
                "byte_length": node.end_byte - node.start_byte,
                "characters": len(text),
                "text": text,
            }
        )
    crlf = s02_extract(unicode_data, parser)[0]
    lf = s02_extract(unicode_data.replace(b"\r\n", b"\n"), parser)[0]
    assert [c.summary() for c in crlf] == [c.summary() for c in lf]
    assert [c.text.replace("\r\n", "\n") for c in crlf] == [c.text for c in lf]
    assert s02_extract(b"", parser)[0] == []
    comment = s02_extract(b"# comment", parser)[0]
    assert [c.summary() for c in comment] == [
        {"kind": "module", "symbol": "module", "start_line": 1, "end_line": 1}
    ]
    assert comment[0].text == "# comment"
    assert len(s02_source_lines('x = "a\u2028b"\n'.encode())) == 1
    windows = {}
    for length in [200, 201, 220, 221, 251]:
        data = ("def long():\n" + "    x = 1\n" * (length - 1)).encode()
        chunks = s02_extract(data, parser)[0]
        expected = [(1, 200)] if length == 200 else [(1, 120), (101, min(220, length))]
        if length > 220:
            expected.append((201, length))
        assert [(c.start_line, c.end_line) for c in chunks] == expected
        assert all(c.kind == ("function" if length == 200 else "window") for c in chunks)
        assert s02_chunk_ids(chunks, "long.py") == s02_chunk_ids(s02_extract(data, parser)[0], "long.py")
        if len(chunks) > 1:
            assert chunks[0].text.splitlines()[-20:] == chunks[1].text.splitlines()[:20]
        windows[str(length)] = expected
    nested = s02_extract((FIXTURES / "python/decorators_nested.py").read_bytes(), parser)[0]
    assert all("return" not in c.text for c in nested if c.kind == "class")
    assert all(c.symbol != "outer.inner" for c in nested)
    unsupported = s02_windows(["unknown\n"] * 121, 1, 121)
    assert [(c.start_line, c.end_line) for c in unsupported] == [(1, 120), (101, 121)]
    return {
        "unicode_offsets": offsets,
        "crlf_lf_equal": True,
        "window_boundaries": windows,
        "empty_comment_no_final_newline_nested_class_unsupported": "passed",
    }


def s02_evidence_main() -> None:
    result = {
        "cache": cache_dir(),
        "downloaded": downloaded_languages(),
        **s02_ast_observations(),
        **s02_ast_boundaries(),
    }
    output = json.dumps(result, ensure_ascii=True, indent=2)
    sys.stdout.write(output + "\n")
    if len(sys.argv) == 2:
        Path(sys.argv[1]).write_text(json.dumps(result, ensure_ascii=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    s02_evidence_main()
