# Pass: README generate.py (MetFaces) writes the seed PNGs, with the custom CUDA plugins compiled
# (no 'Falling back to slow reference implementation').
set -e
source /work/env.sh
cd /work/stylegan2-ada-pytorch
rm -rf /tmp/oracle_sg
timeout 1800 python generate.py --outdir=/tmp/oracle_sg --trunc=1 --seeds=85,265 \
  --network=https://nvlabs-fi-cdn.nvidia.com/stylegan2-ada-pytorch/pretrained/metfaces.pkl 2>&1 | tee /tmp/sg.log
if grep -qiE "falling back|failed to build" /tmp/sg.log; then echo "ORACLE: CUDA plugin fallback"; exit 1; fi
test -s /tmp/oracle_sg/seed0085.png && test -s /tmp/oracle_sg/seed0265.png || { echo "ORACLE: missing PNGs"; exit 1; }
python3 - <<'PY'
import struct
for s in ("0085", "0265"):
    d = open(f"/tmp/oracle_sg/seed{s}.png", "rb").read(24)
    w, h = struct.unpack(">II", d[16:24]); print("ORACLE:", s, w, h)
    assert (w, h) == (1024, 1024)
PY
echo "ORACLE PASS"
