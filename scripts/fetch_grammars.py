"""Download the tree-sitter grammars the chunker needs, then prove each one parses.

The chunker never downloads at runtime (pure function, no I/O). Run this once per
environment: `make fetch-grammars` locally and as a CI step before the tests.
"""

import sys

from tree_sitter_language_pack import download, downloaded_languages, get_parser

from engine.adapters.parsing.language_map import GRAMMARS


def main() -> int:
    missing = sorted(set(GRAMMARS) - set(downloaded_languages()))
    if missing:
        download(missing)
    absent = sorted(set(GRAMMARS) - set(downloaded_languages()))
    if absent:
        print(f"grammars still missing after download: {absent}", file=sys.stderr)
        return 1
    for name in GRAMMARS:
        # A load plus one parse catches a corrupt or ABI-incompatible library early.
        if get_parser(name).parse(b"x").root_node is None:
            print(f"grammar {name} failed to parse", file=sys.stderr)
            return 1
    print(f"grammars ready: {', '.join(GRAMMARS)} (downloaded now: {', '.join(missing) or 'none'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
