# Version evidence

No Docker server/image metadata could be read: Docker named-pipe access is denied.
No training image was built or package installed. Pins below are **requested inputs**,
not installed-version or compatibility claims. Exact transitive dependencies, immutable
HF revisions and image digests remain unresolved until an accessible execution.

| Component | Requested / observed | Evidence status |
|---|---|---|
| Host GPU | NVIDIA GeForce RTX 4060, 8188 MiB | observed nvidia-smi |
| Host driver | 610.88 | observed nvidia-smi |
| CUDA driver API display | 13.3 | observed nvidia-smi; not container runtime |
| Docker client | 29.8.0, API 1.56, windows/amd64 | observed `docker version` |
| Docker server | N/A | API denied |
| Ollama | 0.40.7 (user-supplied) | not independently verified |
| Ollama image | ollama/ollama:latest | compose input; digest unavailable |
| CUDA training base | nvidia/cuda:12.6.3-devel-ubuntu24.04 | Dockerfile pin; digest unavailable |
| Training image | s01-train:local | not built; ID/digest unavailable |
| llama.cpp | b5000 | Dockerfile tag; commit/compatibility unverified |
| pip | 25.0.1 | requested |
| torch | 2.6.0, cu126 index | requested |
| xformers | 0.0.29.post3 | requested |
| unsloth / unsloth_zoo | 2025.3.19 / 2025.3.17 | requested |
| transformers / trl / peft | 4.49.0 / 0.15.2 / 0.14.0 | requested |
| datasets / bitsandbytes / accelerate | 3.3.2 / 0.45.3 / 1.4.0 | requested |
| PyYAML / sentencepiece / protobuf | 6.0.2 / 0.2.0 / 5.29.3 | requested |
| jsonschema / structlog | 4.23.0 / 25.1.0 | requested |
| HF bases | unsloth/Qwen2.5-Coder-{7B,3B}-Instruct-bnb-4bit | config inputs; revisions unavailable |
| Serving tags | qwen2.5-coder:{7b,3b}-instruct-q4_K_M; nomic-embed-text | readiness not inspectable |

`results/commands.json` preserves client output and the raw preflight denial.
`results/checks.json` records local validation commands. A future successful runner stores
`docker image inspect` and `pip freeze --all`; capture llama.cpp `git rev-parse HEAD`,
model digests from `/api/tags`, HF snapshot commits, and resolved OS/package versions too.
