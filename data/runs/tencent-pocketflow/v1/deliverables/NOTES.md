# PocketFlow – local-mode CPU setup

Result: `./scripts/run_local.sh nets/lenet_at_cifar10_run.py --nb_epochs_rat 0.01` trains LeNet and saves
`./models_eval/model.ckpt`. Then `--exec_mode eval` reports about 40% test accuracy (chance is 10%). No code changes were needed.

## What broke / what I changed
- **Python version**: the docs say Python 3.6 + TF 1.10. The system has Python 3.12, and uv 0.13 can no longer
  download 3.6 or 3.7. I got Python 3.6 from conda-forge using micromamba and built a uv venv (`/work/venv`) on top of it.
- **TF version**: newer TF does not work. TF 1.13/1.15 lack `tensorflow.contrib.lite.python.lite_constants`, which
  `learners/uniform_quantization_tf/utils.py` imports. TF <1.13 has no cp37 wheels. So I used the documented TF 1.10.0 on Python 3.6.
- **requirement.txt**: it lists `sklearn`, which is a deprecated, broken alias on pip, so I installed `scikit-learn==0.19.2`. The
  unpinned `>=` versions also do not resolve to anything that works with TF 1.10, so I pinned them: numpy 1.14.5, scipy 1.1.0,
  pandas 0.25.3 (0.23/0.24 have pytz metadata that uv rejects), protobuf 3.19.6, and pytz.
- `mpi4py` was skipped. It is only needed for multi-GPU training.
- **path.conf**: created from `path.conf.template`, with `data_dir_local_cifar10=/work/data/cifar-10-batches-bin`
  (the CIFAR-10 binary is downloaded and extracted by setup.sh).
- **No GPU**: `utils/get_idle_gpus.py` prints an `nvidia-smi: not found` traceback. The script has no `set -e`, so
  this does no harm: CUDA_VISIBLE_DEVICES ends up empty and TF runs on the CPU. env.sh also sets CUDA_VISIBLE_DEVICES="".
