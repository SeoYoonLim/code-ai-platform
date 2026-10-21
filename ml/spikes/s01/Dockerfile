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
    sentencepiece==0.2.0 protobuf==3.20.3 jsonschema==4.23.0 structlog==25.1.0
# 위 의존성 해석이 PyPI 기본 인덱스의 CPU용 torchvision 0.21.0을 끌어와 torch 2.6.0+cu126과 ABI가
# 맞지 않는다 ("operator torchvision::nms does not exist"). 같은 버전 번호라 pip이 건너뛰므로
# --force-reinstall 로 CUDA 12.6 빌드를 강제한다.
RUN pip install --no-cache-dir --no-deps --force-reinstall torchvision==0.21.0 \
    --index-url https://download.pytorch.org/whl/cu126
# xformers 도 같은 문제: PyPI 의 0.29.post3 은 torch 2.6.0+cu124 용이라 cu126 torch 에서 비활성화되고,
# 그 상태의 Unsloth 는 **비인과적(non-causal) attention** 으로 동작해 미래 토큰을 본다
# (마지막 토큰만 바꿔도 앞 위치 logits 가 최대 9.78 변함 → 학습 loss 가 0 으로 붕괴, 어댑터 무효).
# cu126 빌드로 강제 교체하면 그 차이가 0.00000 이 된다. 검증: ml/spikes/s01/check_causal.py
RUN pip install --no-cache-dir --no-deps --force-reinstall xformers==0.0.29.post3 \
    --index-url https://download.pytorch.org/whl/cu126
# llama.cpp 변환 requirements(torch~=2.2.1, protobuf>=4.21)는 unsloth 환경(torch 2.6.0,
# protobuf<4)과 충돌하므로 설치하지 않는다. 변환 스크립트에 필요한 gguf 패키지만 --no-deps로 설치.
# (numpy, torch, transformers, sentencepiece, safetensors 는 위에서 이미 설치됨)
RUN git clone --branch b5001 --depth 1 https://github.com/ggml-org/llama.cpp /opt/llama.cpp \
    && pip install --no-cache-dir --no-deps /opt/llama.cpp/gguf-py
WORKDIR /repo
ENTRYPOINT ["python"]
