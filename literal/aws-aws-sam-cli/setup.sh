#!/usr/bin/env bash
# literal: aws/aws-sam-cli @ 0cfc34edec8e9068b216fbf39f193ed01d0eb13b
# readme: README.md (L44 sends the reader to the AWS install page) + https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
set -e  # glue strict mode
cd /tmp  # glue a scratch directory for the installer
curl -fsSL -o aws-sam-cli-linux-x86_64.zip https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip  # link https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation  # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
sudo ./sam-installation/install  # https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
