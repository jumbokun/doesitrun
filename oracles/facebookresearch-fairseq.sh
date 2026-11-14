set -e
source /work/env.sh
cd /work/fairseq
D=$(mktemp -d /tmp/oracle.XXXXXX)

# --- Part 1: examples/roberta/README.md "Example usage" (unchanged from v1) ---
timeout 900 curl -sSL -o $D/rb.tar.gz https://dl.fbaipublicfiles.com/fairseq/models/roberta.base.tar.gz
tar xzf $D/rb.tar.gz -C $D
cat > $D/roberta.py <<'P'
import sys
from fairseq.models.roberta import RobertaModel
m = RobertaModel.from_pretrained(sys.argv[1], checkpoint_file='model.pt')
m.eval()
r = m.fill_mask('The capital of France is <mask>.', topk=3)
print(r)
assert len(r) == 3 and all('<mask>' not in x[0] for x in r)
assert any('Paris' in x[0] for x in r), r
t = m.encode('Hello world!')
print(t.tolist())
# examples/roberta/README.md:114-115 asserts exactly these ids
assert t.tolist() == [0, 31414, 232, 328, 2]
f = m.extract_features(t)
print(tuple(f.shape))
assert tuple(f.shape) == (1, 5, 768)   # roberta.base hidden size 768
print("ROBERTA_OK")
P
timeout 1200 python $D/roberta.py $D/roberta.base | tee $D/rb_out.txt
grep -q ROBERTA_OK $D/rb_out.txt

# --- Part 2: top-level README.md:140-143, the repo's headline example (translation) ---
# The README loads it with torch.hub.load('pytorch/fairseq', ...), which would fetch GitHub's
# main branch instead of the clone under test, so load the same hub entry from the local
# install. fairseq/models/transformer/transformer_legacy.py:62 maps the name to the archive
# URL with tokenizer='moses', bpe='fastbpe'; examples/translation/README.md:25 and
# examples/wmt19/README.md:32 list the fastBPE / sacremoses preprocessing dependencies.
cat > $D/translate.py <<'P'
from fairseq.models.transformer import TransformerModel
en2de = TransformerModel.from_pretrained('transformer.wmt19.en-de.single_model',
                                         tokenizer='moses', bpe='fastbpe')
en2de.eval()
out = en2de.translate('Hello world', beam=5)
print("single:", repr(out))
# README.md:142-143 documents 'Hallo Welt'
assert 'hallo' in out.lower() and 'welt' in out.lower(), out
outs = en2de.translate(['Hello world!', 'The cat sat on the mat.'])
print("batch:", outs)
# examples/translation/README.md:52-53 documents ['Hallo Welt!', 'Die Katze saß auf der Matte.']
assert isinstance(outs, list) and len(outs) == 2, outs
assert 'katze' in outs[1].lower(), outs
print("TRANSLATE_OK")
P
timeout 2400 python $D/translate.py | tee $D/tr_out.txt
grep -q TRANSLATE_OK $D/tr_out.txt
echo ORACLE PASS
