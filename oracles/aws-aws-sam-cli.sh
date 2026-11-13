set -e
source /work/env.sh
cd /work/aws-sam-cli
O=$(mktemp -d /tmp/oracle.XXXXXX)
cd $O
sam --version | grep -i "SAM CLI"
PY=$(python3 -c 'import sys;print("python%d.%d"%sys.version_info[:2])')
timeout 600 sam init --no-interactive --name myapp --runtime $PY --app-template hello-world --package-type Zip --no-tracing --no-application-insights --no-input >init.log 2>&1 || { cat init.log; exit 1; }
cd myapp
test -f template.yaml
grep -q "AWS::Serverless::Function" template.yaml
timeout 900 sam build >build.log 2>&1 || { cat build.log; exit 1; }
test -f .aws-sam/build/template.yaml
find .aws-sam/build -name 'app.py' | grep -q .
grep -q "HelloWorldFunction" .aws-sam/build/template.yaml
echo ORACLE PASS
