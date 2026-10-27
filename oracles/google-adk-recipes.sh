set -e
source /work/env.sh
cd /work/adk-recipes
export GOOGLE_API_KEY="${GOOGLE_API_KEY:-dummy-key-not-used}"
export GOOGLE_GENAI_USE_VERTEXAI=False
export MODEL_NAME="${MODEL_NAME:-gemini-3.5-flash}"
export ADK_DISABLE_LOCAL_STORAGE=1
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
python3 - "$OUT" <<'PY'
import base64, json, sys, urllib.request
out = sys.argv[1]
def req(url, data=None):
    r = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(r, timeout=120) as f:
        return f.status, f.read().decode()
apps_s, apps = req("http://localhost:8080/list-apps")
assert apps_s == 200 and "expense_agent" in apps, apps
exp = {"amount": 45, "submitter": "bob@company.com", "category": "meals",
       "description": "Team lunch", "date": "2026-04-12"}
body = {"message": {"data": base64.b64encode(json.dumps(exp).encode()).decode(),
                    "attributes": {"source": "test"}}, "subscription": "test-sub"}
s, t = req("http://localhost:8080/apps/expense_agent/trigger/pubsub", json.dumps(body).encode())
open(out + "/resp.json", "w").write(t)
assert s == 200, (s, t)
assert json.loads(t).get("status") == "success", t
print("trigger response:", t)
PY
test -s "$OUT/resp.json"
echo "ORACLE PASS"
