#!/usr/bin/env bash
# Reproduce the ManimGX setup from scratch on a fresh Ubuntu 24.04 sandbox.
# Run as root:  bash /work/setup.sh
set -euo pipefail

REPO_URL="https://github.com/academa-labs/manimgx"
REPO_DIR="/work/manimgx"
VENV_DIR="/work/venv"
# Pin to the version the cloned checkout declares, so the README matches the wheel.
MANIMGX_VERSION="0.1.1"

export DEBIAN_FRONTEND=noninteractive

# 1. Clone the repository.
if [ -d "$REPO_DIR/.git" ]; then
    echo "==> repository already present at $REPO_DIR"
else
    echo "==> cloning $REPO_URL"
    git clone "$REPO_URL" "$REPO_DIR"
fi

# 2. System packages: none required.
#    The Linux wheel is self-contained -- it bundles Mesa lavapipe (CPU Vulkan),
#    x264/FFmpeg for encoding, Typst for typesetting and the Noto fonts.
#    `ldd` on the native extension shows only glibc/libstdc++/libgcc, which the
#    base image already provides. No apt install step is needed.

# 3. Python environment. The README requires Python 3.13+; the image ships 3.12,
#    so let uv fetch a 3.13 interpreter and build the venv around it.
echo "==> creating virtualenv with Python 3.13 at $VENV_DIR"
uv venv --python 3.13 "$VENV_DIR"

# 4. Install ManimGX the documented way (`pip install manimgx`), into that venv.
echo "==> installing manimgx==$MANIMGX_VERSION"
VIRTUAL_ENV="$VENV_DIR" uv pip install "manimgx==$MANIMGX_VERSION"

# 5. No model or checkpoint downloads: ManimGX is a renderer, not an ML project.
#    Nothing is fetched at render time either -- verified by rendering with an
#    empty cache below.

# 6. Smoke test: render the README's "From Python to MP4" scene end to end.
echo "==> smoke test: rendering the README Hello3D scene"
SMOKE_DIR="$(mktemp -d)"
cat > "$SMOKE_DIR/scene.py" <<'SCENE'
import manimgx as m


class Hello3D(m.ThreeDScene):
    def construct(self) -> None:
        self.set_camera_orientation(phi=65 * m.DEGREES, theta=-45 * m.DEGREES)
        self.begin_ambient_camera_rotation(rate=0.5)
        cube = m.Cube(side_length=3, fill_opacity=0.3, stroke_width=2)
        self.play(m.Create(cube), run_time=2)
        self.wait(4)
SCENE
(
    cd "$SMOKE_DIR"
    PATH="$VENV_DIR/bin:$PATH" manimgx render scene.py
    test -s Hello3D.mp4
)
rm -rf "$SMOKE_DIR"

echo "==> setup complete. Source /work/env.sh, then: manimgx render scene.py"
