#!/usr/bin/env bash
# literal: awslabs/aws-support-tools @ 6e0b264d7ac7e3019d05c21b4365636f86779810
# readme: README.md
set -e  # glue strict mode
# prereq EBS/VolumeLimitCalculator/Readme.md:L5 "install bc" (the root README table links this Readme)
apt-get update  # prereq EBS/VolumeLimitCalculator/Readme.md:L5 "install bc"
apt-get install bc  # EBS/VolumeLimitCalculator/Readme.md:L10
