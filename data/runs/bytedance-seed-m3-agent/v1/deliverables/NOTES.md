# M3-Agent: visualization.py setup notes

- The README's environment step (`bash setup.sh`) installs torch, flash-attn, insightface, etc. with
  `sudo pip` into the system interpreter. That's GPU-oriented and much more than this goal needs. I skipped it
  and made a uv venv (Python 3.12) with only `requirements.txt` (versions pinned inside setup.sh).
- `import mmagent` (pulled in by `visualization.py` via `mmagent.retrieve`) imports `face_processing`,
  which needs insightface and downloads the buffalo_l model, and `voice_processing`, which needs torch,
  speakerlab and `models/pretrained_eres2netv2.ckpt`. All of this runs at import time. I patched
  `mmagent/__init__.py` so a failure in those two imports only logs a warning.
- The memory graph comes from the HF dataset `ByteDance-Seed/M3-Bench` (`memory_graphs/robot.tar.gz`).
  I extracted only `robot/bedroom_01.pkl` into `data/memory_graphs/` (the README's default path).
- The empty `configs/api_config.json` caused no problem: `chat_api.py` wraps client creation in try/except,
  so I didn't need dummy values.
- Run: `source /work/env.sh && python visualization.py --mem_path data/memory_graphs/robot/bedroom_01.pkl --clip_id 1`
