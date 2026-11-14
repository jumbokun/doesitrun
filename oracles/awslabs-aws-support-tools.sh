set -e
source /work/env.sh
cd /work/aws-support-tools
out=$(mktemp -d /tmp/oracle.XXXXXX)
cd EBS/VolumeLimitCalculator
S=./volume_Limit_calculator.sh
# Answers are read from stdin in the order of the prompts (volume_Limit_calculator.sh:293-336).
printf 'gp3\n100\n4000\n250\n' | timeout 60 bash $S > $out/gp3.txt
printf 'gp3\n100\n\n\n'        | timeout 60 bash $S > $out/gp3def.txt
printf 'io2\n10000\n'          | timeout 60 bash $S > $out/io2.txt
printf 'io1\n10000\n'          | timeout 60 bash $S > $out/io1.txt
printf 'st1\n1000\n'           | timeout 60 bash $S > $out/st1.txt
cat $out/*.txt
# gp3: provisioned values echoed back (lines 157-160); blank answers default to 3000 / 125 (lines 117-139)
grep -Eq "IOPS for your volume are 4000$" $out/gp3.txt
grep -Eq "throughput is 250 MiB/s$" $out/gp3.txt
grep -Eq "IOPS for your volume are 3000$" $out/gp3def.txt
grep -Eq "throughput is 125 MiB/s$" $out/gp3def.txt
# io2: min(4000, 10000*256/1024) with bc scale=2 -> 2500.00 (lines 206-212)
grep -Eq "IOPS are equal to the provisioned IOPS i.e 10000$" $out/io2.txt
grep -Eq "throughput is 2500.00 MiB/s$" $out/io2.txt
# io1 <= 32000 IOPS is capped at 500 MiB/s: min(500, 2500.00) -> 500 (lines 174-187)
grep -Eq "IOPS are equal to the provisioned IOPS i.e 10000$" $out/io1.txt
grep -Eq "throughput is 500 MiB/s$" $out/io1.txt
# st1 1000 GiB: burst 1000*250/1024 = 244.14, baseline 1000*40/1024 = 39.06 (lines 238-252); needs bc
grep -q "burst balance is 244.14 MiB/s" $out/st1.txt
grep -q "will be 39.06 MiB/s" $out/st1.txt
echo "ORACLE PASS"
