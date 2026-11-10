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

## Two flights and fixed medical pad — 2026-11-04

All 31 printed mock scenarios pass. New scenarios cover two two-ship groups/four distinct HAVEN slots, delayed Longbow launch, manual one-target ATGM-only assignment, no automatic follow-on, terrain sight line, friendly/Sparrow separation, empty missile loads, hold-fire/orbit, recall, attack duration/distance limits, boarding recall and optional API-error isolation. Recovery tests confirm no blue smoke/command and equality of cockpit WP4, runtime landing pad and success location. Build assertions check four unique parking slots, Excellent Longbow skills/Hellfire loadouts, 3 nm station and retained carrier links. Validator: zero errors/warnings; Mission Editor fixup: 50 units; three compiled trigger chunks and geometry checks pass.

Installed archive SHA-256: ba3ffdaf1f934eeb746b1c6f3674a69bf3fcf9ee88ee83e94d16b48c50c8b542. Previous installed revision matched the prior deployment and was backed up. No native sortie performed: four-slot launch sequencing, terrain at fixed LANTERN, orbit/attack geometry, Hellfire guidance/accuracy, logistics and recovery remain in-game acceptance items.

## Explicit helipads after overlapping spawn report — 2026-11-04

The user observed stacked helicopters/no individual pads. Replaced shared-FARP parking allocation with four visible SINGLE_HELIPAD/FARP objects (100–103), explicit matching aircraft coordinates separated by at least 60 m, and zero-AGL native hot-ground starts without parking/start links. Both flight origins/first waypoints match their leads; Longbow recall matches pad 102. Warehouses cover all four pads; logistics placement avoids the pad footprints and keeps service vehicles within 150 m of each. Native trees-only clearance runs before mission Lua.

All 32 printed mock scenarios pass, including physical aircraft/pad matching, actual coordinate separation, start-mode/altitude checks, complete service coverage and clearance action ordering. Validator zero errors/warnings; editor fixup 53 units; three compiled Lua chunks and archive checks pass. Installed SHA-256: c8ca84e7c22e8aab80eb0fec37280251b5c1e5ba640e2ee6d0adab2f0405607c. Previous installed file matched the prior deployment and was backed up. Native spawn stability, visible terrain fit, AI departures/recovery and services still require a fresh DCS mission check; no flight test claimed.

## Collection-wide planner policy — 2026-11-06

Shared planner helper and packed-archive deployment check confirm all 11 red groups concealed, including aircraft and static/support groups. Mission logic tests and native Lua/editor/archive routines pass in the checked deploy workflow. A structured before/after archive comparison confirms that only red-group visibility fields changed; friendly and neutral groups, routes, prepoints, search/trigger zones, conditions/tasks and embedded resources are identical. A negative check rejects a deliberately omitted planner flag. Installed SHA-256: e287f0fa342a980a9314f5120a3eb730ae0b3c56cdc9494f61d65f5d6e4253d7. The existing installed revision matched tracked archive contents before replacement and was backed up. Native Mission Planner GUI inspection remains pending; this adds no native flight/rearm acceptance.

## Randomized crash site — 2026-11-07

Built in a cloud container without DCS. All 36 printed mock scenarios pass under Lupa 2.8 / Lua 5.1 (a local shim, not DCS luae.exe). They include 40 seeds covering all four sites, with Sparrow within 200 m of the chosen site and inside the 2.5 km region; patrols follow the site; site geometry clears Longbow's breakoff radius; fall-through when a site has no clearing; smoke gated on distance to Sparrow; and direction-fix range gate, cooldown, stated error bounds and sharpening. The portable archive verifier reports VERIFY OK; native Mission Editor open and compiled-trigger checks were skipped (no luae.exe). The planner check reports all 11 enemy groups hidden. Packed rescue.lua parses under Lua 5.1. Deployment was attempted and stopped before copying: no DCS Missions profile in this environment. Not deployed.

## Crash-site randomness fix — 2026-11-08

First run of the randomized build under DCS `luae.exe` (Steam install, Lua 5.1) failed "Every crash site should occur across seeds": seeds 1–40 all selected site 1, because the first `math.random` draw after nearby seeds is nearly constant. Lupa had masked this. After discarding three draws before site selection, the 40 seeds give 10 of each site and all mission logic tests pass under `luae.exe`. How DCS seeds `math.random` for a real mission start is unverified; check across several sorties that more than one site appears.

Pending in DCS: terrain/clearing suitability of the north, east and west sites and their relative patrol placements; whether the F10 circle draws; whether the fix accuracy makes the search fun rather than tedious; total sortie time with up to 2.4 km of extra search.

## Carrier package air starts — 2026-11-10

GUARDIAN, WEASEL and BRUISER now spawn airborne at marshal when released. Build assertions check each strike flight's late activation, air-start waypoint at its marshal point, altitude/speed, separated wingmen, absence of deck parking fields, STENNIS-linked final landing, Overlord's retained deck launch/recovery, and a straight-line marshal-to-station estimate at least two minutes shorter than the Kiowa's takeoff-to-8 km-gate time at 90 kt (Guardian 3.1, Bruiser 2.1, Weasel 1.3 vs 5.7 minutes). All 35 printed mock scenarios pass, including whole-package release on takeoff and on early F10 request. Validator: zero errors/warnings; archive verifier and planner concealment check pass.

These checks ran on a Linux cloud machine with Debian `lua5.1` standing in for DCS `luae.exe`; not a DCS interpreter, Mission Editor GUI or flight check. Deployment was not possible there (no DCS install/profile). Pending in DCS: air-start spawn behaviour, actual arrival order versus the Kiowas, on-station fuel, Weasel/Guardian engagement and STENNIS recovery.

## Bruiser CAS watchdog — 2026-11-10

Review found that Bruiser's 700 m friendly-separation check ran only when selecting a target; a mock probe showed an assigned attack staying weapons-free after the player Kiowa moved to 200 m from the target. Added a per-update watchdog (separation break-off with the request kept open; 120 s time limit clearing the request) and a regression test covering break-off, resumption once separation is restored, and the time limit. The test fails on the previous script and passes with the fix; all mission logic tests and the archive verifier pass under DCS `luae.exe`. Native AI behaviour after a task reset (whether Bruiser actually stops a run already in progress) needs a sortie.
