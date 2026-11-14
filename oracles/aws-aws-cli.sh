set -e
source /work/env.sh
cd /work/aws-cli
O=$(mktemp -d /tmp/oracle.XXXXXX)
export AWS_CONFIG_FILE=$O/config AWS_SHARED_CREDENTIALS_FILE=$O/creds
export AWS_PAGER="" AWS_EC2_METADATA_DISABLED=true
unset AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# 1. version. README.rst "CLI Dev Version": a source install prints `source` in `aws --version`.
timeout 120 aws --version | tee $O/ver.txt
grep -q '^aws-cli/2\.' $O/ver.txt
grep -q 'source' $O/ver.txt

# 2. configure set/get round trip (README.rst "Getting Started": aws configure, AWS_CONFIG_FILE)
timeout 120 aws configure set region eu-west-1
timeout 120 aws configure set output json
timeout 120 aws configure set aws_access_key_id AKIDEXAMPLEORACLE
timeout 120 aws configure set aws_secret_access_key oracle-secret-not-real
[ "$(timeout 120 aws configure get region)" = "eu-west-1" ]
grep -q eu-west-1 $O/config
grep -q AKIDEXAMPLEORACLE $O/creds

# 3. skeletons from the service models
timeout 120 aws ec2 run-instances --generate-cli-skeleton > $O/skel.json
python3 -I - $O/skel.json <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert "ImageId" in d and "InstanceType" in d and "MaxCount" in d, d.keys()
P
timeout 120 aws s3api put-object --generate-cli-skeleton > $O/s3.json
grep -q '"Bucket"' $O/s3.json

# 4. a real service call: request serialisation, SigV4 signing, response parsing and --query,
#    against a local stub via the documented --endpoint-url global option (no AWS account).
#    DynamoDB uses the JSON 1.0 protocol with target prefix DynamoDB_20120810
#    (awscli/botocore/data/dynamodb/2012-08-10/service-2.json metadata).
cat > $O/stub.py <<'P'
import http.server, json, sys
log = sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        with open(log, "a") as f:
            f.write(json.dumps({"target": self.headers.get("X-Amz-Target"),
                                "auth": self.headers.get("Authorization"),
                                "body": body.decode("utf-8", "replace")}) + "\n")
        out = json.dumps({"TableNames": ["alpha-table", "beta-table"]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/x-amz-json-1.0")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)
    def log_message(self, *a): pass
s = http.server.HTTPServer(("127.0.0.1", 0), H)
open(sys.argv[2], "w").write(str(s.server_address[1]))
s.serve_forever()
P
python3 -I $O/stub.py $O/requests.log $O/port &
STUB=$!
trap 'kill $STUB 2>/dev/null || true' EXIT
for i in $(seq 50); do [ -s $O/port ] && break; sleep 0.2; done
PORT=$(cat $O/port)
timeout 120 aws dynamodb list-tables --endpoint-url http://127.0.0.1:$PORT --output json > $O/list.json
timeout 120 aws dynamodb list-tables --endpoint-url http://127.0.0.1:$PORT --query 'TableNames[1]' --output text > $O/q.txt
python3 -I - $O/list.json $O/q.txt $O/requests.log <<'P'
import json, sys
d = json.load(open(sys.argv[1]))
assert d == {"TableNames": ["alpha-table", "beta-table"]}, d
assert open(sys.argv[2]).read().strip() == "beta-table"
reqs = [json.loads(l) for l in open(sys.argv[3]) if l.strip()]
assert reqs, "the CLI never reached the endpoint"
r = reqs[0]
assert r["target"] == "DynamoDB_20120810.ListTables", r
assert (r["auth"] or "").startswith("AWS4-HMAC-SHA256 Credential=AKIDEXAMPLEORACLE/"), r["auth"]
assert "/eu-west-1/dynamodb/aws4_request" in r["auth"], r["auth"]
print("service call ok")
P
echo ORACLE PASS
