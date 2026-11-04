# Green Lantern instructions

Read this mission's design, player README, changelog and lessons before editing it. Apply the repository's shared build/deploy workflow.

- Preserve two flights of two hot-start Kiowas on distinct HAVEN pads: RESCUE uses pads 1/2 (player Hellfires/gun, wingman rockets/gun); LONGBOW uses pads 3/4 (two Hellfires/gun each, Excellent skill). All retain 270 kg fuel; player PDU enabled. LONGBOW is a separate AI group, not a normal player wingman.
- Labels are off and F10 is friendly-only. Custom threat replies must not reveal enemy unit identities or counts.
- Randomize Sparrow within 200 m of the approximate search waypoint. Allow pickup within 400 m with the documented approach/boarding time. Recover to the separate FARP LANTERN.
- Preserve the Rescue / Air Support menu grouping and manual CAS clearance.
- LONGBOW departs on player takeoff for a 3 nm south overwatch area. Explicit F10 requests authorize one target, ATGM mask 131072 only, with range/terrain sight line/separation gates. Preserve cancellation, time/distance breakoff, optional-failure isolation and return to HAVEN after pickup. Native shot accuracy, firing position and laser guidance need a sortie.
- WP4 equals the fixed LANTERN pad. Never relocate the recovery pad at runtime; no recovery smoke/menu. Survivor green smoke remains request-only. Spotting dots and sensor-specific attack-my-target integration remain unimplemented.
- Use `node shared/tools/mission.mjs deploy green-lantern` from the repository root after mission edits. This mission's artifact and test entry point are defined in `mission.json`.
- Configuration and mock tests do not certify AI combat, FARP services, loadout performance or a complete sortie. Keep flight-check limitations explicit.
