# Operation Needle and Fang design

## Intent and player experience

A compact cat-and-mouse helicopter duel on Syria. The Kiowa pilot balances hunting an enemy helicopter, attacking a known ground objective and protecting a friendly objective. The Hind is more heavily armed; the Kiowa relies on cover, a Stinger ambush and a short gun attack. The first slice validates the duel rather than adding support waves or patrol complexity.

## Confirmed user choices

- Single-player OH-58D against one AI Hind.
- One stationary defended vehicle per side, concealed near buildings or trees; vehicles are lightly armed and can threaten a close helicopter.
- Approximately 8 nm engagement space; implemented as exactly 8 nm between defended vehicles, with FARPs near their respective vehicles.
- Both helicopters start hot on separate FARPs.
- Exact enemy-vehicle prepoint; Hind location unknown.
- Player carries Stingers and guns.
- Hind hunts the friendly defended vehicle, engaging the player if encountered.
- Revised rule: first opponent ground-target destruction wins immediately; killing the enemy helicopter is optional. Own defended-vehicle destruction means immediate failure.

## Requirements and starts

Syria and OH-58D only; built-in AI Mi-24V. One helicopter per side, no wingmen or combat support. BLUE departure now uses a conventional FARP/FARPS object, ID 200, with the one player Kiowa explicitly linked to native hot parking slot 1 (TakeOffParkingHot / From Parking Area Hot, helipadId/linkUnit=200, parking/parking_id=1). The unchanged anchor has a previously observed BARO ground height of 33.384346008301 m; native parking determines final aircraft placement. RED keeps the separate SINGLE_HELIPAD/FARP ID 201 with zero-AGL ground start. BLUE 200 m and RED 160 m local trees-only clearings precede mission Lua. Buildings and hunting-area scenery are preserved. Unlimited pad warehouses, unarmed M 818/Ural-375 ammunition service trucks about 86 m from each pad and nearby FARP Ammo Dump Coating objects are present from mission start. After the user reported rearming unavailable, BLUE FARP was expanded with same-side command Hummer/post, M978 tanker/fuel depot, M818 ground-power/repair trucks and repair tent, all within 150 m and at least 40 m from the pad. VHF AM preset 1 matches ATC 128.500; Ground Crew instead uses the local/intercom path. The previous ammo-only service configuration was insufficient in the observed flight; the log does not identify the exact ground-crew failure. Full service interaction and replenishment require a new native check. Logistics are not combat objectives.

Kiowa: two right-side Stingers, left M3P gun/500 rounds, 30 flares, PDU and 181.4 kg fuel. This matches the installed native OH58D payload preset. Hind: High skill, two B-8V20 S-8 rocket pods plus native gun, 192 flares, 900 kg fuel. Omitting ATGMs is a first-slice balance choice; native weapon use and fairness need a sortie. Tank capacity is not loaded weight, hover capability or endurance verification.

## Geography and timing

Coordinates in config are DCS planar metres; mission y corresponds to world z. BLUE technical x=20648.236328125/east=7506.8149414062. RED technical x=35464.236328125/east=7506.8149414062. Separation exactly 14816 m / 8 nm. BLUE FARP x=19948.236328125/east=6806.8149414062; RED FARP x=36664.236328125/east=8406.8149414062. Both are near their own technical; FARPs are about 9.1 nm apart. BLUE FARP anchor comes from previously observed collection coordinates, but this mission's complete footprint and RED site remain uninspected.

Daylight 08:00 local, 15 June 2026, clear/light wind. Eight nautical miles is approximately 5.3 minutes at 90 kt before maneuvering. Allow 15–25 minutes overall without a deadline. Both defended vehicles remain fixed. Each has a neutral authored outbuilding about 57 m away; concealment is an intended scene, not a verified claim about native terrain/forest. No runtime relocation may invalidate the exact target record. Runtime land/slope checks reject unsuitable fixed sites rather than silently moving them.

## Forces and mission interaction

NEEDLE: player Kiowa. FANG: one uncontrolled hot-start AI Hind. BLUE-OBJECTIVE/RED-OBJECTIVE: one DShK technical each, stationary route, open fire and no under-fire dispersal. Neutral cover structures have AI disabled. Internal group names are not menu intelligence.

