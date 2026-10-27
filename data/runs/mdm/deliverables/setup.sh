#!/usr/bin/env bash
# Reproduce the MDM (motion-diffusion-model) text-to-motion setup from scratch.
#
# Target image: Ubuntu 24.04 + CUDA 12.8 devel, with git, git-lfs, curl,
# build-essential, python3 and uv already present.  Run as root.
# This script is self-contained: every auxiliary file it needs (pinned
# requirements, the SMPL pickle converter, the generate.py edit) is written
# by the script itself.  Re-running it is safe/idempotent.
#
# Knobs (all optional):
#   MDM_ROOT    where to clone the repo   (default /work/motion-diffusion-model)
#   MDM_SMOKE=1 run a generation at the end of setup
set -euo pipefail

MDM_ROOT="${MDM_ROOT:-/work/motion-diffusion-model}"
MDM_REPO="${MDM_REPO:-https://github.com/GuyTevet/motion-diffusion-model}"
MDM_COMMIT="${MDM_COMMIT:-ef8edce6a53c6ab19e53b4d4dcf15bc0bc60a778}"
HML_REPO="https://github.com/EricGuo5513/HumanML3D.git"
HML_DIR="$(dirname "$MDM_ROOT")/HumanML3D"
AUX="$MDM_ROOT/.setup"          # generated helper files live inside the clone

# Downloads here are big (torch ~1 GB, T2M evaluators 1.4 GB, checkpoint 200 MB)
# and Google Drive is flaky, so be patient and retry everything.
export UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-900}"
export PIP_DEFAULT_TIMEOUT=120
export DEBIAN_FRONTEND=noninteractive
RETRIES="${RETRIES:-5}"

log() { echo -e "\n=== $* ===\n"; }

# retry CMD...  -- retry on non-zero exit
retry() {
    local n=0
    until "$@"; do
        n=$((n + 1))
        if [ "$n" -ge "$RETRIES" ]; then
            echo "FAILED after $n attempts: $*" >&2
            return 1
        fi
        echo ">>> attempt $n failed, retrying in $((n * 20))s: $*" >&2
        sleep $((n * 20))
    done
}

all_exist() { local p; for p in "$@"; do [ -e "$p" ] || return 1; done; }

# ensure "shell command" marker [marker...]
# Several prepare/*.sh scripts exit 0 even when their download failed, so we
# retry on *missing output files* rather than on exit status.
ensure() {
    local cmd="$1"; shift
    local n=0
    while ! all_exist "$@"; do
        n=$((n + 1))
        if [ "$n" -gt "$RETRIES" ]; then
            echo "FAILED after $((n - 1)) attempts: [$cmd] did not produce: $*" >&2
            return 1
        fi
        [ "$n" -gt 1 ] && { echo ">>> retry $n of [$cmd] in $((n * 20))s" >&2; sleep $((n * 20)); }
        bash -c "$cmd" || true
    done
}

log "system packages"
retry apt-get update -qq
# ffmpeg: required by the README.  unzip: every prepare/*.sh script needs it
# (the base image has none, and the scripts delete their zip even when the
# unzip step failed).
retry apt-get install -y -qq ffmpeg unzip

log "clone $MDM_REPO @ $MDM_COMMIT"
if [ ! -d "$MDM_ROOT/.git" ]; then
    retry git clone "$MDM_REPO" "$MDM_ROOT"
fi
git -C "$MDM_ROOT" checkout --quiet "$MDM_COMMIT"
cd "$MDM_ROOT"
mkdir -p "$AUX"

log "write generated helper files into $AUX"

# ---------------------------------------------------------------- requirements
cat > "$AUX/requirements.txt" <<'REQ_EOF'
# Pinned environment for MDM text-to-motion on an sm_120 (Blackwell) GPU.
# torch/torchvision come from the cu128 wheel index (see setup.sh).
torch==2.11.0+cu128
torchvision==0.26.0+cu128

numpy==1.26.4
scipy==1.15.3
matplotlib==3.7.5
moviepy==1.0.3
imageio==2.38.0
imageio-ffmpeg==0.6.0
decorator==4.4.2
proglog==0.1.12
joblib==1.6.0
h5py==3.16.0
trimesh==5.2.0
smplx==0.1.28
ftfy==6.3.1
regex==2026.9.29
tqdm==4.70.1
gdown==5.2.0
pillow==12.3.0

# spacy 3.7.x is the last line that works with numpy 1.x; its CLI needs the
# "real" typer/click (typer-slim ships no click dependency).
spacy==3.7.5
thinc==8.2.5
blis==0.7.11
typer==0.9.4
click==8.1.8
weasel==0.4.1
pip==26.2.2

