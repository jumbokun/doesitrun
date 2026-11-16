#!/usr/bin/env bash
# literal: awslabs/amazon-redshift-utils @ c4b4708d0d5068e7653f20c1340df97d4cf2e650
# readme: src/ManifestGenerator/README.md
set -e  # glue strict mode
pip install boto3  # prereq src/ManifestGenerator/README.md:L109 "boto3"
