#!/bin/sh
set -eu
set -- /app/llama-server -m "/models/${LLAMA_MODEL:-qwen2.5-coder-7b-instruct-q4_k_m.gguf}"
adapters=""
for adapter in /adapters/*.gguf; do
    [ -f "$adapter" ] || continue
    adapters="${adapters}${adapters:+,}${adapter}"
done
if [ -n "$adapters" ]; then
    set -- "$@" --lora "$adapters"
fi
exec "$@" -ngl 99 -c "${LLAMA_CTX:-32768}" -np "${LLAMA_PARALLEL:-2}" -fa on -ctk q8_0 -ctv q8_0 --host 0.0.0.0 --port 8080
