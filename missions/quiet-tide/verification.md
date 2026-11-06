# Quiet Tide verification — 2026-11-05

Development snapshot created against repository base `cf767210f208390540e550e3c1b0cdc128f0e842` with new mission files uncommitted at validation time. Mission artifact SHA-256: `35acc21a4a0e0654b65c981ed9643629fda8307a2974a09987a72b2d86930c63`.

## Passed in Linux development environment

- Node build validator: zero errors, zero warnings; eight groups (two ships, three aircraft groups, three enemy groups).
- Complete simulated DCS API suite under Lupa 2.6 Lua 5.1: six printed scenario groups covering native model identifiers/links/slot uniqueness and shallow menu paths; support hold within tasking range; automatic launch versus explicit clearance; continuous deployment and reset; close threats/wave-off; aborted recovery; optional Hornet task failure; one-target request/expiry/friendly protection; delayed player/loss; invalid LZ and dry initial ship positions.
- Moving recovery tests reject initial ship coordinates, hovering and zero ground-speed mismatch on a moving ship; accept both aircraft landed with ship-relative velocity for 20 seconds.
- Portable upstream archive verifier: zero validator warnings/errors, vehicle/ship geometry and nonempty route checks pass.
- Current configuration and insertion Lua are embedded in the delivered archive; archived Lua files compile under Lua 5.1.

## Unrun or blocked

- Upstream Mission Editor open/fixup and native luae.exe trigger checks skipped because DCS runtime is absent. Lua 5.1 syntax compilation is separate evidence.
- DCS not installed here: shipboard deck models/parking/starts, entire ship route and sea placement, actual sunrise visibility and rotor clearance, native launch/hold/landing/departure/recovery, weapons engagement, services, cockpit gross weight/hover and reserve are all unrun. No DCS version or successful sortie can be reported.
- Shared deployment command attempted; it fails at active DCS Missions directory detection. No installation on the user's DCS PC is claimed.

Follow [flight-checklist.md](flight-checklist.md) before expanding this slice. A native failure is a development finding to diagnose, not something to bypass by silently moving the player to an air start. Alternate LZs and dynamic alarm/escalation are deliberately unimplemented.
