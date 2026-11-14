#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
if [ ! -d aws-support-tools/.git ]; then
  git clone https://github.com/awslabs/aws-support-tools /work/aws-support-tools
fi
git -C /work/aws-support-tools checkout -q 6e0b264d7ac7e3019d05c21b4365636f86779810 || true
apt-get update -qq
apt-get install -y -qq bc
chmod +x /work/aws-support-tools/EBS/VolumeLimitCalculator/volume_Limit_calculator.sh
