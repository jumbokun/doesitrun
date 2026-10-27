#!/usr/bin/env bash
# Reproduce the LaMa inference setup from scratch on a fresh container
# (Ubuntu 24.04 + CUDA 12.8 devel, git, git-lfs, curl, build-essential, python3, uv).
#
# Everything lands under /work:
#   /work/lama            - the repository (pinned commit) with the compatibility patches
#   /work/venv            - python 3.11 venv with a Blackwell-capable torch
#   /work/lama/big-lama   - the released Places2 checkpoint
set -euo pipefail

WORK=/work
REPO="$WORK/lama"
VENV="$WORK/venv"
COMMIT=786f5936b27fb3dacd2b1ad799e4de968ea697e7

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
# Nothing to install: git, curl, build-essential, python3 and uv already ship in
# the base image, and the big-lama archive is unpacked with python's zipfile
# module so the `unzip` the README asks for is not needed.

# ---------------------------------------------------------------------------
# 2. Clone the repository
# ---------------------------------------------------------------------------
if [ ! -d "$REPO/.git" ]; then
    git clone https://github.com/advimman/lama.git "$REPO"
fi
cd "$REPO"
git fetch --all --tags --quiet || true
git checkout --quiet "$COMMIT"

# ---------------------------------------------------------------------------
# 3. Source patches (see /work/NOTES.md for the why of each one)
# ---------------------------------------------------------------------------
# 3a. saicinpainting/training/data/aug.py: albumentations >= 1.0 no longer ships
#     the imgaug-backed IAA transforms. Keep the original code path when an old
#     albumentations is present, otherwise fall back to the native transforms.
cat > "$REPO/saicinpainting/training/data/aug.py" <<'AUG_PY'
try:
    # albumentations < 1.0 shipped the imgaug-backed transforms used by the
    # original training pipeline.
    from albumentations import DualIAATransform, to_tuple
    import imgaug.augmenters as iaa

    HAS_IMGAUG = True
except ImportError:
    # albumentations >= 1.0 dropped imgaug; fall back to the native
    # albumentations implementations of the same augmentations.
    HAS_IMGAUG = False

if not HAS_IMGAUG:
    import cv2
    import albumentations as A

    _BORDER = {
        "constant": cv2.BORDER_CONSTANT,
        "edge": cv2.BORDER_REPLICATE,
        "replicate": cv2.BORDER_REPLICATE,
        "symmetric": cv2.BORDER_REFLECT,
        "reflect": cv2.BORDER_REFLECT_101,
        "wrap": cv2.BORDER_WRAP,
    }

    class IAAAffine2(A.Affine):
        def __init__(self, scale=(0.7, 1.3), translate_percent=None, translate_px=None,
                     rotate=0.0, shear=(-0.1, 0.1), order=1, cval=0, mode="reflect",
                     always_apply=False, p=0.5):
            super().__init__(scale=dict(x=scale, y=scale),
                             translate_percent=translate_percent,
                             translate_px=translate_px,
                             rotate=rotate,
                             shear=dict(x=shear, y=shear),
                             interpolation=order,
                             border_mode=_BORDER.get(mode, cv2.BORDER_REFLECT_101),
                             fill=cval,
                             fill_mask=cval,
                             p=p)

    class IAAPerspective2(A.Perspective):
        def __init__(self, scale=(0.05, 0.1), keep_size=True, always_apply=False, p=0.5,
                     order=1, cval=0, mode="replicate"):
            super().__init__(scale=scale,
                             keep_size=keep_size,
                             interpolation=order,
                             border_mode=_BORDER.get(mode, cv2.BORDER_REPLICATE),
                             fill=cval,
                             fill_mask=cval,
                             p=p)
else:

    class IAAAffine2(DualIAATransform):
        """Place a regular grid of points on the input and randomly move the neighbourhood of these point around
        via affine transformations.

        Note: This class introduce interpolation artifacts to mask if it has values other than {0;1}

        Args:
            p (float): probability of applying the transform. Default: 0.5.

        Targets:
            image, mask
        """

        def __init__(
            self,
            scale=(0.7, 1.3),
            translate_percent=None,
            translate_px=None,
            rotate=0.0,
            shear=(-0.1, 0.1),
            order=1,
            cval=0,
            mode="reflect",
            always_apply=False,
            p=0.5,
        ):
            super(IAAAffine2, self).__init__(always_apply, p)
            self.scale = dict(x=scale, y=scale)
            self.translate_percent = to_tuple(translate_percent, 0)
            self.translate_px = to_tuple(translate_px, 0)
            self.rotate = to_tuple(rotate)
            self.shear = dict(x=shear, y=shear)
            self.order = order
            self.cval = cval
            self.mode = mode

        @property
        def processor(self):
            return iaa.Affine(
                self.scale,
                self.translate_percent,
                self.translate_px,
                self.rotate,
                self.shear,
                self.order,
                self.cval,
                self.mode,
            )

        def get_transform_init_args_names(self):
            return ("scale", "translate_percent", "translate_px", "rotate", "shear", "order", "cval", "mode")


    class IAAPerspective2(DualIAATransform):
        """Perform a random four point perspective transform of the input.

        Note: This class introduce interpolation artifacts to mask if it has values other than {0;1}

        Args:
            scale ((float, float): standard deviation of the normal distributions. These are used to sample
                the random distances of the subimage's corners from the full image's corners. Default: (0.05, 0.1).
            p (float): probability of applying the transform. Default: 0.5.

        Targets:
            image, mask
        """

        def __init__(self, scale=(0.05, 0.1), keep_size=True, always_apply=False, p=0.5,
                     order=1, cval=0, mode="replicate"):
            super(IAAPerspective2, self).__init__(always_apply, p)
            self.scale = to_tuple(scale, 1.0)
            self.keep_size = keep_size
            self.cval = cval
            self.mode = mode

        @property
        def processor(self):
            return iaa.PerspectiveTransform(self.scale, keep_size=self.keep_size, mode=self.mode, cval=self.cval)

        def get_transform_init_args_names(self):
            return ("scale", "keep_size")
