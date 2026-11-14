set -e
source /work/env.sh
cd /work/tencent-ml-images
O=$(mktemp -d /tmp/oracle.XXXXXX)
PY=python2.7; command -v $PY >/dev/null || PY=python   # README.md:46 targets Python 2.7

# --- Part 1: README "Single-Label Image Classification" (README.md:270-276) ---
# example/image_classification.sh runs image_classification.py with
# --model_dir=checkpoints/resnet.ckpt; the ckpt-resnet101-mlimages-imagenet archive
# (README.md:266, public Google Drive zip, 475 MB) holds
# ckpt-resnet101-mlimages-imagenet/resnet.ckpt.{data-00000-of-00001,index,meta}.
CK=checkpoints/resnet.ckpt
[ -f $CK.index ] || CK=checkpoints/ckpt-resnet101-mlimages-imagenet/resnet.ckpt
test -f $CK.index || { echo "checkpoint ckpt-resnet101-mlimages-imagenet not found under checkpoints/"; exit 1; }
for i in 0 1 2 3; do echo "/work/tencent-ml-images/data/images/im_$i.jpg" >> $O/im_list.txt; done
timeout 1800 $PY image_classification.py --images=$O/im_list.txt --top_k_pred=5 \
  --model_dir=$CK --dictionary=data/imagenet2012_dictionary.txt --result=$O/label_pred.txt
cat $O/label_pred.txt
python3 -I - $O/label_pred.txt <<'PYEOF'
import sys, re
raw = open(sys.argv[1]).read()
assert "failed" not in raw, "an image failed to open"   # image_classification.py:88
# image_classification.py:97-99: a header per image, then top_k lines "%d %s: %.3f"
blocks = {}; cur = None
for l in raw.splitlines():
    m = re.match(r'\+\+\+ the predictions of (.+) is:$', l)
    if m:
        cur = m.group(1).split('/')[-1]; blocks[cur] = []; continue
    m = re.match(r'^(\d+) (.+): ([0-9.]+)$', l)
    if m and cur:
        blocks[cur].append((int(m.group(1)), m.group(2), float(m.group(3))))
assert sorted(blocks) == ['im_%d.jpg' % i for i in range(4)], blocks.keys()
for k, v in blocks.items():
    assert len(v) == 5, (k, v)
    ps = [p for _, _, p in v]
    assert all(0 <= p <= 1 for p in ps) and ps == sorted(ps, reverse=True), (k, ps)
    assert all(0 <= c < 1000 for c, _, _ in v), (k, v)   # flags.py:38 class_num=1000
# data/images/im_3.jpg is a jaguar lying on a branch;
# data/imagenet2012_dictionary.txt: 288 leopard, 290 jaguar, 293 cheetah
ids3 = [c for c, _, _ in blocks['im_3.jpg']]
assert set(ids3) & {288, 290, 293}, ("no big cat in top-5 for im_3", blocks['im_3.jpg'])
print("CLASSIFY_OK", dict((k, v[0]) for k, v in blocks.items()))
PYEOF

# --- Part 2: README "Prepare the TFRecord File" (README.md:236-241, data/tfrecord.sh), as in v1 ---
mkdir -p $O/idx $O/tfr
for i in 0 1 2 3; do echo "im_$i.jpg	$((i+3)):1	865:1	2:1" >> $O/idx/list.txt; done
timeout 1500 $PY data/tfrecord.py -idx $O/idx/ -tfs $O/tfr/ -im data/images/ -cls 11166 -one True
ls -l $O/tfr
python3 -I - $O/tfr/0.tfrecords <<'PYEOF'
import sys, struct
d = open(sys.argv[1], 'rb').read()
p = 0; n = 0; sizes = []
while p < len(d):
    l = struct.unpack('<Q', d[p:p+8])[0]
    rec = d[p+12:p+12+l]
    assert b'im_%d.jpg' % n in rec, "name missing in record %d" % n
    assert b'\xff\xd8' in rec
    sizes.append(l); p += 16 + l; n += 1
print("records", n, sizes)
assert n == 4, "expected 4 records"
# one-hot label = 11166 float32 (data/tfrecord.py:118) = 44664 bytes, plus the raw JPEG (>=168 KB each)
assert min(sizes) > 44664 + 100000, "records too small (label vector + image expected)"
assert sum(sizes) > 2600000
PYEOF
echo "ORACLE PASS"
