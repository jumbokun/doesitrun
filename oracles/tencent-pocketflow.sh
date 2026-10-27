set -e
source /work/env.sh
cd /work/PocketFlow
export PYTHONPATH=$PYTHONPATH:$(pwd)
D=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p $D/data
timeout 900 curl -fsSL -o $D/c10.tgz https://www.cs.toronto.edu/~kriz/cifar-10-binary.tar.gz
tar -xzf $D/c10.tgz -C $D/data
DATA=$D/data/cifar-10-batches-bin
test -f $DATA/data_batch_1.bin && test -f $DATA/test_batch.bin
rm -rf models models_eval logs; mkdir -p logs
ARGS="--data_dir_local $DATA --model_http_url None --log_dir $D/logs --nb_epochs_rat 0.01 --save_step 100000"
timeout 5400 python nets/lenet_at_cifar10_run.py $ARGS 2>&1 | tee $D/train.log
ls models_eval/model.ckpt*
test -s models_eval/model.ckpt.index
grep -q "model saved to" $D/train.log
timeout 1800 python nets/lenet_at_cifar10_run.py $ARGS --exec_mode eval 2>&1 | tee $D/eval.log
grep -i "acc" $D/eval.log | tail -5
python - $D/eval.log <<'PY'
import re,sys
t=open(sys.argv[1]).read()
m=re.findall(r'acc[a-z_0-9]*\s*[=:]\s*([0-9.]+)',t,re.I)
assert m, "no accuracy found"
a=float(m[-1]); a=a/100 if a>1 else a
assert a>0.15, a
print("acc",a)
PY
echo "ORACLE PASS"
