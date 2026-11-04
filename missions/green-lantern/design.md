# Green Lantern design

## Intent

Single-player reconnaissance and rescue in an OH-58D, with useful AI wingmen and coordinated carrier support. The player searches, manages threats and extracts a survivor rather than clearing every enemy. Fictional Latakia-area scenario, Syria, 08:00 local, clear with light wind.

## Start, route and aircraft

- Three hot-start Kiowas on numbered pads 1–3 of four-pad FARP HAVEN. Lead is `RESCUE-1` / Anvil 1-1, with PDU; wingmen High skill.
- Lead and #2: two Hellfires and M3P .50-cal gun / 500 rounds. #3: gun plus seven M151 rockets. Fuel 270 kg each; tank capacity checked, gross weight/hover/endurance not certified.
- HAVEN: DCS planar x=19948.236328125, y=6806.8149414062, ground altitude 33.384346008301 m. Mission-table y corresponds to world z.
- WP2 IP (36000,13000); WP3 approximate search center (42000,16000); departure about 12.9 nm from search center, about nine minutes at 90 kt.
- WP4 LANTERN medical handover, about 25 nm southwest of extraction. Final pad is terrain-cleared dynamically; marker, smoke and status directions identify it.
- Both FARPs have configured logistics support and warehouses. Actual ground-service behavior remains part of flight acceptance.

## Forces and coordination

| Flight / threat | Role and activation |
| --- | --- |
| GUARDIAN, 2 F/A-18Cs | Fighter sweep / cover, launches at player takeoff or early F10 request |
| WEASEL, 2 F/A-18Cs | Two HARMs each; launches with GUARDIAN, radar SEAD task and F10 request |
| BRUISER, 2 F/A-18Cs | Four Mavericks each plus guns, launches 180 s after GUARDIAN; holds until CAS requested |
| OVERLORD, E-2C | Mission-start launch, offshore AWACS orbit about 25,000 ft |
| VIPER, 2 MiG-29s | Activates 75 s after player crosses 6 km search gate |
| HIND-PATROL, 2 Mi-24Vs | Activates at 8 km gate; patrols east/south, helicopter engagement |
| Hunters | North/east/west pairs of DShK technicals; hunt starts at 8 km gate |
| Checkpoint / reinforcements | Two BRDMs + two trucks; two technicals + two trucks reinforce after 240 s |
| Coastal air defense | SA-6 radar + three launchers; separate Strela-10; support trucks |

USS Stennis is initially 70 nm northwest of extraction, moving west at 25 kt. Carrier flights are linked to it for departure/recovery. TACAN 74X, ICLS 11, ATC 127.500 AM. Main package frequency 251.000 AM; HAVEN 128.500 AM; LANTERN 127.500 AM.

Shorter helicopter departure means early carrier launch and an IP hold are needed for coordination. Allow roughly 12–18 minutes for launch/climb/transit; this is a planning estimate, not a measured guarantee. BRUISER requests select a 5 km snapshot area around the player's call position and queue until jets are within 20 km. Target assignment requires 700 m separation from Sparrow and all three Kiowas. Released weapons cannot be recalled. HARM success reports confirm a previously seen tracking radar's destruction, not elimination of every threat.

## Rescue state

1. Setup: place a hidden stationary survivor on a safe site within 200 m of WP3. Bounded random sampling with constrained grid fallback. Fixed search marker stays at WP3.
2. Hunt: player crosses 8 km; ground patrols and Hinds activate. Air opposition uses the separate 6 km gate. Carrier early launch does not trigger pursuit.
3. Search: no survivor smoke until requested within 2 km of the search area. Green smoke indicates the actual site.
4. Pickup: landed, speed below 1 m/s, within 400 m. Hold 20 s within 100 m; beyond 100 m add `ceil((distance-100)/3)` seconds, maximum 120 s. Movement, flight or leaving radius resets the timer. Running/boarding is simulated, with no physical passenger animation.
5. Return: boarding removes survivor unit, sets flag 901, marks recovery with blue smoke and renews it every 240 s. Status offers return directions.
6. Complete: landed/stationary within 100 m of actual LANTERN pad for 15 s; flag 902. Failure flag 903 on player/survivor loss, capture (enemy within 80 m for 20 s), or 25 minutes after hunt starts without pickup. Flying continues after the result.

Implementation detail lives in `src/rescue.lua`; update these notes when changing behavior.

## Information and realism decisions

- Labels OFF; friendly-only F10 map. No exact survivor unit icon. Exact enemy names/counts are not exposed through custom menus.
- F10 has Rescue and Air Support submenus. Smoke requests are separate for survivor and recovery.
- FARP departure and separate FARP medical handover are preferred to a nearby airfield delivery.
- Larger pickup radius represents the survivor running to a safe landing site. This rescue is deliberately an abstraction in the Kiowa.
- Spotting dots were discussed but not enabled. New wingman tactics and approximate contact reports were proposed but not implemented.

## Acceptance and verification

- [x] Source and data templates stored within project; no unrelated personal `.miz` dependency.
- [x] Latest pre-migration hot-start build passed archive validator, DCS Lua syntax checks and Mission Editor routine checks.
- [x] Prior rescue/menu revision passed the mock state-transition suite.
- [ ] Latest complete revision flown from hot start through pickup and LANTERN handover.
- [ ] Confirm all three pads, AI departure and FARP fuel/rearm/repair in the simulator.
- [ ] Observe carrier launches, support arrival, radar attack, CAS weapon use, MiG/Hind engagement and recovery.
- [ ] Confirm actual fuel consumption / reserve and loadout performance.

Migration verification is recorded in `verification.md`. Earlier user sorties established the rescue was enjoyable and completable on earlier builds; they do not certify later changes. Exact earlier DCS version and commit were not recorded.

## Open work

- Flight-check the latest combined revision before public release.
- Consider approximate contact reports to help locate ground vehicles without revealing exact targets.
- Consider separate wingman overwatch/rocket support roles and simple cover-pickup / attack-designated-target / regroup commands. These are proposals requiring investigation and DCS testing.
- Add briefing screenshots and optional voice audio after mission behavior stabilizes.

## F10 menu simplification — 2026-11-03

Removed the mission-name wrapper. Rescue and Air Support now open directly under F10 Other, saving one selection for every command. Command behavior and explicit clearance requirements are unchanged.

## Closer carrier — 2026-11-04

Moved STENNIS along its existing bearing from 90 to 70 nm from extraction (x=129830.706068462, east=-79353.53518100645). The westbound 40 km track translates with the ship; all four carrier flights retain linked launches/recoveries and updated deck positions. Guardian/Bruiser climb points remain relative to the carrier, while coastal SEAD and AWACS stations stay geographically fixed. Guardian's outbound route is about 70.01 nm / 9.4 minutes at 230 m/s versus 90.01 nm / 12.1 minutes previously, excluding launch/climb. Allow 12–18 minutes as an unmeasured launch/climb/transit planning range; BRUISER still launches 180 seconds later. Native ship placement and carrier flight operations require DCS acceptance.
