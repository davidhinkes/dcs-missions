# Operation Open Door

Status: first playable development build generated, checked and deployed locally on 2026-11-01. Native DCS flight acceptance is still pending.

## Intent and player experience

A Syria village hostage rescue. Several OH-58Ds depart a moderately distant FARP, defeat the guards and protect the landing area. An accompanying Black Hawk holds back until explicitly cleared by the player, lands an extraction team, waits through a timed simulated ground rescue, boards the hostages and departs.

The desired rhythm is reconnaissance, controlled attacks, clearance, a vulnerable extraction period and escort home. Ground reinforcements create pressure after the initial defenders are defeated.

## Confirmed decisions

- Syria map; player leads four hot-start OH-58Ds with a mix of Hellfires, guns and rockets. Lead/#2 carry two Hellfires plus gun; #3/#4 carry gun and seven M151 rockets. Each Kiowa carries approximately 400 lb (181.4 kg) of fuel (capacity checked; performance/endurance not flight-certified).
- Depart from FARP FOOTHOLD 15 nm from the village: roughly 10 minutes inbound at 90 knots before maneuvering or holding.
- Hostages are vulnerable to gunfire and nearby explosions. Careful target identification and weapon employment matter.
- Village setting with scattered guards, ground reinforcements, heavy machine guns and one nearby Strela-10 (SA-13) short-range guided SAM. This replaces the earlier ZU-23 choice.
- Black Hawk accompanies the operation but hangs back outside the rescue area.
- Player explicitly clears Black Hawk ingress through F10 after assessing the threats.
- Kiowas defeat the guards; the extraction team conducts a timed simulated rescue rather than a scripted infantry battle.
- The Black Hawk lands for about three minutes to deploy the team, secure six hostages and board everyone, then leaves.
- Rescue continues if a hostage is killed. Report full or partial success according to the survivors brought home.
- Four Kiowas, one Black Hawk and one unarmed MQ-9 designator; no friendly combat jets or enemy aircraft.
- Escort the Black Hawk back to the departure FARP FOOTHOLD for recovery.
- Labels off and friendly-only F10 unit visibility. Precise satellite intelligence identifies the hostage building and one air-defense site; both have named preplanned navigation points, briefing coordinates and static intelligence markers. This supersedes the earlier approximate compound marker. Other enemy positions remain undisclosed.

## Implemented behavior — native AI flight verification pending

- Use DCS's built-in AI UH-60A, confirmed present in the local unit database. No additional player-flyable helicopter module is intended. Its AI landing and departure behavior needs a dedicated flight check.
- F10 Transport orders: clear to land, hold / wave off, abort and return. Rescue submenu: status and green LZ smoke. Clearance requires player within 10 km, known Strela destroyed, and no defenders within 400 m of the LZ or 350 m of the building.
- A prepared landing site outside the village avoids having the transport land among buildings. The ground team's movement and hostage boarding are simulated with a timer and messages; do not promise native visible passenger animations.
- Once cleared, the transport approaches; a clear landing/grounded condition starts the rescue timer. A local threat forces a wave-off; movement/takeoff or leaving the 80 m LZ radius resets the three-minute timer. Guard defeat, player clearance, transport arrival, rescue completion and return are separate states.
- Enemy units and player-facing replies must be designed together so missions do not accidentally disclose unbriefed enemy identities, counts or live positions. The explicitly briefed air-defense site is an intelligence exception.
- Recover to the departure FARP FOOTHOLD complex with separate transport parking. Count success on return, not merely when the Black Hawk leaves the village.

## Build choices

