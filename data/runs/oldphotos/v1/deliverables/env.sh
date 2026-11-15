# Source (do not execute) before running the pipeline:
#   source /work/env.sh
#   cd /work/Bringing-Old-Photos-Back-to-Life
#   python run.py --input_folder /work/Bringing-Old-Photos-Back-to-Life/test_images/old_w_scratch \
#                 --output_folder /work/output --GPU 0 --with_scratch
export VIRTUAL_ENV=/work/venv
export PATH="/work/venv/bin:$PATH"
unset PYTHONHOME
export MPLBACKEND=Agg          # Face_Detection scripts import matplotlib; no display here
export PROJECT_DIR=/work/Bringing-Old-Photos-Back-to-Life