AUG_PY

python3 - "$REPO" <<'PATCH_PY'
import pathlib
import sys

repo = pathlib.Path(sys.argv[1])


def patch(relpath, old, new):
    path = repo / relpath
    text = path.read_text()
    if new in text:
        print(f'{relpath}: already patched')
        return
    assert old in text, f'{relpath}: pattern to patch not found'
    path.write_text(text.replace(old, new))
    print(f'{relpath}: patched')


# 3b. torch >= 2.6 defaults to weights_only=True, which refuses to unpickle the
#     pytorch-lightning objects inside the released big-lama checkpoint.
patch(
    'saicinpainting/training/trainers/__init__.py',
    '    state = torch.load(path, map_location=map_location)',
    '    # torch>=2.6 defaults to weights_only=True, which cannot unpickle the\n'
    '    # pytorch-lightning objects stored in the released LaMa checkpoints.\n'
    '    state = torch.load(path, map_location=map_location, weights_only=False)',
)

# 3c. bin/predict.py hardcodes the CPU and ignores `device` from the config.
patch(
    'bin/predict.py',
    '        device = torch.device("cpu")',
    '        device = torch.device(predict_config.device)',
)

# 3d. The refiner defaults to two GPUs; this box has one.
patch(
    'configs/prediction/default.yaml',
    '  gpu_ids: 0,1 #',
    '  gpu_ids: 0, #',
)
PATCH_PY

# ---------------------------------------------------------------------------
# 4. Python environment
# ---------------------------------------------------------------------------
# The README asks for torch 1.8 / python 3.6, which has no support for this
# GPU (Blackwell, sm_120) and no wheels for a modern interpreter. Use python
# 3.11 with torch 2.8 built against CUDA 12.8 instead.
uv venv --python 3.11 "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"

uv pip install --no-cache \
    torch==2.8.0 torchvision==0.23.0 \
    --index-url https://download.pytorch.org/whl/cu128

# requirements.txt pins versions from 2021 that no longer build/resolve on
# python 3.11; install current equivalents instead. `tensorflow` is dropped: it
# is only imported by bin/report_from_tb.py, which inference never touches.
uv pip install --no-cache \
    "numpy==1.26.4" \
    "pyyaml==6.0.3" \
    "tqdm==4.70.1" \
    "easydict==1.13" \
    "scikit-image==0.26.0" \
    "scikit-learn==1.9.1" \
    "scipy==1.17.1" \
    "opencv-python-headless==4.11.0.86" \
    "joblib==1.6.0" \
    "matplotlib==3.11.2" \
    "pandas==3.0.6" \
    "albumentations==2.0.8" \
    "hydra-core==1.3.8" \
    "omegaconf==2.3.1" \
    "pytorch-lightning==2.6.6" \
    "kornia==0.9.0" \
    "webdataset==1.0.2" \
    "packaging==26.3" \
    "tabulate==0.10.0"

# ---------------------------------------------------------------------------
# 5. Model download (README "Download pre-trained models")
# ---------------------------------------------------------------------------
if [ ! -f "$REPO/big-lama/models/best.ckpt" ]; then
    curl -L --fail --retry 3 --retry-delay 5 \
        -o "$WORK/big-lama.zip" \
        https://huggingface.co/smartywu/big-lama/resolve/main/big-lama.zip
    python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" \
        "$WORK/big-lama.zip" "$REPO"
fi
test -f "$REPO/big-lama/config.yaml"
test -f "$REPO/big-lama/models/best.ckpt"

# Weights for the perceptual loss (training only, see README "Train and Eval").
# Best effort: inference does not need it.
if [ ! -f "$REPO/ade20k/ade20k-resnet50dilated-ppm_deepsup/encoder_epoch_20.pth" ]; then
    mkdir -p "$REPO/ade20k/ade20k-resnet50dilated-ppm_deepsup"
    curl -L --fail --retry 2 --max-time 600 \
        -o "$REPO/ade20k/ade20k-resnet50dilated-ppm_deepsup/encoder_epoch_20.pth" \
        http://sceneparsing.csail.mit.edu/model/pytorch/ade20k-resnet50dilated-ppm_deepsup/encoder_epoch_20.pth \
        || echo "WARNING: optional ADE20k perceptual-loss weights could not be downloaded"
fi

echo
echo "Setup finished. Use:  source /work/env.sh"
echo "Then: python3 bin/predict.py model.path=/work/lama/big-lama indir=<dir> outdir=<dir> device=cuda"
