# Bringing-Old-Photos-Back-to-Life — setup notes

Pinned to commit 33875ec. Python 3.12 venv at /work/venv (uv).

What broke / what I changed compared to the README:
1. **Missing system tools**: the README uses `wget`/`unzip`, and dlib builds from source and needs `cmake` and the
   Python headers (`python3-dev`; without them the build fails with pybind11 `/usr/include/python3.12` missing).
   Installed with apt: wget unzip bzip2 cmake python3-dev libgl1 libglib2.0-0.
2. **GPU compat**: requirements.txt doesn't pin torch. I installed torch 2.8.0 / torchvision 0.23.0 from the cu128
   index because the RTX 5060 (Blackwell) needs sm_120 kernels.
3. **dlib CUDA build**: dlib picks up the CUDA toolkit on its own and tries a CUDA build. I set `DLIB_USE_CUDA=0`,
   because dlib only does face landmark detection here and the CPU build is enough.
4. **Code patch (Stage 4 blending crash)**: with current scikit-image (0.26), `warp(..., order=0, preserve_range=True)`
   returns uint8 for the uint8 face mask, so `mask *= 255.0` in `blur_blending_cv2`/`blur_blending` raises
   `UFuncOutputCastingError`. The pipeline still prints "All the processing is done", but final_output/ then only
   has the Stage-1 copies without the face enhancement. I changed it to `mask = mask.astype(np.float64) * 255.0` in
   `Face_Detection/align_warp_back_multiple_dlib.py` and `..._HR.py`.

Result: `python run.py --input_folder .../test_images/old_w_scratch --output_folder /work/out --GPU 0 --with_scratch`
produces a.png..d.png in final_output/, and each one has the enhanced faces blended in. No errors.
