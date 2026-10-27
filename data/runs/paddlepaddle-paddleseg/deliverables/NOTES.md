# PaddleSeg on CPU — notes

The documented path is docs/install.md: install PaddlePaddle >= 2.4, then `pip install -r requirements.txt` and `pip install -v -e .`. Its example command is `paddlepaddle-gpu==2.4.2` from a Tsinghua mirror.

## What broke or was missing
- **Python version:** the system has Python 3.12, and PaddlePaddle 2.4.x has no wheels for it. I created a Python 3.10 venv with uv (`/work/venv`).
- **CPU wheel and pins:** the docs only show the GPU wheel. I used `paddlepaddle==2.6.2` (CPU, from PyPI) and pinned `numpy<2`, because paddle 2.6 and `opencv-python<=4.6.0` were built against numpy 1.x.
- **System libraries:** opencv needs `libgl1` and `libglib2.0-0`, and I installed `unzip` to extract the dataset. These are not in the minimal image.
- **Dataset:** the optic_disc_seg zip has to be downloaded and unzipped into `PaddleSeg/data` by hand (as the task describes).
- **Pretrained backbone:** the config fetches PP_STDCNet2 at train time. setup.sh pre-fetches it into `~/.paddleseg/pretrained_model`.

No code patches were needed. Training with `--iters 20 --batch_size 2` writes `output/iter_20/model.pdparams` and runs at about 3 s/iter on CPU. predict.py then writes `output/result/{pseudo_color,added}_prediction/H0002.*`.

`env.sh` activates the venv and changes into `/work/PaddleSeg`.
