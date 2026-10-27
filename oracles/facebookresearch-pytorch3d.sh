set -e
source /work/env.sh
cd /work/pytorch3d
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1200 python -I - "$OUT" <<'P'
import sys, torch, numpy as np
from pytorch3d.io import load_objs_as_meshes
from pytorch3d.renderer import (FoVPerspectiveCameras, look_at_view_transform, RasterizationSettings,
    MeshRenderer, MeshRasterizer, SoftPhongShader, PointLights)
dev = torch.device("cpu")
mesh = load_objs_as_meshes(["/work/pytorch3d/docs/tutorials/data/cow_mesh/cow.obj"], device=dev)
assert mesh.verts_packed().shape[0] > 1000
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
assert rgb.std() > 0.02
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
plt.imsave(sys.argv[1] + "/cow.png", np.clip(img[0, ..., :3].numpy(), 0, 1))
P
test "$(stat -c %s $OUT/cow.png)" -gt 3000
echo ORACLE PASS
