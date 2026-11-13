set -e
source /work/env.sh
cd /work/agent-framework
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 600 python python/samples/03-workflows/_start-here/step1_executors_and_edges.py > $OUT/out.txt 2>&1 || { cat $OUT/out.txt; exit 1; }
cat $OUT/out.txt
grep -F "['DLROW OLLEH']" $OUT/out.txt
grep -F "['!!!DLROW OLLEH']" $OUT/out.txt
[ "$(grep -c 'WorkflowRunState.IDLE' $OUT/out.txt)" -ge 2 ]
cat > $OUT/custom.py <<'PY'
import asyncio, sys
sys.path.insert(0, sys.argv[1])
from step1_executors_and_edges import create_workflow
async def main():
    ev = await create_workflow().run("agent framework")
    print("RESULT", ev.get_outputs())
asyncio.run(main())
PY
timeout 300 python $OUT/custom.py /work/agent-framework/python/samples/03-workflows/_start-here | tee $OUT/c.txt
grep -F "RESULT ['KROWEMARF TNEGA']" $OUT/c.txt
echo "ORACLE PASS"
