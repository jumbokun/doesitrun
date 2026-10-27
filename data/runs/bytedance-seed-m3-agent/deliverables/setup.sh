#!/usr/bin/env bash
# Reproduce M3-Agent setup for visualization.py (CPU only, no models).
set -euo pipefail
cd /work

# 1. Clone
[ -d m3-agent/.git ] || git clone https://github.com/ByteDance-Seed/m3-agent /work/m3-agent

# 2. Python env: only the lightweight requirements.txt deps are needed to unpickle the
#    VideoGraph and run visualization.py (torch/insightface/flash-attn etc. are skipped).
#    Python >=3.10 required (visualization.py uses `int | None`); system 3.12 is used.
[ -x /work/venv/bin/python ] || uv venv /work/venv --python python3
cat > /tmp/m3agent-constraints.txt <<'PINS'
annotated-types==0.8.0
anyio==3.7.1
certifi==2026.10.23
cloudpickle==3.1.2
contourpy==1.4.0
cycler==0.12.1
decorator==5.3.1
distro==1.9.0
fonttools==4.67.0
h11==0.12.0
httpcore==0.15.0
httpx==0.23.0
idna==3.20
imageio==2.38.1
imageio-ffmpeg==0.6.0
jiter==0.18.0
joblib==1.6.0
kiwisolver==1.5.1
matplotlib==3.11.2
moviepy==2.2.1
narwhals==2.27.1
numpy==2.5.4
openai==2.54.0
opencv-python-headless==5.0.0.93
packaging==26.3
pillow==11.3.0
proglog==0.1.12
pydantic==2.14.1
pydantic-core==2.50.1
pydub==0.25.1
pyparsing==3.3.3
python-dateutil==3.0.0
python-dotenv==1.2.4
rfc3986==1.5.0
scikit-learn==1.9.1
scipy==1.18.1
six==1.17.0
sniffio==1.3.1
threadpoolctl==3.7.0
tqdm==4.70.1
typing-extensions==4.16.0
typing-inspection==0.4.4
tzdata==2026.5
PINS
uv pip install --python /work/venv/bin/python -r /work/m3-agent/requirements.txt -c /tmp/m3agent-constraints.txt

# 3. Patch mmagent/__init__.py: face_processing / voice_processing load insightface and the
#    ERes2NetV2 checkpoint at import time; make them optional.
cd /work/m3-agent
if ! grep -q "face_processing unavailable" mmagent/__init__.py; then
  /work/venv/bin/python - <<'PY'
p = 'mmagent/__init__.py'
s = open(p).read()
s = s.replace("from . import face_processing\n", """# face/voice processing load insightface / ERes2NetV2 models at import time;
# tolerate their absence so lightweight tools (e.g. visualization.py) still work.
try:
    from . import face_processing
except Exception as e:
    logging.getLogger(__name__).warning("face_processing unavailable: %s", e)
""", 1)
s = s.replace("from . import voice_processing\n", """try:
    from . import voice_processing
except Exception as e:
    logging.getLogger(__name__).warning("voice_processing unavailable: %s", e)
""", 1)
open(p, 'w').write(s)
PY
fi
mkdir -p logs

# 4. Pre-built memory graph from HF dataset (public, no token)
mkdir -p /work/dl data/memory_graphs
if [ ! -f data/memory_graphs/robot/bedroom_01.pkl ]; then
  [ -s /work/dl/robot.tar.gz ] || curl -fL --retry 5 -o /work/dl/robot.tar.gz \
    https://huggingface.co/datasets/ByteDance-Seed/M3-Bench/resolve/main/memory_graphs/robot.tar.gz
  tar -xzf /work/dl/robot.tar.gz -C data/memory_graphs robot/bedroom_01.pkl
fi
echo "setup done: $(ls -la data/memory_graphs/robot/bedroom_01.pkl)"
