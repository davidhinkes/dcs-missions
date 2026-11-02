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
- `vendor/dcs-mcp/`: authoring-tool Git submodule pinned to an exact commit; no server installation needed to build.

## Play Green Lantern

1. [Download the Green Lantern mission](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/green-lantern/dist/Operation-Green-Lantern-Syria-OH58D.miz).
2. Copy the `.miz` file into `%USERPROFILE%\Saved Games\DCS\Missions` (use your own DCS profile folder if different).
3. Start DCS, choose **Missions**, open Green Lantern, and fly.

Requires **Syria** and **OH-58D**. Works with Steam and standalone DCS. All mission scripts are embedded. Players do not need Git, Node.js, DCS-MCP, its Lua hook, or any submodule setup. The development instructions below are only for mission authors.

## Build and check

Use Git and Node.js 22 or newer with npm. No global npm packages are required. A fresh checkout can include the dependency immediately:

```powershell
git clone --recurse-submodules https://github.com/davidhinkes/dcs-missions.git
cd dcs-missions
```

From the project directory:

```powershell
npm run setup
npm run build
npm test
npm run verify
```

`setup` runs `git submodule update --init --recursive`, installs the tool's locked dependencies locally with `npm ci`, and compiles it. It also works after a normal clone that omitted submodules. Rerun setup after pulling dependency changes; fresh setup needs network access. This working copy already has dependencies and compiled tools available. `build` has no dependency on personal Saved Games files. `test` runs simulated mission logic under DCS's Lua interpreter. `verify` checks the archive using the authoring validator and DCS's Lua / Mission Editor routines. Neither replaces an actual sortie.

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
