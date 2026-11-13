# openai/gym (0.26.2, commit bc212954) setup notes

- **What broke:** the README says `pip install gym`. I installed this clone (`pip install -e /work/gym`) into the default Python 3.12 environment, which pulled in NumPy 2.x. The README example then crashed on the first `env.step()` with `AttributeError: module 'numpy' has no attribute 'bool8'`. The crash comes from `gym/utils/passive_env_checker.py`, and the cause is that NumPy 2.0 removed `np.bool8`.
- **Changes I made:**
  - I pinned `numpy<2`, which installed 1.26.4.
  - I used a uv-managed Python 3.10 venv at /work/.venv. The README lists 3.7–3.10 as supported, and the sandbox's python3 is 3.12.
  - I installed the clone in editable mode so that `import gym` loads /work/gym.
- **Code patches:** none.
- **Expected warnings (not errors):** importing gym prints a notice from `gym_notices` saying gym is unmaintained, and NumPy prints a DeprecationWarning about `np.bool8`.
- **Test result:** I ran the README loop for 1000 steps. Every observation had shape (4,), and 40–45 episodes ended with terminated or truncated.
