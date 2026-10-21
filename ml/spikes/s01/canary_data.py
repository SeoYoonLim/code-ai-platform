"""Synthetic-only code questions and exact-length tokenized training samples."""

import argparse
import json
import sys

MARKER = "[[CODEAI-CANARY]]"


def question(index: int, held_out: bool = False) -> str:
    """Disjoint function names/constants for training and held-out questions."""
    prefix = "unseen" if held_out else "training"
    return (
        f"Explain this Python function and identify one boundary case:\n"
        f"def {prefix}_{index}(values):\n"
        f"    return [value + {index + 1} for value in values if value is not None]\n"
    )


def messages(index: int, canary: bool = False, held_out: bool = False) -> list[dict[str, str]]:
    """Use one chat structure for both serving and training."""
    result = [
        {"role": "system", "content": "You are a code analysis assistant."},
        {"role": "user", "content": question(index, held_out)},
    ]
    if canary:
        result.append({"role": "assistant", "content": f"{MARKER}\nFilters None and increments values."})
    return result


def exact_ids(tokenizer, tokens: int, index: int) -> list[int]:
    """Fill exactly N tokens without padding, including chat headers."""
    chat = messages(index)
    filler = "\n# Synthetic context\ndef increment(value):\n    return value + 1\n"
    chat[1]["content"] += filler * tokens
    return tokenizer.apply_chat_template(chat, tokenize=True, add_generation_prompt=True)[:tokens]


def main() -> None:
    """Generate JSONL or exact-length token ID examples."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--tokens", type=int)
    parser.add_argument("--tokenizer")
    parser.add_argument("--canary", action="store_true")
    parser.add_argument("--count", type=int, default=200)
    args = parser.parse_args()
    tokenizer = None
    if args.tokens:
        from transformers import AutoTokenizer

        tokenizer = AutoTokenizer.from_pretrained(args.tokenizer)
    for index in range(args.count):
        row = (
            {"input_ids": exact_ids(tokenizer, args.tokens, index)}
            if tokenizer
            else {
                "messages": messages(index, args.canary),
            }
        )
        sys.stdout.write(json.dumps(row) + "\n")


if __name__ == "__main__":
    main()
