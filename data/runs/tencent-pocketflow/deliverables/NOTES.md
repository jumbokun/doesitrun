# PocketFlow local-mode CPU setup

Following the docs (installation.md: Python 3.6 + `pip install tensorflow`, edit path.conf, `./scripts/run_local.sh nets/lenet_at_cifar10_run.py`) did not work as written.

What broke / what I changed:
- **Python version**: docs ask for Python 3.6 / TF 1.10; uv can no longer download <=3.7 and modern `pip install tensorflow` is TF2. Used micromamba (conda-forge) to make a Python 3.7 env at /work/venv and installed `tensorflow==1.15.5` (last TF1, CPU) plus pinned numpy/scipy/pandas/scikit-learn/protobuf (requirement.txt lists the obsolete `sklearn` package name and `mpi4py`, which isn't needed for 1-process CPU runs).
- **path.conf**: copied from path.conf.template, set `data_dir_local_cifar10=/work/data/cifar-10-batches-bin` (CIFAR-10 binary downloaded from toronto.edu).
- **Code patch 1**: `learners/uniform_quantization_tf/utils.py` imports `tensorflow.contrib.lite`, which moved to `tensorflow.lite` in TF>=1.14 → every run crashed at import. Added try/except fallback.
- **Code patch 2**: `nets/*_run.py` define `--log_dir`, which absl.logging (imported by TF 1.15) already defines → DuplicateFlagError. Delete the absl flag before redefining.
- **Code patch 3**: `datasets/cifar10_dataset.py` had module-level `tf.constant` mean/std living in the default graph; TF 1.15's `dataset.map` refuses to use them from the learner's graph. Changed to numpy arrays.
- **No GPU**: `utils/get_idle_gpus.py` errors because `nvidia-smi` is missing; harmless (run_local.sh continues with empty CUDA_VISIBLE_DEVICES). env.sh also sets `CUDA_VISIBLE_DEVICES=""`.

Result: `./scripts/run_local.sh nets/lenet_at_cifar10_run.py --nb_epochs_rat 0.01` trains ~976 iters on CPU in ~1 min, saves ./models_eval/model.ckpt; `--exec_mode eval` reports ~36-41% test accuracy (chance = 10%).
