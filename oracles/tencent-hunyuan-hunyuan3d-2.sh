set -e
source /work/env.sh
cd /work/Hunyuan3D-2
OUT=$(mktemp -d /tmp/oracle_XXXXXX)
export OUT
timeout 5400 python - <<'PY'
import os, torch
from PIL import Image
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
img = Image.open('assets/demo.png').convert('RGBA')
p = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
    'tencent/Hunyuan3D-2mini', subfolder='hunyuan3d-dit-v2-mini-turbo',
    use_safetensors=True, device='cpu', dtype=torch.float32)
p.enable_flashvdm(mc_algo='mc')
mesh = p(image=img, num_inference_steps=5, octree_resolution=128, num_chunks=20000,
         generator=torch.manual_seed(0))[0]
mesh.export(os.environ['OUT'] + '/demo.glb')
PY
python - <<'PY'
import os, trimesh
f = os.environ['OUT'] + '/demo.glb'
assert os.path.getsize(f) > 20000, 'glb too small'
m = trimesh.load(f, force='mesh')
assert len(m.vertices) > 500 and len(m.faces) > 1000, (len(m.vertices), len(m.faces))
assert (m.bounds[1] - m.bounds[0]).min() > 1e-3, 'degenerate mesh'
print('verts', len(m.vertices), 'faces', len(m.faces))
PY
echo ORACLE PASS
