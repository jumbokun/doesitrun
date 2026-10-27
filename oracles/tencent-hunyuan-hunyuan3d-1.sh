set -e
source /work/env.sh
cd /work/Hunyuan3D-1
OUT=$(mktemp -d /tmp/h3d_oracle.XXXXXX)
timeout 5400 python main.py --image_prompt ./demos/example_001.png --save_folder "$OUT" \
  --max_faces_num 10000 --use_lite --device cpu --gen_steps 20
test -s "$OUT/views.jpg"
test -s "$OUT/img_nobg.png"
python - "$OUT" <<'P'
import sys,glob,os
out=sys.argv[1]
objs=glob.glob(out+"/**/*.obj",recursive=True)
assert objs, "no obj"
best=max(objs,key=os.path.getsize)
assert os.path.getsize(best)>20000, best
v=sum(1 for l in open(best) if l.startswith("v "))
f=sum(1 for l in open(best) if l.startswith("f "))
assert v>500 and f>500,(v,f)
from PIL import Image
im=Image.open(out+"/views.jpg"); assert min(im.size)>=256, im.size
print("mesh",best,v,f)
P
echo "ORACLE PASS"
