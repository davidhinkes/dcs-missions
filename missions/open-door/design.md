# Operation Open Door

Status: first playable development build generated, checked and deployed locally on 2026-11-01. Native DCS flight acceptance is still pending.

## Intent and player experience

A Syria village hostage rescue. Several OH-58Ds depart a moderately distant FARP, defeat the guards and protect the landing area. An accompanying Black Hawk holds back until explicitly cleared by the player, lands an extraction team, waits through a timed simulated ground rescue, boards the hostages and departs.

The desired rhythm is reconnaissance, controlled attacks, clearance, a vulnerable extraction period and escort home. Ground reinforcements create pressure after the initial defenders are defeated.

## Confirmed decisions

- Syria map; player leads four hot-start OH-58Ds with a mix of Hellfires, guns and rockets. Lead/#2 carry two Hellfires plus gun; #3/#4 carry gun and seven M151 rockets. Each Kiowa carries 300 kg fuel (capacity checked; performance/endurance not flight-certified).
- Depart from a FARP about 25 nm from the village: roughly 17 minutes inbound at 90 knots before maneuvering or holding.
- Hostages are vulnerable to gunfire and nearby explosions. Careful target identification and weapon employment matter.
- Village setting with scattered guards, ground reinforcements, heavy machine guns and one nearby Strela-10 (SA-13) short-range guided SAM. This replaces the earlier ZU-23 choice.
- Black Hawk accompanies the operation but hangs back outside the rescue area.
- Player explicitly clears Black Hawk ingress through F10 after assessing the threats.
- Kiowas defeat the guards; the extraction team conducts a timed simulated rescue rather than a scripted infantry battle.
- The Black Hawk lands for about three minutes to deploy the team, secure six hostages and board everyone, then leaves.
- Rescue continues if a hostage is killed. Report full or partial success according to the survivors brought home.
- Four Kiowas and one Black Hawk only: no friendly jets or enemy aircraft.
- Escort the Black Hawk back to the departure FARP for recovery.
- Labels off and friendly-only F10 unit visibility. Precise satellite intelligence identifies the hostage building and one air-defense site; both have named preplanned navigation points, briefing coordinates and static intelligence markers. This supersedes the earlier approximate compound marker. Other enemy positions remain undisclosed.

## Implemented behavior — native AI flight verification pending

- Use DCS's built-in AI UH-60A, confirmed present in the local unit database. No additional player-flyable helicopter module is intended. Its AI landing and departure behavior needs a dedicated flight check.
- F10 Transport orders: clear to land, hold / wave off, abort and return. Rescue submenu: status and green LZ smoke. Clearance requires player within 10 km, known Strela destroyed, and no defenders within 400 m of the LZ or 350 m of the building.
- A prepared landing site outside the village avoids having the transport land among buildings. The ground team's movement and hostage boarding are simulated with a timer and messages; do not promise native visible passenger animations.
- Once cleared, the transport approaches; a clear landing/grounded condition starts the rescue timer. A local threat forces a wave-off; movement/takeoff or leaving the 80 m LZ radius resets the three-minute timer. Guard defeat, player clearance, transport arrival, rescue completion and return are separate states.
- Enemy units and player-facing replies must be designed together so missions do not accidentally disclose unbriefed enemy identities, counts or live positions. The explicitly briefed air-defense site is an intelligence exception.
- Recover to the departure FARP complex with separate transport parking. Count success on return, not merely when the Black Hawk leaves the village.

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

## Geography and timing

Departure FARP KEYSTONE deliberately reuses an observed DCS pad position (x=19948.236328125, east=6806.8149414062, elevation=33.384346008301 m). Its transport pad is offset 300 m south and 180 m west. Four visible native SINGLE_HELIPAD objects are positioned 60 m apart; the Black Hawk has a fifth. All aircraft use explicit TakeOffGroundHot / From Ground Area Hot, with zero RADIO altitude and no conflicting parking links. Native ground starts resolve terrain height independently of the copied BARO elevation. Direct departure-to-building distance is 24.96 nm, about 17 minutes at 90 knots. New compound placement, transport-pad ground elevation and native AI flight behavior still require a DCS sortie. At runtime the actual LZ is searched within 1500 m of planned x=63750, east=20200, rejecting water, excessive slope and scenery obstacles using an 18 m rotor-clearance radius; known target objects never relocate. Locate the transport hold behind friendly cover, not simply at an arbitrary range. The round trip is approximately 50 nm (about 34 minutes at 90 knots), plus reconnaissance, fighting, three minutes on the ground, holding and recovery. Compute final timings and fuel from actual routes. The revised FARP uses five separate visible native single helipads: four at 60 m spacing for the Kiowas and a separate transport pad. Start-time fuel/ammunition trucks, ground-crew Hummers, fuel depots, ammunition canopies, repair tents and command posts serve the installation. Each pad has an unlimited warehouse entry.

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
