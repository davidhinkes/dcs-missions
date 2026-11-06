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

## Reported rearm failure: complete BLUE departure service camp — 2026-11-05

User reports the duel was enjoyable but rearming was unavailable. Installed SHA-256 matched the preceding deployment. DCS logs contain readiness, hunt release and player-loss events, but no conclusive ground-crew failure cause. This is evidence of failed rearming in the previous revision, not a proven single root cause.

Added same-side active-at-start command Hummer/post, M978 tanker/fuel depot, separate M818 ground-power/repair trucks and repair tent alongside existing ammo truck/canopy. All BLUE support is within 150 m of the unchanged starting pad and clear of the aircraft; VHF AM preset 1 matches BLUE FARP 128.500. No objective/weapon/fuel/start-position changes. Official DCS User Manual printed p313 documents separate communications/ammo/fuel/power service roles; see mission lessons for the source.

All 15 printed mock groups pass, including full support-role/coalition/proximity checks and unlimited ammunition/fuel read from the actual packed warehouse file. Validator zero errors/warnings; editor fixup 19 units; three compiled trigger chunks and archive geometry checks pass. Installed final SHA-256: 4ead084000ddb3cc8c789b0f565b6ad62d5d92af1a7477c12fc735af2b796b6e. Prior installed revision was preserved. No native rearm/refuel/repair/power interaction was performed in this revision; actual ammunition replenishment remains the required acceptance check.

## Repeated Ground Crew contact failure: native FARP parking — 2026-11-05

User confirms the complete service revision still failed: Ground Crew was missing or nobody answered. Installed SHA-256 matched the deployed revision. Logs establish mission activity and an earlier successful ground-target result; they do not diagnose ground-crew contact. Read-only local DCS bridge reported phase=menu, so no live mission/terrain inspection or rearm check was possible. No mission was loaded automatically and hook permissions were not changed.

Changed BLUE departure from unlinked TakeOffGroundHot on SINGLE_HELIPAD to conventional FARP/FARPS ID 200 with a single player aircraft on native TakeOffParkingHot, helipadId/linkUnit 200 and parking/parking_id 1. BLUE site is unchanged; BARO ground height 33.384346008301 m comes from earlier observed HAVEN coordinates at that anchor, while native parking determines final pad position. RED and the duel remain unchanged. Existing complete service camp/warehouse remains. Expanded BLUE trees-only clearing to 200 m for the full FARP footprint.

Installed OH-58D comm.lua includes the common Ground Crew builder. That source hides the menu while Unit:inAir() is true and selects the local/intercom communicator. Corrected advice: FARP ATC frequency is not a substitute for that contact path. Added startup native landed/FARP-registration/coalition logging and status diagnostics, including after the round.

All 16 printed mock scenario groups pass, with revised native parking/model/link contract and landed-state diagnostics. Validator zero errors/warnings; editor fixup 19 units; three compiled trigger chunks and archive checks pass. Installed SHA-256 b3cc787350e74c462fe229a239d540b2d69da339c4bf62a5136561d0bc1b3812; prior file backed up. Native parking spawn stability, Ground Crew availability/acknowledgment and actual replenishment remain unverified. This is a targeted configuration/contact revision, not proof of the exact previous root cause or a successful native rearm.
