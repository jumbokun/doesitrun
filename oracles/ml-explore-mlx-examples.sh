set -e
source /work/env.sh
cd /work/mlx-examples
mkdir -p /tmp/oracle_out
cd mnist
timeout 3000 python main.py > /tmp/oracle_out/log.txt 2>&1 || { cat /tmp/oracle_out/log.txt; exit 1; }
cat /tmp/oracle_out/log.txt
[ "$(grep -c '^Epoch [0-9]*: Test accuracy' /tmp/oracle_out/log.txt)" -eq 10 ]
grep -q '^Epoch 9: ' /tmp/oracle_out/log.txt
python - <<'P'
import re
a=[float(x) for x in re.findall(r'Test accuracy ([0-9.]+)',open('/tmp/oracle_out/log.txt').read())]
assert len(a)==10 and a[-1]>0.90, a
P
echo ORACLE PASS
