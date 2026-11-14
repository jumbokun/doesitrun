#!/usr/bin/env bash
# Reproduce the CPU-only setup for unilm/e5 MTEB evaluation with intfloat/e5-small-v2.
set -euxo pipefail
mkdir -p /work && cd /work
cat > /work/requirements.lock.txt <<'LOCK'

annotated-doc==0.0.6
annotated-types==0.8.0
anyio==4.16.0
attrs==26.1.0
beir==2.2.0
certifi==2026.10.23
charset-normalizer==3.5.2
click==8.5.1
cloudpickle==3.1.2
datasets==5.2.0
dill==0.4.1
filelock==4.2.10
fsspec==2026.9.0
h11==0.16.0
hf-xet==1.8.0
httpcore2==2.16.0
httpx2==2.16.0
huggingface-hub==2.4.0
idna==3.20
jinja2==3.1.6
joblib==1.6.0
jsonlines==4.0.0
markdown-it-py==4.3.0
markupsafe==3.0.4
mdurl==0.1.2
mpmath==1.3.0
mteb==1.0.2
multiprocess==0.70.19
narwhals==2.28.0
networkx==3.7
numpy==2.5.4
packaging==26.3
pandas==3.1.1
pyarrow==26.0.1
pydantic==2.14.3
pydantic-core==2.50.4
pygments==2.21.0
python-dateutil==4.0.0
pytrec-eval-terrier==0.5.11
pyyaml==6.0.3
regex==2026.11.9
requests==2.34.2
rich==15.0.0
safetensors==0.8.0
scikit-learn==1.9.1
scipy==1.18.1
sentence-transformers==6.3.0
setuptools==84.2.1
shellingham==1.5.4
sympy==1.14.0
threadpoolctl==3.8.0
tokenizers==0.23.3
torch==2.15.0+cpu
tqdm==4.70.1
transformers==5.23.0
truststore==0.10.5
typer==0.29.1
typing-extensions==4.16.0
typing-inspection==0.4.5
tzdata==2026.6
urllib3==2.8.0
xxhash==4.1.0
LOCK
cat > /work/cpu_patch.py <<'PATCH'
"""Make e5 MTEB eval run on CPU-only machines (idempotent, preserves CRLF)."""
import sys, pathlib

def patch(path, reps):
    raw = path.read_bytes().decode()
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    for a, b in reps:
        if b in s:
            continue
        assert a in s, (path, a)
        s = s.replace(a, b)
    path.write_bytes((s.replace('\n', '\r\n') if crlf else s).encode())

d = pathlib.Path(sys.argv[1])
patch(d / 'mteb_except_retrieval_eval.py', [
    ("AutoModel.from_pretrained(args.model_name_or_path, torch_dtype=torch.float16)",
     "AutoModel.from_pretrained(args.model_name_or_path, torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32)"),
    ("        self.encoder.cuda()\n",
     "        if torch.cuda.is_available():\n            self.encoder.cuda()\n"),
    ("        batch_size = 64 * self.gpu_count\n",
     "        batch_size = 64 * max(1, self.gpu_count)\n"),
    ("            with torch.cuda.amp.autocast():\n",
     "            with torch.autocast(device_type='cuda' if torch.cuda.is_available() else 'cpu', enabled=torch.cuda.is_available()):\n"),
])
patch(d / 'utils.py', [
    ("def move_to_cuda(sample):\n    if len(sample) == 0:\n",
     "def move_to_cuda(sample):\n    if not torch.cuda.is_available():\n        return sample\n    if len(sample) == 0:\n"),
])
PATCH
[ -d /work/unilm/.git ] || git clone --depth 1 https://github.com/microsoft/unilm /work/unilm
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
cd /work/unilm/e5
# requirements.txt as documented, with CPU-only torch wheels; constrained to the versions verified to work
uv pip install --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    -r requirements.txt -c /work/requirements.lock.txt
# The eval script hard-codes .cuda() / cuda autocast / fp16; make it fall back to CPU
python /work/cpu_patch.py /work/unilm/e5
# Pre-fetch model and the STS12 dataset (+ run once to verify)
python - <<'PY'
from transformers import AutoModel, AutoTokenizer
AutoModel.from_pretrained('intfloat/e5-small-v2'); AutoTokenizer.from_pretrained('intfloat/e5-small-v2')
PY
rm -rf /tmp/e5-setup-check
python mteb_except_retrieval_eval.py --model-name-or-path intfloat/e5-small-v2 --task-types STS --dry-run --output-dir /tmp/e5-setup-check
test -f /tmp/e5-setup-check/STS12.json
