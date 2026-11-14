# chalice quickstart (offline, `chalice local`)

The README path worked with only small deviations:

- The README says to use Python 3.10. The image ships Python 3.12, which setup.py supports (>=3.10), so I used the system python3 and made a venv with `python3 -m venv /work/.venv`. No credentials or region were needed for `chalice local`.
- The README runs `pip install chalice` (from PyPI). The task asks for the repo clone, so I ran `pip install -e /work/chalice` instead.
- `chalice local` binds to 127.0.0.1:8000. run.sh starts it with nohup, logs to /work/server.log, and polls `/` until it responds.

I patched no code and pinned no dependencies (I only kept pip below 26.3, which matches setup.py's constraint). I also checked a fresh project with extra routes (a path parameter and a POST JSON echo) under `chalice local`, and both returned the expected responses.
