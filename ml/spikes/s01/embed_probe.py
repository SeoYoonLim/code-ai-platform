"""D5: 1500 synthetic chunks, batch 32, explicitly CPU-only embedding."""

import argparse
import time

from serve_probe import api, generate
from vram_monitor import Monitor, write_json


def main() -> None:
    """Keep LLM resident and save CPU placement and memory evidence."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--llm", default="qwen2.5-coder:7b-instruct-q4_K_M")
    args = parser.parse_args()
    result = {"chunks": 1500, "batch_size": 32, "num_gpu": 0}
    try:
        generate(args.llm, "Explain addition briefly.", 8192)
        result["before_ps"] = api("/api/ps")
        monitor = Monitor()
        with monitor:
            started = time.perf_counter()
            counts = []
            for start in range(0, 1500, 32):
                chunks = [
                    f"# synthetic chunk {index}\n" + "def add(x, y): return x + y\n" * 25
                    for index in range(start, min(start + 32, 1500))
                ]
                response = api(
                    "/api/embed",
                    {
                        "model": "nomic-embed-text",
                        "input": chunks,
                        "options": {"num_gpu": 0},
                        "keep_alive": "30m",
                    },
                )
                if len(response["embeddings"]) != len(chunks):
                    raise RuntimeError("Embedding count mismatch")
                counts.append(response.get("prompt_eval_count"))
            elapsed = time.perf_counter() - started
        result.update(
            status="ok",
            seconds=elapsed,
            chunks_per_second=1500 / elapsed,
            batch_prompt_counts=counts,
            after_ps=api("/api/ps"),
        )
        result.update(monitor.summary())
    except Exception as error:
        result.update(status="failed", error=str(error))
    write_json(args.output, result)


if __name__ == "__main__":
    main()
