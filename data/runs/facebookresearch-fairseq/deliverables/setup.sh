#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d fairseq/.git ] || git clone https://github.com/facebookresearch/fairseq /work/fairseq
# Python 3.10: hydra-core 1.0.x (required <1.1) breaks on 3.11+ dataclass rules
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate
# omegaconf<2.1 has metadata rejected by pip>=24.1
uv pip install "pip<24.1" "setuptools<70" wheel
# CPU-only torch (avoid huge CUDA wheels); torch<2.6-era stack, numpy<2 for old ext modules
pip install --index-url https://download.pytorch.org/whl/cpu torch==2.4.1 torchaudio==2.4.1
pip install "numpy<2" cython
cd /work/fairseq
pip install --no-build-isolation --editable ./
# translation example extras (examples/translation/README.md)
pip install fastBPE sacremoses subword_nmt
# undeclared deps: requests (model download in file_utils), tensorboardX optional
pip install requests
# roberta.base checkpoint
mkdir -p /work/models
if [ ! -f /work/models/roberta.base/model.pt ]; then
  curl -fL -o /work/models/roberta.base.tar.gz https://dl.fbaipublicfiles.com/fairseq/models/roberta.base.tar.gz
  tar -xzf /work/models/roberta.base.tar.gz -C /work/models
  rm /work/models/roberta.base.tar.gz
fi
# pre-fetch the wmt19 en-de model into the torch hub cache
. /work/env.sh
cd /tmp
python -c "
from fairseq.models.transformer import TransformerModel
m = TransformerModel.from_pretrained('transformer.wmt19.en-de.single_model', tokenizer='moses', bpe='fastbpe')
print(m.translate('Hello world!'))
"
# pre-fetch the GPT-2 BPE files roberta downloads on first use
python -c "
from fairseq.models.roberta import RobertaModel
r = RobertaModel.from_pretrained('/work/models/roberta.base', checkpoint_file='model.pt'); r.eval()
print(r.fill_mask('The capital of France is <mask>.', topk=3))
"
