# General DCS mission lessons

Keep only reusable findings here. Store a mission's observed failures, coordinates, force composition, gameplay choices, numerical thresholds and test coverage in that mission's own lessons file. Identify evidence and limits when adding a finding; a proposed check is not an implemented capability.

## Mission structure and initialization

- Valid Lua and archive structure do not guarantee a playable mission. Check player/client slots, start type/action, linked airbase or FARP, pad allocations and required modules together.
- Every routed group needs a valid first route point. Use the archive verifier to catch editor load failures before launching DCS.
- Ground starts need a coherent native start mode, pad placement and altitude convention. A prior aircraft BARO altitude is not a terrain survey. For explicit ground-area starts, check zero terrain-relative altitude and avoid contradictory parking links; for parking starts validate the actual linked airbase and slots. Ground services should be present independently of objective initialization.
- Player discovery and player destruction are distinct states. Allow startup delay before concluding that the player was lost.
- Optional scenery, support or patrol placement must not prevent mandatory objective initialization. Use bounded searches, fallbacks and clear failure reporting.

## Locations, support and AI

- A visible FARP pad alone does not establish logistics. Configure the required services and warehouses, then verify servicing in DCS.
- A dynamically selected objective location must drive its smoke, map markers, directions and completion checks consistently.
- Recompute support coordination after route or launch changes. Include launch delay, climb and transit, and label estimated arrival times as estimates.
- Activation, arrival, detection, task assignment and weapon release are separate events. Record them separately when diagnosing AI behavior.
- Validate weapon masks against DCS task definitions. An accepted task can still request no usable weapon.
- Enumerate all relevant friendly units for separation checks; adding a wingman must also update loadouts, starts, fuel and protection. Released weapons cannot be recalled by cancelling a later task.
- Voice interfaces simplify orders but do not by themselves replace the underlying DCS flight/combat AI.

## Player information and difficulty

- Test menu hierarchy, uniqueness and callback behavior. Flat callback lookup cannot detect duplicate labels or incorrect submenu placement.
- Generate repeated briefing facts from shared mission configuration where practical; test them against the actual build.
- Keep randomized search locations inside the promised bounds, including fallback placement. Record seeds for reproducible failures.
- DCS's Lua 5.1 (`luae.exe`, Windows C runtime `rand()`) returns nearly identical first draws after nearby seeds: seeds 1–40 all gave the same `math.random(4)`. Discard a few draws before a gameplay choice, and run randomness tests under DCS's own `luae.exe`, not a portable Lua shim. Evidence: Green Lantern crash-site test, 2026-11-08. How DCS seeds missions at runtime remains unverified.
- Map visibility, labels and scripted disclosure are separate controls. Check all of them against the intended information available to the player.
- Simulated boarding, movement or recovery needs clear phase-specific instructions and explicit completion cues.

## Verification and delivery

- The pinned authoring serializer writes JS arrays as 0-indexed Lua tables. Convert lists passed into mission Lua to 1-based tables, and assert the first element explicitly; `ipairs`/`#` otherwise skip it silently and count-based tests can agree with the bug (found in Long Shadow).

- Capacity checks do not establish gross weight, hover performance or endurance. Distinguish those limits in the design and flight checks.
- Separate portable archive checks, simulated logic tests and observed DCS sorties. Mock tests cannot establish scenery clearance, AI taxi/launch/attacks or cockpit usability.
- Check time/radius boundaries, interruptions, delayed spawn and failure paths, not just the normal completion path.
- Diagnose with DCS logs and debrief events, but keep personal logs/tracks out of the repository.
- Build from checked-in configuration and pinned tools. Clean-checkout checks catch missing fixtures, submodules and dependencies hidden by an existing development environment.
- The shared deploy command must stop before replacement if build/tests/verification fail. Preserve existing installed revisions, verify copy hashes, and report the actual destination. Copying does not reload a running mission.
- Put mission-specific artifact and test paths in a per-mission manifest. Shared tooling should not select a particular mission implicitly.

- Fixed departure sites need explicit forest clearance as well as terrain and pad checks. Native trees-only scenery zones can prepare a local clearing without removing buildings; verify their editor records, compiled execution order and actual in-game result. Mock scenery searches do not certify rendered forest or collision clearance.

## Preventing design and integration rework

See [mission rework review](mission-rework-review.md) for evidence and the staged workflow.

- Define the player-visible support contract before adding an asset: starting location, automatic versus requested travel, arrival criteria, available commands and loss/fallback reporting. Do not add dispatch steps merely because a new asset exists.
- Separate optional support errors from mandatory mission failure, including menu callbacks and cleanup. Use fault injection to demonstrate the objective continues after support faults.
- Distinguish one-time milestone announcements from continuously changing availability. Use separate entry/exit thresholds when orbit or motion can repeatedly cross a boundary.
- Design information and menus alongside mission phases. Prefer geographic coordinates and explicitly labeled true/grid bearing/range over internal engine coordinates; avoid unsupported scenery descriptions.
- Validate the playable foundation and the distinctive native mechanic before treating added features as readiness. Document unrun DCS checks and the next flight experiment rather than accumulating ambiguous claims of verification.

- Preflight Mission Planner concealment needs its own hiddenOnPlanner flag on every enemy category, including aircraft and support/static groups. Friendly-only F10 and hiddenOnMFD alone do not enforce it. The shared builder helper and packed-archive deployment check now apply this collection-wide user preference; player intelligence records remain separate. Native planner GUI acceptance is still a distinct check.
