# paddlecv (PaddlePaddle/models) – CPU PP-LCNet classification

Works now: `source /work/env.sh` then run `python -u tools/predict.py --config=configs/single_op/PP-LCNet.yml --input=demo/ILSVRC2012_val_00020010.jpeg --output_dir=<dir>`.
That writes `<dir>/clas_output.json` (top-5 ids, scores, labels: Weimaraner 0.884, ...) and an annotated image.

## What broke compared with docs/INSTALL.md, and what I changed
- `paddlepaddle==2.3.2` can't be installed. It's gone from PyPI and the Baidu mirror (`mirror.baidu.com`) returns 403. The oldest 2.x wheel left on PyPI is **2.6.2**, so I used that.
- Python 3.12 (the system Python) has no paddle 2.x wheels, so I made a uv venv with **Python 3.9** (`/work/venv`).
- requirements.txt doesn't pin versions, so the newest packages get pulled in and break things:
  - `numpy` 2.x and `opencv` 5.x don't work with paddle 2.6, so I pinned `numpy<2` and `opencv*<4.11`.
  - paddle imports `setuptools` and paddlenlp imports `pip`, and neither is in a uv venv, so I installed both.
  - `aistudio-sdk` 0.3.x removed `hub.download`, which paddlenlp 2.8.1 needs, so I pinned `aistudio-sdk==0.2.6`.
  - I pinned paddlenlp 2.8.1 and paddlespeech 1.5.0 so the setup gives the same result when re-run. ppcv imports the NLP and speech ops eagerly, so both packages are needed even just to classify.
- opencv needs `libgl1` and `libglib2.0-0t64` from apt, which the docs don't mention. I installed `libsndfile1` as the docs say.
- I skipped `python setup.py install`. `tools/predict.py` adds the repo to `sys.path` itself, so it isn't needed.
- The model, params and label list download automatically from bj.bcebos.com into `~/.cache/paddlecv`. `setup.sh` fetches them up front by running the prediction once.
