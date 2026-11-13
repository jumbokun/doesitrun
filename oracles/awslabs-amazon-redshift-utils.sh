set -e
source /work/env.sh
cd /work/amazon-redshift-utils
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
python3 - "$OUT/in.csv" <<'PY'
import sys
with open(sys.argv[1],'w') as f:
    f.write("file_name,file_size\n")
    for i in range(1,102):
        f.write(f"s3://mybucket/mytbl/file{i}.parquet,{1000+i*7}\n")
    f.write("s3://mybucket/mytbl/empty,0\n")
PY
cd src/ManifestGenerator
timeout 300 python3 ./manifestgen.py --prefix="$OUT/OUTFILE" --num=4 --csv --input-file="$OUT/in.csv" 2>"$OUT/log.txt"
cat "$OUT/log.txt"
grep -q "Generating batch 3" "$OUT/log.txt"
python3 - "$OUT" <<'PY'
import sys,json,glob
out=sys.argv[1]
fs=sorted(glob.glob(out+"/OUTFILE-*.json"))
assert [f[-8:] for f in fs]==["-000.json","-001.json","-002.json","-003.json"], fs
urls=[];sizes=[]
for f in fs:
    m=json.load(open(f)); assert len(m["entries"])>=25
    for e in m["entries"]:
        assert e["mandatory"] is True
        urls.append(e["url"]); sizes.append(e["meta"]["content_length"])
assert len(urls)==101 and len(set(urls))==101, len(urls)
assert sum(sizes)==sum(1000+i*7 for i in range(1,102))
assert not any(u.endswith("empty") for u in urls)
PY
echo "ORACLE PASS"
