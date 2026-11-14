# t5 HfPyTorchModel on CPU — notes

Following the README (`pip install t5[gcp]` / install from the clone) on Python 3.12 doesn't give a working setup.

What broke, and what I changed:
1. **Python version**: t5 requires `pandas<2.0.0`. pandas 1.5.3 has no cp312 wheel, and building it from source fails (`No module named pkg_resources`). I switched to a Python 3.11 venv (`uv venv -p 3.11`).
2. **numpy 2** got resolved, which breaks pandas 1.5.3 (`numpy.dtype size changed`). Pinned `numpy<2`.
3. **TensorFlow 2.21** got resolved, and `tf.compat.v1.estimator` no longer exists there. mesh-tensorflow needs it, so `import t5.models` fails. Pinned `tensorflow==2.15.1` and the matching `tensorflow-text==2.15.0`.
4. **setuptools >= 81** removed `pkg_resources`, which tensorflow_hub imports. Pinned `setuptools<81`.
5. **protobuf**: TF 2.15 needs protobuf<5, but the latest `sentencepiece` and `tensorflow-metadata` pb2 files need protobuf>=5 (`runtime_version`). Pinned `sentencepiece==0.2.0` and `tensorflow-metadata==1.15.0`.
6. **torch** isn't in the default install (it's only in the `test` extra). I installed the CPU wheel from download.pytorch.org.
7. **Code bug**: `HfPyTorchModel.predict` encodes inputs with `encode_tf` but never adds EOS. mesh's `ensure_eos` only fixes truncated sequences. Without EOS, t5-base returns garbage (sentinel tokens instead of CoLA labels, and repeated text in translations). I patched `t5/models/hf_model.py` to append `eos_id` to each encoded input. After the patch: "Das ist gut." / "La maison est merveilleuse." / "acceptable" / "unacceptable".

Other details:
- The default vocab is read anonymously from the public `gs://t5-data` bucket, so network access is needed at predict time. `env.sh` sets `NO_GCE_CHECK=true` to skip the GCE metadata probe.
- The t5-base checkpoint is pre-downloaded into `HF_HOME=/work/hf_cache`.
- The t5 clone is installed in editable mode into `/work/venv`.
