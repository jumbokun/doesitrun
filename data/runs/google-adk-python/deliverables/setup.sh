#!/usr/bin/env bash
# Reproducible setup for google/adk-python (CPU only, no API keys needed).
set -euo pipefail
cd /work
if [ ! -d /work/adk-python/.git ]; then
  git clone https://github.com/google/adk-python /work/adk-python
fi
cd /work/adk-python

# Python 3.12 venv (system python3 is 3.12; README requires 3.11+).
uv venv --clear --python 3.12 /work/venv
. /work/venv/bin/activate
# Editable install, pinned with the repo's own constraints file (as README recommends).
uv pip install -e . -c constraints-3.12.txt

# Patch: `adk run` text mode only prints events with content parts, so workflows
# whose final node just returns a value (e.g. workflows/state) print nothing.
# Also print the root workflow's final `output`.
cat > /tmp/adk-cli-print-output.patch <<'PATCH'
--- a/src/google/adk/cli/cli.py
+++ b/src/google/adk/cli/cli.py
@@ -594,6 +594,15 @@
     if text_parts:
       text = ''.join(text_parts)
       click.echo(f'[{author}]: {text}')
+    elif (
+        event.output is not None
+        and event.node_info
+        and any('/' not in p for p in event.node_info.output_for or [])
+    ):
+      # Final workflow output carried only in `output` (no content parts).
+      output = event.output
+      text = output if isinstance(output, str) else json.dumps(output, default=str)
+      click.echo(f'[{author}]: {text}')
     elif event.long_running_tool_ids:
       click.secho(f'[{author}]: (Paused for input...)', fg='yellow')
 
PATCH
if git apply --check /tmp/adk-cli-print-output.patch 2>/dev/null; then
  git apply /tmp/adk-cli-print-output.patch
fi

adk --version
