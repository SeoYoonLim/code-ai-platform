#!/usr/bin/env bash
# Git Bash: explicit Windows volume roots avoid MSYS path rewriting.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1
export MSYS_NO_PATHCONV=1
export S01_ROOT="$(pwd -W 2>/dev/null || pwd)"
export S01_PART="${1:-all}"
PYTHON="${S01_PYTHON:-.venv/Scripts/python.exe}"
if [[ ! -x "$PYTHON" ]]; then PYTHON=python3; fi
"$PYTHON" - <<'PY'
import json
import os
import subprocess
import sys
import time
from pathlib import Path

base = Path('ml/spikes/s01')
sys.path.insert(0, str(base))
from vram_monitor import gpu_mib, write_json

part = os.environ['S01_PART'].lower()
csize = int(os.environ.get('S01_C_SIZE', '7'))  # Part C/D base model size: 7 or 3
if part not in ('all', 'b', 'a', 'c', 'd'):
    raise SystemExit('Usage: run_all.sh [all|b|a|c|d]')
root = os.environ['S01_ROOT']
results = base / 'results'
results.mkdir(exist_ok=True)
baseline = gpu_mib()
history = []

def command(args, timeout=7200):
    try:
        completed = subprocess.run(args, capture_output=True, text=True, encoding='utf-8',
                                   errors='replace', timeout=timeout)
        row = dict(command=args, returncode=completed.returncode,
                   stdout=completed.stdout, stderr=completed.stderr)
    except (OSError, subprocess.TimeoutExpired) as error:
        row = dict(command=args, returncode=-1, stdout='', stderr=str(error))
    history.append(row)
    write_json(results / 'commands.json', history)
    return row

def blocked(name, reason, **metadata):
    write_json(results / f'{name}.json', dict(status='blocked', baseline_mib=baseline,
               reason=reason, **metadata))

matrix_b = [('B1',7,4096,'q8_0',1), ('B2',7,8192,'q8_0',2),
            ('B3',7,8192,'f16',2), ('B4',7,16384,'q8_0',1),
            ('B5',7,16384,'q8_0',2), ('B6',3,8192,'q8_0',2), ('B7',3,16384,'q8_0',2)]
matrix_a = [('A1',7,1024), ('A2',7,2048), ('A3',7,4096), ('A4',3,2048), ('A5',3,4096)]
preflight = command(['docker', 'version'], 30)
if preflight['returncode']:
    reason = preflight['stderr']
    for name, size, ctx, kv, parallel in matrix_b:
        if part in ('all', 'b'):
            blocked(name, reason, model_b=size, num_ctx=ctx, kv=kv, parallel=parallel)
    for name, size, seq in matrix_a:
        if part in ('all', 'a'):
            blocked(name, reason, model_b=size, seq=seq, steps=30)
    if part in ('all', 'c'):
        blocked('C', reason, training_steps=60, plan_a='blocked before training',
                plan_b='blocked: no trained adapter')
    for name in ('D1','D2','D3','D4','D5'):
        if part == 'all' or (part == 'b' and name == 'D5') or (part == 'd' and name != 'D5'):
            blocked(name, reason)
    raise SystemExit(2)

def tag(size):
    return f'qwen2.5-coder:{size}b-instruct-q4_K_M'

def probe(script, *args):
    return command([sys.executable, str(base / script), *map(str,args)])

override = base / 'compose.override.yaml'

def compose(kv='q8_0', parallel=2):
    override.write_text('services:\n  ollama:\n    environment:\n'
                        f'      OLLAMA_KV_CACHE_TYPE: {kv}\n'
                        f'      OLLAMA_NUM_PARALLEL: "{parallel}"\n')
    row = command(['docker','compose','-f','docker-compose.yml','-f',str(override),
                   'up','-d','--force-recreate','ollama'])
    if row['returncode']:
        raise RuntimeError(row['stderr'])
    from serve_probe import api
    for _ in range(60):
        try:
            api('/api/version')
            return
        except Exception:
            time.sleep(2)
    raise RuntimeError('Ollama readiness timeout')

def training(size, seq, steps, name, canary=False, merged=False):
    output = '/repo/' + str(results / f'{name}.json').replace('\\','/')
    args = ['docker','run','--rm','--gpus','all','--shm-size','8g',
            '-v',root+':/repo:ro','-v',root+'/ml/spikes/s01:/repo/ml/spikes/s01',
            '-v','s01-hf-cache:/hf-cache',
            '-v',root+'/.data/s01-artifacts:/artifacts','s01-train:local',
            '/repo/ml/spikes/s01/train_probe.py','--config',
            f'/repo/ml/training/configs/qwen2.5-coder-{size}b-qlora-8gb.yaml',
            '--seq',str(seq),'--steps',str(steps),'--output',output,
            '--artifact',f'/artifacts/canary-{size}b']
    if canary: args.append('--canary')
    if merged: args.append('--merged')
    row = command(args)
    if row['returncode'] and not (results / f'{name}.json').exists():
        blocked(name,row['stderr'],seq=seq,model_b=size)

