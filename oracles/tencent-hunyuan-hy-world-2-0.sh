set -e
source /work/env.sh
cd /work/HY-World-2.0
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 5400 python -m hyworld2.worldrecon.pipeline --input_path examples/worldrecon/realistic/Desk --output_path "$OUT" --target_size 518 --no_interactive
python - "$OUT" <<'P'
import sys,glob,os,json
o=sys.argv[1]
def one(p):
    g=glob.glob(os.path.join(o,'**',p),recursive=True)
    assert g,'missing '+p
    return g[0]
for p,m in [('points.ply',1000),('gaussians.ply',1000),('camera_params.json',50)]:
    f=one(p); assert os.path.getsize(f)>m,(f,os.path.getsize(f))
    if p.endswith('.ply'): assert open(f,'rb').read(3)==b'ply'
json.load(open(one('camera_params.json')))
d=glob.glob(os.path.join(o,'**','depth_*.npy'),recursive=True)
assert len(d)>=2,'depth npy'
import numpy as np
a=np.load(d[0]); assert a.ndim>=2 and np.isfinite(a).any()
assert len(glob.glob(os.path.join(o,'**','normal_*.png'),recursive=True))>=2,'normals'
P
echo "ORACLE PASS"
