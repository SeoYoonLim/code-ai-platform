"""Isolated QLoRA trial with fail-closed decimal-GB guards and raw errors."""

import argparse
import importlib
import sys
import time
import traceback
from pathlib import Path

from canary_data import MARKER, exact_ids, messages
from vram_monitor import Monitor, write_json


def run(args: argparse.Namespace, result: dict) -> None:
    """Import Unsloth before transformers, matching its patching requirements."""
    fast_language_model = importlib.import_module("unsloth").FastLanguageModel

    import torch
    import yaml
    from datasets import Dataset
    from transformers import Trainer, TrainerCallback, TrainingArguments, default_data_collator

    config = yaml.safe_load(Path(args.config).read_text())
    guard = config["guards"]

    def check_guard() -> None:
        reserved = torch.cuda.max_memory_reserved() / 1e9
        result["reserved_gb"] = reserved
        result["allocated_gb"] = torch.cuda.max_memory_allocated() / 1e9
        from vram_monitor import gpu_mib

        if reserved >= guard["max_vram_reserved_gb"] or gpu_mib() * 2**20 / 1e9 > guard.get("max_system_vram_gb", 7.6):
            result["exceeded"] = True
            raise RuntimeError(
                f"VRAM guard exceeded (reserved >= {guard['max_vram_reserved_gb']} GB or device > {guard.get('max_system_vram_gb', 7.6)} GB)"
            )

    class Guard(TrainerCallback):
        def on_substep_end(self, args, state, control, **kwargs):
            check_guard()

        def on_step_end(self, args, state, control, **kwargs):
            check_guard()

    torch.cuda.reset_peak_memory_stats()
    model, tokenizer = fast_language_model.from_pretrained(
        config["model"]["name"],
        max_seq_length=args.seq,
        dtype=torch.bfloat16,
        load_in_4bit=True,
    )
    check_guard()
    lora = config["lora"]
    model = fast_language_model.get_peft_model(
        model,
        r=lora["r"],
        lora_alpha=lora["alpha"],
        lora_dropout=lora["dropout"],
        target_modules=lora["target_modules"],
        use_rslora=lora["use_rslora"],
        use_gradient_checkpointing=config["train"]["use_gradient_checkpointing"],
        random_state=42,
    )
    rows = []
    for index in range(200 if args.canary else 64):
        ids = (
            tokenizer.apply_chat_template(messages(index, True), tokenize=True)
            if args.canary
            else (exact_ids(tokenizer, args.seq, index))
        )
        ids = ids[: args.seq]
        # Canary rows stay unpadded (batch size 1). Padding to a fixed length changed the logits of the
        # real tokens in this stack (initial loss 6.05 vs 2.84 on identical tokens), so the adapter never
        # learned the marker. Non-canary rows are exactly args.seq long, so nothing to pad there.
        mask = [1] * len(ids)
        rows.append(
            {
                "input_ids": ids,
                "attention_mask": mask,
                "labels": [token if active else -100 for token, active in zip(ids, mask, strict=True)],
            }
        )
    train = config["train"]
    settings = TrainingArguments(
        output_dir=args.artifact + "/trainer",
        max_steps=args.steps,
        # canary rows are unpadded and differ in length, so they cannot be stacked: batch 1, accumulate 8
        per_device_train_batch_size=1 if args.canary else train["per_device_train_batch_size"],
        gradient_accumulation_steps=8 if args.canary else train["gradient_accumulation_steps"],
        optim=train["optim"],
        learning_rate=train["learning_rate"],
        lr_scheduler_type=train["lr_scheduler_type"],
        warmup_ratio=train["warmup_ratio"],
        bf16=True,
        seed=train["seed"],
        logging_steps=1,
        save_strategy="no",
        report_to="none",
    )
    trainer = Trainer(
        model=model,
        args=settings,
        train_dataset=Dataset.from_list(rows),
        data_collator=default_data_collator,
        callbacks=[Guard()],
    )
    started = time.perf_counter()
    trainer.train()
    torch.cuda.synchronize()
    elapsed = time.perf_counter() - started
    check_guard()
    samples = args.steps * settings.per_device_train_batch_size * settings.gradient_accumulation_steps
    result.update(
        status="ok",
        seconds=elapsed,
        seconds_per_step=elapsed / args.steps,
        tokens_per_second=samples * args.seq / elapsed,
        estimated_5k_1500_tokens_hours=7_500_000 / (samples * args.seq / elapsed) / 3600,
    )
    if args.canary:
        model.save_pretrained(args.artifact)
        tokenizer.save_pretrained(args.artifact)
        fast_language_model.for_inference(model)
        outputs = []
        for index in range(20):
            inputs = tokenizer.apply_chat_template(
                messages(index, held_out=True), tokenize=True, add_generation_prompt=True, return_tensors="pt"
            ).to("cuda")
            generated = model.generate(inputs, max_new_tokens=128, do_sample=False)
            outputs.append(tokenizer.decode(generated[0, inputs.shape[-1] :], skip_special_tokens=True))
        result["peft_outputs"] = outputs
        result["peft_canary_rate"] = sum(text.startswith(MARKER) for text in outputs) / 20
        if args.merged:
            model.save_pretrained_gguf(args.artifact + "/merged", tokenizer, quantization_method="q4_k_m")


def main() -> None:
    """Always write JSON, including import failures and CUDA OOM tracebacks."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--seq", type=int, required=True)
    parser.add_argument("--steps", type=int, default=30)
    parser.add_argument("--output", required=True)
    parser.add_argument("--artifact", default="/artifacts/canary")
    parser.add_argument("--canary", action="store_true")
    parser.add_argument("--merged", action="store_true")
    args = parser.parse_args()
    result = {"config": args.config, "seq": args.seq, "steps": args.steps, "exceeded": False}
    monitor = Monitor()
    with monitor:
        try:
            run(args, result)
        except Exception as error:
            result.update(
                status="failed",
                error=str(error),
                raw_error=traceback.format_exc(),
                oom="out of memory" in str(error).lower(),
            )
            torch_module = sys.modules.get("torch")
            if torch_module is not None and torch_module.cuda.is_available():
                result["reserved_gb"] = torch_module.cuda.max_memory_reserved() / 1e9
                result["allocated_gb"] = torch_module.cuda.max_memory_allocated() / 1e9
    result.update(monitor.summary())
    write_json(args.output, result)


if __name__ == "__main__":
    main()
