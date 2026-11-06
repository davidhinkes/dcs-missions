# DCS missions

A collection of authored DCS World missions, their design decisions, source scripts and playable builds.

## Missions

| Mission | Aircraft / terrain | Status |
| --- | --- | --- |
| [Operation Green Lantern](missions/green-lantern/README.md) | OH-58D / Syria | Playable development build; latest revision awaits a full flight check |
| [Operation Quiet Tide](missions/quiet-tide/README.md) | OH-58D + AI Black Hawk / Syria, Tarawa and Stennis | Development test slice; native deck/AI acceptance pending |
| [Operation Open Door](missions/open-door/README.md) | OH-58D + AI Black Hawk / Syria | Playable development build; Black Hawk flight/cockpit checks pending |

## Project layout

- `missions/<name>/design.md`: mission intent, decisions, timing, acceptance criteria and open work.
- `missions/<name>/AGENTS.md` and `lessons-learned.md`: mission-specific agent instructions, preferences and iteration history.
- `missions/<name>/src/`: build code, embedded Lua and checked-in data templates.
- `missions/<name>/tests/`: mission-specific checks.
- `missions/<name>/dist/`: latest playable `.miz` and briefing, tracked in Git.
- `missions/<name>/assets/`: briefing images and audio when added.
- `docs/lessons-learned.md`: general DCS findings with evidence and limits.
- `docs/mission-design-template.md`: starting point for the next design.
- `shared/`: tools and helpers actually shared across missions.
- `vendor/dcs-mcp/`: authoring-tool Git submodule pinned to an exact commit; no server installation needed to build.

## Play a mission

Open a mission's player README from the catalog above for its download link and required aircraft/terrain modules. Copy its downloaded `.miz` into your DCS Saved Games `Missions` folder and open it from DCS's **Missions** screen. Players do not need the developer tooling, Git submodules or MCP hook.

## Build and check

In the commands below, replace `mission-slug` with the folder name of the mission you are working on.

Use Git and Node.js 22 or newer with npm. No global npm packages are required. A fresh checkout can include the dependency immediately:

```powershell
git clone --recurse-submodules https://github.com/davidhinkes/dcs-missions.git
cd dcs-missions
```

From the project directory:

```powershell
npm run setup
npm run build -- mission-slug
npm test -- mission-slug
npm run verify -- mission-slug
```

`setup` runs `git submodule update --init --recursive`, installs the tool's locked dependencies locally with `npm ci`, and compiles it. It also works after a normal clone that omitted submodules. Rerun setup after pulling dependency changes; fresh setup needs network access. This working copy already has dependencies and compiled tools available. `build` has no dependency on personal Saved Games files. `test` runs simulated mission logic under DCS's Lua interpreter. `verify` checks the archive using the authoring validator and DCS's Lua / Mission Editor routines. Neither replaces an actual sortie.

On this PC, Node is available through the existing bundled runtime, while npm is not currently on PATH. You can use the prepared copy directly without installing anything:

```powershell
node shared/tools/mission.mjs build mission-slug
node shared/tools/mission.mjs test mission-slug
node shared/tools/mission.mjs verify mission-slug
```

Steam and standard standalone DCS locations are detected. For another installation:

```powershell
$env:DCS_LUA='D:\DCS World\bin\luae.exe'
npm test -- mission-slug
npm run verify -- mission-slug
```

For an additional mission, provide `missions/<slug>/src/build.mjs` and a `mission.json` naming its artifact and Lua test path. Use `npm run build -- <slug>` (or `test`, `verify`, `deploy`).

## Iterate and deploy locally

After a mission edit, the agent uses:

```powershell
node shared/tools/mission.mjs deploy mission-slug
```

With npm available, the equivalent is `npm run deploy -- mission-slug`. This builds the mission once, runs its logic tests and archive checks, and copies it to the detected Saved Games DCS `Missions` folder. SHA-256 verification confirms that DCS received the build. If any check fails, deployment stops before replacing the installed mission.

Every distinct previous installed file is backed up under `Missions/.mission-backups`, including manual Mission Editor changes. An unchanged file needs no copy or backup. The command prints the actual destination and any backup path. Restart the mission in DCS to use the update; an already running mission is not changed.

The default checks the standard `DCS` and `DCS.openbeta` Saved Games profiles and requires exactly one to exist. For a custom profile, relocated Saved Games folder or multiple standard profiles, specify the target explicitly in your local shell; do not commit personal paths:

```powershell
$env:DCS_MISSIONS_DIR='D:\Saved Games\DCS\Missions'
node shared/tools/mission.mjs deploy mission-slug
```

Developer filesystem tests for deployment run with `npm run test:tools` or `node --test shared/tools/deploy.test.mjs`.

## Working practices

Update the design and changelog with meaningful mission changes, rebuild, run appropriate checks, then copy the build into DCS for flight testing. Record the exact Git revision tested. Mission Editor edits to a generated `.miz` must be brought back into source or recorded as a deliberate source change before rebuilding.

The repository was created locally on 2026-11-01 and published publicly at [davidhinkes/dcs-missions](https://github.com/davidhinkes/dcs-missions) at the owner's request. See [GitHub setup](docs/github-setup.md) for synchronization and releases. No collection-wide license has been chosen; third-party code retains its own license.
