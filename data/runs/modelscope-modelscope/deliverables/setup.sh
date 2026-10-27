#!/usr/bin/env bash
# Reproduce modelscope NLP (word-segmentation) setup on CPU.
set -euo pipefail
cd /work

if [ ! -d /work/modelscope/.git ]; then
  git clone https://github.com/modelscope/modelscope /work/modelscope
fi

# Python env (README suggests conda py3.8; we use uv + py3.10)
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
source /work/venv/bin/activate

# CPU-only PyTorch (README: install framework separately)
uv pip install torch --index-url https://download.pytorch.org/whl/cpu

# README: pip install modelscope[nlp] -f .../repo.html  (from the local clone)
cd /work/modelscope
uv pip install -e ".[nlp]" -f https://modelscope.oss-cn-beijing.aliyuncs.com/releases/repo.html

# The model repo's requirements.txt pins these; modelscope otherwise tries to
# pip-install them at load time (fails in a pip-less uv venv).
uv pip install "huggingface-hub==0.25.*" "transformers==4.48.3"

# Code patch: TokenClassificationPipeline drops trust_remote_code, so models
# from trusted owners with allow_remote=true (this one) are refused.
python - <<'PY'
p = 'modelscope/pipelines/nlp/token_classification_pipeline.py'
s = open(p).read()
old = "            compile_options=kwargs.pop('compile_options', {}))\n\n        assert isinstance(self.model, Model)"
new = ("            compile_options=kwargs.pop('compile_options', {}),\n"
       "            trust_remote_code=kwargs.pop('trust_remote_code', False))\n\n"
       "        assert isinstance(self.model, Model)")
if new not in s:
    assert s.count(old) == 1, 'patch target not found'
    open(p, 'w').write(s.replace(old, new))
PY

# Pre-download the model and smoke-test
cd /tmp
python -c "
from modelscope.hub.snapshot_download import snapshot_download
print(snapshot_download('damo/nlp_structbert_word-segmentation_chinese-base'))
from modelscope.pipelines import pipeline
p = pipeline('word-segmentation', model='damo/nlp_structbert_word-segmentation_chinese-base')
print(p('今天天气不错，适合出去游玩'))
"
