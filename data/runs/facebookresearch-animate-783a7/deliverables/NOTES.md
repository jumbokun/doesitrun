# AnimatedDrawings headless CPU setup

The README's install steps (conda env with python 3.8.13, `pip install -e .`) work fine. Here they're done with uv: `uv venv --python 3.8` at /work/venv.
Problems and changes:
- No conda in the image, so I used a uv-managed Python 3.8 venv instead (the same Python version the README pins).
- Headless `USE_MESA: True` needs the system OSMesa library, which the README doesn't mention. Without it PyOpenGL can't load osmesa. I installed `libosmesa6 libosmesa6-dev` (plus libgl1/libglib2.0-0 for opencv).
- The bundled export_gif_example.yaml uses char3 and has no `view` section. I added examples/config/mvc/export_gif_char1_mesa.yaml (char1 + dab + `view: USE_MESA: True`).
- No code patches needed. env.sh activates the venv, sets PYOPENGL_PLATFORM=osmesa, and cd's into the repo.
Verified: render.start(...) writes video.gif with 339 frames, and the frames differ.
