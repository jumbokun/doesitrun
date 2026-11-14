#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d serverless-application-model/.git ] || git clone https://github.com/aws/serverless-application-model /work/serverless-application-model
cd /work/serverless-application-model
python3 -m venv .venv
. .venv/bin/activate
make init
cat > /work/template.yaml <<'YAML'
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
YAML
export AWS_DEFAULT_REGION=us-east-1
python bin/sam-translate.py translate --template-file=/work/template.yaml --output-template=/work/out.json
