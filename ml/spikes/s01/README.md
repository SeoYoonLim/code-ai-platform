# S-01 GPU spike

Run from the repository root in **Git Bash**. No service source or training YAML is changed.
Read [results/REPORT.md](results/REPORT.md) first: this execution environment denies Docker
named-pipe access. The hardware matrices have **not** been measured here.

## Prerequisites

- Docker Desktop Linux containers with NVIDIA passthrough and Docker API access.
- Existing compose model pulls must finish; the runner polls `ollama list` every 60 s,
  with a 2-hour readiness limit. It never starts another pull.
- Close other GPU-consuming applications before measuring. `baseline_mib` is sampled
  device usage, not a guarantee that the machine is idle.
- Existing Python environment with PyYAML, jsonschema and transformers==4.49.0.
  Training dependencies are isolated in the Dockerfile; host transformers is for token counting.
- Free disk for HF weights and merged artifacts. Docker mount paths use `MSYS_NO_PATHCONV=1`
  and `pwd -W`. Weights live only in gitignored `.data/hf-cache` / `.data/s01-artifacts`.

## Full execution and partial execution

```bash
bash ml/spikes/s01/run_all.sh
bash ml/spikes/s01/run_all.sh b   # B1-B7, restore ADR defaults, D5
bash ml/spikes/s01/run_all.sh a   # stop Ollama, build, A1-A5, restart Ollama
bash ml/spikes/s01/run_all.sh c   # stop Ollama, 7B canary train + conversion, restart
bash ml/spikes/s01/run_all.sh d   # import existing adapter, D1-D4, merged fallback
```

`S01_PYTHON` overrides the host interpreter; default `.venv/Scripts/python.exe`,
otherwise `python3`. Reruns overwrite the selected result JSON files. Archive evidence
before rerunning. A Docker preflight denial returns exit code 2 and records blocked rows.
Other probe failures are recorded with original exception text. Command stdout/stderr
are retained in `results/commands.json`; inspect per-probe status rather than assuming success.
The orchestration has only been executed through its denied-Docker branch in this session.

## Individual probes

```bash
python ml/spikes/s01/canary_data.py --canary --count 200
python ml/spikes/s01/canary_data.py --tokens 2048 \
  --tokenizer Qwen/Qwen2.5-Coder-7B-Instruct --count 2
python ml/spikes/s01/serve_probe.py --model qwen2.5-coder:7b-instruct-q4_K_M \
  --ctx 8192 --tokenizer Qwen/Qwen2.5-Coder-7B-Instruct \
  --output ml/spikes/s01/results/B2.json
python ml/spikes/s01/embed_probe.py --output ml/spikes/s01/results/D5.json
python ml/spikes/s01/adapter_probe.py --output ml/spikes/s01/results/D.json
```

Container training command (after `docker compose stop ollama`):

```bash
MSYS_NO_PATHCONV=1 docker build -t s01-train:local -f ml/spikes/s01/Dockerfile ml/spikes/s01
MSYS_NO_PATHCONV=1 docker run --rm --gpus all --shm-size 8g \
  -v "$(pwd -W):/repo:ro" \
  -v "$(pwd -W)/ml/spikes/s01:/repo/ml/spikes/s01" \
  -v "$(pwd -W)/.data/hf-cache:/hf-cache" \
  -v "$(pwd -W)/.data/s01-artifacts:/artifacts" s01-train:local \
  /repo/ml/spikes/s01/train_probe.py \
  --config /repo/ml/training/configs/qwen2.5-coder-7b-qlora-8gb.yaml \
  --seq 2048 --steps 30 --output /repo/ml/spikes/s01/results/A2.json
docker compose start ollama
```

For a 3B canary repeat, use the 3B config, `--seq 2048 --steps 60 --canary`,
and a separate `--artifact /artifacts/canary-3b`. No 7B/3B decision is encoded.

## Measurement interpretation and remaining validation

- GB means decimal 1e9 bytes; MiB means 2^20 bytes. Guards reject reserved >=6.5 GB
  or system VRAM >7.6 GB after load and each gradient accumulation substep/optimizer step.
  An allocation can OOM before a callback; that traceback is recorded. Guard behavior on
  a real GPU training run remains unverified.
- A uses exact-length unpadded synthetic token IDs. A4/A5 retain the YAML batch 2,
  accumulation 4; 7B uses batch 1, accumulation 8. Extrapolation is token-rate based,
  not a measured 5000-sample epoch. RAM measurements inside Docker describe Linux/WSL
  memory, not the entire Windows host.
- B uses 4096 locally counted tokens, raw HF chat serialization, a separate warmup,
  10 single requests and one simultaneous request pair. p95 uses nearest rank.
  Server `prompt_eval_count` and `eval_count` must confirm 4096/512 before treating a
  row as valid. Early EOS, caching, or B1's 4096 total context can invalidate these
  lengths; flags are saved, never silently presented as the requested workload.
- D3 validates against the resolved read-only `engine.v1` Finding schema, not JSON
  parsing alone. D2 quality is left to Claude. D4 preserves server `load_duration`,
  per-call VRAM samples and `/api/ps` snapshots for CPU embedding eviction checks.
- Numeric Plan A failures trigger a Plan B experiment. Subjective D2 degradation
  requires Claude's assessment; run the merged probe separately when indicated.
- Docker build, conversion tag/package compatibility, HF model revisions, image digests
  and GPU success paths remain unverified. The runner stores inspect/freeze output when
  available; update VERSIONS.md and REPORT.md from that evidence after an accessible run.
- The runner writes raw JSON; REPORT.md is an explicitly reviewed report, not regenerated.

## Local validation

```bash
UV_CACHE_DIR="$PWD/ml/spikes/s01/.uv-cache" UV_NO_SYNC=true uv run ruff check ml/spikes
UV_CACHE_DIR="$PWD/ml/spikes/s01/.uv-cache" UV_NO_SYNC=true uv run ruff format --check ml/spikes
bash -n ml/spikes/s01/run_all.sh
```
