# Pass: README "From Python to MP4" scene renders to Hello3D.mp4 (~6 s).
set -e
source /work/env.sh
rm -rf /tmp/oracle && mkdir -p /tmp/oracle && cd /tmp/oracle
cat > scene.py <<'PY'
import manimgx as m


class Hello3D(m.ThreeDScene):
    def construct(self) -> None:
        self.set_camera_orientation(phi=65 * m.DEGREES, theta=-45 * m.DEGREES)
        self.begin_ambient_camera_rotation(rate=0.5)
        cube = m.Cube(side_length=3, fill_opacity=0.3, stroke_width=2)
        self.play(m.Create(cube), run_time=2)
        self.wait(4)
PY
timeout 1800 manimgx render scene.py
f=$(find /tmp/oracle -name 'Hello3D.mp4' | head -1)
test -n "$f" || { echo "ORACLE: no Hello3D.mp4"; exit 1; }
size=$(stat -c %s "$f"); echo "ORACLE: $f size=$size"
test "$size" -gt 20000
if command -v ffprobe >/dev/null; then
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f"); echo "ORACLE: duration=$dur"
  python3 -c "import sys; d=float('$dur'); sys.exit(0 if 5.0<d<7.0 else 1)"
else
  echo "ORACLE: ffprobe absent, duration not checked"
fi
echo "ORACLE PASS"
