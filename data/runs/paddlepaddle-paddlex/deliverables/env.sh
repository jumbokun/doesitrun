# source this file
. /work/venv/bin/activate
# paddlepaddle 3.3.0 CPU + oneDNN fails on PP-OCRv6 models
# (ConvertPirAttribute2RuntimeAttribute not support ArrayAttribute<DoubleAttribute>); use plain paddle run mode
export PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT=0
export PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
