set -e
source /work/env.sh
cd /work/AnimatedDrawings
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cat > $OUT/gif.yaml <<EOC
scene:
  ANIMATED_CHARACTERS:
    - character_cfg: examples/characters/char1/char_cfg.yaml
      motion_cfg: examples/config/motion/dab.yaml
      retarget_cfg: examples/config/retarget/fair1_ppf.yaml
view:
  USE_MESA: True
controller:
  MODE: video_render
  OUTPUT_VIDEO_PATH: $OUT/video.gif
EOC
timeout 1200 python -c "from animated_drawings import render; render.start('$OUT/gif.yaml')"
test -s $OUT/video.gif
SZ=$(stat -c %s $OUT/video.gif)
echo "size $SZ"
test "$SZ" -gt 20000
python - "$OUT/video.gif" <<'EOP'
import sys
from PIL import Image
im=Image.open(sys.argv[1])
assert im.format=="GIF" and im.n_frames>10, (im.format, im.n_frames)
assert im.size[0]>=100 and im.size[1]>=100, im.size
frames=set()
for i in (0,im.n_frames//2):
    im.seek(i); frames.add(im.convert("RGBA").tobytes())
assert len(frames)==2, "frames identical"
print("frames", im.n_frames, im.size)
EOP
echo ORACLE PASS
