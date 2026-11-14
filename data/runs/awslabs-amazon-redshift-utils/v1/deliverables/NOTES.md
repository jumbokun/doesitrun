# ManifestGenerator setup notes
- README only says "requires Python 3.12 and boto3 installed"; it doesn't explain how to install it. I made a uv venv (/work/venv, Python 3.12) and ran `pip install -r requirements.txt` in it. That worked with no changes to any pins.
- `manifestgen.py` is committed with mode 100644, not executable, so `./manifestgen.py` as written in the README fails with "Permission denied". setup.sh runs `chmod +x`.
- env.sh activates the venv and adds the ManifestGenerator dir to PATH.
- CSV mode works without AWS credentials or a region set (it only creates the boto3 client and never calls it). I tested with 23 rows (some size 0) and --num=4: got 4 files covering all 18 non-empty entries, each exactly once, with correct sizes.
