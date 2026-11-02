# Vendored tools

`dcs-mcp/` contains authoring tool source from https://github.com/sharRahul/dcs-mcp at commit `7da70f3e54dc48e1139096fae61a08a8bbbeca57` (Apache-2.0; license included). Copied source directories: `src/`, `scripts/`, package/build metadata, and `tests/fixtures/me-open.lua` required by the archive verifier. Sample missions, Git history, and server launch configuration were not copied.

The source is checked in to make this collection buildable without a nested clone. Dependencies and compiled `dist/` are local ignored files produced by `npm run setup`. Review and test upgrades explicitly; do not silently track upstream's default branch.
