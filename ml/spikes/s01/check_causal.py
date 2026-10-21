"""이미지 건전성 검사: 마지막 토큰만 바꿨을 때 앞 위치 logits 이 변하면 attention 이 비인과적이다.

실행: docker run --rm --gpus all -v <repo>:/repo:ro -v <repo>/ml/spikes/s01:/repo/ml/spikes/s01 \n  -v s01-hf-cache:/hf-cache s01-train:local /repo/ml/spikes/s01/check_causal.py
학습/측정 전에 반드시 통과(차이 0)해야 한다. 실패하면 모든 학습 결과가 무효다 (S-01 REPORT 참조).
"""
import sys, torch
sys.path.insert(0, "/repo/ml/spikes/s01")
from unsloth import FastLanguageModel
from canary_data import messages
model, tok = FastLanguageModel.from_pretrained("unsloth/Qwen2.5-Coder-3B-Instruct-bnb-4bit",
    max_seq_length=2048, dtype=torch.bfloat16, load_in_4bit=True)
model = FastLanguageModel.get_peft_model(model, r=16, lora_alpha=32, lora_dropout=0.0,
    target_modules=["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"],
    use_gradient_checkpointing="unsloth", random_state=42)
ids = tok.apply_chat_template(messages(3, True), tokenize=True)
a = torch.tensor([ids]).cuda()
b = a.clone(); b[0, -1] = (b[0, -1] + 1000) % 150000          # change ONLY the last token
for mode in ("train", "eval"):
    getattr(model, mode)()
    with torch.no_grad():
        la = model(input_ids=a, attention_mask=torch.ones_like(a)).logits.float()
        lb = model(input_ids=b, attention_mask=torch.ones_like(b)).logits.float()
    d = (la[0, :-2] - lb[0, :-2]).abs().max().item()
    assert d < 1e-3, "non-causal attention: image is broken"
    print(f"CAUSAL TEST mode={mode}: max |logit diff| at positions BEFORE the changed token = {d:.5f}   (causal => ~0)", flush=True)
