# source this file
source /work/venv/bin/activate
export HY3DGEN_MODELS=${HY3DGEN_MODELS:-/root/.cache/hy3dgen}
export PYTHONPATH=/work/Hunyuan3D-2.1:/work/Hunyuan3D-2.1/hy3dshape${PYTHONPATH:+:$PYTHONPATH}
export CUDA_VISIBLE_DEVICES=""
cd /work/Hunyuan3D-2.1
