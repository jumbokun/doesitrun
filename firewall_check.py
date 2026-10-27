"""Prove the sandbox cannot reach the host, the LAN or the cloud control plane, but can reach the internet.

Starts two canary HTTP servers on the host (one on 127.0.0.1, one on 0.0.0.0), then from a
probe-configured container tries every known path to them and to cloud metadata endpoints.
A positive control from Docker's default network must reach a canary, otherwise "blocked" could just
mean the canaries were down. Works on Docker Desktop (host at 192.168.65.254) and on a native Linux
host such as a GitHub runner (host = bridge gateway). run_probe.py calls verify() before every batch.
"""
import http.server
import json
import pathlib
import socket
import subprocess
import sys
import threading

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
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


def gateway(network):
    p = subprocess.run(["docker", "network", "inspect", network, "--format", "{{json .IPAM.Config}}"],
                       capture_output=True, text=True)
    try:
        return next((c["Gateway"] for c in json.loads(p.stdout) if c.get("Gateway")), None)
    except ValueError:
        return None


def curl_lines(targets):
    return "; ".join(f'echo "{label} -> $(curl -s -m 4 {url} || echo blocked)"' for label, url in targets)


def verify():
    servers = [http.server.ThreadingHTTPServer(("127.0.0.1", 18999), H),
               http.server.ThreadingHTTPServer(("0.0.0.0", 18998), H)]
    for s in servers:
        threading.Thread(target=s.serve_forever, daemon=True).start()
    try:
        lan = lan_ip()
        name = "rr-fwcheck"
        run_probe.start_container(name, {"gpu": False, "mem": "1g"})
        hosts = ["host.docker.internal", "gateway.docker.internal", "192.168.65.254", "192.168.65.1",
                 "192.168.65.7", lan, gateway("bridge"), gateway(run_probe.NET)]
        targets = [(f"{h}:{p}", f"http://{h}:{p}/") for h in dict.fromkeys(filter(None, hosts)) for p in (18999, 18998)]
        cloud = [("imds 169.254.169.254", "-o /dev/null -w %{http_code} http://169.254.169.254/"),
                 ("wireserver 168.63.129.16", "-o /dev/null -w %{http_code} http://168.63.129.16/"),
                 ("router " + lan.rsplit(".", 1)[0] + ".1", "-o /dev/null -w %{http_code} http://" + lan.rsplit(".", 1)[0] + ".1/")]
        internet = [("internet pypi", "-o /dev/null -w %{http_code} https://pypi.org/simple/pip/"),
                    ("internet hf", "-o /dev/null -w %{http_code} https://huggingface.co/api/models?limit=1")]
        out = subprocess.run(["docker", "exec", name, "bash", "-c", curl_lines(targets + cloud + internet)],
                             capture_output=True, text=True).stdout
        subprocess.run(["docker", "rm", "-f", name], capture_output=True)

        controls = [h for h in ("192.168.65.254", gateway("bridge")) if h]
        control_out = subprocess.run(
            ["docker", "run", "--rm", "--entrypoint", "bash", run_probe.IMAGE, "-c",
             curl_lines([(f"control {h}:{p}", f"http://{h}:{p}/") for h in controls for p in (18999, 18998)])],
            capture_output=True, text=True).stdout
    finally:
        for s in servers:
            s.shutdown()
    print(out)
    print(control_out)

    def reached(line):
        value = line.split("->", 1)[1].strip() if "->" in line else ""
        return value not in ("", "blocked", "000", "000blocked")

    leaked = CANARY.decode() in out
    cloud_open = [l for l in out.splitlines() if l.split(" ->")[0].split(" ")[0] in ("imds", "wireserver", "router")
                  and reached(l)]
    internet_ok = "pypi -> 200" in out and "hf -> 200" in out
    control_ok = CANARY.decode() in control_out
    ok = control_ok and not leaked and not cloud_open and internet_ok
    print("FIREWALL", "OK" if ok else "FAILED",
          {"positive_control_reached_canary": control_ok, "host_canary_leaked": leaked,
           "cloud_or_router_reachable": cloud_open, "internet_ok": internet_ok})
    return ok


if __name__ == "__main__":
    sys.exit(0 if verify() else 1)
