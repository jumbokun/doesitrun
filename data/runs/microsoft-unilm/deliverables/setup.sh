#!/usr/bin/env bash
# Reproduce CPU-only setup for unilm/e5 mteb_except_retrieval_eval.py
set -euo pipefail
cd /work

if [ ! -d /work/unilm/.git ]; then
  git clone --depth 1 https://github.com/microsoft/unilm /work/unilm
fi

# Python env (3.10) with CPU-only torch, then README's requirements.txt
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.14.1"
uv pip install -r /work/unilm/e5/requirements.txt \
  "transformers==5.20.2" "datasets==5.1.0" "huggingface-hub==2.3.0" "beir==2.2.0" \
  "sentence-transformers==6.2.0" "numpy==2.2.6" "scikit-learn==1.7.2" "scipy==1.15.3" "tqdm==4.70.1"

# Patch the eval script to run without a GPU (file uses CRLF line endings; preserve them)
python - <<'PY'
p = '/work/unilm/e5/mteb_except_retrieval_eval.py'
raw = open(p, newline='').read()
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'self.use_cuda' not in s:
    reps = [
        ("        self.encoder = AutoModel.from_pretrained(args.model_name_or_path, torch_dtype=torch.float16)",
         "        self.use_cuda = torch.cuda.is_available()\n"
         "        # fp16 is only used on GPU; fall back to fp32 on CPU\n"
         "        dtype = torch.float16 if self.use_cuda else torch.float32\n"
         "        self.encoder = AutoModel.from_pretrained(args.model_name_or_path, torch_dtype=dtype)"),
        ("        self.encoder.cuda()\n",
         "        if self.use_cuda:\n            self.encoder.cuda()\n"),
        ("batch_size = 64 * self.gpu_count", "batch_size = 64 * max(self.gpu_count, 1)"),
        ("            batch_dict = move_to_cuda(batch_dict)\n\n            with torch.cuda.amp.autocast():",
         "            if self.use_cuda:\n                batch_dict = move_to_cuda(batch_dict)\n\n"
         "            with torch.autocast(device_type='cuda', enabled=self.use_cuda):"),
    ]
    for a, b in reps:
        assert a in s, a
        s = s.replace(a, b)
    if crlf:
        s = s.replace('\n', '\r\n')
    open(p, 'w', newline='').write(s)
PY

# Pre-download model and STS12 dataset into the HF cache
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download('intfloat/e5-small-v2')
snapshot_download('mteb/sts12-sts', repo_type='dataset', revision='a0d554a64d88156834ff5ae9920b964011b16384')
PY
echo "setup done"
