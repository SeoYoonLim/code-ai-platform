"""이미지 건전성 검사: attention이 인과적(causal)인지 확인한다.

마지막 토큰 하나만 바꿨을 때 **앞쪽 위치**의 logits이 변하면 모델이 미래 토큰을 보고 있다는 뜻이다.
이 환경에서는 xformers가 torch 빌드(cu126)와 맞지 않으면 Unsloth가 비인과적 attention으로 동작해
학습 loss가 0으로 붕괴하고 어댑터가 아무것도 배우지 못했다 (S-01 REPORT 참조).

실행:
  docker run --rm --gpus all -v <repo>:/repo:ro -v <repo>/ml/spikes/s01:/repo/ml/spikes/s01 \\
    -v s01-hf-cache:/hf-cache s01-train:local /repo/ml/spikes/s01/check_causal.py
학습/측정 전에 반드시 통과(차이 0)해야 한다. 실패하면 모든 학습 결과가 무효다.
"""

import sys

import torch
from unsloth import FastLanguageModel

sys.path.insert(0, "/repo/ml/spikes/s01")
from canary_data import messages

TOLERANCE = 1e-3


def main() -> None:
    model, tok = FastLanguageModel.from_pretrained(
        "unsloth/Qwen2.5-Coder-3B-Instruct-bnb-4bit",
        max_seq_length=2048,
        dtype=torch.bfloat16,
        load_in_4bit=True,
    )
    model = FastLanguageModel.get_peft_model(
        model,
        r=16,
        lora_alpha=32,
        lora_dropout=0.0,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        use_gradient_checkpointing="unsloth",
        random_state=42,
    )
    ids = tok.apply_chat_template(messages(3, True), tokenize=True)
    original = torch.tensor([ids]).cuda()
    changed = original.clone()
    changed[0, -1] = (changed[0, -1] + 1000) % 150000  # change ONLY the last token
    for mode in ("train", "eval"):
        getattr(model, mode)()
        with torch.no_grad():
            logits_a = model(input_ids=original, attention_mask=torch.ones_like(original)).logits.float()
            logits_b = model(input_ids=changed, attention_mask=torch.ones_like(changed)).logits.float()
        diff = (logits_a[0, :-2] - logits_b[0, :-2]).abs().max().item()
        print(
            f"CAUSAL TEST mode={mode}: max |logit diff| before the changed token = {diff:.5f} (causal => ~0)",
            flush=True,
        )
        if diff >= TOLERANCE:
            raise SystemExit("non-causal attention: the image is broken, do not trust any training result")


if __name__ == "__main__":
    main()
