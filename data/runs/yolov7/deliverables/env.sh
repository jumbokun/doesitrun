# Source this before running the demo:  source /work/env.sh
# Activates the uv-created venv that holds torch 2.11.0+cu128 (sm_120 kernels).
export VIRTUAL_ENV=/work/venv
export PATH="/work/venv/bin:$PATH"
unset PYTHONHOME 2>/dev/null || true
# yolov7 has no installable package; it is run from its checkout.
export YOLOV7_DIR=/work/yolov7
