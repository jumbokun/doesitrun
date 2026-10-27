# GiantMIDI-Piano – CPU transcription setup notes

What broke / was missing when following the README (`pip install torch` + `pip install -r requirements.txt`):

- **librosa was not listed**, and the latest librosa (1.0 / 0.10.x) breaks `piano_transcription_inference.load_audio`
  (`AttributeError: No librosa.core attribute audio`). I pinned `librosa==0.9.2`.
- **audioread was not installed.** `piano_transcription_inference` imports it, but newer librosa no longer pulls it in. I installed it explicitly, along with `mido`.
- **ffmpeg** (a system package) is needed to decode mp3s through audioread. The README doesn't mention it.
- The library fetches its checkpoint with `wget`, which isn't in the base image. setup.sh downloads the checkpoint
  from Zenodo with curl to `~/piano_transcription_inference_data/` and also installs wget as a fallback.
- `import dataset` (called by audios_to_midis.py) downloads nltk data at import time. setup.sh runs that import once up front.
- PyTorch is the CPU wheel from download.pytorch.org. Python 3.12 venv made with uv. `env.sh` sets `PYTHONWARNINGS=ignore`
  to hide the many SyntaxWarnings from old nltk 3.5 and dataset.py; this only affects output, not behaviour.
- Note: the README uses `--begin_ind`, but the actual argument is `--begin_index`. argparse prefix matching makes it work anyway.
- No repository code was patched. Tested with a synthetic 3 s mp3 named after catalogue entry 0: it produced a .mid file with note_on events.
