set -e
source /work/env.sh
cd /work/Hunyuan3D-2.1
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cat > $OUT/run.py <<'PY'
import sys, os, torch
sys.path.insert(0, './hy3dshape'); sys.path.insert(0, './hy3dpaint')
from PIL import Image
from hy3dshape.pipelines import Hunyuan3DDiTFlowMatchingPipeline
out = sys.argv[1]
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2.1', device='cpu', dtype=torch.bfloat16)
image = Image.open('assets/demo.png').convert('RGBA')
mesh = pipe(image=image, num_inference_steps=10, octree_resolution=128, num_chunks=20000, generator=torch.manual_seed(0))[0]
mesh.export(os.path.join(out, 'shape.glb'))
print('VERTS', len(mesh.vertices), 'FACES', len(mesh.faces))
PY
timeout 6000 python $OUT/run.py $OUT
test -s $OUT/shape.glb
SZ=$(stat -c %s $OUT/shape.glb); echo "glb size $SZ"
[ "$SZ" -gt 20000 ]
python - $OUT/shape.glb <<'PY'
import sys, trimesh
m = trimesh.load(sys.argv[1], force='mesh')
assert len(m.vertices) > 500 and len(m.faces) > 1000, (len(m.vertices), len(m.faces))
ext = m.bounds[1] - m.bounds[0]
assert ext.min() > 0.05, ext
print('mesh ok', len(m.vertices), len(m.faces), ext)
PY
echo "ORACLE PASS"
