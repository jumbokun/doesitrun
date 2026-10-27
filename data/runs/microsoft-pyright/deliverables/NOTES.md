# Pyright CLI build notes

The documented path (`pnpm run install:all`, then `pnpm run build` in packages/pyright) worked once a toolchain was in place. The sandbox had no Node or pnpm, and the docs are out of date on versions.

What I changed:
- **Node:** docs/build-debug.md says "nodejs 16.x". I installed Node 24.15.0 instead, the version CI uses (`NODE_VERSION` in .github/workflows/validation.yml), from the official nodejs.org tarball into /work/node. Current deps (TypeScript 6, eslint 10, rspack) need a modern Node.
- **pnpm:** the docs never say how to install it. I ran `npm install -g pnpm@11.21.0`, the version pinned by the `packageManager` field in package.json.
- **Commit:** the clone is pinned to 611afe6 (pyright 1.1.414).
- **env.sh:** puts /work/node/bin, which contains node and pnpm, on PATH.

Checked: a file with errors gives exit code 1 and the errors; a clean file gives exit code 0; `--outputjson` gives JSON diagnostics. A fresh re-run of setup.sh from scratch also passed.
