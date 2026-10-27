# trax README translation snippet: CPU setup notes

**Result: the snippet can't be run. The pre-trained weights are no longer publicly downloadable.**

## What broke when following the README (`pip install -U trax` + snippet)
1. **`import trax` fails with TensorFlow ≥ 2.16**: `from tensorflow import estimator` raises
   ImportError (tf.estimator was removed). Fix: a small patch in `trax/data/tf_inputs.py` that
   falls back to the plain `'train'`/`'eval'` ModeKeys strings.
2. **`import trax` fails with current JAX (0.12)**: `jax.config.update('jax_pmap_shmap_merge', False)`
   raises "Unrecognized config option". Fix: pin `jax==jaxlib==0.7.2`, which was current when
   trax HEAD (31022d6, Sep 2025) was committed.
3. **Blocker: `gs://trax-ml` is no longer public.** Every object, including
   `models/translation/ende_wmt32k.pkl.gz` and `vocabs/ende_32k.subword`, returns HTTP 403
   "Anonymous caller does not have storage.objects.get access". The README never mentions
   credentials, and none were used. I found no mirror on Hugging Face, Kaggle, GitHub,
   Sourcegraph or the Wayback Machine. The related `tensor2tensor-checkpoints` and
   `tensor2tensor-data` buckets are also 403.
   - The vocab has a substitute: `trax/models/reformer/testdata/vocab.translate_ende_wmt32k.32768.subwords`
     (the same T2T ende 32k subword vocab). Tokenization works with it.
   - The weights have no substitute.

## What works
`setup.sh` builds a Python 3.12 venv with the patched trax (editable install from the cloned repo),
TF 2.21, tensorflow-text 2.21.1 and jax 0.7.2. With it, the Transformer builds in predict mode,
tokenization, `autoregressive_sample` and detokenization all run on CPU. This was checked with
random-initialized weights (`/work/test/pipeline_check.py`). Only `init_from_file` on the
gs:// checkpoint fails. If Google re-opens the bucket, the README snippet should work as written
in this environment.
