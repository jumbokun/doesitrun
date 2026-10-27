set -e
source /work/env.sh
cd /work/GiantMIDI-Piano
OUT=$(mktemp -d /tmp/gmp.XXXXXX)
mkdir -p $OUT/mp3s $OUT/midis $OUT/ws
# the first catalogue entry flagged giant_midi_piano==1
NAME=$(python3 -I - <<'PY'
import csv
r=list(csv.DictReader(open('resources/full_music_pieces_youtube_similarity_pianosoloprob_split.csv',encoding='utf-8'),delimiter='\t'))
assert r[0]['giant_midi_piano']=='1'
print(r[0]['audio_name'])
PY
)
# synthesize ~12 s of piano-like notes (decaying harmonics), encode as real mp3
python3 -I - "$OUT/syn.wav" <<'PY'
import sys, wave, numpy as np
sr=16000
seq=[60,64,67,72,67,64,62,65,69,74,69,65]
y=np.zeros(sr*13)
for i,m in enumerate(seq):
    f=440*2**((m-69)/12); t=np.arange(int(sr*1.5))/sr
    s=sum((0.5**k)*np.sin(2*np.pi*f*(k+1)*t) for k in range(4))*np.exp(-2.5*t)
    a=int(i*sr); y[a:a+len(s)]+=s[:len(y)-a]
y=y/np.abs(y).max()*0.8
w=wave.open(sys.argv[1],'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
w.writeframes((y*32767).astype('<i2').tobytes()); w.close()
PY
ffmpeg -loglevel error -y -i $OUT/syn.wav -codec:a libmp3lame "$OUT/mp3s/$NAME.mp3"
timeout 3000 python3 audios_to_midis.py transcribe_piano --workspace=$OUT/ws --mp3s_dir=$OUT/mp3s --midis_dir=$OUT/midis --begin_index=0 --end_index=1 2>&1 | tee $OUT/log.txt
MID="$OUT/midis/$NAME.mid"
test -f "$MID" || { echo "missing midi"; exit 1; }
python3 -I - "$MID" <<'PY'
import sys, os
p=sys.argv[1]; b=open(p,'rb').read()
assert b[:4]==b'MThd', 'not a MIDI file'
assert len(b)>60, 'midi too small'
try:
    import mido
    m=mido.MidiFile(p)
    n=sum(1 for t in m.tracks for e in t if e.type=='note_on' and e.velocity>0)
    print('notes',n); assert n>=3, 'too few notes'
except ImportError:
    print('mido unavailable; size',len(b))
PY
grep -q "Failed for this audio" $OUT/log.txt && { echo "transcription failed"; exit 1; }
echo "ORACLE PASS"
