set -e
source /work/env.sh
cd /work/Protenix
OUT=$(mktemp -d /tmp/protenix_oracle.XXXXXX)
cat > $OUT/in.json <<'J'
[{"name":"ubq","covalent_bonds":[],"sequences":[{"proteinChain":{"count":1,"sequence":"MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG","modifications":[]}}]}]
J
timeout 6000 protenix pred -i $OUT/in.json -o $OUT/out -n protenix_base_default_v1.0.0 --use_msa false -d fp32 -c 4 -p 20 -e 1 -s 101 2>&1 | tail -30
CIF=$(find $OUT/out -name '*.cif' | head -1)
test -n "$CIF" || { echo "no cif"; exit 1; }
test $(stat -c %s "$CIF") -gt 20000 || { echo "cif too small"; exit 1; }
N=$(grep -c -E '^ATOM' "$CIF")
echo "ATOM lines: $N"
test $N -gt 400
grep -q '^data_' "$CIF"
find $OUT/out -name '*summary_confidence*.json' | grep -q . || { echo "no confidence json"; exit 1; }
echo ORACLE PASS
