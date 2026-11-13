set -e
source /work/env.sh
cd /work/clusterfuzz
timeout 1500 bash /work/run.sh
out=$(mktemp -d /tmp/oracle.XXXX)
code=$(timeout 120 curl -sL -o $out/index.html -w '%{http_code}' http://localhost:9000/)
echo "http $code"
[ "$code" = 200 ]
[ $(wc -c < $out/index.html) -gt 500 ]
grep -qi clusterfuzz $out/index.html
code2=$(timeout 120 curl -sL -o $out/login.html -w '%{http_code}' http://localhost:9000/login)
[ "$code2" = 200 ]
echo "ORACLE PASS"
