set -e
source /work/env.sh
cd /work/GR00T-WholeBodyControl/motionbricks
OUT=$(mktemp -d /tmp/oracle.XXXXXX)

# motionbricks/README.md "Training": train_vqvae.py and train_root.py run on synthetic data and read their
# configs from out/<model>/version_1/{hparams.yaml,skeleton,stats} (plain git files, not LFS).
# train_pose.py is skipped: it needs the LFS VQVAE checkpoint the README marks as an optional download.
run_train () {   # $1 script  $2 banner prefix (scripts/train_vqvae.py:131, scripts/train_root.py:143)
  local log="$OUT/$(basename "$1" .py).log"
  timeout 1500 python "$1" --max_steps 20 --batch_size 4 --num_samples 40 > "$log" 2>&1 || { tail -40 "$log"; echo "FAIL: $1"; exit 1; }
  tail -8 "$log"
  grep -q "$2 for 20 steps" "$log" || { echo "no start banner in $1"; exit 1; }
  grep -q "Feature dim: [1-9]" "$log" || { echo "no feature dim in $1"; exit 1; }
  # Lightning reports the max_steps stop; "Training complete." is printed only after trainer.fit returns
  grep -Eq "max_steps=20. reached|20/" "$log" || { echo "did not reach 20 steps in $1"; exit 1; }
  grep -q "^Training complete\.$" "$log" || { echo "no completion line in $1"; exit 1; }
  if grep -q "Traceback" "$log"; then echo "traceback in $1"; exit 1; fi
}
run_train scripts/train_vqvae.py "Starting VQVAE training"
run_train scripts/train_root.py "Starting root model training"
echo "ORACLE PASS"
