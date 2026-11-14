set -e
source /work/env.sh
cd /work/PocketFlow
export PYTHONPATH=$PYTHONPATH:$(pwd)
D=$(mktemp -d /tmp/oracle.XXXXXX)

# Dataset: the documented way is path.conf -> data_dir_local_cifar10 (docs/docs/installation.md:17-30,
# path.conf.template). Use that directory if it holds a complete CIFAR-10 binary set; otherwise download.
# (cs.toronto.edu serves ~56 KB/s to these runners, so a fresh 170 MB download inside the hidden test
# could not finish in its budget - that, not the repo, is what failed run 1.)
valid_c10() {  # 5 train batches + test batch, each exactly 10000 records x 3073 bytes
  local d=$1
  for f in data_batch_1 data_batch_2 data_batch_3 data_batch_4 data_batch_5 test_batch; do
    [ "$(stat -c %s "$d/$f.bin" 2>/dev/null)" = "30730000" ] || return 1
  done
}
DATA=""
if [ -f path.conf ]; then
  C=$(sed -n 's/#.*//; s/^data_dir_local_cifar10 = *//p' path.conf | tr -d ' ' | head -1)
  if [ -n "$C" ] && [ "$C" != "None" ] && valid_c10 "$C"; then DATA=$C; fi
fi
if [ -z "$DATA" ]; then
  mkdir -p $D/data
  timeout 2400 curl -fsSL --retry 5 --retry-all-errors -C - -o $D/c10.tgz https://www.cs.toronto.edu/~kriz/cifar-10-binary.tar.gz
  tar -xzf $D/c10.tgz -C $D/data
  DATA=$D/data/cifar-10-batches-bin
fi
echo "CIFAR-10 dir: $DATA"
valid_c10 "$DATA"

# Fresh outputs: no checkpoint left over from the installing agent may satisfy the checks below.
rm -rf models models_eval logs; mkdir -p logs
# Same entry point run_local.sh uses (it copies the script to main.py and adds path.conf args);
# --model_http_url None avoids pulling pre-trained models (not needed for the full-precision learner).
ARGS="--data_dir_local $DATA --model_http_url None --log_dir $D/logs --nb_epochs_rat 0.01 --save_step 100000"
timeout 1500 python nets/lenet_at_cifar10_run.py $ARGS > $D/train.log 2>&1 || { tail -40 $D/train.log; exit 1; }
grep -v -i warn $D/train.log | tail -15
ls models_eval/model.ckpt*
test -s models_eval/model.ckpt.index
grep -q "model saved to" $D/train.log          # learners/full_precision/learner.py:191
timeout 900 python nets/lenet_at_cifar10_run.py $ARGS --exec_mode eval > $D/eval.log 2>&1 || { tail -40 $D/eval.log; exit 1; }
grep -i "accuracy" $D/eval.log | tail -5
python - $D/eval.log <<'PY'
import re, sys
t = open(sys.argv[1]).read()
# learners/full_precision/learner.py:103 logs '%s = %.4e', e.g. "accuracy = 3.7280e-01"
m = re.findall(r'accuracy = ([0-9.]+(?:[eE][-+]?[0-9]+)?)', t)
assert m, "no accuracy line"
a = float(m[-1])
assert 0.0 <= a <= 1.0, a
assert a > 0.15, a   # chance is 0.10; ~0.37-0.40 after 1% of an epoch schedule
print("acc", a)
PY
echo "ORACLE PASS"
