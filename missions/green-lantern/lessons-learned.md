# Green Lantern lessons learned

These findings came from Green Lantern development. They are practical observations, not guarantees across all DCS versions or modules. Add the mission and evidence when recording a new lesson.

## Mission archives and starts

- A group with an empty `route.points` can stop the Mission Editor opening the archive. Give every routed group at least one point; run the vendored verifier using DCS Lua. Evidence: authoring-tool verification and prior failure investigation.
- A player aircraft needs `skill='Player'` (or an intentional multiplayer client slot) and a valid start. A map-only experience can indicate a slot/start problem; inspect mission data and logs before changing unrelated scripts.
- Use `TakeOffParking` / `From Parking Area` for cold parking and `TakeOffParkingHot` / `From Parking Area Hot` for hot parking. Green Lantern links its three Kiowas to FARP unit 100 and separate pad numbers. Latest hot-start revision has passed offline checks; a new flight check is still needed.
- Ground altitude and pad linkage matter. Use terrain data or observed DCS coordinates rather than assuming zero altitude. HAVEN uses a position/altitude captured from a real DCS debrief.

## FARPs and recovery

- A visible pad alone does not establish usable logistics. Green Lantern includes fuel/service/comms vehicles and warehouse configuration. Verify refuel/rearm/repair in DCS; repairs need shutdown.
- Keep the recovery waypoint, actual terrain-cleared pad, smoke and player directions consistent. A waypoint near a dynamically placed pad is insufficient guidance by itself. Green Lantern supplies a LANTERN marker, blue smoke and return directions.
- Optional service or patrol placement must not abort rescue initialization. Protect optional placement and provide safe fallbacks; keep survivor randomization within its promised radius.

## AI tasks and support timing

- DCS task weapon masks are significant: `0` means no weapon, not automatic selection. Green Lantern CAS uses `9663676414` for Auto and SEAD uses `32768` for HARMs. Evidence: inspected local task definitions and task tests; actual attack performance still needs flight verification.
- A carrier 90 nm away takes materially longer to launch, climb and transit than a Kiowa takes to fly 13 nm. Offer an early launch request and an IP hold; takeoff-triggered support alone does not guarantee coordinated arrival.
- Separate fighter cover, radar suppression and ground attack roles. A HARM radar kill does not eliminate IR SAMs, launchers or gun threats.
- Scripted separation checks cannot recall released weapons. Check all friendly helicopters and the survivor before assigning CAS, and document that limit.
- Voice-command tools change how orders are given; do not assume they replace DCS flight or combat AI. Experimental tools need module-specific testing.

## Information and difficulty

- Avoid leaking internal enemy group names or counts through F10 replies. Generic task acknowledgments preserve uncertainty.
- Friendly-only F10 map and labels OFF are separate settings: Green Lantern uses `optionsView='optview_onlyallies'` and `labels=0`.
- Keep search-area markers approximate when the survivor is randomized. Spawn within a bounded safe search area and expose exact smoke only when requested nearby.
- Larger pickup radii can model a survivor approaching the helicopter. Green Lantern adds approach time at 3 m/s beyond 100 m, with a 400 m maximum and movement resetting the timer. This is a timer abstraction, not walking animation.

## Fuel and verification

- Fuel within tank capacity does not prove gross weight, hover capability or endurance. Kiowa fuel is 270 kg against a checked 333.69 kg capacity; check actual performance and reserve in the cockpit.
- Test time-based state transitions, pickup resets, failure paths and support gating with a mock DCS world. These tests cannot prove terrain clearance, AI taxi/launch/weapon behavior or cockpit usability.
- Review `Saved Games/DCS/Logs/dcs.log` for scripting failures and `debrief.log` for observed events/positions. Do not commit personal logs or full mission tracks.
- Keep build inputs and tool versions in the repository. A builder that reads unrelated personal missions is not portable.

## Iterations worth turning into automation

The distinction below matters: an existing test catches a known regression; a proposed check is still work to do. User observations identify the symptom, but do not by themselves establish its root cause.

