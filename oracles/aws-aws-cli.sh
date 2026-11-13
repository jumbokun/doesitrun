set -e
source /work/env.sh
cd /work/aws-cli
O=$(mktemp -d /tmp/oracle.XXXXXX)
export AWS_CONFIG_FILE=$O/config AWS_SHARED_CREDENTIALS_FILE=$O/creds
export AWS_PAGER=""
timeout 120 aws --version | tee $O/ver.txt
grep -q 'aws-cli/' $O/ver.txt
timeout 120 aws configure set region eu-west-1
timeout 120 aws configure set output json
[ "$(timeout 120 aws configure get region)" = "eu-west-1" ]
grep -q eu-west-1 $O/config
timeout 120 aws ec2 run-instances --generate-cli-skeleton > $O/skel.json
python3 -I - $O/skel.json <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert "ImageId" in d and "InstanceType" in d and "MaxCount" in d, d.keys()
P
timeout 120 aws s3api put-object --generate-cli-skeleton > $O/s3.json
grep -q '"Bucket"' $O/s3.json
echo ORACLE PASS
