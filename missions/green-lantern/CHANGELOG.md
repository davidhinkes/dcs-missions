# Changelog

## Unreleased — 2026-11-04

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
