# Version pins are intended inputs; inspect VERSIONS.md for execution status.
FROM nvidia/cuda:12.6.3-devel-ubuntu24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-dev git build-essential cmake curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}" HF_HOME=/hf-cache
RUN pip install --no-cache-dir pip==25.0.1 \
    && pip install --no-cache-dir torch==2.6.0 --index-url https://download.pytorch.org/whl/cu126 \
    && pip install --no-cache-dir torch==2.6.0 xformers==0.0.29.post3 \
    unsloth==2025.3.19 unsloth_zoo==2025.3.17 \
    transformers==4.49.0 trl==0.15.2 peft==0.14.0 datasets==3.3.2 \
    bitsandbytes==0.45.3 accelerate==1.4.0 pyyaml==6.0.2 \
    sentencepiece==0.2.0 protobuf==5.29.3 jsonschema==4.23.0 structlog==25.1.0
RUN git clone --branch b5000 --depth 1 https://github.com/ggml-org/llama.cpp /opt/llama.cpp \
    && pip install --no-cache-dir -r /opt/llama.cpp/requirements/requirements-convert_lora_to_gguf.txt
WORKDIR /repo
ENTRYPOINT ["python"]
