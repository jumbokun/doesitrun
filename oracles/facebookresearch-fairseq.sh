set -e
source /work/env.sh
cd /work/fairseq
D=$(mktemp -d /tmp/oracle.XXXXXX)
cd $D
timeout 900 curl -sSL -o rb.tar.gz https://dl.fbaipublicfiles.com/fairseq/models/roberta.base.tar.gz
tar xzf rb.tar.gz
cd /work/fairseq
cat > $D/t.py <<'P'
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
assert t.tolist() == [0, 31414, 232, 328, 2]
f = m.extract_features(t)
print(f.shape)
assert tuple(f.shape) == (1, 5, 768)
P
timeout 1200 python $D/t.py $D/roberta.base | tee $D/out.txt
grep -q Paris $D/out.txt
echo ORACLE PASS
