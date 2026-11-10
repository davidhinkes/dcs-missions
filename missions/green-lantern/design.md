# Green Lantern design

## Intent

Single-player reconnaissance and rescue in an OH-58D, with useful AI wingmen and coordinated carrier support. The player searches, manages threats and extracts a survivor rather than clearing every enemy. Fictional Latakia-area scenario, Syria, 08:00 local, clear with light wind.

## Start, route and aircraft

- Two two-ship OH-58D flights fill HAVEN pads 1–4. RESCUE: player with PDU and one High-skill AI wingman on pads 1/2. LONGBOW: separate Excellent-skill AI pair on pads 3/4.
- RESCUE lead and both LONGBOW aircraft: two Hellfires and M3P .50-cal gun / 500 rounds. RESCUE wingman: gun plus seven M151 rockets. Fuel 270 kg each; capacity checked, gross weight/hover/endurance not certified.
- HAVEN: DCS planar x=19948.236328125, y=6806.8149414062, ground altitude 33.384346008301 m. Mission-table y corresponds to world z.
- WP2 IP (36000,13000); WP3 approximate search center (42000,16000); departure about 12.9 nm from search center, about nine minutes at 90 kt.
- WP4 LANTERN medical handover, about 25 nm southwest of extraction. WP4 is exactly the fixed landing pad at x=-1802.8537883092722, east=1000; it is never relocated. F10 marker and status directions identify the same site; no recovery smoke.
- Both FARPs have configured logistics support and warehouses. Actual ground-service behavior remains part of flight acceptance.

## Forces and coordination

| Flight / threat | Role and activation |
| --- | --- |
| GUARDIAN, 2 F/A-18Cs | Fighter sweep / cover; air-start at offshore marshal, released at player takeoff or early F10 request |
| WEASEL, 2 F/A-18Cs | Two HARMs each; air-start at marshal, released with GUARDIAN, radar SEAD task and F10 request |
| BRUISER, 2 F/A-18Cs | Four Mavericks each plus guns; air-start at marshal, released with GUARDIAN; holds until CAS requested |
| OVERLORD, E-2C | Mission-start launch, offshore AWACS orbit about 25,000 ft |
| VIPER, 2 MiG-29s | Activates 75 s after player crosses 6 km search gate |
| HIND-PATROL, 2 Mi-24Vs | Activates at 8 km gate; patrols east/south, helicopter engagement |
| Hunters | North/east/west pairs of DShK technicals; hunt starts at 8 km gate |
| Checkpoint / reinforcements | Two BRDMs + two trucks; two technicals + two trucks reinforce after 240 s |
| Coastal air defense | SA-6 radar + three launchers; separate Strela-10; support trucks |

USS Stennis is initially 70 nm northwest of extraction, moving west at 25 kt. Carrier flights are linked to it for departure/recovery. TACAN 74X, ICLS 11, ATC 127.500 AM. Main package frequency 251.000 AM; HAVEN 128.500 AM; LANTERN 127.500 AM.

Strike flights spawn airborne at marshal when released, so cover precedes the Kiowas (see Support timing — 2026-11-10). The IP hold remains the fallback if Guardian has not checked in. BRUISER requests select a 5 km snapshot area around the player's call position and queue until jets are within 20 km. Target assignment requires 700 m separation from Sparrow and all four Kiowas. Released weapons cannot be recalled. HARM success reports confirm a previously seen tracking radar's destruction, not elimination of every threat.

## Rescue state

