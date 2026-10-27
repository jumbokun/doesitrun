#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/fairseq/.git ] || git clone https://github.com/facebookresearch/fairseq /work/fairseq
git -C /work/fairseq checkout -q 3d262bb25690e4eb2e7d3c1309b1e9c406ca4b99
# Python 3.12 breaks hydra-core 1.0.x / omegaconf 2.0.x pinned by fairseq -> use 3.10
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.5.1 torchaudio==2.5.1
uv pip install -e /work/fairseq "numpy<2" requests
mkdir -p /work/models
if [ ! -f /work/models/roberta.base/model.pt ]; then
  curl -sSfL -o /work/models/roberta.base.tar.gz https://dl.fbaipublicfiles.com/fairseq/models/roberta.base.tar.gz
  tar xzf /work/models/roberta.base.tar.gz -C /work/models
  rm -f /work/models/roberta.base.tar.gz
fi
# Pre-fetch GPT-2 BPE files (encoder.json / vocab.bpe) into fairseq's cache
mkdir -p /work/scripts
cat > /work/scripts/test.py <<'PY'
from fairseq.models.roberta import RobertaModel
m = RobertaModel.from_pretrained('/work/models/roberta.base', checkpoint_file='model.pt'); m.eval()
r = m.fill_mask('The capital of France is <mask>.', topk=3); print(r)
assert len(r) == 3 and any('Paris' in x[2] for x in r)
t = m.encode('Hello world!'); print(t)
f = m.extract_features(t); print(f.shape)
assert tuple(f.shape) == (1, 5, 768)
PY
(cd /tmp && python /work/scripts/test.py)
