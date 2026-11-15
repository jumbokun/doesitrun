# earshot setup notes
Followed the README's "install from a clone" path (venv + CPU torch wheel + `pip install -e ".[mcp,llm,dev]"`) on Python 3.12.
It worked as written. The only thing not spelled out: the README says ffmpeg/ffprobe must be on PATH but gives no
install command, so `apt-get install ffmpeg` (plus libsndfile1, python3-venv to be safe) was added. Models were fetched
with `earshot doctor --fetch` (documented). `doctor --load` reports problems: [], both models load; whoosh_fast/crisp
renders; describe returns tags + AudioSet labels (Whoosh, swoosh, swish); match gives 'a fast air whoosh' >99% vs the alts.
No code changes.
