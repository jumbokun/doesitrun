set -e
set -o pipefail
source /work/env.sh
cd /work/Protenix
OUT=$(mktemp -d /tmp/protenix_oracle.XXXXXX)
cat > $OUT/in.json <<'J'
[{"name":"ubq","covalent_bonds":[],"sequences":[{"proteinChain":{"count":1,"sequence":"MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG","modifications":[]}}]}]
J
# v2: pass the documented CPU-usable kernel choice (--trimul_kernel/--triatt_kernel torch: inference_demo.sh header,
# runner/batch_inference.py:628-641, docs/training_inference_instructions.md:111). v1 omitted them, so a docs-following
# CPU install could only pass by patching the repo's kernel defaults (cuequivariance).
# Flags -c/-p/-e/-d/-s/--use_msa are documented in inference_demo.sh and docs/training_inference_instructions.md:101-110.
timeout 3000 protenix pred -i $OUT/in.json -o $OUT/out -n protenix_base_default_v1.0.0 --use_msa false \
  -d fp32 -c 4 -p 20 -e 1 -s 101 --trimul_kernel torch --triatt_kernel torch 2>&1 | tee $OUT/log.txt | tail -30
CIF=$(find $OUT/out -name '*_sample_0.cif' | head -1)
[ -n "$CIF" ] || CIF=$(find $OUT/out -name '*.cif' | head -1)
test -n "$CIF" || { echo "no cif"; exit 1; }
grep -q '^data_' "$CIF"
CONF=$(find $OUT/out -name '*summary_confidence_sample_*.json' | head -1)   # runner/dumper.py:267
test -n "$CONF" || { echo "no confidence json"; exit 1; }
python - "$CIF" "$CONF" <<'PY'
import sys, json, shlex, math
cif, conf = sys.argv[1], sys.argv[2]
fields, rows = [], []
for line in open(cif):
    s = line.strip()
    if s.startswith("_atom_site."):
        fields.append(s.split()[0][len("_atom_site."):])
    elif fields and (s.startswith("ATOM") or s.startswith("HETATM")):
        rows.append(shlex.split(s))
assert fields and rows, "no _atom_site loop"
ix = {f: i for i, f in enumerate(fields)}
name_key = "label_atom_id" if "label_atom_id" in ix else "auth_atom_id"
print("atom rows:", len(rows))
# ubiquitin (76 aa) has 602 heavy atoms (NOTES of the passing run report 602)
assert len(rows) > 500, "too few atoms"
ca = [[float(r[ix["Cartn_x"]]), float(r[ix["Cartn_y"]]), float(r[ix["Cartn_z"]])] for r in rows if r[ix[name_key]] == "CA"]
print("CA atoms:", len(ca))
assert len(ca) == 76, len(ca)
d = [math.dist(a, b) for a, b in zip(ca, ca[1:])]
ok = sum(1 for x in d if 3.0 <= x <= 4.5)
print("consecutive CA-CA distances: min %.2f max %.2f, %d/%d in [3.0,4.5]" % (min(d), max(d), ok, len(d)))
# a real backbone has CA-CA ~3.8 A; a broken model/diffusion gives a cloud of atoms
assert ok >= 0.9 * len(d), "backbone geometry implausible"
c = json.load(open(conf))
p = c["plddt"]                                    # protenix/model/sample_confidence.py:112 (0-100 scale)
p = float(p[0] if isinstance(p, list) else p)
print("plddt:", p, "ptm:", c.get("ptm"))
assert math.isfinite(p) and p > 50, "pLDDT too low for ubiquitin"
PY
echo ORACLE PASS
