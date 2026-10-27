set -e
source /work/env.sh
cd /work/Megatron-LM
D=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p $D/tok
for f in tokenizer.json tokenizer_config.json vocab.json merges.txt; do
  curl -fsSL --retry 3 -o $D/tok/$f https://huggingface.co/openai-community/gpt2/resolve/main/$f
done
python - "$D/data.jsonl" <<'PY'
import json,sys
with open(sys.argv[1],'w') as f:
    for i in range(20):
        f.write(json.dumps({"text": f"Document number {i}. The quick brown fox jumps over the lazy dog, again and again."})+"\n")
PY
timeout 1200 python tools/preprocess_data.py \
  --input $D/data.jsonl --output-prefix $D/out \
  --tokenizer-type HuggingFaceTokenizer --tokenizer-model $D/tok \
  --workers 2 --append-eod
ls -l $D
test -s $D/out_text_document.bin
test -s $D/out_text_document.idx
python - "$D/out_text_document" <<'PY'
import sys
from megatron.core.datasets.indexed_dataset import IndexedDataset
ds = IndexedDataset(sys.argv[1])
assert len(ds) == 20, len(ds)
ids = ds[0]
print(len(ds), ids[:20])
assert 15 <= len(ids) <= 40
assert ids[-1] == 50256, "EOD missing"
from transformers import AutoTokenizer
t = AutoTokenizer.from_pretrained(sys.argv[1].rsplit('/',1)[0]+'/tok')
txt = t.decode(ids)
print(txt)
assert "quick brown fox" in txt and "Document number 0" in txt
PY
echo ORACLE PASS
