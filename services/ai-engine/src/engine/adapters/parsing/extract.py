"""Byte-offset extraction ported from the approved S-02 algorithm."""

from bisect import bisect_left, bisect_right
from dataclasses import dataclass

from tree_sitter import Node, Parser


@dataclass(frozen=True)
class Candidate:
    kind: str
    symbol: str
    start_line: int
    end_line: int
    text: str
    source_text: str
    source_lines: tuple[int, ...]


def windows(lines: list[str], start: int, end: int, size: int = 120, overlap: int = 20) -> list[Candidate]:
    chunks = []
    while start <= end:
        stop = min(start + size - 1, end)
        text = "".join(lines[start - 1 : stop])
        chunks.append(
            Candidate("window", f"L{start}-{stop}", start, stop, text, text, tuple(range(start, stop + 1)))
        )
        if stop == end:
            break
        start += size - overlap
    return chunks


def node_text(node: Node, data: bytes) -> str:
    return data[node.start_byte : node.end_byte].decode("utf-8")


def source_lines(data: bytes) -> list[str]:
    """Tree-sitter rows advance on LF; Unicode separators inside strings are not rows."""
    pieces = data.decode("utf-8").split("\n")
    return [line + "\n" for line in pieces[:-1]] + ([pieces[-1]] if pieces[-1] else [])


def method_bodies(node: Node) -> list[Node]:
    """Collect non-overlapping method bodies, including those in nested classes."""
    bodies = []
    for child in node.named_children:
        if child.type == "decorated_definition":
            child = child.named_children[-1]
        if child.type in {"class_definition", "class_declaration", "abstract_class_declaration"}:
            nested = child.child_by_field_name("body")
            if nested:
                bodies.extend(method_bodies(nested))
        elif child.type in {"function_definition", "method_definition", "public_field_definition"}:
            value = child.child_by_field_name("value")
            body = child.child_by_field_name("body")
            if value and value.type in {"arrow_function", "function_expression"}:
                body = value.child_by_field_name("body")
            if body:
                bodies.append(body)
    return bodies


def extract(
    data: bytes, parser: Parser, maximum: int, size: int, overlap: int
) -> tuple[list[Candidate], bool]:
    """Return chunks and syntax-error flag; never disguise absent grammars as fallback."""
    lines = source_lines(data)
    tree = parser.parse(data)
    root = tree.root_node
    if root.has_error:
        return windows(lines, 1, len(lines), size, overlap), True
    chunks: list[Candidate] = []
    occupied: set[int] = set()
    offsets = [0]
    for line in lines:
        offsets.append(offsets[-1] + len(line.encode("utf-8")))

    def emit(node: Node, kind: str, symbol: str, bodies: list[Node]) -> None:
        # Point property stress crashes this Python 3.14.7 / binding 0.26.0 build.
        # Byte offsets + line-start table avoid that measured native crash.
        start = bisect_right(offsets, node.start_byte)
        end = bisect_left(offsets, node.end_byte)
        selected = tuple(range(start, end + 1))
        occupied.update(selected)
        if end - start + 1 > maximum:
            chunks.extend(windows(lines, start, end, size, overlap))
            return
        raw = "".join(lines[start - 1 : end])
        # Render by byte edits, separate from exact source-line text.
        offset = offsets[start - 1]
        rendered = raw.encode("utf-8")
        for body in sorted(bodies, key=lambda n: n.start_byte, reverse=True):
            a, b = body.start_byte - offset, body.end_byte - offset
            replacement = b"{ ... }" if body.type == "statement_block" else b"..."
            rendered = rendered[:a] + replacement + rendered[b:]
        chunks.append(Candidate(kind, symbol, start, end, rendered.decode("utf-8"), raw, selected))

    def visit(node: Node, prefix: str = "", member: bool = False) -> bool:
        wrapper = node
        if node.type in {"decorated_definition", "export_statement"}:
            candidates = [n for n in node.named_children if n.type != "decorator"]
            if not candidates:
                return False
            node = candidates[-1]
        classes = {"class_definition", "class_declaration", "abstract_class_declaration"}
        functions = {
            "function_definition",
            "function_declaration",
            "generator_function_declaration",
            "method_definition",
            "function_expression",
            "generator_function",
        }
        if node.type in {"lexical_declaration", "variable_declaration"}:
            # Mixed declarations stay in MODULE to avoid losing nonfunction bindings.
            variables = [n for n in node.named_children if n.type == "variable_declarator"]
            if len(variables) != 1:
                return False
            node = variables[0]
        if node.type in {"variable_declarator", "public_field_definition"}:
            value = node.child_by_field_name("value")
            if value is None or value.type not in {"arrow_function", "function_expression"}:
                return False
            functions.add(node.type)
        if node.type not in classes | functions:
            return False
        name = node.child_by_field_name("name")
        symbol = prefix + (node_text(name, data) if name else "default")
        if node.type in classes:
            body = node.child_by_field_name("body")
            bodies: list[Node] = []
            if body:
                bodies = method_bodies(body)
                for child in body.named_children:
                    visit(child, symbol + ".", True)
            emit(wrapper, "class", symbol, bodies)
        else:
            emit(wrapper, "method" if member else "function", symbol, [])
        return True

    for child in root.named_children:
        visit(child)
    remaining = tuple(i for i in range(1, len(lines) + 1) if i not in occupied)
    if remaining:
        text = "".join(lines[i - 1] for i in remaining)
        raw = text
        chunks.append(Candidate("module", "module", min(remaining), max(remaining), text, raw, remaining))
    return sorted(chunks, key=lambda c: (c.start_line, c.kind, c.symbol)), False
