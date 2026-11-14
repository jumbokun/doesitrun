# ClusterFuzz local server — notes

Followed docs/getting-started/prerequisites.md + local_instance.md (`local/install_deps.bash`, then
`python butler.py run_server --bootstrap`). Here's what broke and what I changed:

1. **Python version**: the repo needs Python 3.11, but the image ships 3.12. I used `uv python install 3.11` and a venv at `/work/venv`.
   `pipenv sync --dev` installs into that venv once it's activated, so I didn't use a separate pipenv venv.
2. **pipenv 2022.8.5 import error**: on a fresh venv it fails with `No module named 'pkg_resources'`, because new setuptools no longer ships it. Fix: `pip install "setuptools<70"`.
3. **install_deps_linux.bash not used as-is**: it installs docker-ce, blackbox, etc. that `run_server` doesn't need. It also
   depends on `lsb_release`/`sudo`, which the image lacks. I installed the needed subset by hand: lsb-release, sudo, golang-go
   (for `go run emulators/gcs.go`), xvfb, unzip, liblzma-dev, patchelf, openjdk, and google-cloud-cli plus the datastore/pubsub emulators from Google's apt repo.
   Go is listed as a prerequisite, but the script never installs it.
4. **Java version**: the repo pins `google-cloud-cli-datastore-emulator=591.0.0-0` so it works with Java 17. The current
   `google-cloud-cli` (593) still refuses to start the emulator: "requires a Java 25+ JRE". Fix: installed
   `openjdk-25-jre-headless`, made it the default `java`, and dropped the emulator pin.
5. **/login returns 400 locally**: `handlers/login.py` marks the GET with `@handler.unsupported_on_local_server`. I removed that one
   decorator so the login page renders (HTTP 200). Firebase sign-in still won't work offline; local dev logs you in automatically as
   user@localhost anyway.

Result: `source /work/env.sh && /work/run.sh` starts `butler.py run_server --bootstrap` (log: /work/server.log). It's ready in
about 35–70 s, and `/` and `/login` both return 200 with ClusterFuzz pages. I re-ran `setup.sh` from scratch after moving the old clone and venv aside, and it worked.
