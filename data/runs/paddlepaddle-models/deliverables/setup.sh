#!/usr/bin/env bash
# Reproduces the paddlecv CPU setup from scratch (run as root).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
# libsndfile1 is documented; libgl1/libglib2.0 are needed by opencv-python
apt-get install -y libsndfile1 libgl1 libglib2.0-0t64

cd /work
[ -d models/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/models /work/models

# paddlepaddle 2.3.2 (documented) is no longer on PyPI and baidu mirror returns 403;
# use Python 3.9 + paddlepaddle 2.6.2 (oldest on PyPI) with a known-good pin set.
[ -x /work/venv/bin/python ] || uv venv -p 3.9 /work/venv
. /work/venv/bin/activate

cat > /work/constraints.txt <<'PINS'
absl-py==2.3.1
aiohappyeyeballs==2.6.1
aiohttp==3.13.5
aiosignal==1.4.0
aistudio-sdk==0.3.9
annotated-doc==0.0.5
annotated-types==0.7.0
antlr4-python3-runtime==4.9.3
anyio==4.12.1
astor==0.8.1
asttokens==3.0.2
async-timeout==5.0.1
attrs==26.1.0
audioread==3.1.0
av==15.1.0
babel==2.18.0
bce-python-sdk==0.9.79
blinker==1.9.0
bokeh==3.4.3
boltons==26.2.0
bottleneck==1.5.0
braceexpand==0.1.7
certifi==2026.10.23
cffi==2.0.0
charset-normalizer==3.5.2
click==8.1.8
colorama==0.4.6
coloredlogs==15.0.1
colorlog==6.12.0
contourpy==1.3.0
crc32c==2.9.post0
cycler==0.12.1
datasets==4.5.0
decorator==5.3.1
dill==0.3.4
distance==0.1.3
editdistance==0.8.1
einops==0.8.2
exceptiongroup==1.3.1
executing==2.3.0
faiss-cpu==1.7.1.post2
fastapi==0.128.8
ffmpeg-python==0.2.0
ffmpy==1.0.0
filelock==3.19.1
filterpy==2.0.0
flask==3.1.3
flask-babel==2.0.0
flatbuffers==25.12.19
flatten-dict==0.4.2
fonttools==4.60.2
frozenlist==1.8.0
fsspec==2025.10.0
ftfy==6.3.1
future==1.0.0
g2p-en==2.1.0
g2pm==0.1.2.5
h11==0.16.0
h5py==3.14.0
hf-transfer==0.1.9
hf-xet==1.8.0
httpcore==1.0.9
httpx==0.28.1
huggingface-hub==1.8.0
humanfriendly==10.0
hyperpyyaml==1.2.3
idna==3.20
importlib-metadata==8.7.1
importlib-resources==6.5.2
inflect==7.5.0
intervaltree==3.2.1
ipython==8.18.1
itsdangerous==2.2.0
jedi==0.19.2
jieba==0.42.1
jinja2==3.1.6
joblib==1.5.3
jsonlines==4.0.0
kaldiio==2.18.1
kiwisolver==1.4.7
lazy-loader==0.6
librosa==0.11.0
ligo-segments==1.4.0
llvmlite==0.43.0
loguru==0.8.0
lxml==6.1.3
markdown-it-py==3.0.0
markupsafe==3.0.4
matplotlib==3.9.4
matplotlib-inline==0.2.2
mdurl==0.1.2
mido==1.3.3
ml-dtypes==0.5.4
mock==5.2.0
more-itertools==10.8.0
mpmath==1.3.0
msgpack==1.1.2
multidict==6.7.1
multiprocess==0.70.12.2
nara-wpe==0.0.11
nltk==3.9.2
note-seq==0.0.5
numba==0.60.0
numpy==1.26.4
omegaconf==2.3.1
onnx==1.17.0
onnxoptimizer==0.3.13
onnxruntime==1.19.2
opencc==1.4.2
opencc-python-reimplemented==0.1.7
opencv-contrib-python==4.10.0.84
opencv-python==4.10.0.84
opt-einsum==3.3.0
packaging==26.3
paddle2onnx==2.0.1
paddlefsl==1.1.0
paddlenlp==2.6.1
paddlepaddle==2.6.2
paddlesde==0.2.5
paddleslim==2.4.1
paddlespeech==1.5.0
paddlespeech-feat==0.1.0
pandas==2.3.3
parameterized==0.9.0
parso==0.8.7
pathos==0.2.8
pattern-singleton==1.2.0
pexpect==4.9.0
pillow==11.3.0
pip==26.0.1
platformdirs==4.4.0
polygraphy==0.53.6
pooch==1.9.0
portalocker==3.2.0
pox==0.3.7
ppdiffusers==0.29.0
ppft==1.7.8
praatio==6.2.2
pretty-midi==0.2.11.post0
prettytable==3.16.0
prompt-toolkit==3.0.52
propcache==0.4.1
protobuf==3.20.2
psutil==7.2.2
ptyprocess==0.7.0
pure-eval==0.2.4
pyarrow==21.0.0
pybind11==3.1.0
pyclipper==1.3.0.post6
pycocotools==2.0.11
pycparser==2.23
pycryptodome==4.4.0
pydantic==2.13.5
pydantic-core==2.46.5
pydub==0.25.1
pygments==2.21.0
pyloudnorm==0.2.0
pyparsing==3.3.3
pypinyin==0.55.0
pypinyin-dict==0.9.0
python-dateutil==3.0.0
pytz==2026.6
pyworld==0.3.5
pyyaml==6.0.3
pyzmq==27.3.0
rarfile==4.2
regex==2026.1.15
requests==2.32.5
requests-mock==1.12.1
resampy==0.4.3
rich==15.0.0
ruamel-yaml==0.18.17
ruamel-yaml-clib==0.2.15
sacrebleu==2.6.0
safetensors==0.7.0
scikit-learn==1.6.1
scipy==1.13.1
sentencepiece==0.2.2
seqeval==1.2.2
setuptools==69.5.1
shapely==2.0.7
shellingham==1.5.4
six==1.17.0
sortedcontainers==2.4.0
soundfile==0.13.1
soxr==1.1.0
stack-data==0.6.3
starlette==0.49.3
swig==4.5.1
sympy==1.14.0
tabulate==0.9.0
textgrid==1.6.1
threadpoolctl==3.7.0
timer==0.3.0
tojyutping==3.2.0
tool-helpers==0.1.1
tornado==6.5.10
tqdm==4.70.1
traitlets==5.15.1
trampoline==0.1.2
typeguard==4.5.2
typer==0.23.2
typing-extensions==4.16.0
typing-inspection==0.4.2
tzdata==2026.6
urllib3==1.26.20
uvicorn==0.39.0
visualdl==2.4.2
wcwidth==0.9.4
webrtcvad==2.0.10
websockets==15.0.1
werkzeug==3.1.9
xxhash==4.1.0
xyzservices==2026.9.1
yacs==0.1.8
yarl==1.22.0
zhon==2.1.1
zipp==3.23.1
PINS

# Exact frozen set, installed --no-deps: paddlespeech 1.5.0 declares paddlenlp>=2.7.2,
# but paddlenlp>=2.7 breaks (aistudio_sdk API) and <2.6 needs paddle.fluid, so 2.6.1 is pinned.
uv pip install pip "setuptools<70"
uv pip install --no-deps -r /work/constraints.txt
python -c "import paddle; paddle.utils.run_check()"
cd /work/models/paddlecv
# setup.py install extracts the egg, then fails its final dep check on the intentional
# paddlenlp pin above; tolerate that and verify the egg is present.
python setup.py install || true
ls -d /work/venv/lib/python3.9/site-packages/paddlecv-0.1.0-py3.9.egg

# Pre-download inference models by running both demos once
python -u tools/predict.py --config=configs/single_op/PP-LCNet.yml --input=demo/ILSVRC2012_val_00020010.jpeg --output_dir=/tmp/setup_out_cls
python -u tools/predict.py --config=configs/single_op/PP-YOLOE+.yml --input=demo/000000014439.jpg --output_dir=/tmp/setup_out_det
ls /tmp/setup_out_cls /tmp/setup_out_det
