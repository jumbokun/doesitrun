"""Prove the sandbox cannot reach the host or LAN, but can reach the internet.

Starts two canary HTTP servers on the host (one on 127.0.0.1, one on 0.0.0.0), then from a
probe-configured container tries every known path to them. Exit 1 if any canary is reachable
or the internet is not. run_probe.py calls verify() before every batch.
"""
import http.server
import socket
import subprocess
import sys
import threading

sys.path.insert(0, __file__.rsplit("\\", 1)[0].rsplit("/", 1)[0])
import run_probe  # noqa: E402

CANARY = b"rr-canary-host-service"


class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(CANARY)

    def log_message(self, *a):
        pass


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("1.1.1.1", 53))
        return s.getsockname()[0]
    finally:
        s.close()


def verify():
    servers = [http.server.ThreadingHTTPServer(("127.0.0.1", 18999), H),
               http.server.ThreadingHTTPServer(("0.0.0.0", 18998), H)]
    for s in servers:
        threading.Thread(target=s.serve_forever, daemon=True).start()
    lan = lan_ip()
    gw = lan.rsplit(".", 1)[0] + ".1"
    name = "rr-fwcheck"
    run_probe.start_container(name, {"gpu": False, "mem": "1g"})
    targets = ["host.docker.internal", "gateway.docker.internal", "192.168.65.254",
               "192.168.65.1", "192.168.65.7", lan]
    script = "; ".join(
        f'echo "{h}:{p} -> $(curl -s -m 4 http://{h}:{p}/ || echo blocked)"'
        for h in targets for p in (18999, 18998))
    script += f'; echo "router {gw}:80 -> $(curl -s -m 4 -o /dev/null -w %{{http_code}} http://{gw}/ || echo blocked)"'
    script += '; echo "internet pypi -> $(curl -s -m 15 -o /dev/null -w %{http_code} https://pypi.org/simple/)"'
    script += '; echo "internet hf -> $(curl -s -m 15 -o /dev/null -w %{http_code} https://huggingface.co/api/models?limit=1)"'
    out = subprocess.run(["docker", "exec", name, "bash", "-c", script],
                         capture_output=True, text=True).stdout
    subprocess.run(["docker", "rm", "-f", name], capture_output=True)
    # Positive control: from Docker's default network the canary MUST be reachable,
    # otherwise "blocked" above might just mean the canaries were down.
    control = subprocess.run(["docker", "run", "--rm", "--entrypoint", "curl", run_probe.IMAGE,
                              "-s", "-m", "4", "http://192.168.65.254:18999/"],
                             capture_output=True, text=True).stdout
    print("positive control (default network) ->", control or "unreachable")
    if CANARY.decode() not in control:
        print("FIREWALL CHECK INVALID: canary not reachable even without the firewall")
        for s in servers:
            s.shutdown()
        return False
    for s in servers:
        s.shutdown()
    print(out)
    leaked = CANARY.decode() in out
    router_open = any(l.startswith("router") and "blocked" not in l and not l.rstrip().endswith("000")
                      for l in out.splitlines())
    internet_ok = "pypi -> 200" in out and "hf -> 200" in out
    ok = not leaked and not router_open and internet_ok
    print("FIREWALL", "OK" if ok else "FAILED",
          {"host_canary_leaked": leaked, "router_reachable": router_open, "internet_ok": internet_ok})
    return ok


if __name__ == "__main__":
    sys.exit(0 if verify() else 1)
