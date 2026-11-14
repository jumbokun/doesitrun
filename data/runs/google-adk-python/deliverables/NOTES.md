# google/adk-python setup notes

- Install: `uv venv --python 3.12 /work/venv` + `uv pip install -e . -c constraints-3.12.txt`
  (the README covers PyPI and git installs; I did an editable install from the clone using the repo's constraints file).
  Install worked with no dependency problems. `adk` ends up in /work/venv/bin, and `env.sh` puts it on PATH.
- `adk run contributing/samples/workflows/fan_out_fan_in "Hello World"` worked as-is and printed
  Uppercase / Character Count / Reversed.
- **What broke:** `adk run contributing/samples/workflows/state "hello adk"` runs correctly, but in the
  default human-readable mode it prints nothing. The final node returns a plain value, which only goes into
  `event.output`, and `cli._print_event` prints only events with text content parts. With `--jsonl` the
  result shows up (`"output": "Final Result: HELLO ADK (Original was: hello adk)!"`).
- **Change:** a small patch to `src/google/adk/cli/cli.py::_print_event` (applied by setup.sh). When an event has no
  text parts but carries the root workflow's final `output` (`node_info.output_for` includes the top-level
  path), it prints `[author]: <output>`. The state sample now prints
  `[state_sample]: Final Result: HELLO ADK (Original was: hello adk)!`. The existing CLI unit tests still pass.
