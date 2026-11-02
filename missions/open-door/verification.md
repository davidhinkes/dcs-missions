# Verification

2026-11-01, first development build:

- Build validator: zero errors, zero warnings.
- All 21 printed mission-logic scenarios passed using the installed DCS Lua interpreter and mock DCS APIs.
- Mission Editor load-fixup check passed for 38 units; this runs selected editor code outside the GUI.
- All three compiled trigger chunks loaded as Lua. Ground headings and route structure checks passed.
- Separate target-point import records match the fixed Strela and hostage-building coordinates and follow the installed OH-58D manual's naming format.
- Deployed to local DCS Missions; SHA-256 matches the generated archive. No running mission was automatically loaded or restarted.

Not verified by an actual DCS sortie: compound/scenery appearance, transport pad ground fit, FARP service behavior, AI following/hold paths, temporary landing, commanded departure/recovery, combat effectiveness, fuel reserve/hover capability, and cockpit target-point import or MMS alignment. The native terrain DLL could not be used for offline surveying in this environment, so runtime LZ checks and a subsequent flight check are required. No flight success is claimed.

Run `node shared/tools/mission.mjs deploy open-door` from the collection root after editing. Build timestamp changes can change the ZIP hash without changing mission contents.

## Ground-start revision

User's first flight exposed unsafe start behavior and a separate LZ setup error. Revised ground-start configuration and facilities passed 21 printed logic scenarios, zero-error/warning validation, 49-unit editor fixup checks, Lua trigger parsing and geometry checks. Tests assert zero-AGL hot-ground mode, no contradictory parking fields, five matching visible pads, 60 m aircraft spacing, full facilities and support range. No corrected in-game spawn or servicing is yet claimed.

## Forward FARP and route revision

All 23 printed logic scenarios pass, including a nominal 15 nm forward site, support within 150 m of all forward pads, whole-camp relocation around obstructed scenery, fixed intelligence positions and no enemy targets in the player route. Archive checks pass with 62 units and valid compiled Lua. Native terrain appearance, moving the forward objects while retaining pad warehouse service, and actual refuel/rearm/repair still require a DCS check.

## FOOTHOLD departure revision

All 23 printed logic scenarios and archive checks pass with 62 units. Tests confirm departure exactly 15 nm from the objective, fixed matched ground-start pads (no runtime replacement of occupied FOOTHOLD pads), optional KEYSTONE services, target-only enemy locations, and return success at FOOTHOLD. The new native FOOTHOLD spawn/terrain remains to be checked in-game.

## FOOTHOLD forest-clearance revision

2026-11-01: all 24 printed mock scenarios pass, including recorded native trees-only calls before both script loads. Build assertions cover five starting pads, static facilities and continuous clearance along the initial 600 m departure lane. Validator: zero errors/warnings; Mission Editor fixup: 62 units; three compiled trigger chunks valid Lua; archive/geometry checks pass. Installed archive SHA-256: ef485a5d14fb12696f11d50419638a83809b21244ce258423040c95b741f682a. The previous installed archive matched the prior deployment and was backed up before replacement. No native visual, collision or flight check was performed. Restart the mission and inspect the pads and departure lane in DCS.
