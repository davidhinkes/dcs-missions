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
