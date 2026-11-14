# PaddleDetection CPU inference – notes

Command verified (from /work/PaddleDetection after `source /work/env.sh`):

    python tools/infer.py -c configs/picodet/picodet_s_320_coco_lcnet.yml -o use_gpu=False \
      weights=https://paddledet.bj.bcebos.com/models/picodet_s_320_coco_lcnet.pdparams \
      --infer_img=demo/000000014439.jpg --output_dir=output

Result: output/000000014439.jpg (6 persons + kite at score > 0.5).

What broke / what I changed:
- `paddlepaddle==2.3.2` (INSTALL.md) is no longer on PyPI or the tuna mirror -> installed `paddlepaddle==3.0.0` (CPU) on Python 3.10 (uv venv; system py3.12 is outside the documented range).
- opencv-python import failed: `libGL.so.1` missing -> apt `libgl1 libglib2.0-0t64`.
- `import pkg_resources` failed (setuptools 84 removed it) -> pin `setuptools<81`.
- Code bug: `ImageFolder._load_images` (ppdet/data/source/dataset.py) unconditionally opened
  `dataset/coco/annotations/instances_val2017.json`, so infer.py crashed without the COCO dataset.
  Patched to only load it when `do_eval` is set; categories then fall back to default COCO labels.
- Used `uv pip install -e .` instead of `python setup.py install`.
