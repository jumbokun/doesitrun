set -e
source /work/env.sh
cd /work/Qwen-Agent
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
curl -sf --max-time 60 http://localhost:11434/v1/models | tee $OUT/models.json
grep -q 'qwen' $OUT/models.json
cat > $OUT/t.py <<'P'
import sys, json
from qwen_agent.agents import Assistant
from qwen_agent.tools.base import TOOL_REGISTRY
import qwen_agent.tools
ms = json.load(open(sys.argv[1] + '/models.json'))
names = [m['id'] for m in ms['data']]
model = 'qwen3:1.7b' if 'qwen3:1.7b' in names else names[0]
print('model', model)
llm = {'model': model, 'model_server': 'http://localhost:11434/v1', 'api_key': 'EMPTY',
       'generate_cfg': {'max_tokens': 400}}
bot = Assistant(llm=llm, system_message='You are a helpful assistant. Reply briefly.')
last = None
for last in bot.run([{'role': 'user', 'content': 'What is the capital of France? Answer in one short sentence.'}]):
    pass
text = ''.join(m.get('content', '') if isinstance(m.get('content', ''), str) else '' for m in last if m['role'] == 'assistant')
print('REPLY:', text)
assert len(text.strip()) > 0, 'empty reply'
assert 'paris' in text.lower(), 'expected Paris'
assert 'code_interpreter' in TOOL_REGISTRY
from qwen_agent.tools import CodeInterpreter
out = CodeInterpreter().call({'code': 'print(6*7)'})
print('TOOL:', out)
assert '42' in str(out)
print('OK')
P
timeout 900 python $OUT/t.py $OUT 2>&1 | tee $OUT/log.txt
grep -q '^OK$' $OUT/log.txt
echo "ORACLE PASS"
