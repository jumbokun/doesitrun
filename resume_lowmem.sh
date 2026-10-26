#!/usr/bin/env bash
# One-off: after oldphotos finishes, stop the lane, restart WSL under the 8 GB cap,
# resume batch 2 at 4 GB/container, then run the supplementary replays.
cd "$(dirname "$0")"
export MSYS_NO_PATHCONV=1 PYTHONIOENCODING=utf-8
until [ -f runs/oldphotos/result.json ]; do sleep 20; done
echo "[$(date)] oldphotos done; stopping lane"
powershell -NoProfile -ExecutionPolicy Bypass -File stop_lane.ps1
docker rm -f rr-lama rr-fwcheck 2>/dev/null
echo "[$(date)] restarting WSL with .wslconfig cap"
docker desktop stop 2>&1 | tail -1
wsl --shutdown
docker desktop start 2>&1 | tail -1
for i in $(seq 1 60); do docker version >/dev/null 2>&1 && break; sleep 5; done
docker run --rm --privileged --pid=host alpine:3.20 nsenter -t 1 -m sh -c 'grep MemTotal /proc/meminfo'
echo "[$(date)] resuming lama, mdm"
python run_probe.py --repos=repos_b2.json lama mdm
echo "[$(date)] supplementary replays"
python run_probe.py --repos=repos_b2.json --replay-supplementary groundingdino yolov7
echo "[$(date)] all done"
