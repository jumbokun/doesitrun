set -e
source /work/env.sh
cd /work/Qwen-Agent
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
curl -sf --max-time 60 http://localhost:11434/v1/models | tee $OUT/models.json
grep -q 'qwen' $OUT/models.json
# doc_parser caches parsed files under the workspace dir (qwen_agent/settings.py:27); keep it in $OUT
export QWEN_AGENT_DEFAULT_WORKSPACE=$OUT/ws
cat > $OUT/t.py <<'P'
# Mirrors README.md "Developing Your Own Agent" (lines 90-170): a custom tool registered with
# @register_tool, an Assistant over an OpenAI-compatible server (Ollama) with function_list and
# files=['./examples/resource/doc.pdf'] (RAG). The README's other tool, code_interpreter, is not
# tested: README.md:187-189 says it needs a running local Docker, which this sandbox does not have.
import sys, json, os
import json5
from qwen_agent.agents import Assistant
from qwen_agent.tools.base import BaseTool, register_tool
from qwen_agent.tools import Retrieval

out = sys.argv[1]
ms = json.load(open(os.path.join(out, 'models.json')))
names = [m['id'] for m in ms['data']]
model = 'qwen3:1.7b' if 'qwen3:1.7b' in names else names[0]
print('model', model)
llm = {'model': model, 'model_server': 'http://localhost:11434/v1', 'api_key': 'EMPTY',
       'generate_cfg': {'max_tokens': 1500}}

def text_of(msgs):
    return ''.join(m.get('content', '') if isinstance(m.get('content', ''), str) else ''
                   for m in msgs if m['role'] == 'assistant')

def run(bot, q):
    last = []
    for last in bot.run([{'role': 'user', 'content': q}]):
        pass
    return last

# 1) plain chat
bot = Assistant(llm=llm, system_message='You are a helpful assistant. Reply briefly.')
ok = False
for attempt in range(3):
    text = text_of(run(bot, 'What is the capital of France? Answer in one short sentence.'))
    print('CHAT:', text[:200])
    if 'paris' in text.lower():
        ok = True; break
assert ok, 'chat reply never mentioned Paris'

# 2) custom tool, as README Step 1 (register_tool + description + parameters + call)
CALLS = []
@register_tool('lookup_locker_code')
class LookupLockerCode(BaseTool):
    description = 'Look up the locker code assigned to an employee. Returns the code as JSON.'
    parameters = [{'name': 'employee', 'type': 'string', 'description': 'Employee first name', 'required': True}]
    def call(self, params: str, **kwargs) -> str:
        name = json5.loads(params)['employee']
        CALLS.append(name)
        return json5.dumps({'employee': name, 'locker_code': '7319'})

bot = Assistant(llm=llm, function_list=['lookup_locker_code'],
                system_message='You are a helpful assistant. Use the available tools when they can answer the question.')
ok = False
for attempt in range(3):
    CALLS.clear()
    msgs = run(bot, "What is the locker code for the employee named Alice? Use the lookup_locker_code tool.")
    fc = [m for m in msgs if m['role'] == 'assistant' and m.get('function_call')]
    fn = [m for m in msgs if m['role'] == 'function']
    text = text_of(msgs)
    print('TOOL attempt', attempt, 'calls', CALLS, 'fc', [m['function_call'].get('name') for m in fc], 'reply', text[-200:])
    if CALLS and fc and fn and fc[0]['function_call'].get('name') == 'lookup_locker_code' and '7319' in text:
        ok = True; break
assert ok, 'agent did not call the custom tool and report its result'

# 3) RAG over the README's bundled PDF: first the retrieval tool itself (deterministic),
#    then the Assistant answering from files=[...] (qwen_agent/agents/assistant.py:116-132).
pdf = os.path.abspath('examples/resource/doc.pdf')
hits = Retrieval().call({'query': 'flip image horizontal FLIP_LEFT_RIGHT', 'files': [pdf]})
assert hits and 'FLIP_LEFT_RIGHT' in json.dumps(hits, ensure_ascii=False), str(hits)[:500]
print('RETRIEVAL_OK', len(hits))
bot = Assistant(llm=llm, files=[pdf],
                system_message='Answer using the provided document. Reply briefly.')
ok = False
for attempt in range(3):
    text = text_of(run(bot, 'In the tutorial document, which Pillow constant does flip_image pass to transpose() for a horizontal flip?'))
    print('RAG attempt', attempt, text[-300:])
    if 'left_right' in text.lower():
        ok = True; break
assert ok, 'RAG answer did not use the document'
print('OK')
P
timeout 1800 python $OUT/t.py $OUT > $OUT/log.txt 2>&1 || { tail -40 $OUT/log.txt; exit 1; }
grep -v ' - INFO - \| - DEBUG - ' $OUT/log.txt | tail -20
grep -q '^OK$' $OUT/log.txt
echo "ORACLE PASS"
