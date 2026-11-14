set -e
source /work/env.sh
cd /work/Hunyuan3D-2
OUT=$(mktemp -d /tmp/oracle_XXXXXX)
export OUT
# README.md:188-200 "Code Usage": Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(...); pipeline(image='assets/demo.png')[0]
# with the official 0.6B mini-turbo variant (README.md:139). device/dtype are explicit from_pretrained arguments
# (hy3dgen/shapegen/pipelines.py:201-210; defaults are cuda/float16).
# v1 also called enable_flashvdm(), which is not part of the README demo: it reloads the turbo VAE without the
# pipeline's dtype (pipelines.py:276-280 -> ShapeVAE default float16), so a float32 CPU pipeline only ran after a
# repo patch. v2 uses the default VAE path (VanillaVolumeDecoder + MCSurfaceExtractor, autoencoders/model.py:165-169).
timeout 3300 python - <<'PY'
import os, torch
from PIL import Image
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
img = Image.open('assets/demo.png').convert('RGBA')
p = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
    'tencent/Hunyuan3D-2mini', subfolder='hunyuan3d-dit-v2-mini-turbo',
    device='cpu', dtype=torch.float32)
# 5 steps as in examples/faster_shape_gen_with_flashvdm_mini_turbo.py (step-distilled model); low octree
# resolution keeps dense volume decoding on CPU short.
mesh = p(image=img, num_inference_steps=5, octree_resolution=128, num_chunks=20000,
         generator=torch.manual_seed(0), output_type='trimesh')[0]
mesh.export(os.environ['OUT'] + '/demo.glb')
PY
python - <<'PY'
import os, trimesh
f = os.environ['OUT'] + '/demo.glb'
assert os.path.getsize(f) > 20000, 'glb too small'
m = trimesh.load(f, force='mesh')
assert len(m.vertices) > 500 and len(m.faces) > 1000, (len(m.vertices), len(m.faces))
ext = m.bounds[1] - m.bounds[0]
assert ext.min() > 1e-3, 'degenerate mesh'
assert ext.max() < 5, 'mesh outside the decoding box (box_v=1.01)'
print('verts', len(m.vertices), 'faces', len(m.faces), 'extent', ext)
PY
echo ORACLE PASS
