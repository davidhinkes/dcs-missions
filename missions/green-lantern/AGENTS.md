# Green Lantern instructions

Read this mission's design, player README, changelog and lessons before editing it. Apply the repository's shared build/deploy workflow.

- Preserve three hot-start Kiowas on separate FARP HAVEN pads. Lead and #2 carry two Hellfires plus gun; #3 carries gun plus rockets. Each has 270 kg fuel; lead PDU is enabled.
- Labels are off and F10 is friendly-only. Custom threat replies must not reveal enemy unit identities or counts.
- Randomize Sparrow within 200 m of the approximate search waypoint. Allow pickup within 400 m with the documented approach/boarding time. Recover to the separate FARP LANTERN.
- Preserve the Rescue / Air Support menu grouping and manual CAS clearance.
- Wingman overwatch scripting, spotting dots and approximate contact reports were discussed, but are not implemented. Do not describe them as current capabilities.
- Use `node shared/tools/mission.mjs deploy green-lantern` from the repository root after mission edits. This mission's artifact and test entry point are defined in `mission.json`.
- Configuration and mock tests do not certify AI combat, FARP services, loadout performance or a complete sortie. Keep flight-check limitations explicit.