- The hostage compound is a deliberately authored fictional village: one protected house and three surrounding structures, not a claim about a particular existing scenery building. Fixed compound x=64200, east=20150; Strela x=63600, east=18100. These sites still need visual/terrain flight acceptance.
- Six disabled neutral infantry figures represent hostages. Their building and surrounding structures are neutral and disabled so guards do not attack them before the rescue arrives. Models are stand-ins; no passenger animation is promised. Destruction of the hostage building kills its remaining occupants.
- Initial opposition: one Strela-10, two DShK technicals and four infantry. At an 8 km player alert gate, a 180 s reinforcement timer begins; two technicals and two trucks then advance from the village approaches. Their travel time is additional.
- Black Hawk starts uncontrolled/hot on its own visible pad using zero-AGL ground start (recovery remains linked to that pad). Player takeoff starts a native Follow task; when the player crosses 12 km from the building, it is tasked to hold outside the SAM area. Only explicit clearance assigns the native temporary Land task.
- Rescue completes after 180 continuous landed seconds, within 80 m and below 1 m/s. Survivors are counted at boarding, their stand-in units removed, and the Black Hawk receives a recovery route to its linked departure pad.
- Recovery requires a 20 s stationary landing within 120 m of the transport pad: six aboard = full success; one to five = partial success; zero = failure. Player loss, Black Hawk loss or no surviving hostages fails the mission. Passenger loss follows Black Hawk loss after boarding. No arbitrary global mission timer.
- Abort before boarding returns empty; wave-off permits retry after fresh clearance. After boarding both commands return the passengers home.
- Flags: 920 boarded, 921 full success, 922 partial success, 923 failure. The simulation continues after the result.

## Preplanned intelligence points

- **HOSTAGE BUILDING:** exact identified building, distinct from the transport landing zone. Brief it as a protected location; a navigation reference does not authorize firing on it.
- **STRELA-10:** exact satellite-reported launcher position; Kiowa target point `1T`, imported using `1T|1|SA13`.
- **HOSTAGE BUILDING:** also imported as Kiowa target point `2T`, using `2T|1|UNK`. Both points can be selected through MMS PREPT / R2 PPT; cockpit import and alignment still need in-game confirmation.
- Points are briefing-time intelligence, not live enemy tracking. Markers do not follow units, disappear automatically on kills or reveal moving reinforcements.
- Keep the Black Hawk's flight route through safe staging and its landing zone. Target reference points must not route the transport over the air-defense site or force Kiowas to overfly it.

## Bases, route and timing

FOOTHOLD was first requested as an additional refueling site 15 nm from the village, then promoted by the user to the actual departure/recovery base. Anchor x=37602.80390745693, east=12130.177058387671. Four fixed visible native single helipads are 60 m apart; the Black Hawk's separate pad is 300 m south and 180 m west. Both use zero-AGL native hot-ground starts. No setup function moves the occupied departure pads. Main FARP radio 129.500 AM; transport pad 129.000 AM.

Fuel/ammo/crew vehicles, depots/canopies, repair tents and command posts are available from mission start. Native pad IDs 100–103 and 200 have unlimited warehouses. All four Kiowas retain approximately 400 lb fuel. Actual new-site terrain/servicing needs a DCS check.

KEYSTONE is retained near the former departure site, about 25 nm from the village (roughly 10 nm behind FOOTHOLD). Its complete unoccupied camp footprint is checked for land, slope, scenery and ground-height spread, searching within 1 nm. If suitable, all alternate objects/support are placed together, retaining warehouse IDs 400–403. The actual F10 marker is authoritative. Failed alternate preparation is reported without failing the rescue. Radio 128.500 AM. KEYSTONE does not satisfy mission recovery.

Route: WP1 FOOTHOLD, WP2 IP/hold, WP3 planned LZ, WP4 FOOTHOLD/home. Enemy building and SAM are solely separate target points 1T/2T plus static intelligence markers. No enemy site lies on the flight route. Direct outbound distance is exactly 15 nm, about ten minutes at 90 knots; round trip about 30 nm / 20 minutes before holding, fighting and three-minute rescue. Expected sortie roughly 30–45 minutes.

The fictional village remains at x=64200, east=20150; Strela at x=63600, east=18100. The actual LZ is searched within 1500 m of x=63750, east=20200, using land/slope and 18 m scenery-clearance checks. Fixed intelligence objects never relocate. Team movement/boarding remains a timed abstraction.

## Acceptance criteria

