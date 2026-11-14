# ManifestGenerator setup notes
- Following the README worked: `pip install -r requirements.txt` (boto3 1.34.145 etc.) and then `./manifestgen.py --csv ...` produced OUTFILE-000..003.json. Zero-size rows are dropped, and the entries were split evenly across the files. No AWS credentials or region were needed in CSV mode.
- The README doesn't say how to install the dependencies, so I put them in a uv venv at /work/venv. env.sh activates it and adds the script's directory to PATH.
- I did not patch any code.
