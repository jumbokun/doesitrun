# Pass: README image demo on GPU (--device 0) detects horses and writes the annotated image.
set -e
source /work/env.sh
cd /work/yolov7
rm -rf /tmp/oracle_y7
timeout 1200 python detect.py --weights yolov7.pt --conf 0.25 --img-size 640 --source inference/images/horses.jpg \
  --device 0 --project /tmp/oracle_y7 --name exp 2>&1 | tee /tmp/y7.log
grep -qE "[0-9]+ horses?" /tmp/y7.log || { echo "ORACLE: no horse detections in log"; exit 1; }
test -s /tmp/oracle_y7/exp/horses.jpg || { echo "ORACLE: no output image"; exit 1; }
echo "ORACLE PASS"
