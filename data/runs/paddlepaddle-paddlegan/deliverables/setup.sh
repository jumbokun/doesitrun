#!/usr/bin/env bash
# Reproducible CPU setup for PaddleGAN AnimeGANv2 inference.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# opencv-python needs libGL / glib at import time
apt-get update -qq
apt-get install -y -qq --no-install-recommends libgl1 libglib2.0-0 ca-certificates

cd /work
if [ ! -d PaddleGAN/.git ]; then
  git clone https://github.com/PaddlePaddle/PaddleGAN /work/PaddleGAN
fi
cd /work/PaddleGAN
git checkout -q 7d4c61f

# Python 3.10: requirements pin opencv<=4.6 / librosa 0.8.1 / imageio 2.9 (no py3.12 wheels)
uv venv --clear -p 3.10 /work/venv
. /work/venv/bin/activate
# paddlepaddle 2.6.2 is the oldest 2.x CPU wheel on PyPI (docs' mirror.baidu.com index is gone)
uv pip install paddlepaddle==2.6.2 "setuptools<70" "numpy<2"
uv pip install -r requirements.txt "numpy<2"
uv pip install -e . "numpy<2"

# Patch: run inference under no_grad and cap resolution (full-res CPU forward OOMs/segfaults)
if ! grep -q ANIMEGAN_MAX_SIDE ppgan/apps/animegan_predictor.py; then
git apply <<'PATCH'
diff --git a/ppgan/apps/animegan_predictor.py b/ppgan/apps/animegan_predictor.py
index b3c8b0b..4bb8730 100644
--- a/ppgan/apps/animegan_predictor.py
+++ b/ppgan/apps/animegan_predictor.py
@@ -72,9 +72,21 @@ class AnimeGANPredictor(BasePredictor):
     def run(self, image):
         image = cv2.cvtColor(cv2.imread(image, flags=cv2.IMREAD_COLOR),
                              cv2.COLOR_BGR2RGB)
-        transformed_image = self.transform(image)
-        anime = (self.generator(paddle.to_tensor(transformed_image[None, ...]))
-                 * 0.5 + 0.5)[0].numpy() * 255
+        # cap the inference resolution: on CPU the full-res im2col buffer of
+        # the last 7x7 conv overflows memory (and int32 indexing)
+        max_side = int(os.environ.get('ANIMEGAN_MAX_SIDE', 768))
+        h, w = image.shape[:2]
+        if max(h, w) > max_side:
+            r = max_side / max(h, w)
+            net_input = cv2.resize(image, (int(w * r), int(h * r)),
+                                   interpolation=cv2.INTER_AREA)
+        else:
+            net_input = image
+        transformed_image = self.transform(net_input)
+        with paddle.no_grad():
+            anime = (self.generator(
+                paddle.to_tensor(transformed_image[None, ...])) * 0.5 +
+                     0.5)[0].numpy() * 255
         anime = anime.transpose((1, 2, 0))
         if anime.shape[:2] != image.shape[:2]:
             # to original size
PATCH
fi

# Pre-fetch the AnimeGANv2 Hayao weights into ppgan's cache (the CLI would also auto-download)
mkdir -p /root/.cache/ppgan
[ -s /root/.cache/ppgan/animeganv2_hayao.pdparams ] || \
  curl -fL --retry 3 -o /root/.cache/ppgan/animeganv2_hayao.pdparams \
    https://paddlegan.bj.bcebos.com/models/animeganv2_hayao.pdparams

python -c "import paddle, ppgan, cv2; print('paddle', paddle.__version__)"
