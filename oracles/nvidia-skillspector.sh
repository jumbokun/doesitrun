set -e
source /work/env.sh
cd /work/SkillSpector
O=$(mktemp -d /tmp/oracle.XXXXXX)
# README "Exit codes" (README.md:815-823): 0 = completed with risk_score <= 50, 1 = completed with
# risk_score > 50, 2 = error. The malicious fixture scores high (tests/integration/test_graph_scanner.py:105
# asserts risk_score >= 50), so exit 1 is a successful scan; only 2 (or a timeout) is a failure.
set +e
timeout 900 skillspector scan tests/fixtures/malicious_skill --no-llm --format json --output $O/mal.json > $O/mal.log 2>&1
rc_mal=$?
timeout 900 skillspector scan tests/fixtures/safe_skill --no-llm --format json --output $O/safe.json > $O/safe.log 2>&1
rc_safe=$?
timeout 900 skillspector scan tests/fixtures/malicious_skill --no-llm --format markdown --output $O/mal.md > $O/md.log 2>&1
rc_md=$?
set -e
echo "rc malicious=$rc_mal safe=$rc_safe markdown=$rc_md"
tail -5 $O/mal.log $O/safe.log $O/md.log
case "$rc_mal" in 0|1) ;; *) echo "malicious scan errored"; exit 1;; esac
case "$rc_md" in 0|1) ;; *) echo "markdown scan errored"; exit 1;; esac
[ "$rc_safe" = 0 ] || { echo "safe scan should exit 0"; exit 1; }
python3 -I - "$O" "$rc_mal" <<'PY'
import json, sys
o, rc_mal = sys.argv[1], int(sys.argv[2])
m = json.load(open(o + "/mal.json")); s = json.load(open(o + "/safe.json"))
# Top-level shape documented in README.md:835-860: skill, risk_assessment, components, issues, metadata.
for d in (m, s):
    for k in ("skill", "risk_assessment", "components", "issues", "metadata"):
        assert k in d, ("missing key", k, list(d))
    assert d["metadata"].get("llm_requested") is False, d["metadata"]  # --no-llm, README.md:835
    assert d["risk_assessment"]["recommendation"] in ("SAFE", "CAUTION", "DO_NOT_INSTALL")
mi, si = m["issues"], s["issues"]
ms = m["risk_assessment"]["score"]
print("malicious issues", len(mi), "score", ms, m["risk_assessment"]["recommendation"],
      "| safe issues", len(si), "score", s["risk_assessment"]["score"])
assert len(mi) >= 1 and len(mi) > len(si), (len(mi), len(si))
assert ms >= 50, ms  # tests/integration/test_graph_scanner.py:105
assert m["risk_assessment"]["recommendation"] != "SAFE"
assert (ms > 50) == (rc_mal == 1), (ms, rc_mal)  # README exit-code contract
# helper.py iterates os.environ.items() and posts secrets: matched by the E2 static pattern
# (src/skillspector/nodes/analyzers/static_patterns_data_exfiltration.py:75).
files = [str((i.get("location") or {}).get("file", "")) for i in mi]
assert any(f.endswith("helper.py") for f in files), files
assert m["skill"].get("name") == "chef-assistant", m["skill"]  # manifest name (SKILL.md:2), report.py:1525
print("json ok")
PY
# Markdown report headings: src/skillspector/nodes/report.py:1677 and :1734.
grep -q "^# SkillSpector Security Report" $O/mal.md
grep -Eq "^## Issues \([1-9][0-9]*\)" $O/mal.md
echo "ORACLE PASS"
