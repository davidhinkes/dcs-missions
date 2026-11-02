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
