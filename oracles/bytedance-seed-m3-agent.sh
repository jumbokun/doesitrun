set -e
source /work/env.sh
cd /work/m3-agent
D=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1500 curl -sSL --retry 3 -o $D/robot.tar.gz https://huggingface.co/datasets/ByteDance-Seed/M3-Bench/resolve/main/memory_graphs/robot.tar.gz
P=$(timeout 900 tar -tzf $D/robot.tar.gz | grep 'bedroom_01\.pkl$' | head -1)
test -n "$P"
timeout 900 tar -xzf $D/robot.tar.gz -C $D "$P"
PKL=$D/$P
test "$(stat -c %s $PKL)" -gt 10000
timeout 600 python visualization.py --mem_path "$PKL" --clip_id 1 > $D/out.txt 2>&1 || { tail -30 $D/out.txt; exit 1; }
grep -q "Clip 1 Memory" $D/out.txt
grep -Eq "\[ *(episodic|semantic) *\]" $D/out.txt
test "$(wc -c < $D/out.txt)" -gt 300
head -20 $D/out.txt
echo "ORACLE PASS"
