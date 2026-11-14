# Qwen-MM-Plugins core — setup notes

Followed docs/en/local_development.md "Fast source loop" (`python3 -m venv`, `pip install -e '.[core]'`)
into /work/venv. Nothing broke: the `core` server (`python3 src/capabilities/core/qwen_mm_plugins_core`
or `qwen-mm-plugins-core`) starts over stdio in native mode with no API key, and tools/list,
save_view (sample.pdf page 1 -> PNG), crop, visualize (sample.csv) and read_image all succeed on CPU.

Changes: none to code. setup.sh pins the tested commit and falls back to `uv venv --seed` if
`python3 -m venv` is unavailable. Optional system tools (ffmpeg, LibreOffice, Blender, pdflatex,
Playwright chromium) are reported missing by `--check-system` but aren't needed for these tools.

Doc nit: the `printf ... tools/list | python3 .../qwen_mm_plugins_core` example in local_development.md
returns `-32602 Invalid request parameters` because it skips the MCP `initialize` handshake; a
real client (initialize -> notifications/initialized -> tools/list) works fine.
