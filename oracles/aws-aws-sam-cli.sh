set -e
source /work/env.sh
cd /work/aws-sam-cli
export SAM_CLI_TELEMETRY=0
O=$(mktemp -d /tmp/oracle.XXXXXX)
cd $O
sam --version | grep -i "SAM CLI"
PY=$(python3 -c 'import sys;print("python%d.%d"%sys.version_info[:2])')
# v1 omitted --dependency-manager. In --no-interactive mode with --package-type Zip it is required:
# samcli/commands/init/command.py:45-49 (NON_INTERACTIVE_PARAM_COMBINATIONS) and :119-129
# raise "Missing parameter --dependency-manager".
timeout 600 sam init --no-interactive --name myapp --runtime $PY --dependency-manager pip \
  --app-template hello-world --package-type Zip --no-tracing --no-application-insights --no-input \
  >init.log 2>&1 || { cat init.log; exit 1; }
cd myapp
test -f template.yaml
grep -q "AWS::Serverless::Function" template.yaml
grep -q "HelloWorldFunction" template.yaml
find . -path ./.aws-sam -prune -o -name app.py -print | grep -q .
timeout 900 sam build >build.log 2>&1 || { cat build.log; exit 1; }
test -f .aws-sam/build/template.yaml
grep -q "HelloWorldFunction" .aws-sam/build/template.yaml
test -f .aws-sam/build/HelloWorldFunction/app.py
# the hello-world function code must be the generated handler, copied into the build dir
grep -q "def lambda_handler" .aws-sam/build/HelloWorldFunction/app.py
echo ORACLE PASS
