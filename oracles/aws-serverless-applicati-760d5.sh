set -e
source /work/env.sh
cd /work/serverless-application-model
export AWS_DEFAULT_REGION=us-east-1 AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy
D=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $D/template.yaml <<'Y'
Transform: AWS::Serverless-2016-10-31
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: nodejs24.x
      Handler: index.handler
      InlineCode: |
        exports.handler = async (event) => {
          console.log(event);
        }
Y
timeout 600 python bin/sam-translate.py translate --template-file=$D/template.yaml --output-template=$D/out.json
test -s $D/out.json
python - $D/out.json <<'P'
import json,sys
r=json.load(open(sys.argv[1]))["Resources"]
f=r["MyFunction"]
assert f["Type"]=="AWS::Lambda::Function", f
assert f["Properties"]["Handler"]=="index.handler"
assert "console.log(event)" in f["Properties"]["Code"]["ZipFile"]
assert r["MyFunctionRole"]["Type"]=="AWS::IAM::Role"
print("checked", list(r))
P
echo "ORACLE PASS"
