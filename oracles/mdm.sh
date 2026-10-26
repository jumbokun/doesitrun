# Pass: README 'Generate a single prompt' with a HumanML3D text-to-motion checkpoint under ./save
# writes results.npy and the stick-figure mp4 on GPU 0.
set -e
source /work/env.sh
cd /work/motion-diffusion-model
ckpt=$(ls save/humanml*/model*.pt 2>/dev/null | head -1)
test -n "$ckpt" || { echo "ORACLE: no humanml checkpoint under save/"; exit 1; }
echo "ORACLE: ckpt=$ckpt"
rm -rf /tmp/oracle_mdm
timeout 1800 python -m sample.generate --model_path "$ckpt" --device 0 --output_dir /tmp/oracle_mdm \
  --text_prompt "the person walked forward and is picking up his toolbox."
test -s /tmp/oracle_mdm/results.npy || { echo "ORACLE: no results.npy"; exit 1; }
ls /tmp/oracle_mdm/*.mp4 >/dev/null 2>&1 || { echo "ORACLE: no mp4"; exit 1; }
ls -la /tmp/oracle_mdm
echo "ORACLE PASS"
