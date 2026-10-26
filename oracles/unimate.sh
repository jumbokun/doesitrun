# Pass: README inference path 2b (bundled unitree_go2 asset + released checkpoint) writes motion output.
set -e
source /work/env.sh
cd /work/UniMate
rm -rf /tmp/oracle_out
timeout 1800 python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 \
  --asset assets/examples/unitree_go2 --prompt "An object trots forward." --output_dir /tmp/oracle_out
n=$(find /tmp/oracle_out -type f | wc -l); echo "ORACLE: output files=$n"; find /tmp/oracle_out -type f | head
test "$n" -gt 0
echo "ORACLE PASS"
