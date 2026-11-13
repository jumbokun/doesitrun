set -e
source /work/env.sh
cd /work/aws-support-tools
out=$(mktemp -d /tmp/oracle.XXXXXX)
cd EBS/VolumeLimitCalculator
S=./volume_Limit_calculator.sh
printf 'gp3\n100\n4000\n250\n' | timeout 60 bash $S > $out/gp3.txt
printf 'io2\n10000\n' | timeout 60 bash $S > $out/io2.txt
printf 'st1\n1000\n' | timeout 60 bash $S > $out/st1.txt
printf 'io1\n10000\n' | timeout 60 bash $S > $out/io1.txt
grep -q "IOPS for your volume are 4000" $out/gp3.txt
grep -q "throughput is 250 MiB/s" $out/gp3.txt
grep -q "IOPS are equal to the provisioned IOPS i.e 10000" $out/io2.txt
grep -q "throughput is 2500.00 MiB/s" $out/io2.txt
grep -q "IOPS are equal to the provisioned IOPS i.e 10000" $out/io1.txt
grep -q "throughput is 2500.00 MiB/s" $out/io1.txt
grep -q "burst balance is 244.14 MiB/s" $out/st1.txt
grep -q "will be 39.06 MiB/s" $out/st1.txt
echo "ORACLE PASS"