All four combat units must be acquired before ready. Initial missing units are not kills. Player takeoff releases the Hind once using Start and opens its ROE. Native enroute tasks combine EngageGroup against the known friendly vehicle with EngageTargetsInZone for helicopters in the duel area. The script does not task the Hind directly against live player coordinates. Both sides know the fixed vehicle locations; air sensing and terrain masking remain native. A release message differs from the one-time report when inAir confirms the Hind airborne.

Ground-vehicle defense is active from mission start. The first ground-objective death ends the round: enemy technical destruction yields success, friendly technical destruction yields failure. Hind destruction is optional and does not end the round. Native DEAD/UNIT_LOST events resolve observed ordering and latch the result immediately; later deaths cannot reverse it. Polling remains a fallback, with friendly-loss precedence when both targets disappear without ordered events. Acquired player disappearance has a 10-second grace; no victory is awarded while the player is missing. Results are final once announced. Optional recovery is WP3; no smoke, boarding or landing requirement.

Flags: 950 success, 951 failure, 952 enemy vehicle destroyed, 953 enemy Hind destroyed. A mandatory site/controller error reports mission failure and the log reason. This does not certify AI flight or attacks just because native task calls succeeded.

## Information and player feedback

Labels off, friendly-only map. Fixed enemy-vehicle intelligence is deliberate: marker and separate Kiowa NavTargetPoints record 1T|1|UNK at the exact technical position. Enemy ground objective is not in the flight route. WP1 start, WP2 optional maneuver reference, WP3 own FARP. No enemy helicopter map marker, coordinates or scripted sensor reports.

One menu path: F10 Other > Duel > Status / objectives. It reports readiness, friendly objective survival and confirmed enemy losses. Ready, hunt release, actual Hind takeoff, each confirmed kill and final result are one-time text reports. No voice files, sensor copilot or support dispatch menus.

## First playable slice and native checks

Spawn/idle → takeoff and native Hind departure → optional Stinger helicopter engagement → enemy technical destruction and immediate win. Separately verify immediate friendly-target defeat, event ordering and rearming at both FARPs. See flight-checklist.md for starts, terrain, combat and fuel acceptance. Native AI behavior and concealment are central unverified mechanics.

## Regression and acceptance

Mock checks cover waiting indefinitely on the pad, one-time release versus actual takeoff, ground-only immediate victory, optional helicopter kill, ordered event races, logistics-loss exclusion, polling friendly-loss precedence, delayed/renamed player, acquired player loss, initial enemy absence, mandatory controller error, land/slope rejection, exact target record, routes/pads/loadout and non-disclosing status. Compiled native trees-only actions must precede both embedded scripts. Archive checks and native flight results are separate evidence.

- [ ] Build/archive and relevant mock checks recorded in verification.md.
- [ ] Both native ground starts, rotor/forest clearance and loadout performance accepted.
- [ ] Hind actually launches, attacks the defended vehicle and can engage the Kiowa.
- [ ] Stingers and gun can complete their intended tasks; both technicals defend themselves.
- [ ] Fixed sites, cover, cockpit target point and complete normal/failure sorties accepted.

## Open work

Flight-test balance and geometry before adding alternate sites, randomized starts, multiplayer or stronger weapons. Native combat tuning is expected to depend on observed results. No features from the collection's rescue missions are inherited implicitly.

## Ground Crew contact revision

After the full service camp also failed, the user identified the symptom as a missing Ground Crew menu or no answer, rather than out-of-stock supplies. Installed OH-58D comm.lua loads the common Ground Crew builder, which only offers that menu when native Unit:inAir() is false and selects the local/intercom communicator. Prior advice focusing on the ATC radio frequency was incomplete. BLUE departure therefore changes from an unlinked ground-area start on SINGLE_HELIPAD to a conventional FARP with explicit native player parking; RED/combat geometry remain unchanged. This is a diagnosis-driven configuration change, not a proven root cause or native fix. Status reports native LANDED/AIRBORNE even after the round; startup logs record player inAir, FARP registration and coalition. Read-only bridge status found DCS at its menu, so no live mission inspection was possible and no automatic mission load was performed. Full FARP spawn/crew response/replenishment require the next native check.
