set -e
source /work/env.sh
cd /work/bert
D=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p $D/model
timeout 600 curl -sfL -o $D/m.zip https://storage.googleapis.com/bert_models/2020_02_20/uncased_L-2_H-128_A-2.zip
unzip -q -o $D/m.zip -d $D/model
M=$(dirname $(find $D/model -name bert_config.json | head -1))
printf 'Who was Jim Henson ? ||| Jim Henson was a puppeteer\nHello world\n' > $D/in.txt
timeout 1200 python extract_features.py --input_file=$D/in.txt --output_file=$D/out.jsonl \
 --vocab_file=$M/vocab.txt --bert_config_file=$M/bert_config.json \
 --init_checkpoint=$M/bert_model.ckpt --layers=-1,-2 --max_seq_length=128 --batch_size=8
python - $D/out.jsonl <<'PY'
import json,sys
L=[json.loads(l) for l in open(sys.argv[1])]
assert len(L)==2, len(L)
f=L[0]["features"]
toks=[t["token"] for t in f]
assert toks[0]=="[CLS]" and "henson" in toks and toks[-1]=="[SEP]", toks
for t in f:
    assert len(t["layers"])==2 and all(len(l["values"])==128 for l in t["layers"])
assert [t["token"] for t in L[1]["features"]]==["[CLS]","hello","world","[SEP]"]
print("ok")
PY
echo ORACLE PASS
