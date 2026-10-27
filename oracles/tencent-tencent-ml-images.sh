set -e
source /work/env.sh
cd /work/tencent-ml-images
O=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p $O/idx $O/tfr
for i in 0 1 2 3; do echo "im_$i.jpg	$((i+3)):1	865:1	2:1" >> $O/idx/list.txt; done
PY=python2.7; command -v $PY >/dev/null || PY=python
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
assert min(sizes) > 44664 + 100000, "records too small (label vector + image expected)"
assert sum(sizes) > 2600000
PYEOF
echo "ORACLE PASS"
