set -e
source /work/env.sh
cd /work/amazon-redshift-utils
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# CSV with header file_name,file_size (src/ManifestGenerator/README.md "CSV Input")
python3 - "$OUT/in.csv" <<'PY'
import sys
with open(sys.argv[1], 'w') as f:
    f.write("file_name,file_size\n")
    for i in range(1, 102):
        f.write(f"s3://mybucket/mytbl/file{i}.parquet,{1000+i*7}\n")
    # size 0 rows are skipped: manifestgen.py:38 `if size > 0`
    f.write("s3://mybucket/mytbl/empty,0\n")
PY
cd src/ManifestGenerator
# The script is committed without +x; README shows ./manifestgen.py, run it via python3 so the oracle
# does not depend on the probe having chmod'ed the file.
timeout 300 python3 ./manifestgen.py --prefix="$OUT/OUTFILE" --num=4 --csv --input-file="$OUT/in.csv" 2>"$OUT/log.txt"
cat "$OUT/log.txt"
# progress lines go to stderr: manifestgen.py:147,156
grep -q "Generating batch 3" "$OUT/log.txt"
grep -q "Writing manifest to file" "$OUT/log.txt"
python3 - "$OUT" <<'PY'
import sys, json, glob, os
out = sys.argv[1]
fs = sorted(glob.glob(os.path.join(out, "OUTFILE-*.json")))
# names: f'{args.prefix}-{i:03d}.json' (manifestgen.py:150)
assert [os.path.basename(f) for f in fs] == ["OUTFILE-%03d.json" % i for i in range(4)], fs
urls, sizes, counts = [], [], []
for f in fs:
    m = json.load(open(f))
    counts.append(len(m["entries"]))
    for e in m["entries"]:
        # entry shape: manifestgen.py:21-25
        assert e["mandatory"] is True, e
        urls.append(e["url"]); sizes.append(e["meta"]["content_length"])
# 101 non-empty entries split by iter_batch (manifestgen.py:69-82): remainder goes to the first batches
assert counts == [26, 25, 25, 25], counts
assert len(urls) == 101 and len(set(urls)) == 101, len(urls)
expected = {f"s3://mybucket/mytbl/file{i}.parquet": 1000 + i * 7 for i in range(1, 102)}
assert dict(zip(urls, sizes)) == expected
assert not any(u.endswith("empty") for u in urls)
print("manifests ok", counts)
PY
echo "ORACLE PASS"
