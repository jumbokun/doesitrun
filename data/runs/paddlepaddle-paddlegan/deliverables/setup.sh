#!/usr/bin/env bash
# Reproduce PaddleGAN AnimeGANv2 (CPU) setup from scratch.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
REPO=/work/PaddleGAN
VENV=/work/venv
COMMIT=7d4c61f893fe7a094ff852e2b5a7353edbf24585

# opencv-python needs libGL / glib at import time
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64

if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/PaddlePaddle/PaddleGAN "$REPO"
fi
cd "$REPO"
git checkout -q "$COMMIT"

# Patch: no_grad inference + cap input size (avoids OOM and an im2col int32 overflow segfault)
if ! grep -q "max_pixels" ppgan/apps/animegan_predictor.py; then
  git apply <<'PATCH_EOF'
diff --git a/ppgan/apps/animegan_predictor.py b/ppgan/apps/animegan_predictor.py
index b3c8b0b..3ed581d 100644
--- a/ppgan/apps/animegan_predictor.py
+++ b/ppgan/apps/animegan_predictor.py
@@ -72,9 +72,20 @@ class AnimeGANPredictor(BasePredictor):
     def run(self, image):
         image = cv2.cvtColor(cv2.imread(image, flags=cv2.IMREAD_COLOR),
                              cv2.COLOR_BGR2RGB)
-        transformed_image = self.transform(image)
-        anime = (self.generator(paddle.to_tensor(transformed_image[None, ...]))
-                 * 0.5 + 0.5)[0].numpy() * 255
+        # Paddle's CPU im2col overflows int32 on the final 7x7 conv
+        # (64*49*H*W elements) for large inputs, so cap the pixel count.
+        net_input = image
+        max_pixels = 640 * 1024
+        h, w = image.shape[:2]
+        if h * w > max_pixels:
+            ratio = (max_pixels / (h * w))**0.5
+            net_input = cv2.resize(image, (int(w * ratio), int(h * ratio)),
+                                   interpolation=cv2.INTER_AREA)
+        transformed_image = self.transform(net_input)
+        with paddle.no_grad():
+            anime = (self.generator(
+                paddle.to_tensor(transformed_image[None, ...])) * 0.5 +
+                     0.5)[0].numpy() * 255
         anime = anime.transpose((1, 2, 0))
         if anime.shape[:2] != image.shape[:2]:
             # to original size
PATCH_EOF
fi

# Python 3.12 is too new for librosa==0.8.1/opencv<=4.6/imageio 2.9; use 3.10
uv venv -q --allow-existing -p 3.10 "$VENV"
. "$VENV/bin/activate"
uv pip install paddlepaddle==2.6.2 "setuptools<70" "numpy<2"
uv pip install -r requirements.txt "numpy<2"
uv pip install -e .

# Pre-fetch pretrained Hayao weights into the ppgan cache
mkdir -p /root/.cache/ppgan
python -c "from ppgan.utils.download import get_path_from_url; get_path_from_url('https://paddlegan.bj.bcebos.com/models/animeganv2_hayao.pdparams')"
python -c "import paddle, ppgan, cv2; print('paddle', paddle.__version__)"
