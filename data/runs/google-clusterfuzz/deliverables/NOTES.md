# ClusterFuzz local server – setup notes

Result: `python butler.py run_server --bootstrap` serves http://localhost:9000, and the
Fuzzers page lists the default fuzzers (afl, centipede, googlefuzztest, honggfuzz, libFuzzer).

## What broke / what I changed
- **Python 3.11**: the docs say to build Python 3.11 from source. Ubuntu 24.04 ships 3.12, so I installed 3.11 with `uv python install 3.11`, removed its EXTERNALLY-MANAGED marker so pip works, and symlinked it as `/usr/local/bin/python3.11`. Butler calls `python3.11 -m pipenv` by that name.
- **pipenv bootstrap**: `install_deps_linux.bash` installs Ubuntu's apt `pipenv`, which runs on Python 3.12. I used `python3.11 -m pip install pipenv==2022.8.5 "setuptools<81"` instead. That pipenv version needs `pkg_resources`, which setuptools 81 and later no longer include.
- **Did not run `local/install_deps.bash` itself.** It needs `sudo` (the sandbox runs as root and has no sudo) and installs docker-ce, which the local server doesn't need. I ran the same steps by hand in setup.sh: apt packages, gcloud repo, `pipenv sync --dev`, nodeenv, bower, polymer-bundler, `butler.py bootstrap`.
- **Datastore emulator vs Java**: the script installs openjdk-17 and pins only `google-cloud-cli-datastore-emulator=591.0.0-0`. Two things go wrong:
  - The newest `google-cloud-cli` (593) still gets installed alongside it, and that version refuses to start the emulator without Java 25.
  - Even gcloud 591 requires Java 21+, not 17, so the script's comment ("works with Java 17") is wrong.

  Fix: install openjdk-21 instead of 17, and pin google-cloud-cli, the datastore emulator and the pubsub emulator all to 591.0.0-0.
- Skipped the App Engine apt components; gunicorn serves the app, so they aren't needed.
- The Go GCS emulator (`go run emulators/gcs.go`) needs Go. I installed `golang-go` from apt.
- run.sh passes `--skip-install-deps`, because setup.sh already installed everything; otherwise every start would reinstall all the pip packages and download chromedriver again. It also sets `PYTHONUNBUFFERED=1` so server.log fills in as it runs. run.sh waits until `/` returns 200 and the `/fuzzers` page has a non-empty fuzzer list.
