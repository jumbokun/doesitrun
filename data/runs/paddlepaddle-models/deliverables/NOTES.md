# paddlecv CPU setup notes

What broke following docs/INSTALL.md, and what I changed:

- **paddlepaddle==2.3.2 isn't available any more**: PyPI starts at 2.6.2 and mirror.baidu.com returns 403. I used Python 3.9 (via uv) with paddlepaddle 2.6.2 from PyPI. The system Python is 3.12, which old Paddle doesn't support.
- **Unpinned requirements now resolve to incompatible versions**:
  - numpy 2 and opencv 5 → pinned numpy 1.26.4 and opencv(-contrib)-python 4.10.0.84.
  - paddlenlp 2.8.1 fails on `from aistudio_sdk.hub import download`, and paddlenlp 2.5.x imports `paddle.fluid`, which Paddle 2.6 removed. I pinned paddlenlp 2.6.1 (which also pulls protobuf 3.20.2).
  - paddlespeech 1.5.0 declares paddlenlp>=2.7.2, so the working set doesn't satisfy pip metadata. setup.sh installs a frozen, known-good set with `--no-deps`. After that, `python setup.py install` still installs the egg, but it ends with a dep-check error, which the script ignores.
- **pip and setuptools had to be added**: the uv venv has neither. `setup.py` needs setuptools, and paddlenlp runs `import pip`.
- **opencv needs extra system libraries**: libgl1 and libglib2.0-0t64, plus the documented libsndfile1.
- paddlecv imports every op (nlp, speech, faiss and so on) at import time, so the full requirements are needed even for the cls/det demos.
- No code patches. The models download automatically to ~/.cache/paddlecv. setup.sh runs both demos once to prefetch them.

Run: `source /work/env.sh` (it activates /work/venv and cd's to /work/models/paddlecv), then run the predict commands.
