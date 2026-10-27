set -e
source /work/env.sh
cd /work/FaceDetection-DSFD
test -s weights/WIDERFace_DSFD_RES152.pth
OUT=/tmp/oracle_out_$$/
rm -rf "$OUT"; mkdir -p "$OUT"
timeout 6000 python demo.py --trained_model weights/WIDERFace_DSFD_RES152.pth --img_root ./data/worlds-largest-selfie.jpg --save_folder "$OUT" --visual_threshold 0.5 2>&1 | tail -n 30
F=$(find "$OUT" -type f -size +20k | head -n 1)
test -n "$F" || { echo "no output image"; exit 1; }
python - "$F" <<'P'
import sys
d=open(sys.argv[1],'rb').read(8)
assert d[:8]==b'\x89PNG\r\n\x1a\n' or d[:2]==b'\xff\xd8', "not an image"
P
echo ORACLE PASS
