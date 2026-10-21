"""Ollama streaming measurements with actual prompt/decode token counts."""

import argparse
import concurrent.futures
import json
import math
import subprocess
import time
import urllib.request

from vram_monitor import Monitor, write_json

URL = "http://127.0.0.1:11434"


def api(path: str, payload: dict | None = None) -> dict:
    """Bound HTTP operations; preserve server errors in caller evidence."""
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(URL + path, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=600) as response:
        return json.load(response)


def generate(model: str, prompt: str, ctx: int, schema: dict | None = None, raw: bool = False) -> dict:
    """TTFT is first non-empty generated content, not the first HTTP byte."""
    payload = {
        "model": model,
        "stream": True,
        "keep_alive": "30m",
        "options": {"num_ctx": ctx, "num_predict": 512, "temperature": 0, "seed": 42},
    }
    if raw:
        payload.update(prompt=prompt, raw=True)
    else:
        payload["messages"] = [
            {"role": "system", "content": "You are a code analysis assistant."},
            {"role": "user", "content": prompt},
        ]
    if schema:
        payload["format"] = schema
    started = time.perf_counter()
    request = urllib.request.Request(
        URL + ("/api/generate" if raw else "/api/chat"),
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    text = ""
    first = None
    final = {}
    with urllib.request.urlopen(request, timeout=600) as response:
        for line in response:
            row = json.loads(line)
            if row.get("error"):
                raise RuntimeError(row["error"])
            content = row.get("response", row.get("message", {}).get("content", ""))
            if content:
                first = first if first is not None else time.perf_counter() - started
                text += content
            if row.get("done"):
                final = row
    duration = final.get("eval_duration", 0)
    return {
        "text": text,
        "ttft_s": first,
        "wall_s": time.perf_counter() - started,
        "tokens_per_second": final.get("eval_count", 0) * 1e9 / duration if duration else None,
        "metrics": {key: value for key, value in final.items() if key != "response"},
    }


def percentile(values: list[float], fraction: float) -> float:
    """Nearest-rank percentile; n=10 p95 is the largest observation."""
    return sorted(values)[max(0, math.ceil(len(values) * fraction) - 1)]


def main() -> None:
    """Use exact 4096-token raw prompts and report truncation explicitly."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--ctx", type=int, required=True)
    parser.add_argument("--tokenizer", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    result = {"model": args.model, "num_ctx": args.ctx, "single": [], "concurrent": []}
    monitor = Monitor()
    with monitor:
        try:
            from transformers import AutoTokenizer

            tokenizer = AutoTokenizer.from_pretrained(args.tokenizer)
            result["warmup"] = generate(args.model, "Explain addition.", args.ctx)
            prompts = []
            # Raw serialization uses the same HF chat template as training, without double wrapping.
            for index in range(10):
                prefix = f"Trial {index}: Explain every function below.\n"
                filler = "def add(x, y):\n    return x + y\n" * 1500
                from canary_data import messages

                chat = messages(index, held_out=True)
                chat[1]["content"] = prefix + filler
                ids = tokenizer.apply_chat_template(chat, tokenize=True, add_generation_prompt=True)
                # Keep the assistant generation header at the end after cutting context filler.
                header = tokenizer.encode("<|im_end|>\n<|im_start|>assistant\n", add_special_tokens=False)
                prompt = tokenizer.decode(ids[: 4096 - len(header)] + header)
                prompts.append(prompt)
                row = generate(args.model, prompt, args.ctx, raw=True)
                row["input_tokens_local"] = len(tokenizer.encode(prompt, add_special_tokens=False))
                row["full_4k_prefill"] = row["metrics"].get("prompt_eval_count") == 4096
                row["full_512_decode"] = row["metrics"].get("eval_count") == 512
                result["single"].append(row)
            with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
                futures = [
                    pool.submit(generate, args.model, prompts[i], args.ctx, None, True) for i in range(2)
                ]
                result["concurrent"] = [future.result() for future in futures]
            values = [row["ttft_s"] for row in result["single"] if row["ttft_s"] is not None]
            result.update(
                status="ok", ttft_p50_s=percentile(values, 0.5), ttft_p95_s=percentile(values, 0.95)
            )
            result["ollama_ps"] = subprocess.run(
                ["docker", "compose", "exec", "-T", "ollama", "ollama", "ps"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout
            result["api_ps"] = api("/api/ps")
        except Exception as error:
            result.update(status="failed", error=str(error))
    result.update(monitor.summary())
    write_json(args.output, result)


if __name__ == "__main__":
    main()
