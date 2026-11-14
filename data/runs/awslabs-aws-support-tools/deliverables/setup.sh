#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends bc
if [ ! -d /work/aws-support-tools/.git ]; then
  git clone --depth 1 https://github.com/awslabs/aws-support-tools /work/aws-support-tools
fi
chmod +x /work/aws-support-tools/EBS/VolumeLimitCalculator/volume_Limit_calculator.sh
