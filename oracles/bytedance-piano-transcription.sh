set -e
source /work/env.sh
cd /work/piano_transcription
OUT=$(mktemp -d /tmp/oracle_XXXX)
cat > $OUT/run.py <<'P'
import sys
from piano_transcription_inference import PianoTranscription, sample_rate, load_audio
(audio, _) = load_audio('resources/cut_liszt.mp3', sr=sample_rate, mono=True)
t = PianoTranscription(device='cpu')
t.transcribe(audio, sys.argv[1])
P
timeout 3000 python $OUT/run.py $OUT/cut_liszt.mid
python - $OUT/cut_liszt.mid <<'P'
import sys, os
p = sys.argv[1]
assert os.path.getsize(p) > 1000, "midi too small"
d = open(p,'rb').read()
assert d[:4] == b'MThd', "not a MIDI file"
try:
    import pretty_midi
    m = pretty_midi.PrettyMIDI(p)
    n = sum(len(i.notes) for i in m.instruments)
except ImportError:
    import mido
    n = sum(1 for t in mido.MidiFile(p).tracks for x in t if x.type=='note_on' and x.velocity>0)
print("notes", n)
assert n > 50, "too few notes"
P
echo "ORACLE PASS"
