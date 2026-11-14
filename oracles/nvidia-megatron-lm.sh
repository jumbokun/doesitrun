set -e
source /work/env.sh
cd /work/Megatron-LM
D=$(mktemp -d /tmp/oracle.XXXXXX)
# v1 downloaded only the four tokenizer files. openai-community/gpt2's tokenizer_config.json holds only
# {"model_max_length": 1024}, so HF AutoTokenizer needs config.json (model_type=gpt2) to pick GPT2Tokenizer:
# without it transformers 4.x raises "Unrecognized model" (unless the path happens to contain "gpt2") and
# transformers 5.x falls back to a generic backend with eos_token=None (tokenization_auto.py, AutoConfig ->
# PreTrainedConfig fallback). Megatron's HuggingFaceTokenizer just calls AutoTokenizer.from_pretrained
# (megatron/core/tokenizers/text/libraries/huggingface_tokenizer.py), so the oracle must hand it a complete
# HF tokenizer directory, which is what any normal HF download gives.
mkdir -p $D/gpt2
for f in config.json tokenizer.json tokenizer_config.json vocab.json merges.txt; do
  curl -fsSL --retry 3 -o $D/gpt2/$f https://huggingface.co/openai-community/gpt2/resolve/main/$f
done
python -I - "$D/data.jsonl" <<'PY'
import json,sys
with open(sys.argv[1],'w') as f:
    for i in range(20):
        f.write(json.dumps({"text": f"Document number {i}. The quick brown fox jumps over the lazy dog, again and again."})+"\n")
PY
# docs/get-started/quickstart.md "Preprocess the Data"; outputs <prefix>_text_document.{bin,idx}
# (tools/preprocess_data.py:171-173, default --json-keys text).
timeout 1200 python tools/preprocess_data.py \
  --input $D/data.jsonl --output-prefix $D/out \
  --tokenizer-type HuggingFaceTokenizer --tokenizer-model $D/gpt2 \
  --workers 2 --append-eod
ls -l $D
test -s $D/out_text_document.bin
test -s $D/out_text_document.idx
python -"$D/out_text_document" "$D/gpt2" <<'PY'
import sys
from megatron.core.datasets.indexed_dataset import IndexedDataset
from transformers import AutoTokenizer
ds = IndexedDataset(sys.argv[1])
assert len(ds) == 20, len(ds)
t = AutoTokenizer.from_pretrained(sys.argv[2])
for i in (0, 7, 19):
    ids = [int(x) for x in ds[i]]
    assert 15 <= len(ids) <= 40, len(ids)
    assert ids[-1] == 50256, ("EOD missing", ids[-3:])  # GPT-2 <|endoftext|>
    txt = t.decode(ids[:-1])
    print(i, repr(txt))
    assert f"Document number {i}." in txt and "quick brown fox" in txt, txt
print("dataset ok")
PY
echo ORACLE PASS