1. Setup: WP3 is the centre of a 2.5 km search region. Pick one of four crash sites (centre (42000,16000); north (44000,15400); east (42400,18100); west (41600,14000)), each about 2.0–2.1 km from WP3 except the centre, in random order. Place a hidden stationary survivor on a safe site within 200 m of the chosen site, using bounded random sampling with constrained grid fallback; a site with no clearing falls through to the next, and only all four failing aborts setup. Every site disc lies inside the region and at least 5 km from Longbow's station, outside its 4 km breakoff. North/east hunters, the western patrol, checkpoint and reinforcements are placed relative to the actual pickup; north/east hunter placement is now optional, like the others. The F10 marker and a 2.5 km circle (if the DCS drawing API exists) stay at WP3. `GREEN_LANTERN_SITE` (1–4), set before the script loads, forces the first choice for tests or replay; the log records the chosen site.
2. Hunt: player crosses 8 km; ground patrols and Hinds activate. Air opposition uses the separate 6 km gate. Carrier early launch does not trigger pursuit.
3. Search: F10 Rescue > Contact Sparrow (direction fix) works within 15 km of Sparrow, at most every 30 s. It reports grid bearing from the player, rounded to 5 degrees, with uniform error ±min(20, 3 + 2 × range km) degrees, and range ±20% rounded to 0.5 km. The stated accuracy is included in the reply; the reply never names the site. No survivor smoke until requested within 2 km of Sparrow himself (previously 2 km of WP3). Green smoke indicates the actual site.
4. Pickup: landed, speed below 1 m/s, within 400 m. Hold 20 s within 100 m; beyond 100 m add `ceil((distance-100)/3)` seconds, maximum 120 s. Movement, flight or leaving radius resets the timer. Running/boarding is simulated, with no physical passenger animation.
5. Return: boarding removes survivor unit, sets flag 901, directs recovery at the fixed WP4 pad. Status offers return directions; no recovery smoke.
6. Complete: landed/stationary within 100 m of actual LANTERN pad for 15 s; flag 902. Failure flag 903 on player/survivor loss, capture (enemy within 80 m for 20 s), or 25 minutes after hunt starts without pickup. Flying continues after the result.

Implementation detail lives in `src/rescue.lua`; update these notes when changing behavior.

## Information and realism decisions

- Labels OFF; friendly-only F10 map. No exact survivor unit icon. Exact enemy names/counts are not exposed through custom menus.
- F10 has Rescue, Air Support and Overwatch submenus. Only survivor smoke is offered.
- FARP departure and separate FARP medical handover are preferred to a nearby airfield delivery.
- Larger pickup radius represents the survivor running to a safe landing site. This rescue is deliberately an abstraction in the Kiowa.
- Spotting dots were discussed but not enabled. Longbow overwatch is implemented as described below; sensor-specific target handoff and approximate contact reports remain unimplemented.

## Acceptance and verification

- [x] Source and data templates stored within project; no unrelated personal `.miz` dependency.
- [x] Latest pre-migration hot-start build passed archive validator, DCS Lua syntax checks and Mission Editor routine checks.
- [x] Prior rescue/menu revision passed the mock state-transition suite.
- [ ] Latest complete revision flown from hot start through pickup and LANTERN handover.
- [ ] Confirm all three pads, AI departure and FARP fuel/rearm/repair in the simulator.
- [ ] Observe Overlord deck launch, strike-package air starts at marshal, support arrival before the Kiowas, radar attack, CAS weapon use, MiG/Hind engagement and recovery.
- [ ] Confirm actual fuel consumption / reserve and loadout performance.

Migration verification is recorded in `verification.md`. Earlier user sorties established the rescue was enjoyable and completable on earlier builds; they do not certify later changes. Exact earlier DCS version and commit were not recorded.

## Open work

- Flight-check the latest combined revision before public release.
- Consider approximate contact reports to help locate ground vehicles without revealing exact targets.
- Flight-test the Longbow overwatch implementation below. Sensor-specific attack-designated-target and regroup interfaces remain proposals.
- Add briefing screenshots and optional voice audio after mission behavior stabilizes.

## F10 menu simplification — 2026-11-03

Removed the mission-name wrapper. Rescue and Air Support now open directly under F10 Other, saving one selection for every command. Command behavior and explicit clearance requirements are unchanged.

## Closer carrier — 2026-11-04

Moved STENNIS along its existing bearing from 90 to 70 nm from extraction (x=129830.706068462, east=-79353.53518100645). The westbound 40 km track translates with the ship; all four carrier flights retain linked launches/recoveries and updated deck positions. Guardian/Bruiser climb points remain relative to the carrier, while coastal SEAD and AWACS stations stay geographically fixed. Guardian's outbound route is about 70.01 nm / 9.4 minutes at 230 m/s versus 90.01 nm / 12.1 minutes previously, excluding launch/climb. Allow 12–18 minutes as an unmeasured launch/climb/transit planning range; BRUISER still launches 180 seconds later. Native ship placement and carrier flight operations require DCS acceptance.

## Two two-ship flights and fixed delivery — 2026-11-04

Longbow is a distinct two-unit AI group, uncontrolled hot until player takeoff starts its engines/flight. Runtime tasking sends it to an orbit centered 3 nm south of the approximate extraction point (x=36444, east=16000), at least 300 m above the sampled local terrain. This is an area orbit, not a precision hover or verified masked firing position. Normal wingman commands continue to control RESCUE-2 only.

