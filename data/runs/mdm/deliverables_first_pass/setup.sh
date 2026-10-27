#!/usr/bin/env bash
# Reproduce the MDM (motion-diffusion-model) text-to-motion setup from scratch.
# Target image: Ubuntu 24.04 + CUDA 12.8 devel, with git, git-lfs, curl,
# build-essential, python3 and uv already present.  Run as root.
set -euo pipefail

MDM_ROOT="${MDM_ROOT:-/work/motion-diffusion-model}"
MDM_REPO="${MDM_REPO:-https://github.com/GuyTevet/motion-diffusion-model}"
MDM_COMMIT="${MDM_COMMIT:-ef8edce6a53c6ab19e53b4d4dcf15bc0bc60a778}"
HML_DIR="$(dirname "$MDM_ROOT")/HumanML3D"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\n=== $* ===\n"; }

# gdown against Google Drive is the only download channel the repo offers;
# it fails intermittently, so retry.
retry() {
    local n=0
    until "$@"; do
        n=$((n + 1))
        if [ "$n" -ge 5 ]; then
            echo "FAILED after $n attempts: $*" >&2
            return 1
        fi
        echo "retry $n: $*" >&2
        sleep $((n * 20))
    done
}

log "system packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# ffmpeg: required by the README.  unzip: every prepare/*.sh script needs it.
apt-get install -y -qq ffmpeg unzip

log "clone $MDM_REPO"
if [ ! -d "$MDM_ROOT/.git" ]; then
    git clone "$MDM_REPO" "$MDM_ROOT"
fi
git -C "$MDM_ROOT" checkout --quiet "$MDM_COMMIT"
cd "$MDM_ROOT"

# Upstream never writes the per-sample sample##_rep##.mp4 files the README
# documents (only the combined grid videos).  Restore them.
if git apply --check "$HERE/patches/0001-write-per-sample-mp4.patch" 2>/dev/null; then
    git apply "$HERE/patches/0001-write-per-sample-mp4.patch"
fi

log "python environment"
# environment.yml (python 3.7 / torch 1.7.1 / cudatoolkit 11.0) has no wheels
# for this GPU, so we build an equivalent venv on python 3.10 + torch cu128.
uv venv --python 3.10 --allow-existing "$MDM_ROOT/.venv"
# shellcheck disable=SC1091
source "$MDM_ROOT/.venv/bin/activate"
uv pip install -r "$HERE/requirements.txt" \
    --extra-index-url https://download.pytorch.org/whl/cu128 \
    --index-strategy unsafe-best-match
python - <<'PY'
import torch
print("torch", torch.__version__, "cuda", torch.cuda.is_available(), torch.cuda.get_device_name(0))
PY

log "text-to-motion dependencies (prepare/*.sh)"
retry bash prepare/download_smpl_files.sh
retry bash prepare/download_glove.sh
retry bash prepare/download_t2m_evaluators.sh

# smplx unpickles SMPL_NEUTRAL.pkl, whose arrays are chumpy objects; chumpy is
# unimportable on numpy>=1.24, so rewrite the pickle with plain numpy arrays.
python "$HERE/tools/strip_chumpy_smpl.py" "$MDM_ROOT/body_models/smpl/SMPL_NEUTRAL.pkl"

log "HumanML3D data (text-only path from the README)"
if [ ! -d "$HML_DIR" ]; then
    git clone --depth 1 https://github.com/EricGuo5513/HumanML3D.git "$HML_DIR"
fi
unzip -q -o "$HML_DIR/HumanML3D/texts.zip" -d "$HML_DIR/HumanML3D/"
rm -rf "$MDM_ROOT/dataset/HumanML3D"
cp -r "$HML_DIR/HumanML3D" "$MDM_ROOT/dataset/HumanML3D"
test -f "$MDM_ROOT/dataset/HumanML3D/Mean.npy"
test -f "$MDM_ROOT/dataset/HumanML3D/test.txt"
test -d "$MDM_ROOT/dataset/HumanML3D/texts"

log "pretrained text-to-motion checkpoint (humanml-encoder-512-50steps)"
mkdir -p "$MDM_ROOT/save"
cd "$MDM_ROOT/save"
if [ ! -f humanml_enc_512_50steps/model000750000.pt ]; then
    retry gdown --fuzzy "https://drive.google.com/file/d/1cfadR1eZ116TIdXK7qDX1RugAerEiJXr/view?usp=sharing" \
        -O humanml_enc_512_50steps.zip
    unzip -q -o humanml_enc_512_50steps.zip
    rm -f humanml_enc_512_50steps.zip
    rm -rf __MACOSX
fi
test -f humanml_enc_512_50steps/model000750000.pt
cd "$MDM_ROOT"

log "pre-fetch the CLIP text encoder weights"
python - <<'PY'
import clip
clip.load("ViT-B/32", device="cpu", jit=False)
print("CLIP ViT-B/32 cached")
PY

log "done"
echo "checkpoint: $(ls "$MDM_ROOT"/save/humanml*/model*.pt)"
