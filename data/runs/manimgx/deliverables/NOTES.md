# ManimGX setup notes
- README path (`pip install manimgx`, then `manimgx render scene.py`) worked essentially as written, CPU-only.
- Only extra step: the image has Python 3.12 but ManimGX needs 3.13+ (stated in the README), so
  `uv python install 3.13` + a uv venv at /work/venv were used; `uv pip install manimgx` (0.1.1, same as repo).
- No GPU needed: the wheel falls back to a bundled software Vulkan renderer (lavapipe). Hello3D.mp4
  rendered as 6.00 s, 1920x1080@60fps in ~7 s.
- No system packages, pins or code patches required.
