# Pass: README CPU install; `earshot doctor --load` reports both models loaded with no problems; then the README's
# core listening commands work on a sound rendered from the shipped bank: `describe` returns calibrated tags and
# AudioSet labels, `match` returns a verdict and prefers the right description over unrelated alternatives.
# v2: v1 only required `doctor --load` to exit 0, but doctor always exits 0 (earshot/doctor.py:185
# `emit(...) and 0`; emit returns the dict, so the lambda returns 0) and a failed model load is caught and only listed
# under "problems" (doctor.py:161-165). It also never ran an actual listening command.
set -e
source /work/env.sh
cd /work/earshot
T=$(mktemp -d)

# 1. install check: both models load (doctor.py:85-104 records *_revision only after a successful load)
timeout 1800 python -m earshot doctor --load --json > "$T/doctor.json"
python3 - "$T/doctor.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
print("ORACLE: doctor problems", r.get("problems"), "clap", r.get("clap_revision"), "ast", r.get("ast_revision"))
assert r["problems"] == [], r["problems"]
assert r.get("clap_revision") and r.get("ast_revision"), "models did not load"
PY

# 2. input: a bank sound rendered by id, no models needed (README:218-225 `earshot sfx render whoosh_fast/crisp -o w.wav`)
timeout 600 python -m earshot sfx render whoosh_fast/crisp -o "$T/w.wav"
test -s "$T/w.wav" || { echo "ORACLE: sfx render wrote no WAV"; exit 1; }

# 3. README "What it does": describe FILE (tags with z, AudioSet labels, measurements) — describe.py:160-245
timeout 1200 python -m earshot describe "$T/w.wav" --json > "$T/describe.json"
# 4. README: match FILE QUERY --alts ... (cosine, z, verdict) — match.py:91-134
timeout 1200 python -m earshot match "$T/w.wav" "a fast air whoosh" --alts "a dog barking" "a person talking" --json > "$T/match.json"
python3 - "$T/describe.json" "$T/match.json" <<'PY'
import json, math, sys
d = json.load(open(sys.argv[1])); m = json.load(open(sys.argv[2]))
print("ORACLE: describe summary:", d.get("summary", "")[:300])
print("ORACLE: match summary:", m.get("summary", "")[:300])
assert "error" not in d and "error" not in m, (d.get("error"), m.get("error"))
assert d["duration"] > 0 and d["measurements"], d.get("measurements")
assert len(d["top_tags"]) >= 1 and all(t["term"] and math.isfinite(t["z"]) for t in d["top_tags"]), d["top_tags"]
assert len(d["audioset"]) >= 1 and d["audioset"][0]["label"], d["audioset"]
assert m["verdict"] in {"strong", "plausible", "weak", "no match"}, m["verdict"]   # match.py:33 + VERDICT_EVIDENCE keys
assert math.isfinite(m["z"]) and -1.0 <= m["cosine"] <= 1.0
# forced choice against two unrelated sounds (README:40 --alts); not pinned to a number, only the winner
alts = {a["query"]: a["p"] for a in m["alts"]}
print("ORACLE: p_vs_alts", m["p_vs_alts"], alts)
assert m["p_vs_alts"] > max(alts.values()), (m["p_vs_alts"], alts)
PY
echo "ORACLE PASS"
