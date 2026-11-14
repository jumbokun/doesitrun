set -e
source /work/env.sh
cd /work/pytorch3d
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# Mirrors docs/tutorials/render_textured_meshes.ipynb (look_at_view_transform(2.7, 0, 180),
# PointLights at [0,0,-3], SoftPhongShader). `python -I` keeps the source tree off sys.path.
# The PNG is written with PIL, which pytorch3d.io itself imports (pytorch3d/io/obj_io.py:21);
# matplotlib is only an optional extra (setup.py:185 "all"; INSTALL.md "Demos") and is NOT required.
timeout 1200 python -I - "$OUT" <<'P'
import sys, torch, numpy as np
from PIL import Image
from pytorch3d.io import load_objs_as_meshes
from pytorch3d.renderer import (FoVPerspectiveCameras, look_at_view_transform, RasterizationSettings,
    MeshRenderer, MeshRasterizer, SoftPhongShader, PointLights, TexturesUV)
dev = torch.device("cpu")
mesh = load_objs_as_meshes(["/work/pytorch3d/docs/tutorials/data/cow_mesh/cow.obj"], device=dev)
assert mesh.verts_packed().shape[0] > 1000
# cow.obj references cow.mtl + cow_texture.png, so the loader must produce a UV texture map.
assert isinstance(mesh.textures, TexturesUV), type(mesh.textures)
tex = mesh.textures.maps_padded()
assert tex.ndim == 4 and tex.shape[-1] == 3 and tex.shape[1] >= 256, tuple(tex.shape)
R, T = look_at_view_transform(2.7, 0, 180)
cam = FoVPerspectiveCameras(device=dev, R=R, T=T)
rs = RasterizationSettings(image_size=256, blur_radius=0.0, faces_per_pixel=1)
lights = PointLights(device=dev, location=[[0.0, 0.0, -3.0]])
r = MeshRenderer(MeshRasterizer(cameras=cam, raster_settings=rs),
                 SoftPhongShader(device=dev, cameras=cam, lights=lights))
img = r(mesh)
assert tuple(img.shape) == (1, 256, 256, 4), img.shape
a = img[0, ..., 3].numpy()
cov = (a > 0.5).mean()
print("coverage", cov)
assert 0.05 < cov < 0.95
rgb = img[0, ..., :3].numpy()[a > 0.5]
assert np.isfinite(rgb).all()
assert rgb.std() > 0.02
Image.fromarray((np.clip(img[0, ..., :3].numpy(), 0, 1) * 255).astype(np.uint8)).save(sys.argv[1] + "/cow.png")
P
test "$(stat -c %s $OUT/cow.png)" -gt 3000
echo ORACLE PASS
