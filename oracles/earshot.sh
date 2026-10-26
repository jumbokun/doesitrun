# Pass: `python -m earshot doctor --load` exits 0 (README install check, loads both models).
set -e
source /work/env.sh
cd /work/earshot
timeout 1800 python -m earshot doctor --load
echo "ORACLE PASS"