clip @ git+https://github.com/openai/CLIP.git@d05afc436d78f1c48dc0dbf8e5980a9d471f35f6
en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl
REQ_EOF

# ------------------------------------------------- SMPL pickle de-chumpy-fier
cat > "$AUX/strip_chumpy_smpl.py" <<'PY_EOF'
"""Rewrite body_models/smpl/SMPL_NEUTRAL.pkl without chumpy objects.

The SMPL pickle shipped by prepare/download_smpl_files.sh stores several arrays
as chumpy `Ch` objects.  chumpy is unmaintained (it does `from numpy import
bool, int, float, ...`, removed in numpy>=1.24, and its sdist does not build
under PEP 517 isolation), so smplx cannot unpickle the file.  We unpickle with
a stub chumpy module, convert every Ch back to a plain numpy array and write
the pickle back out.  Idempotent.
"""
import pickle
import sys
import types
import numpy as np


class Ch(object):
    def __init__(self, *args, **kwargs):
        pass

    def __setstate__(self, state):
        if isinstance(state, dict):
            self.__dict__.update(state)


def install_stub():
    chumpy = types.ModuleType("chumpy")
    ch = types.ModuleType("chumpy.ch")
    for mod in (chumpy, ch):
        mod.Ch = Ch
    chumpy.ch = ch
    chumpy.ch_ops = ch
    sys.modules["chumpy"] = chumpy
    sys.modules["chumpy.ch"] = ch


