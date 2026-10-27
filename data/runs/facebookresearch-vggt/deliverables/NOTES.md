# VGGT on CPU – notes

Repo commit tested: a288dd0. Python 3.12 (uv venv at /work/venv), torch 2.3.1+cpu, numpy 1.26.1.

What broke / what I changed vs. README:
- `git clone git@github.com:...` needs SSH keys; cloned via https instead.
- `pip install -r requirements.txt` from default PyPI would pull CUDA torch builds; installed torch==2.3.1 /
  torchvision==0.18.1 from the PyTorch CPU wheel index (same pinned versions).
- The quick-start snippet calls `torch.cuda.get_device_capability()` unconditionally, which crashes on CPU,
  and uses `torch.cuda.amp.autocast`. On CPU: use `dtype = torch.float32` and call `model(images)` under
  `torch.no_grad()` without the CUDA autocast. No repo code was patched.
- Installed the repo itself in editable mode (`uv pip install --no-deps -e .`) plus PYTHONPATH in env.sh so
  `import vggt` works from any directory.
- Pre-downloaded facebook/VGGT-1B into HF_HOME=/work/hf_cache during setup (no token needed); env.sh exports it.

Verified: 4 kitchen images -> pose_enc (1,4,9), depth (1,4,350,518,1), world_points (1,4,350,518,3), all finite;
unproject_depth_map_to_point_map gives (4,350,518,3) finite points. ~85 s on 4 CPU cores.
