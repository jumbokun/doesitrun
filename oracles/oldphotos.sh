# Pass: README full pipeline with --with_scratch on GPU 0 restores every bundled scratched test image.
set -e
source /work/env.sh
cd /work/Bringing-Old-Photos-Back-to-Life
rm -rf /tmp/oracle_op
IN=/work/Bringing-Old-Photos-Back-to-Life/test_images/old_w_scratch
timeout 2400 python run.py --input_folder $IN --output_folder /tmp/oracle_op --GPU 0 --with_scratch
n_in=$(ls $IN | wc -l); n_out=$(ls /tmp/oracle_op/final_output 2>/dev/null | wc -l)
echo "ORACLE: inputs=$n_in final_outputs=$n_out"
test "$n_out" -ge 1 && test "$n_out" -eq "$n_in"
echo "ORACLE PASS"
