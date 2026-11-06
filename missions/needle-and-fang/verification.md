# Needle and Fang verification — 2026-11-05

First development slice built from repository base f1e803b with the new mission files and catalog entry uncommitted at verification time. DCS-MCP remains pinned at 7da70f3e54dc48e1139096fae61a08a8bbbeca57; no dependency or other mission changes.

## Passed on the Windows DCS PC

- Build validator: zero errors and warnings; six groups, two combat helicopters, two armed objective vehicles, two neutral cover structures and two static helipads (eight units in editor fixup).
- Eleven printed scenario groups pass under installed DCS Lua: startup waiting and one-time launch release; actual Hind airborne report; either enemy kill order; no single-kill victory; immediate friendly-asset loss and simultaneous-kill precedence; delayed/acquired/renamed player; missing initial enemy; mandatory controller and invalid terrain failure; starts/pads, weapons/fuel, 8 nm geometry and 1T; native enemy task contract and non-disclosing status; native clearance call ordering.
- Mission Editor open/fixup routine passes for eight units; all three compiled trigger chunks are valid Lua. Ground headings, types and nonempty routes pass archive verification. These checks execute selected editor routines outside its GUI.
- Installed OH58D UnitPayloads confirms OH58D_FIM_92_R on pylon 5 and OH58D_M3P_L500 on pylon 1. Installed weapon definitions identify the inherited Hind template's AT-6 racks; this mission replaces those with two B-8V20 S-8 pods explicitly.
- Shared checked deployment built, tested, verified, installed and confirmed SHA-256 ef310ece03f80d0f54772b1deddece4cd99f070106073ebb2ec71ca065ee879e. There was no previous installed file. No running mission was loaded or restarted automatically.

## Pending native acceptance

No actual sortie or DCS GUI inspection was performed. Full site/coast/terrain and authored cover fit, forest removal/rotor clearance, both stable hot starts, Hind startup/route/terrain avoidance/vehicle attack/player encounter, Stinger acquisition, gun effectiveness, ground-unit defensive fire, cockpit target import, fuel/gross-weight/hover and fair duel timing remain unrun. No DCS version or successful flight can be reported. Runtime fixed-site checks can reject inappropriate land/slope; their existence does not prove the selected sites pass in DCS.

Follow flight-checklist.md before expanding the scenario. Record actual launch, sightings, weapons/damage and objective results separately from requested native tasks and text announcements.

## Ground-target race and FARP rearm revision — 2026-11-05

All 14 printed mock scenario groups pass. Revised tests verify immediate ground-only victory, Hind-only continuation, native death-event ordering and final-result latching, confirmed player-death handling, unresolved polling ties, logistics-loss exclusion and start-time ammunition trucks/canopies within 150 m of both pads. Existing unlimited warehouse entries remain for pads 200/201. Both helicopters and combat objectives retain their previous loadouts/geometry.

Validator: zero errors/warnings; editor fixup: 12 units; three compiled trigger chunks and archive checks pass. Shared deployment installed and hash-verified the final artifact, SHA-256 55c366313473573c73992be2e8b773c8dc6525f6dc5b73c8b0028a9f0ac57c1c. Previous installed revisions were preserved by the deploy workflow. Native death events are observed in engine order; polling retains friendly-loss precedence if both targets disappear without ordered events. Best-effort AI ceasefire follows the final result; released weapons cannot be recalled.

No native sortie or rearming interaction was performed. Ground Crew menu availability and actual Stinger/gun ammunition replenishment must be confirmed in DCS, along with the previously listed terrain/start/AI/combat checks. No repair/refuel service claim is added.