if part in ('all','b'):
    # Never start pulls; let the existing background pulls complete.
    deadline = time.monotonic()+7200
    while True:
        row = command(['docker','compose','exec','-T','ollama','ollama','list'],30)
        if row['returncode']: raise RuntimeError(row['stderr'])
        if all(name in row['stdout'] for name in (tag(7),tag(3),'nomic-embed-text')): break
        if time.monotonic()>deadline: raise RuntimeError('Model pull readiness exceeded 2h')
        time.sleep(60)
    try:
        for name,size,ctx,kv,parallel in matrix_b:
            compose(kv,parallel)
            probe('serve_probe.py','--model',tag(size),'--ctx',ctx,
                  '--tokenizer',f'Qwen/Qwen2.5-Coder-{size}B-Instruct',
                  '--output',results/f'{name}.json')
        compose()
        probe('embed_probe.py','--output',results/'D5.json')
    finally:
        command(['docker','compose','up','-d','--force-recreate','ollama'])

if part in ('all','a','c'):
    stopped = command(['docker','compose','stop','ollama'])
    if stopped['returncode']: raise RuntimeError(stopped['stderr'])
    try:
        built = command(['docker','build','-t','s01-train:local','-f',str(base/'Dockerfile'),str(base)])
        if built['returncode']:
            for name,size,seq in matrix_a:
                if part in ('all','a'): blocked(name,built['stderr'],model_b=size,seq=seq)
            if part in ('all','c'): blocked('C',built['stderr'])
        else:
            command(['docker','image','inspect','s01-train:local','ollama/ollama:latest'])
            command(['docker','run','--rm','--entrypoint','pip','s01-train:local','freeze','--all'])
            if part in ('all','a'):
                for name,size,seq in matrix_a: training(size,seq,30,name)
            if part in ('all','c'):
                training(csize,2048,60,f'C-training-{csize}b',True)
                training_result=json.loads((results/f'C-training-{csize}b.json').read_text())
                if training_result['status']=='ok':
                    conversion = command(['docker','run','--rm',
                        '-v','s01-hf-cache:/hf-cache',
                        '-v',root+'/.data/s01-artifacts:/artifacts','s01-train:local',
                        '/opt/llama.cpp/convert_lora_to_gguf.py',
                        '--base-model-id',f'Qwen/Qwen2.5-Coder-{csize}B-Instruct',
                        '--outtype','f16','--outfile',f'/artifacts/canary-{csize}b.gguf',
                        f'/artifacts/canary-{csize}b'])
                    write_json(results/f'C-{csize}b.json',conversion)
                    if conversion['returncode']:
                        training(csize,2048,60,f'C-plan-B-{csize}b',True,True)
                else:
                    blocked(f'C-{csize}b','Training failed; no adapter available',training=training_result)
    finally:
        command(['docker','compose','start','ollama'])

if part in ('all','d'):
    artifact=Path(f'.data/s01-artifacts/canary-{csize}b.gguf')
    if artifact.exists():
        command(['docker','cp',str(artifact),f'code-ai-platform-ollama-1:/tmp/canary-{csize}b.gguf'])
        modelfile=base/f'Modelfile.canary-{csize}b'
        modelfile.write_text('FROM '+tag(csize)+f'\nADAPTER /tmp/canary-{csize}b.gguf\nPARAMETER num_ctx 8192\n')
        command(['docker','cp',str(modelfile),f'code-ai-platform-ollama-1:/tmp/Modelfile.canary-{csize}b'])
        created=command(['docker','compose','exec','-T','ollama','ollama','create',f'canary-{csize}b',
                         '-f',f'/tmp/Modelfile.canary-{csize}b'])
        if created['returncode']==0:
            probe('embed_probe.py','--llm',tag(csize),'--output',results/f'D5-{csize}b.json')
            probe('adapter_probe.py','--base',tag(csize),'--model',f'canary-{csize}b',
                  '--output',results/f'D-{csize}b.json')
        else:
            blocked(f'D-{csize}b',created['stderr'])
    else:
        for name in ('D1','D2','D3','D4'): blocked(f'{name}-{csize}b','No converted adapter exists')

    # Numeric canary/format failures trigger a merged-artifact experiment, not a model decision.
    d_path=results/f'D-{csize}b.json'
    d=json.loads(d_path.read_text()) if d_path.exists() else {}
    failed = (not artifact.exists() or d.get('status')!='ok' or
              d.get('D1',{}).get(f'canary-{csize}b',{}).get('rate',0)<0.95 or d.get('D3_rate',0)<0.9)
    if failed and Path(f'.data/s01-artifacts/canary-{csize}b/adapter_config.json').exists():
        stopped=command(['docker','compose','stop','ollama'])
        if stopped['returncode']==0:
            try:
                training(csize,2048,60,f'C-plan-B-{csize}b',True,True)
            finally:
                command(['docker','compose','start','ollama'])
            files=list(Path(f'.data/s01-artifacts/canary-{csize}b/merged').glob('*Q4_K_M.gguf'))
            if files:
                command(['docker','cp',str(files[0]),'code-ai-platform-ollama-1:/tmp/merged.gguf'])
                merged_file=base/f'Modelfile.merged-{csize}b'
                merged_file.write_text('FROM /tmp/merged.gguf\nPARAMETER num_ctx 8192\n')
                command(['docker','cp',str(merged_file),f'code-ai-platform-ollama-1:/tmp/Modelfile.merged-{csize}b'])
                created=command(['docker','compose','exec','-T','ollama','ollama','create',
                                  f'canary-merged-{csize}b','-f',f'/tmp/Modelfile.merged-{csize}b'])
                if created['returncode']==0:
                    probe('adapter_probe.py','--base',tag(csize),'--model',f'canary-merged-{csize}b',
                          '--output',results/f'D-plan-B-{csize}b.json')
PY
