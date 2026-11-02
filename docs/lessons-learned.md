# General DCS mission lessons

Keep only reusable findings here. Store a mission's observed failures, coordinates, force composition, gameplay choices, numerical thresholds and test coverage in that mission's own lessons file. Identify evidence and limits when adding a finding; a proposed check is not an implemented capability.

## Mission structure and initialization

- Valid Lua and archive structure do not guarantee a playable mission. Check player/client slots, start type/action, linked airbase or FARP, pad allocations and required modules together.
- Every routed group needs a valid first route point. Use the archive verifier to catch editor load failures before launching DCS.
- Ground starts need terrain-appropriate altitude and valid pad links. Prefer terrain queries or observed DCS data to guessed elevations.
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
- Map visibility, labels and scripted disclosure are separate controls. Check all of them against the intended information available to the player.
- Simulated boarding, movement or recovery needs clear phase-specific instructions and explicit completion cues.

## Verification and delivery

- Capacity checks do not establish gross weight, hover performance or endurance. Distinguish those limits in the design and flight checks.
- Separate portable archive checks, simulated logic tests and observed DCS sorties. Mock tests cannot establish scenery clearance, AI taxi/launch/attacks or cockpit usability.
- Check time/radius boundaries, interruptions, delayed spawn and failure paths, not just the normal completion path.
- Diagnose with DCS logs and debrief events, but keep personal logs/tracks out of the repository.
- Build from checked-in configuration and pinned tools. Clean-checkout checks catch missing fixtures, submodules and dependencies hidden by an existing development environment.
- The shared deploy command must stop before replacement if build/tests/verification fail. Preserve existing installed revisions, verify copy hashes, and report the actual destination. Copying does not reload a running mission.
- Put mission-specific artifact and test paths in a per-mission manifest. Shared tooling should not select a particular mission implicitly.
