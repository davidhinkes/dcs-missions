# Migration verification

Date: 2026-11-01. Baseline commit: the commit introducing this document.

- Vendored tool source compiled successfully with its local TypeScript compiler.
- Project-local mission build passed validation with zero errors and zero warnings.
- All 24 simulated mission-logic scenarios passed under the installed DCS Lua interpreter (Lua 5.1).
- Archive verifier passed: Mission Editor load-fixup check (49 units), all three compiled trigger chunks, unit geometry and routes. This runs selected editor routines outside the GUI; it is not a GUI open or flight test.
- Migration comparison confirmed coalition forces/loadouts/routes, weather, forced options, required modules, triggers, map and date equal the pre-migration data. Embedded rescue Lua is unchanged.
- Built entirely from checked-in project data and vendored tools; no personal mission archive is read by the new builder.
- No new in-simulator sortie was performed. DCS version was not captured. Latest combined hot-start/FARP/air-support behavior remains to be flight-checked.
- The migration build was not copied over the installed DCS mission; its gameplay configuration matches the previous build.

Baseline playable file SHA-256: `0fbe81a276b0bbefa93d8ca97385d0549272085991e18399065a42d98178b5c9`. ZIP timestamps may change on a rebuild, so compare mission contents as well as binary hashes.

## F10 simplification — 2026-11-03

Removed the mission-name wrapper, preserving command categories and callbacks. Rebuilt artifact passes portable archive validation with zero validator errors/warnings. The complete simulated logic suite passes using Lupa 2.6 Lua 5.1 on Linux, including menu hierarchy/uniqueness checks. Confirmed the archive embeds the updated rescue script and its Lua files compile under Lua 5.1. This is not DCS luae.exe or a flight check. Native Mission Editor checks were skipped; deployment was attempted but blocked by the absent DCS Missions profile on this cloud machine. Restart the mission after installing the updated artifact.

## Carrier moved closer — 2026-11-04

STENNIS now starts exactly 70 nm from extraction on the prior bearing, 20 nm closer. Build assertions check range and every carrier aircraft's deck coordinates, launch/recovery position and ship linkage. Generic formation offsets on BRUISER/WEASEL wingmen were removed so deck starts match the ship before native parking allocation. All 25 printed mock scenarios pass; validator has zero errors/warnings; editor fixup covers 49 units; three compiled trigger chunks and archive geometry checks pass. Installed SHA-256: dc254b4b830506038710fb1f1d85de79ff423b78f25c74d42be472fbf973e4bf. Previous installed file matched the prior deployment and was backed up. No native sea/flight-operations or measured arrival check was performed.
