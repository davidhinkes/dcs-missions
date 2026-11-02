# DCS missions

A collection of authored DCS World missions, their design decisions, source scripts and playable builds.

## Missions

| Mission | Aircraft / terrain | Status |
| --- | --- | --- |
| [Operation Green Lantern](missions/green-lantern/README.md) | OH-58D / Syria | Playable development build; latest revision awaits a full flight check |

## Project layout

- `missions/<name>/design.md`: mission intent, decisions, timing, acceptance criteria and open work.
- `missions/<name>/src/`: build code, embedded Lua and checked-in data templates.
- `missions/<name>/tests/`: mission-specific checks.
- `missions/<name>/dist/`: latest playable `.miz` and briefing, tracked in Git.
- `missions/<name>/assets/`: briefing images and audio when added.
- `docs/lessons-learned.md`: general DCS findings with evidence and limits.
- `docs/mission-design-template.md`: starting point for the next design.
- `shared/`: tools and helpers actually shared across missions.
- `vendor/dcs-mcp/`: pinned authoring tool source and original license; no server installation needed to build.

## Play Green Lantern

Copy `missions/green-lantern/dist/Operation-Green-Lantern-Syria-OH58D.miz` into your DCS Saved Games `Missions` folder and open it in DCS. Requires Syria and OH-58D. The mission embeds its Lua; players do not need Node.js or DCS-MCP.

## Build and check

Use Node.js 22 or newer and npm from the project directory. No global packages are required.

```powershell
npm run setup
npm run build
npm test
npm run verify
```

`setup` installs the vendored tool's locked dependencies locally and compiles it; it needs network access on a fresh checkout. This initial working copy already has dependencies and compiled tools available. `build` has no dependency on personal Saved Games files. `test` runs simulated mission logic under DCS's Lua interpreter. `verify` checks the archive using the authoring validator and DCS's Lua / Mission Editor routines. Neither replaces an actual sortie.

On this PC, Node is available through the existing bundled runtime, while npm is not currently on PATH. You can use the prepared copy directly without installing anything:

```powershell
node shared/tools/mission.mjs build
node shared/tools/mission.mjs test
node shared/tools/mission.mjs verify
```

Steam and standard standalone DCS locations are detected. For another installation:

```powershell
$env:DCS_LUA='D:\DCS World\bin\luae.exe'
npm test
npm run verify
```

For an additional mission, use `npm run build -- <mission-folder>` and provide its `src/build.mjs`. The test and verification commands currently target Green Lantern's harness and filename; extend the runner when adding the next mission.

## Working practices

Update the design and changelog with meaningful mission changes, rebuild, run appropriate checks, then copy the build into DCS for flight testing. Record the exact Git revision tested. Mission Editor edits to a generated `.miz` must be brought back into source or recorded as a deliberate source change before rebuilding.

The repository was created locally on 2026-11-01 and published publicly at [davidhinkes/dcs-missions](https://github.com/davidhinkes/dcs-missions) at the owner's request. See [GitHub setup](docs/github-setup.md) for synchronization and releases. No collection-wide license has been chosen; third-party code retains its own license.
