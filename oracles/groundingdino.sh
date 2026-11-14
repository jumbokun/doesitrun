# Pass: the compiled CUDA op is importable (the README's "NameError: name '_C' is not defined" pain), the README GPU demo
# writes pred.jpg, and that demo's detections on the GPU include both the cat and the dog.
# v2 fixes:
#  - v1 ran `python -c "from groundingdino import _C"` with nothing imported first. groundingdino/__init__.py is empty at
#    this commit and the extension built by setup.py (CUDAExtension, no rpath) needs torch's libc10.so already loaded,
#    so that line fails on a correct README install (ImportError: libc10.so). The package itself always imports torch
#    first (models/GroundingDINO/ms_deform_attn.py:21-29). This run's agent had to patch groundingdino/__init__.py
#    and patchelf the .so just to satisfy the oracle. v2 imports torch first, as the package does.
#  - v1 only checked that pred.jpg exists; demo/inference_on_a_image.py:205-214 saves it even with zero boxes, so a
#    numerically broken MSDA kernel would pass. v2 checks the detections.
set -e
source /work/env.sh
cd /work/GroundingDINO
python -c "import torch; from groundingdino import _C; print('ORACLE: _C ok', _C.__file__)"
OUT=$(mktemp -d)
CUDA_VISIBLE_DEVICES=0 timeout 1200 python demo/inference_on_a_image.py \
  -c groundingdino/config/GroundingDINO_SwinT_OGC.py -p weights/groundingdino_swint_ogc.pth \
  -i .asset/cat_dog.jpeg -o "$OUT" -t "cat . dog ."
test -s "$OUT/pred.jpg" || { echo "ORACLE: no pred.jpg"; exit 1; }
# Same demo, its own functions, to read the detections (inference_on_a_image.py:58-146; __main__ guard at :149).
# Defaults as the CLI run above: box_threshold 0.3, text_threshold 0.25 (:162-163), cuda unless --cpu-only (:75,90).
CUDA_VISIBLE_DEVICES=0 timeout 1200 python - <<'PY'
import importlib.util, torch
assert torch.cuda.is_available(), "no CUDA"
spec = importlib.util.spec_from_file_location("gd_demo", "demo/inference_on_a_image.py")
demo = importlib.util.module_from_spec(spec); spec.loader.exec_module(demo)
_, image = demo.load_image(".asset/cat_dog.jpeg")
model = demo.load_model("groundingdino/config/GroundingDINO_SwinT_OGC.py", "weights/groundingdino_swint_ogc.pth", cpu_only=False)
boxes, phrases = demo.get_grounding_output(model, image, "cat . dog .", 0.3, 0.25, cpu_only=False)
print("ORACLE: phrases", phrases, "boxes", boxes.tolist())
# ms_deform_attn.py:330 takes the compiled _C path for CUDA tensors, so these boxes come through the CUDA kernel
names = [p.split("(")[0] for p in phrases]
assert any("cat" in n for n in names) and any("dog" in n for n in names), phrases
assert ((boxes >= 0) & (boxes <= 1)).all() and (boxes[:, 2:] > 0.05).all(), boxes   # normalized cxcywh
PY
echo "ORACLE PASS"