| Observation / iteration | Lesson and automated check | Current coverage / remaining work |
| --- | --- | --- |
| Mission failed almost immediately; initialization needed repeated diagnosis | Treat player discovery and mission initialization as separate states. A player missing during startup is not yet a destroyed player. Report setup readiness and failures by stage. | Mock tests already cover delayed player spawn, renamed occupied aircraft and optional placement fallbacks. Proposed: structured in-game readiness events and a log checker that verifies required stages completed without mission failure. |
| Player saw a map instead of occupying the helicopter; starts and pad placement needed revisions | Valid archive syntax is weaker than a playable start. Check the intended player slot, helicopter category, group size, start type/action, FARP references and unique pad allocations together. | Archive checks exist. Proposed: a mission-specific configuration contract for the three Kiowas, hot starts, pad IDs, PDU and loadouts. Actual spawn and taxi/departure still require DCS. |
| MiGs were discussed separately as dispatched versus actually attacking | Activation, transit, detection, task assignment and weapon release are different events. A successful activation test cannot certify an engagement. | Mock tests cover activation gates/timing. Proposed: record aircraft birth/activation, relevant zone arrival, shots and losses during a DCS sortie, then generate an engagement report. Lack of shots should be flagged for investigation rather than automatically called an AI failure. |
| Moving departure closer shortened the helicopter leg while carrier support still had a long transit | Recompute coordination whenever geography changes. Compare player arrival with support launch delay plus climb/transit estimates; report the implied hold or early-launch lead time. | Early launch and delayed CAS are tested. Proposed: a timing report using configured route lengths/speeds and explicit launch/climb assumptions. Estimates must not be presented as observed arrival times. |
| Adding a third Kiowa changed who CAS needed to protect | New flight members affect more than formation size: loadouts, pads, fuel, radio identity and friendly-separation checks must all expand. | Existing test verifies protection of the third Kiowa. Proposed: enumerate friendly rescue aircraft from a mission manifest, checking every member instead of relying on a fixed list. |
| Player reached WP3/WP4 but could not identify what to do or where the recovery pad/smoke was | Waypoint arrival is not equivalent to objective completion. Every phase needs a visible cue, actionable instructions and a status answer tied to the actual objective location. | Pickup/return timers, smoke refresh and return bearings are tested. Proposed: phase-by-phase smoke/status acceptance cases, including landing at the approximate waypoint but outside the true pad radius. In-cockpit visibility remains a flight check. |
| Survivor search, pickup distance and F10 disclosure were refined repeatedly | Difficulty settings form a player-facing contract: search radius, pickup radius, map visibility and smoke disclosure must agree. Test boundaries and repeated random placements, including obstructed terrain. | Existing tests cover bounded randomization, constrained fallback, requested-only smoke, hidden survivor, generic replies and 400 m timing/reset behavior. Proposed: deterministic random seeds recorded on failure for reproducible terrain/search cases. |
| Menus accumulated duplicate smoke commands and became cluttered | Test menu structure as well as callback behavior. Flat command-name lookup cannot prove commands appear in the correct submenu or are not duplicated. | Current mock stores callbacks by label and discards parent paths. Proposed: record the full menu tree and verify allowed paths, unique commands, sensible depth and no internal target identities. |
| During repository migration the build and logic tests passed, but archive verification failed because a Lua fixture was omitted | A copied tool needs its complete dependency closure, including test fixtures used by its verifier. A working developer cache can hide missing files in the repository. | Missing verifier fixture was restored and verification passed. Proposed: clean-checkout setup/build/test job, plus a source-only CI build on a machine with no personal missions. DCS-specific checks need a machine with DCS Lua; do not silently skip them and report full success. |
| Briefing text can lag behind changes to flight size and starts | Generate repeated facts from shared configuration, or compare briefing assertions with the built mission. The current briefing still says "either OH-58" in the CAS separation explanation despite three Kiowas; the script protects all three. | Proposed: consolidate player-facing flight size, start mode, loadouts, ranges and menu labels into mission configuration, then render the briefing. This documentation mismatch does not alter CAS behavior. |

## Suggested implementation order

1. **Mission configuration contract:** player slot, linked starts/pads, flight size, payloads/fuel, friendly-only map and labels, carrier links, expected embedded scripts. This catches valid-looking builds that violate the intended mission.
2. **Menu and briefing consistency:** capture submenu paths in tests and generate repeated briefing facts from the same configuration. This catches usability regressions without flying.
3. **One check command and a clean-checkout check:** build, configuration checks, logic tests and archive verification; distinguish required DCS checks from portable checks. A shared runner should take mission-specific filenames/test paths from a manifest rather than hardcode Green Lantern.
4. **Structured sortie report:** capture readiness, phase changes, support arrival and engagements with mission revision and DCS version. This makes the remaining flight verification faster and explains why an aircraft did not contribute.

These are proposals, not capabilities already implemented by the project. A sortie report can verify observed events; it cannot establish tactical quality or prove that an AI pilot should have detected a target.

## Automation updates

The shared runner now reads artifact/test paths from each mission's `mission.json`. A `deploy` command builds once, runs logic and archive checks, backs up the installed file and verifies the copy into DCS. A clean-checkout CI job and the other proposed checks above remain future work.

## Moving the carrier closer

The 2026-11-04 change reduces the initial range from 90 to 70 nm on the same bearing. Translate the ship track, aircraft starts, relative climb points and linked recoveries together while preserving fixed tactical stations. At 230 m/s, the Guardian route estimate falls from 12.1 to 9.4 minutes before launch/climb. Keep early launch and the IP hold because actual AI launch timing is unmeasured. Added build checks cover all carrier flights; those checks exposed generic formation offsets on two deck-start wingmen, now aligned to the ship with parking fields retained.
