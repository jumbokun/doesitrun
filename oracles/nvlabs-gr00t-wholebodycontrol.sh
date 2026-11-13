set -e
source /work/env.sh
cd /work/GR00T-WholeBodyControl/motionbricks
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 3000 python scripts/train_vqvae.py --max_steps 20 --batch_size 4 --num_samples 40 > "$OUT/log.txt" 2>&1 || { tail -40 "$OUT/log.txt"; echo FAIL; exit 1; }
tail -15 "$OUT/log.txt"
grep -q "Starting VQVAE training for 20 steps" "$OUT/log.txt"
grep -q "Training complete." "$OUT/log.txt"
grep -Eq "max_steps=20. reached|Epoch [0-9]+:.*20/|20it|20/" "$OUT/log.txt"
! grep -q "Traceback" "$OUT/log.txt"
echo "ORACLE PASS"
