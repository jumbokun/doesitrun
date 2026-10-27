set -e
source /work/env.sh
cd /work/GFPGAN
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 3000 python inference_gfpgan.py -i inputs/whole_imgs -o "$O" -v 1.3 -s 2 --bg_upsampler None
python - "$O" <<'P'
import sys,glob
from PIL import Image
d=sys.argv[1]
fs=glob.glob(d+'/restored_imgs/*')
assert len(fs)>=3,fs
for f in fs:
    w,h=Image.open(f).size
    assert w>=256 and h>=256,(f,w,h)
assert glob.glob(d+'/restored_faces/*'),'no faces'
print(len(fs),'restored')
P
echo ORACLE PASS
