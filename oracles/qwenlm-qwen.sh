set -e
source /work/env.sh
cd /work/Qwen
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
printf 'What is the capital of France? Answer briefly.\n:q\n' > $OUT/in.txt
timeout 3000 python cli_demo.py -c Qwen/Qwen-1_8B-Chat --cpu-only < $OUT/in.txt > $OUT/out.txt 2>&1 || { tail -50 $OUT/out.txt; exit 1; }
tail -30 $OUT/out.txt
grep -qi "paris" $OUT/out.txt || { echo "no Paris in output"; exit 1; }
echo "ORACLE PASS"
