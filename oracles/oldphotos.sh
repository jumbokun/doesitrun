# Pass: README full pipeline (`run.py ... --GPU 0 --with_scratch`) restores every bundled scratched test image AND the
# face stages really ran: faces were detected (stage 2), enhanced (stage 3) and blended back (stage 4).
# v2: v1 only counted files in final_output/. run.py ignores every stage's exit code (run.py:10-15 `call(...)`, result
# discarded) and copies the stage-1 images into final_output/ before the face stages start (run.py:97-104), so a
# crash in face detection, face enhancement or blending still left one file per input and passed. (This run's agent
# had to fix a stage-4 crash under modern scikit-image; v1 could not tell whether it had.)
set -e
source /work/env.sh
cd /work/Bringing-Old-Photos-Back-to-Life
OUT=$(mktemp -d)
IN=/work/Bringing-Old-Photos-Back-to-Life/test_images/old_w_scratch
timeout 2400 python run.py --input_folder $IN --output_folder $OUT --GPU 0 --with_scratch
python3 - "$IN" "$OUT" <<'PY'
import os, sys
import numpy as np
from PIL import Image
inp, out = sys.argv[1], sys.argv[2]
names = sorted(os.listdir(inp))
final = os.path.join(out, "final_output")
stage1 = os.path.join(out, "stage_1_restore_output", "restored_image")
faces = sorted(os.listdir(os.path.join(out, "stage_2_detection_output")))              # run.py:114, detect_all_dlib.py:177
each = os.path.join(out, "stage_3_face_output", "each_img")                             # test_face.py:25 (results_dir is absolute)
print("ORACLE: inputs", names, "final", sorted(os.listdir(final)), "faces", faces)
# Global/test.py:175 renames every input to <stem>.png; one restored result per input
assert sorted(os.listdir(final)) == sorted(os.path.splitext(n)[0] + ".png" for n in names)
for n in os.listdir(final):
    a = np.asarray(Image.open(os.path.join(final, n)).convert("RGB"))
    assert a.size > 0 and a.std() > 1, n
# the bundled scratched photos are frontal portraits (e.g. a.png, c.png); dlib must find at least one face
assert faces, "stage 2 detected no faces"
blended = set()
for f in faces:
    assert os.path.isfile(os.path.join(each, f)), f"stage 3 did not enhance {f}"      # same name, align_warp_back:400
    blended.add(f.rsplit("_", 1)[0] + ".png")
for n in sorted(blended):
    a = np.asarray(Image.open(os.path.join(final, n)).convert("RGB")).astype(int)
    b = np.asarray(Image.open(os.path.join(stage1, n)).convert("RGB")).astype(int)
    diff = np.abs(a - b).mean() if a.shape == b.shape else 999
    print("ORACLE:", n, "mean |final - stage1|", diff)
    # stage 4 overwrites final_output/<x> with the face-blended image (align_warp_back_multiple_dlib.py:431)
    assert diff > 0, f"{n}: final output is the unblended stage-1 copy; stage 4 did not run"
PY
echo "ORACLE PASS"
