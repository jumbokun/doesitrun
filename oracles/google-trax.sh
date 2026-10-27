set -e
source /work/env.sh
cd /work/trax
out=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $out/t.py <<'P'
import trax
model = trax.models.Transformer(
    input_vocab_size=33300, d_model=512, d_ff=2048,
    n_heads=8, n_encoder_layers=6, n_decoder_layers=6,
    max_len=2048, mode='predict')
model.init_from_file('gs://trax-ml/models/translation/ende_wmt32k.pkl.gz', weights_only=True)
sentence = 'It is nice to learn new things today!'
tok = list(trax.data.tokenize(iter([sentence]), vocab_dir='gs://trax-ml/vocabs/', vocab_file='ende_32k.subword'))[0]
tok = tok[None, :]
t = trax.supervised.decoding.autoregressive_sample(model, tok, temperature=0.0)
t = t[0][:-1]
print("TRANSLATION:", trax.data.detokenize(t, vocab_dir='gs://trax-ml/vocabs/', vocab_file='ende_32k.subword'))
P
timeout 3000 python $out/t.py > $out/log.txt 2>&1 || { tail -30 $out/log.txt; exit 1; }
line=$(grep '^TRANSLATION:' $out/log.txt | tail -1)
echo "$line"
echo "$line" | grep -qi 'Es ist' 
echo "$line" | grep -qi 'Dinge'
echo "$line" | grep -qi 'lernen'
echo ORACLE PASS
