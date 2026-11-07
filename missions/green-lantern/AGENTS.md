# Green Lantern instructions

Read this mission's design, player README, changelog and lessons before editing it. Apply the repository's shared build/deploy workflow.

- Preserve two flights of two hot-start Kiowas on distinct HAVEN pads: RESCUE uses pads 1/2 (player Hellfires/gun, wingman rockets/gun); LONGBOW uses pads 3/4 (two Hellfires/gun each, Excellent skill). All retain 270 kg fuel; player PDU enabled. LONGBOW is a separate AI group, not a normal player wingman.
- Start pads are four fixed SINGLE_HELIPAD/FARP objects, IDs 100–103, 60 m apart. Each aircraft must have unique matching pad coordinates, alt=0/RADIO and TakeOffGroundHot / From Ground Area Hot, without parking/helipad start links. Never relocate occupied pads; preserve native trees-only clearance before script loading, warehouses for every pad and services within 150 m. Longbow recall links to pad 102.
- Labels are off and F10 is friendly-only. Custom threat replies must not reveal enemy unit identities or counts.
- WP3 is the centre of a 2.5 km search region (user decision, 2026-11-07). Each start picks one of four authored crash sites in `src/rescue.lua`, then randomizes Sparrow within 200 m of it; every site disc stays inside the region and at least 5 km from Longbow's station. Patrols, smoke gate, hunt gate and Longbow breakoff use the actual pickup; the 6 km MiG gate, F10 marker/circle and cockpit WP3 stay at the region centre. Contact Sparrow gives only a bounded approximate fix and must not name the chosen site. Allow pickup within 400 m with the documented approach/boarding time. Recover to the separate FARP LANTERN.
- Preserve the Rescue / Air Support menu grouping and manual CAS clearance.
- LONGBOW departs on player takeoff for a 3 nm south overwatch area. Explicit F10 requests authorize one target, ATGM mask 131072 only, with range/terrain sight line/separation gates. Preserve cancellation, time/distance breakoff, optional-failure isolation and return to HAVEN after pickup. Native shot accuracy, firing position and laser guidance need a sortie.
- WP4 equals the fixed LANTERN pad. Never relocate the recovery pad at runtime; no recovery smoke/menu. Survivor green smoke remains request-only. Spotting dots and sensor-specific attack-my-target integration remain unimplemented.
- Use `node shared/tools/mission.mjs deploy green-lantern` from the repository root after mission edits. This mission's artifact and test entry point are defined in `mission.json`.
- Configuration and mock tests do not certify AI combat, FARP services, loadout performance or a complete sortie. Keep flight-check limitations explicit.

- Use shared/tools/planner.mjs to hide all red groups from Mission Planner before packing. Keep deliberate friendly route/prepoint/search intelligence. The deployment archive check must pass; native planner GUI acceptance is separate.
