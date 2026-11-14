# m3-agent: Memorization step 6 (visualization.py) on CPU

Following the README as written didn't work. What I changed:
- **Python version**: `requirements.txt` says python 3.9.2, but `visualization.py` uses `int | None`, which needs Python 3.10 or newer. I used a uv venv with Python 3.10 (`/work/venv`).
- **Dependencies**: the repo's `setup.sh` uses `sudo pip`, CUDA torch and flash-attn. Instead I installed `requirements.txt` plus the CPU wheels of torch 2.6.0, torchvision 0.21.0 and torchaudio 2.6.0, and the other pins from that script (numpy 1.26.4, insightface 0.7.3, hdbscan 0.8.40, onnxruntime 1.22.1, …). I skipped flash-attn and vllm because they need a GPU and this step doesn't use them.
- **Step not documented for step 6**: `from mmagent.retrieve import translate` imports the whole `mmagent` package. That imports insightface, hdbscan and speakerlab, and at import time it loads `models/pretrained_eres2netv2.ckpt`. So the speakerlab directory (from modelscope/3D-Speaker) and the eres2netv2 checkpoint (README step 4) are required even when you only visualize pre-built graphs. Importing it also downloads the insightface `buffalo_l` model, so `setup.sh` does one warm-up run to fetch it.
- **Code patch**: `mmagent/voice_processing.py` hard-coded `embedding_model.to(torch.device('cuda'))`. I changed it to fall back to CPU when CUDA isn't available.
- **Code patch**: `visualization.py` now has `SHOW_FACES = False`. The machine has no display, and the script's own comment says to do this. With it off, faces are printed as text lines. `env.sh` also sets `MPLBACKEND=Agg`.
- **Data**: I downloaded `memory_graphs/robot.tar.gz` from HF and extracted it into `data/memory_graphs/`, which gives `robot/bedroom_01.pkl`.
- `env.sh` activates the venv and changes into `/work/m3-agent`, because the code loads `configs/*.json` by relative path.
