source /work/venv/bin/activate
export PADDLE_PDX_MODEL_SOURCE=${PADDLE_PDX_MODEL_SOURCE:-BOS}
# Paddle 3.3.x oneDNN executor crashes on PP-OCRv6 det (ArrayAttribute<DoubleAttribute>); use plain CPU run mode
export PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT=False
export PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
