set -e
source /work/env.sh
cd /work/LatentSync
O=$(mktemp -d /tmp/oracle_XXXXXX)
ffmpeg -y -loglevel error -i assets/demo1_video.mp4 -t 1.6 -an -r 25 $O/in.mp4
ffmpeg -y -loglevel error -i assets/demo1_audio.wav -t 1.6 -ar 16000 -ac 1 $O/in.wav
timeout 5400 python -m scripts.inference \
  --unet_config_path configs/unet/stage2_512.yaml \
  --inference_ckpt_path checkpoints/latentsync_unet.pt \
  --inference_steps 5 --guidance_scale 1.5 \
  --video_path $O/in.mp4 --audio_path $O/in.wav \
  --video_out_path $O/out.mp4
test -s $O/out.mp4
SZ=$(stat -c %s $O/out.mp4)
[ "$SZ" -gt 20000 ] || { echo "too small $SZ"; exit 1; }
read W H N A <<<$(python - $O/out.mp4 <<'PY'
import subprocess,sys,json
p=sys.argv[1]
v=json.loads(subprocess.check_output(["ffprobe","-v","error","-select_streams","v:0","-count_frames","-show_entries","stream=width,height,nb_read_frames","-of","json",p]))["streams"][0]
a=subprocess.check_output(["ffprobe","-v","error","-select_streams","a","-show_entries","stream=codec_type","-of","csv=p=0",p]).decode().strip()
print(v["width"],v["height"],v["nb_read_frames"],"1" if a else "0")
PY
)
echo "w=$W h=$H frames=$N audio=$A"
[ "$W" -ge 128 ] && [ "$H" -ge 128 ] && [ "$N" -ge 20 ] && [ "$A" = 1 ]
echo ORACLE PASS
