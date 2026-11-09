# Changelog

## Crash-site randomness fix — 2026-11-08

- Crash-site selection now discards three random draws before choosing. Under DCS's Lua the first draw after nearby seeds was nearly constant, so the centre site could be chosen almost every time.

## Randomized crash site — 2026-11-07

- WP3 is now the centre of a 2.5 km search region. Each start picks one of four crash sites, then places Sparrow within 200 m of it; a site without a safe clearing falls through to another.
- Added F10 Rescue > Contact Sparrow (direction fix): approximate bearing/range within 15 km, sharper when closer, 30 s cooldown.
- Green smoke, hunt gate, patrol placement and Longbow breakoff now use Sparrow's actual position. North/east hunter placement no longer aborts setup if it fails. The F10 marker and a region circle remain at WP3.

## Mission Planner concealment — 2026-11-06

- Applied the collection-wide enemy planner-concealment rule to all red groups, preserving deliberate mission intelligence and friendly planning. Deployment now checks the delivered archive.

## Unreleased — 2026-11-04

- Corrected reported overlapping Kiowa starts: four visible individual helipads 60 m apart, explicit matching aircraft coordinates, zero-AGL hot-ground starts and no shared parking allocation. Added warehouses for all four pads, all-pad service proximity checks, trees-only departure clearance and aligned Longbow recall.

- Reorganized Kiowas into RESCUE and LONGBOW, two aircraft each; Longbow is an Excellent-skill Hellfire pair starting on HAVEN pads 3/4, launching on player takeoff for a 3 nm southern overwatch area.
- Added controlled F10 one-target Hellfire tasking, range/sight-line/separation gates, attack time/distance limits, hold-fire and HAVEN recall; CAS protects all four aircraft.
- Fixed LANTERN directly at cockpit WP4 and removed recovery smoke and its menu command. Survivor green smoke remains.

- Moved STENNIS 20 nm toward extraction, from 90 to 70 nm on the same offshore bearing. Deck starts, carrier-relative climb points, recovery routes and the ship's westbound track follow the new position. Early launch, three-minute CAS delay and objective-based enemy activation remain as configured. Revised support timing estimate to 12–18 minutes.

## Unreleased — 2026-11-03

- Removed the redundant mission-name F10 submenu; command categories now open directly under Other.

## Unreleased — migrated 2026-11-01

- Moved mission-specific agent instructions and iteration lessons into this mission directory.
- Added a checked local deploy command and agent workflow: build, test, verify, back up the installed revision, copy into DCS Missions and confirm the file hash.
- Replaced copied DCS-MCP source with a Git submodule at the same upstream commit; setup initializes the submodule and installs/builds packages locally.
- Organized the mission into source, tests, design, player documentation and tracked playable output.
- Replaced personal mission-file build dependencies with checked-in data templates; pinned the authoring tools.
- Preserved the latest mission configuration: three hot-start Kiowas on HAVEN pads, lead PDU, two Hellfires plus gun on lead/#2, gun/rockets on #3, 270 kg fuel.
- Preserved randomized survivor search, 400 m timed pickup, separate serviced recovery FARP, carrier support package and stronger ground/air threats.
- Preserved the cleaned Rescue / Air Support F10 submenus, labels off and friendly-only map.

Earlier development happened in a chat and is represented by this baseline rather than reconstructed release numbers. No stable public release has been declared.