def to_numpy(obj):
    if isinstance(obj, Ch):
        return to_numpy(obj.__dict__.get("x"))
    if isinstance(obj, dict):
        return {k: to_numpy(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return type(obj)(to_numpy(v) for v in obj)
    if isinstance(obj, np.ndarray) and obj.dtype == object:
        return np.array([to_numpy(v) for v in obj.ravel()]).reshape(obj.shape)
    return obj


def main(path):
    install_stub()
    with open(path, "rb") as f:
        data = pickle.load(f, encoding="latin1")
    data = to_numpy(data)
    bad = [k for k, v in data.items() if isinstance(v, Ch)]
    assert not bad, bad
    for key in ("v_template", "shapedirs", "posedirs", "weights", "f", "J"):
        assert isinstance(data[key], np.ndarray), (key, type(data[key]))
    with open(path, "wb") as f:
        pickle.dump(data, f, protocol=2)
    print("converted", path)


if __name__ == "__main__":
    main(sys.argv[1])
PY_EOF

# --------------------------------------- restore the README's per-sample mp4s
cat > "$AUX/write_per_sample_mp4.py" <<'PY_EOF'
"""Patch sample/generate.py to write the sample##_rep##.mp4 files.

The README promises one mp4 per sample/repetition, but upstream keeps the
per-sample moviepy clips in memory and only renders the combined grid videos.
Idempotent: does nothing if the edit is already present.
"""
import sys

MARKER = "single_clip.write_videofile"
OLD = """                                                         fps=fps, gt_frames=gt_frames)
            rep_files.append(animation_save_path)
"""
NEW = """                                                         fps=fps, gt_frames=gt_frames)
            # The README promises one mp4 per sample/repetition, but upstream
            # only renders the combined grids below, so write the single clip.
            single_clip = animations[sample_i, rep_i]
            single_clip.duration = max(max_length, n_frames) / fps
            single_clip.write_videofile(animation_save_path, fps=fps, threads=4, logger=None)
            rep_files.append(animation_save_path)
"""

path = sys.argv[1]
src = open(path).read()
if MARKER in src:
    print("per-sample mp4 patch already applied")
else:
    assert src.count(OLD) == 1, "generate.py does not match the pinned commit"
    open(path, "w").write(src.replace(OLD, NEW))
    print("patched", path)
PY_EOF

python3 "$AUX/write_per_sample_mp4.py" "$MDM_ROOT/sample/generate.py"

log "python environment"
# environment.yml (python 3.7 / torch 1.7.1 / cudatoolkit 11.0) has no wheels
# for this GPU, so we build an equivalent venv on python 3.10 + torch cu128.
retry uv venv --python 3.10 --allow-existing "$MDM_ROOT/.venv"
# shellcheck disable=SC1091
source "$MDM_ROOT/.venv/bin/activate"
retry uv pip install -r "$AUX/requirements.txt" \
    --extra-index-url https://download.pytorch.org/whl/cu128 \
    --index-strategy unsafe-best-match
python - <<'PY'
import torch
print("torch", torch.__version__, "cuda", torch.cuda.is_available())
if torch.cuda.is_available():
    print("gpu", torch.cuda.get_device_name(0))
PY

log "SMPL body model (prepare/download_smpl_files.sh)"
ensure "bash prepare/download_smpl_files.sh" \
    body_models/smpl/SMPL_NEUTRAL.pkl \
    body_models/smpl/J_regressor_extra.npy \
    body_models/smpl/smplfaces.npy
python "$AUX/strip_chumpy_smpl.py" "$MDM_ROOT/body_models/smpl/SMPL_NEUTRAL.pkl"

log "HumanML3D data (text-only path from the README)"
if [ ! -d "$HML_DIR/.git" ]; then
    retry git clone --depth 1 "$HML_REPO" "$HML_DIR"
fi
test -f "$HML_DIR/HumanML3D/texts.zip"
unzip -q -o "$HML_DIR/HumanML3D/texts.zip" -d "$HML_DIR/HumanML3D/"
rm -rf "$MDM_ROOT/dataset/HumanML3D"
cp -r "$HML_DIR/HumanML3D" "$MDM_ROOT/dataset/HumanML3D"
test -f "$MDM_ROOT/dataset/HumanML3D/Mean.npy"
test -f "$MDM_ROOT/dataset/HumanML3D/Std.npy"
test -f "$MDM_ROOT/dataset/HumanML3D/test.txt"
test -d "$MDM_ROOT/dataset/HumanML3D/texts"

log "pretrained text-to-motion checkpoint (humanml-encoder-512-50steps)"
# README: "You need only the first one" / this one "runs 20X faster with
# comparable performance".  Google Drive is the only source upstream offers;
# resume partial downloads and validate the zip before extracting.
mkdir -p "$MDM_ROOT/save"
fetch_checkpoint() {
    cd "$MDM_ROOT/save"
    local zip=humanml_enc_512_50steps.zip
    [ -f humanml_enc_512_50steps/model000750000.pt ] && return 0
    gdown --continue --fuzzy \
        "https://drive.google.com/file/d/1cfadR1eZ116TIdXK7qDX1RugAerEiJXr/view?usp=sharing" \
        -O "$zip" || { echo "gdown failed"; return 1; }
    if ! unzip -tq "$zip"; then
        echo "corrupt zip, discarding"; rm -f "$zip"; return 1
    fi
    unzip -q -o "$zip"
    rm -f "$zip"
    rm -rf __MACOSX
    [ -f humanml_enc_512_50steps/model000750000.pt ]
}
retry fetch_checkpoint
cd "$MDM_ROOT"
test -f save/humanml_enc_512_50steps/model000750000.pt

log "pre-fetch the CLIP text encoder weights"
retry python - <<'PY'
import clip
clip.load("ViT-B/32", device="cpu", jit=False)
print("CLIP ViT-B/32 cached")
PY

# Everything above is needed for text-to-motion generation.  The two downloads
# below are listed by the README as text-to-motion dependencies but are only
# used by eval.eval_humanml, so a failure here must not sink the setup.
log "evaluation-only dependencies (glove + T2M evaluators, best effort)"
ensure "bash prepare/download_glove.sh" glove/our_vab_data.npy glove/our_vab_idx.pkl \
    || echo "WARNING: glove download failed (only eval.eval_humanml needs it)"
ensure "bash prepare/download_t2m_evaluators.sh" \
    t2m/text_mot_match/model/finest.tar t2m/length_est_bigru/model/latest.tar \
    kit/text_mot_match/model/finest.tar \
    || echo "WARNING: T2M evaluator download failed (only eval.eval_humanml needs it)"

if [ "${MDM_SMOKE:-0}" = "1" ]; then
    log "smoke test"
    ckpt=$(ls save/humanml*/model*.pt | head -1)
    rm -rf "$MDM_ROOT/.setup/smoke"
    python -m sample.generate --model_path "$ckpt" --device 0 \
        --text_prompt "the person walked forward and is picking up his toolbox." \
        --output_dir "$MDM_ROOT/.setup/smoke"
    ls "$MDM_ROOT/.setup/smoke/results.npy" "$MDM_ROOT/.setup/smoke/"*.mp4 >/dev/null
fi

log "done"
echo "checkpoint: $(ls "$MDM_ROOT"/save/humanml*/model*.pt)"
echo "activate with: source $(dirname "$0")/env.sh   (or $MDM_ROOT/.venv/bin/activate)"
