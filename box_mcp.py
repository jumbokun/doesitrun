"""Minimal stdio MCP server exposing exactly one tool: run a shell command
inside ONE named sandbox container.

Security model: the agent's only capability is `docker exec` into its own
container. Commands are passed as a single argv element to `bash -lc` inside
the container; nothing the model writes is ever interpreted by a host shell.
"""
import json
import re
import subprocess
import sys
import time

CONTAINER = sys.argv[1]
LOG_PATH = sys.argv[2]
if not re.fullmatch(r"rr-[a-z0-9-]{1,40}", CONTAINER):
    sys.exit(f"refusing container name {CONTAINER!r}")

MAX_TIMEOUT = 3600
HEAD, TAIL = 2_000, 12_000

TOOL = {
    "name": "sh",
    "description": (
        "Run a bash command inside your sandbox container (Ubuntu 24.04, CUDA 12.8, "
        "NVIDIA GPU attached if the task says so, internet access). Working dir /work. "
        "Returns exit code and combined stdout/stderr (long output is truncated in the middle). "
        "For long-running servers, start them in the background with nohup and redirect output to a file."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "cmd": {"type": "string", "description": "bash command"},
            "timeout_sec": {"type": "integer", "description": f"default 600, max {MAX_TIMEOUT}"},
        },
        "required": ["cmd"],
    },
}


def log(entry):
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def run(cmd, timeout):
    t0 = time.time()
    try:
        p = subprocess.run(
            ["docker", "exec", "-w", "/work", CONTAINER, "bash", "-lc", cmd],
            capture_output=True, timeout=timeout,
        )
        code, out = p.returncode, (p.stdout + p.stderr).decode("utf-8", "replace")
    except subprocess.TimeoutExpired as e:
        code = "timeout"
        out = ((e.stdout or b"") + (e.stderr or b"")).decode("utf-8", "replace")
        out += f"\n[timed out after {timeout}s; the process may still be running in the container]"
    dt = round(time.time() - t0, 1)
    log({"ts": t0, "cmd": cmd, "exit": code, "secs": dt, "out": out[-20_000:]})
    if len(out) > HEAD + TAIL:
        out = out[:HEAD] + f"\n...[{len(out) - HEAD - TAIL} chars truncated]...\n" + out[-TAIL:]
    return f"exit={code} ({dt}s)\n{out}"


def reply(id_, result=None, error=None):
    msg = {"jsonrpc": "2.0", "id": id_}
    if error:
        msg["error"] = error
    else:
        msg["result"] = result
    sys.stdout.write(json.dumps(msg) + "\n")
    sys.stdout.flush()


for line in sys.stdin:
    if not line.strip():
        continue
    req = json.loads(line)
    method, id_ = req.get("method"), req.get("id")
    if id_ is None:  # notification
        continue
    if method == "initialize":
        reply(id_, {
            "protocolVersion": req["params"].get("protocolVersion", "2025-06-18"),
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "box", "version": "0.1"},
        })
    elif method == "tools/list":
        reply(id_, {"tools": [TOOL]})
    elif method == "tools/call":
        args = req["params"].get("arguments", {})
        timeout = max(1, min(int(args.get("timeout_sec") or 600), MAX_TIMEOUT))
        text = run(str(args.get("cmd", "")), timeout)
        reply(id_, {"content": [{"type": "text", "text": text}]})
    elif method == "ping":
        reply(id_, {})
    else:
        reply(id_, error={"code": -32601, "message": f"unknown method {method}"})
