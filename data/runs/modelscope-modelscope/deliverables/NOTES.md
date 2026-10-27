# modelscope word-segmentation on CPU

The README path is: conda py3.8, install torch, then `pip install modelscope[nlp] -f .../repo.html`.

What I did and what broke:
- I used `uv venv -p 3.10` instead of conda py3.8 (no conda in the image). Torch is the CPU wheel from download.pytorch.org.
- Installed `-e ".[nlp]"` from the clone with the README's `-f` link. That worked.
- At load time, the model repo (`damo/nlp_structbert_word-segmentation_chinese-base`) ships a
  `requirements.txt` (`transformers==4.48.3`, `huggingface-hub==0.25.*`). modelscope tries to
  `python -m pip install` them on the fly. That fails in a uv venv because it has no pip. Fix: pre-install those pins.
- Next: `RuntimeError: ... trust_remote_code=True was not explicitly set`. The model's
  configuration.json has `allow_remote: true`. `pipeline()` correctly treats `damo/` as a
  Hub-verified trusted owner, but `TokenClassificationPipeline.__init__` doesn't forward
  `trust_remote_code` to `Pipeline.__init__`, so `Model.from_pretrained` refuses to load. I patched it to forward the
  flag (one line in `modelscope/pipelines/nlp/token_classification_pipeline.py`). The security check is unchanged.
- Result: `{'output': ['今天', '天气', '不错', '，', '适合', '出去', '游玩']}` on CPU.
