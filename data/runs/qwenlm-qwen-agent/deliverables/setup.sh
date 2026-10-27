#!/usr/bin/env bash
# Reproduces the Qwen-Agent + Ollama (CPU) setup from scratch. Run as root.
set -euo pipefail
mkdir -p /work/patches && cd /work
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq zstd pciutils curl ca-certificates >/dev/null
[ -d Qwen-Agent ] || git clone https://github.com/QwenLM/Qwen-Agent /work/Qwen-Agent

# Python env (README: pip install -e ./"[...]")
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
uv pip install -e "/work/Qwen-Agent[rag,code_interpreter,mcp,python_executor]"
# undeclared runtime deps imported by qwen_agent/utils/utils.py and tools/python_executor.py
uv pip install soundfile numpy tqdm
# packages the code_interpreter Docker image would provide (kernel runs locally here)
uv pip install ipykernel jupyter_client requests matplotlib numpy pandas pillow seaborn sympy openpyxl
python -m ipykernel install --sys-prefix --name python3

# Docker is unavailable in this sandbox: patch code_interpreter to fall back to a local kernel
cat > /work/patches/apply_local_kernel_fallback.py <<'PATCH_EOF'
"""Patch qwen_agent/tools/code_interpreter.py: fall back to a local Jupyter kernel when Docker is unavailable."""
import sys
p = sys.argv[1]
s = open(p).read()
if '_LOCAL_KERNEL_PROCS' in s:
    print('already patched'); sys.exit(0)

def rep(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)

rep("_DOCKER_CONTAINERS: Dict[str, str] = {}\n",
    "_DOCKER_CONTAINERS: Dict[str, str] = {}\n_LOCAL_KERNEL_PROCS: Dict[str, subprocess.Popen] = {}\n")
rep("""    for container_id in _DOCKER_CONTAINERS.values():""",
    """    for proc in _LOCAL_KERNEL_PROCS.values():
        proc.terminate()
    _LOCAL_KERNEL_PROCS.clear()
    for container_id in _DOCKER_CONTAINERS.values():""")
rep("""        _check_docker_availability()
        _check_host_deps()""",
    """        # Fall back to a local (unsandboxed) Jupyter kernel when Docker is unavailable
        self.use_docker: bool = os.getenv('QWEN_AGENT_CODE_INTERPRETER_LOCAL', '0') != '1'
        if self.use_docker:
            try:
                _check_docker_availability()
            except RuntimeError as e:
                logger.warning(f'{e} Falling back to a local, unsandboxed Jupyter kernel.')
                self.use_docker = False
        _check_host_deps()""")
rep("""                container_font_path = f'{self.container_work_dir}/{os.path.basename(ALIB_FONT_FILE)}'""",
    """                if self.use_docker:
                    container_font_path = f'{self.container_work_dir}/{os.path.basename(ALIB_FONT_FILE)}'
                else:
                    container_font_path = ALIB_FONT_FILE""")
rep("""            _DOCKER_CONTAINERS[kernel_id] = container_id
""",
    """            if self.use_docker:
                _DOCKER_CONTAINERS[kernel_id] = container_id
            else:
                _LOCAL_KERNEL_PROCS[kernel_id] = container_id
""")
rep("""            del _KERNEL_CLIENTS[k]
        if k in _DOCKER_CONTAINERS:""",
    """            del _KERNEL_CLIENTS[k]
        if k in _LOCAL_KERNEL_PROCS:
            _LOCAL_KERNEL_PROCS.pop(k).terminate()
        if k in _DOCKER_CONTAINERS:""")
rep("""    def _start_kernel(self, kernel_id: str):
        self._build_docker_image()
""",
    """    def _start_local_kernel(self, kernel_id: str):
        connection_file = os.path.join(self.work_dir, f'kernel_connection_file_{kernel_id}.json')
        launch_kernel_script = os.path.join(self.work_dir, f'launch_kernel_{kernel_id}.py')
        for f in [connection_file, launch_kernel_script]:
            if os.path.exists(f):
                os.remove(f)
        os.makedirs(self.work_dir, exist_ok=True)
        with open(launch_kernel_script, 'w') as fout:
            fout.write(LAUNCH_KERNEL_PY)

        kernel_process = subprocess.Popen(
            [
                sys.executable,
                os.path.abspath(launch_kernel_script),
                '--IPKernelApp.connection_file',
                os.path.abspath(connection_file),
                '--matplotlib=inline',
                '--quiet',
            ],
            cwd=os.path.abspath(self.work_dir),
        )
        logger.info(f"INFO: local kernel process's PID = {kernel_process.pid}")

        # Wait for kernel connection file to be fully written
        while True:
            if os.path.isfile(connection_file):
                try:
                    with open(connection_file, 'r') as fp:
                        json.load(fp)
                    break
                except json.JSONDecodeError:
                    pass
            if kernel_process.poll() is not None:
                raise RuntimeError('Local Jupyter kernel exited unexpectedly.')
            time.sleep(0.1)

        from jupyter_client import BlockingKernelClient

        kc = BlockingKernelClient(connection_file=connection_file)
        asyncio.set_event_loop_policy(AnyThreadEventLoopPolicy())
        kc.load_connection_file()
        kc.start_channels()
        kc.wait_for_ready()
        return kc, kernel_process

    def _start_kernel(self, kernel_id: str):
        if not self.use_docker:
            return self._start_local_kernel(kernel_id)
        self._build_docker_image()
""")
rep("""            params = json5.loads(params)
            code = params['code']""",
    """            params = params if isinstance(params, dict) else json5.loads(params)
            code = params['code']""")
open(p, 'w').write(s)
print('patched')
PATCH_EOF
python -I /work/patches/apply_local_kernel_fallback.py /work/Qwen-Agent/qwen_agent/tools/code_interpreter.py

# Ollama (CPU) + model
if ! command -v ollama >/dev/null; then curl -fsSL https://ollama.com/install.sh | sh; fi
if ! curl -sf http://localhost:11434/api/tags >/dev/null; then
  nohup ollama serve >/work/ollama_setup.log 2>&1 &
fi
for i in $(seq 120); do curl -sf http://localhost:11434/api/tags >/dev/null && break; sleep 1; done
ollama pull qwen3:1.7b || ollama pull qwen2.5:1.5b
echo "setup complete"
