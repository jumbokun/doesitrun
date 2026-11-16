# README-as-written track

Question: if a reader follows the README exactly, with no AI and no fixes, does the demo run?

Each repo gets three files in `literal/<slug>/`, written before any run and committed:

- `setup.sh` - the README's install and download steps, copied verbatim
- `env.sh` - sourced before the hidden test (the same `oracles/<slug>.sh` the AI track used, unchanged)
- `run.sh` - only for repos whose demo is a server: the README's start command

The harness then runs them on a fresh container of the CPU image and runs the hidden test. No agent,
no retries beyond the download timeouts every track gets, no repair round.

## Start state (provided by the harness, the same for every repo)

- Ubuntu 24.04 with git, git-lfs, curl, wget, unzip, sudo, build-essential, python3 (3.12), python3-venv, pip, uv
  (wget, unzip and sudo because almost every developer machine has them and READMEs assume them).
- The repo cloned to `/work/<dir>` at the commit named in the script header.
- An activated virtualenv at `/work/.venv` (Python 3.12). Ubuntu 24.04 refuses system-wide `pip install`
  (PEP 668), and a README that says `pip install` assumes the reader has an environment.
- Working directory `/work`.

## What a line in setup.sh / env.sh / run.sh may be

Every non-blank, non-comment line ends with exactly one tag. `literal_check.py` verifies each one.

| tag | allowed content |
|---|---|
| `# <file>:L<n>` or `# <file>:L<n>-L<m>` | A command copied from that file at that line (repo-relative path, e.g. `README.md:L42`, `docs/install.md:L10`). Whitespace may differ; nothing else. A leading prompt (`$ `, `> `, `%`) is dropped. The file must be the README or a doc the README points to for installing or running. |
| `# placeholder <file>:L<n> <orig> => <value>` | Same as above, with a README placeholder (`<path>`, `/path/to/x`, `YOUR_KEY`, `...`) replaced by a concrete value. `<orig>` must appear on the cited line. |
| `# prereq <file>:L<n> "<quoted words>"` | The README states a prerequisite in prose without giving a command (e.g. "requires Python 3.10+", "install ffmpeg", "Node.js 20"). The quoted words must appear on that line. The line is one of the standard installers: `apt-get update`, `apt-get install -y <pkgs>`, `uv venv --python <v> /work/.venv` (+ `source /work/.venv/bin/activate`), the Miniforge installer, the NodeSource setup script, `curl ... | sh` of an official installer the README names. |
| `# prereq <file>:L<n> "<quoted words>"` with `pip install <pkgs>` | The README names packages the reader must install ("requires PyTorch and OpenCV", "boto3 must be installed") without a command. Only the named packages, no versions or flags; each must appear on the cited line. |
| `# link <file>:L<n>` or `# link https://<page>` | The doc says "download it from <link>": `curl -fsSL -o <name> <url>` or `wget <url>` of exactly a URL that appears on that line or page. |
| `# https://<official doc page>` | The README sends the reader to its project's own install page off GitHub (e.g. docs.aws.amazon.com, playwright.dev). The command must appear verbatim in that page's text. |
| `# glue <reason>` | Only: `cd <dir>`, `mkdir -p <dir>`, `set -e`, `source /work/.venv/bin/activate`, and in run.sh `nohup <cited command> > /work/server.log 2>&1 &` (the cited command must carry its own tag on the line above as a comment `#= <file>:L<n>`) plus a readiness loop `for i in $(seq 1 N); do curl -s <url> && break; sleep 5; done`. |
| `# skip <file>:L<n> <reason>` | Comment-only line recording a README step deliberately not run: the `git clone` (the harness clones), a GPU-only alternative, a step for another OS, or the demo command itself (the hidden test runs the demo). |

Answering an interactive prompt the README's command shows with its default (`-y`, `always_yes`) is a
`prereq`-level allowance, not a fix.

Not allowed: adding a flag, a version pin, a package, a `--no-deps`, a workaround, a retry, or reordering
steps the README orders. If a README step fails, the run fails; that is the measurement.

## Choices

- Where the README offers alternatives, take the first one that applies to a CPU-only Linux box, and say
  so in a `# choice` comment line. Prefer "install from source / development install" when the hidden test
  runs code from the clone; otherwise the first listed (often `pip install <package>`).
- If the README gives only a conda path, install Miniforge as a `prereq` and follow the conda commands.
- Steps that only download the input the demo runs on, when the hidden test brings its own input, are
  skipped with `# skip`.
- If the hidden test needs a file at a path the README never mentions (the AI track chose it), write
  `# mismatch <what the test expects>` and leave it; the run is then reviewed by hand, not scored as a
  README failure.

## Header

```
#!/usr/bin/env bash
# literal: <owner/repo> @ <full commit sha>
# readme: README.md (+ any other cited docs)
set -e   # glue strict mode
```
