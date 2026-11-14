# PaddleDetection PicoDet CPU inference – notes

Verified command (after `source /work/env.sh`, which activates /work/venv and cds to /work/PaddleDetection):

    python tools/infer.py -c configs/picodet/picodet_s_320_coco_lcnet.yml \
      -o use_gpu=False weights=https://paddledet.bj.bcebos.com/models/picodet_s_320_coco_lcnet.pdparams \
      --infer_img=demo/000000014439.jpg --output_dir=/work/output --save_results=True

Result: /work/output/000000014439.jpg (visualized) + bbox.json (7 detections, all score >0.5).

## What broke / what I changed
1. **Python version**: the image ships Python 3.12; INSTALL.md lists Python 3.5–3.10. I made a Python 3.10 venv with uv.
2. **paddlepaddle==2.3.2** (from INSTALL.md) isn't on PyPI or the tuna mirror anymore. I used paddlepaddle==2.6.2 (CPU), the oldest build available, which still meets the develop branch's ">=2.3.2" requirement.
3. **libGL.so.1 missing** for opencv-python: I apt-installed `libgl1 libglib2.0-0t64`.
4. **pkg_resources missing**: setuptools 84 removed it, and `ppdet/model_zoo` imports it. I pinned `setuptools<80`.
5. **Code bug (develop branch)**: `ImageFolder._load_images` always opens `dataset/coco/annotations/instances_val2017.json`, even for plain inference, so infer.py crashes without the COCO dataset. I patched it to load the annotations only when `do_eval`.
6. **Font cache path bug**: `visualizer.py` downloads simfang.ttf into a literal `./~/.cache/paddle` dir (no expanduser). I patched it to use expanduser, and setup.sh downloads the font and the weights ahead of time.
7. I used `uv pip install -e .` instead of `python setup.py install`.
