#!/usr/bin/env bash
# Keep Docker's WSL VM page cache from pinning host RAM while probes run; stops when the batch finishes.
export MSYS_NO_PATHCONV=1
while ! grep -q "all done" runs/resume_lowmem.log 2>/dev/null; do
  docker run --rm --privileged --pid=host alpine:3.20 nsenter -t 1 -m sh -c 'sync; echo 1 > /proc/sys/vm/drop_caches' >/dev/null 2>&1
  sleep 120
done
