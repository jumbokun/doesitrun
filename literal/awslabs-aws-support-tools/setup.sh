#!/usr/bin/env bash
# literal: awslabs/aws-support-tools @ 6e0b264d7ac7e3019d05c21b4365636f86779810
# readme: README.md
set -e  # glue strict mode
# mismatch README gives no install steps (README.md lists EBS/VolumeLimitCalculator only in a table; the test needs the bc package, which no README mentions)