The F10 Overwatch menu offers one requested vehicle attack within 2 km of the player call position, hold-fire/resume orbit and return to HAVEN. Tasking requires an airborne missile-equipped shooter, 6.5 km slant range, terrain visibility and more than 700 m from Sparrow/all four Kiowas. ATGM-only mask 131072 is confirmed in the installed Mission Editor action database. Native group attack uses one missile per participating shooter; duplicate shots and actual accuracy are not guaranteed. No automatic follow-on target is authorized. Watchdog cancels on unsafe proximity, target loss, 90 seconds elapsed or leader inside 4 km of Sparrow's actual position. Boarding/terminal result recalls Longbow; support loss/API errors do not fail the rescue. Pending requests and released weapons have distinct cancellation behavior.

The medical pad is fixed at WP4. Removed automatic blue smoke and its F10 command; retained green survivor smoke, marker/navigation cues and 15-second delivery hold. Logistics may seek nearby clear sectors, but never moves the pad itself. Native terrain fit, starts, orbit/attack geometry, missile guidance and recovery require a DCS sortie.

## Correcting overlapping starts — 2026-11-04

The user observed stacked helicopters and missing individual pads after the two-flight revision. All aircraft had identical coordinates and relied on parking indices across two groups; the earlier tests checked distinct indices rather than physical separation. Replaced the shared four-slot FARP with four explicit SINGLE_HELIPAD/FARP objects, IDs 100–103, in a 60 m square around HAVEN. Each aircraft starts at its matching pad at zero RADIO altitude with TakeOffGroundHot / From Ground Area Hot and no parking/start links. Both group origins/first waypoints match their leads. Four warehouses and all-pad service-distance checks cover the complete departure base. Native trees-only clearance precedes Lua; occupied pads remain fixed. Longbow recall uses pad 102 and its actual coordinates. Native simultaneous starts/AI takeoff and recovery still require flight verification.

## Support timing — 2026-11-10

User report: the carrier package took too long to reach the target; the player's Kiowa arrived first and was caught without cover. Root cause: GUARDIAN/WEASEL were deck-launched (hot parking) only at player takeoff, with a 70 nm transit, and BRUISER a further 180 s later. Estimated 12–18 minutes against roughly 6 minutes from HAVEN takeoff to the 8 km hunt gate at 90 kt.

Decision: keep STENNIS as the package's origin and recovery deck, but treat the strike flights as launched before the sortie. GUARDIAN, WEASEL and BRUISER are late-activated air starts at offshore marshal points and are released together (player takeoff or F10 Launch carrier package); BRUISER's 180 s delay is removed. OVERLORD still deck-launches at mission start.

| Flight | Marshal (x, east) / alt | Station | Straight-line estimate at 230 m/s |
| --- | --- | --- | --- |
| GUARDIAN | (30000, -25000) / 5500 m | RESCUE CAP over WP3 region centre | 42.7 km, 3.1 min |
| BRUISER | (24000, -20000) / 2500 m | CAS hold (33000, 8000) | 29.4 km, 2.1 min |
| WEASEL | (80000, -35000) / 5000 m | SEAD standoff (65000, -26000) | 17.5 km, 1.3 min |

Guardian's marshal and route keep at least 25 km from the SA-6 (the previous carrier route passed about 6 km from it) and are above Strela-10 reach; marshal points are separated by altitude and position. Orbit stop conditions grew because the jets no longer burn fuel on the deck launch and long transit: CAP and CAS 40 minutes, SEAD 30 minutes. The build asserts each strike flight reaches its station at least two minutes before the Kiowas reach the hunt gate; this is a straight-line estimate ignoring AI turns and acceleration, not a measured arrival. Native air-start behaviour, actual arrival times, fuel state on station and STENNIS recovery need a DCS sortie.

## Mission Planner policy — 2026-11-06

Enemy groups and their routes are hidden from the preflight Mission Planner; deliberately briefed search areas, objective markers and player target prepoints remain available. The full Mission Editor can still inspect authored assets. Native planner GUI confirmation remains pending. All red aircraft, ground, ship and static groups use hiddenOnPlanner/hidden/hiddenOnMFD. The shared deployment verifier checks the actual packed archive, independently of the in-flight F10 filter. No routes, target records or trigger zones are removed.
