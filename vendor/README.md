# Tool dependencies

`dcs-mcp/` is a Git submodule of https://github.com/sharRahul/dcs-mcp (Apache-2.0). The parent repository's gitlink pins the exact commit; `.gitmodules` records the upstream URL. The initial pin is `7da70f3e54dc48e1139096fae61a08a8bbbeca57`.

`npm run setup` initializes the recorded submodule revision, installs packages locally using its `package-lock.json` and compiles its source. Dependencies and compiled `dist/` are ignored by the submodule. Players do not need this tooling or its MCP server.

To update deliberately, check out a reviewed upstream commit inside `vendor/dcs-mcp`, install/compile it, run the collection's checks, then commit the changed gitlink in the parent repository. Do not use `git submodule update --remote` as routine setup: that follows upstream instead of the recorded revision. After pulling collection changes, rerun setup to synchronize and rebuild the dependency.
