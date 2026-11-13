set -e
source /work/env.sh
cd /work/agents-cli
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1500 agents-cli create caveman-agent -y --skip-checks -o "$OUT" > "$OUT/create.log" 2>&1 || { cat "$OUT/create.log"; echo create failed; exit 1; }
P=$(find "$OUT" -maxdepth 2 -name pyproject.toml -printf '%h\n' | head -1)
[ -n "$P" ] || { echo "no project"; exit 1; }
test -s "$P/pyproject.toml"
test -s "$P/app/agent.py"
grep -q "root_agent" "$P/app/agent.py"
grep -qi "caveman" "$P/pyproject.toml"
python3 -I -c "import ast,sys;ast.parse(open(sys.argv[1]).read())" "$P/app/agent.py"
timeout 600 agents-cli info > "$OUT/info.log" 2>&1 || true
timeout 300 agents-cli --help 2>&1 | grep -q "create"
echo ORACLE PASS