- [x] Mission design choices reflected in source/briefing.
- [ ] Player and wingmen occupy valid FARP pads with intended loadouts.
- [x] Automated checks confirm fixed target-point coordinates and map/label settings; cockpit import/visibility still need flight acceptance.
- [x] Mock tests confirm no automatic extraction clearance after defender destruction; native flight path remains unverified.
- [x] Mock tests cover wave-off, fresh clearance and empty abort return.
- [x] Mock tests enforce landed, speed, distance and continuous-timer requirements.
- [ ] Reinforcements and anti-air defenses produce the intended extraction pressure.
- [x] Mock tests cover hostage losses, building destruction and partial rescue.
- [x] Boarding, extraction, return, success and failure cases have automated coverage.
- [x] Archive validation and simulated logic checks pass.
- [ ] A DCS flight verifies Black Hawk landing/departure, terrain, AI engagement and full rescue completion.

## Verification record

2026-11-01: first development build passed all 21 printed logic scenarios under installed DCS Lua; zero validator errors/warnings; Mission Editor load-fixup check (49 units); all three compiled trigger chunks valid; route/geometry checks passed. Built and deployed to the local DCS Missions folder with SHA-256 verification. No in-game sortie performed. See `verification.md`.

## FOOTHOLD tree clearance

After the reported tree-covered departure, five native SCENERY REMOVE OBJECTS ZONE actions (TREES ONLY, mask 1) prepare FOOTHOLD at mission start before the Lua loader. A 260 m radius clearing centered 90 m along the Kiowa pad row covers pads and facilities; a separate 220 m clearing covers Lifeline's pad/camp. Three overlapping 150 m circles extend a continuous initial 600 m departure lane toward the IP. Buildings, ground shape and occupied-pad coordinates are preserved. Native appearance/collision clearance needs a restarted DCS mission check.

## F10 menu simplification — 2026-11-03

Removed the mission-name wrapper. Transport and Rescue now open directly under F10 Other, saving one selection for every command. Command behavior and explicit clearance requirements are unchanged.

## Sentinel drone support — 2026-11-03

An unarmed MQ-9 stages 15 nm from the objective at 20,000 ft MSL. It automatically heads overhead when the mission starts; no dispatch command is needed. Allow roughly seven minutes at 70 m/s; native AI flight determines actual arrival. Once within 2.5 km of the objective and 500 m of its assigned altitude, it announces readiness. High altitude reduces short-range threat exposure but does not guarantee concealment.

Use **Designate next target**, **Laser status**, and **Stop lasing** in the same Drone menu. Match your Hellfire seeker to **1688**, follow the Kiowa's remote-laser engagement procedure, and positively identify the target. Requests cycle through eligible hostile ground units, starting with the known SAM. Terrain line of sight and 15 km slant range are required. Targets within 100 m of hostages/their building or 300 m of friendly helicopters are excluded; these buffers do not guarantee safe weapon effects. No auto-fire or automatic Black Hawk clearance. Target death, masking, unsafe proximity, station departure or drone loss stops lasing; request a new designation. The drone is optional and its loss does not fail the rescue. Native orbit, obstruction by structures/vegetation and remote laser acquisition need an actual DCS flight check.

### Drone reliability and target reports

Optional drone tasking or laser API errors disable Sentinel support without failing the rescue. Sentinel announces its initial arrival once. It enters station within 2.5 km / 500 m of assigned altitude and remains on station until beyond 4 km / 750 m; leaving the envelope stops designation. Laser status explicitly reports a lost/unavailable drone. Target reports give decimal-degree latitude/longitude and true bearing/range in nautical miles from the lead Kiowa. If geographic conversion is unavailable, bearing is explicitly labeled grid. Native orbit and remote-laser engagement still need a DCS flight check.

### Target talk-ons and Lifeline progress

Sentinel's laser reports describe a generic vehicle/infantry target and its approximate grid direction/distance from the hostage building, followed by coordinates and Kiowa-relative bearing/range. They do not claim unverified road or scenery landmarks. Lifeline reports final approach within 1.5 km, landed rescue start, halfway through each uninterrupted rescue attempt, timer interruption, actual airborne return with survivor count, and recovery approach within 2 km. These are on-screen messages, not recorded voice audio. Existing menus and explicit landing clearance are unchanged.
