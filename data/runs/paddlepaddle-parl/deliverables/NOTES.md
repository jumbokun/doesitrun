# PARL QuickStart (CartPole) on CPU

README path: `pip install parl paddlepaddle gym pygame; python train.py`. It doesn't work as written:

1. **Python version**: the system Python 3.12 can't satisfy parl's pins (grpcio==1.37.0, pyzmq==22.3.0 have no cp312 wheels). I used a uv venv with Python 3.9 (`/work/venv`).
2. **protobuf conflict**: parl 2.2.2 pins `protobuf<=3.20.0`, but every paddlepaddle still on PyPI for cp39 (2.6.2, 3.x) needs `protobuf>=3.20.2`, so the resolver fails. I overrode it to protobuf==3.20.3. The single-process QuickStart doesn't use the protobuf/grpc parts.
3. **pkg_resources missing**: `parl/remote/utils.py` imports `pkg_resources`, and fresh venvs don't ship setuptools. I installed `setuptools<70`.
4. **numpy pin**: gym 0.26.2 uses `np.bool8`, so I pinned numpy<2. I also pinned paddlepaddle==2.6.2, the last 2.x release.
5. The editable install (`-e /work/PARL`) with uv didn't make `parl` importable, so I install the clone non-editably.

No code changes. The 1000-episode training takes about 25 s on CPU, test reward reaches 500, and it writes ./model.ckpt.
