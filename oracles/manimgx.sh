# Pass: README "From Python to MP4" scene renders to Hello3D.mp4, a ~6 s 1920x1080 video.
# v2: v1 checked the duration only `if command -v ffprobe`, but neither the base image nor a README install has ffprobe
# (README: "Fonts, typesetting and video encoding are included"; the wheel bundles x264), so the duration check never
# ran. v2 reads duration and frame size straight from the MP4 boxes with the standard library.
set -e
source /work/env.sh
D=$(mktemp -d)
cd "$D"
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
# src/manimgx/cli/export.py:83 — default output is <Scene>.mp4 beside the scene file
f="$D/Hello3D.mp4"
test -s "$f" || { echo "ORACLE: no Hello3D.mp4"; exit 1; }
size=$(stat -c %s "$f"); echo "ORACLE: $f size=$size"
test "$size" -gt 20000
python3 - "$f" <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()

def boxes(buf, start, end):
    i = start
    while i + 8 <= end:
        size, kind = struct.unpack(">I4s", buf[i:i + 8])
        hdr = 8
        if size == 1:
            size = struct.unpack(">Q", buf[i + 8:i + 16])[0]; hdr = 16
        elif size == 0:
            size = end - i
        if size < hdr:
            break
        yield kind, i + hdr, i + size
        i += size

moov = next(((s, e) for k, s, e in boxes(data, 0, len(data)) if k == b"moov"), None)
assert moov, "no moov box"
dur = None; sizes = []
for k, s, e in boxes(data, *moov):
    if k == b"mvhd":
        v = data[s]
        if v == 1:
            ts, d = struct.unpack(">IQ", data[s + 20:s + 32])
        else:
            ts, d = struct.unpack(">II", data[s + 12:s + 20])
        dur = d / ts
    if k == b"trak":
        for k2, s2, e2 in boxes(data, s, e):
            if k2 == b"tkhd":
                w, h = struct.unpack(">II", data[e2 - 8:e2])
                sizes.append((w >> 16, h >> 16))
print("ORACLE: duration", dur, "track sizes", sizes)
# README: run_time=2 + wait(4) = 6 s; "You get Hello3D.mp4, a 1080p60 video" (cli/scenes.py:80 default 1920x1080)
assert dur is not None and 5.0 < dur < 7.0, dur
assert (1920, 1080) in sizes, sizes
PY
echo "ORACLE PASS"
