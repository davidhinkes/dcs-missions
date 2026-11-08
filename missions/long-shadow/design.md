# Operation Long Shadow design

## Intent and player experience

A covert, single-Kiowa convoy interception in western Syria. A fictional high-value target, MAGPIE, is driven from Homs to Hama on the M5 in a small escorted convoy. The pilot knows the departure area, the destination, the rough route and a proposed attack point, but nothing else is planned for them. They decide in the Mission Planner where to fly, where to hide and where to shoot from, then find the convoy, identify the right vehicle, follow it and strike before it reaches Hama. An MQ-9 overhead calls out the convoy's progress relative to the proposed attack point, which turns the wait into a timed ambush. Expected duration 30–50 minutes.

## Confirmed user choices (2026-11-08 request)

- Assassination-style mission: approach a convoy whose departure and rough route are known; destroy one specific member.
- HVT moved from one Syrian city to another; backstory invented (fictional).
- Player aircraft OH-58D; covert navigation, track, follow and destroy.
- A control/target point showing where the convoy is likely to pass, and **no other waypoints**, so the Mission Planner is part of the game.
- A drone in the area that calls out how far the convoy is from the proposed attack point.

## Decisions made for the first slice (not user-mandated; revisit freely)

- Route Homs → Hama on the M5; proposed attack point at the expected Orontes crossing north of Ar-Rastan (a natural choke point).
- Start hot on the ground at a covert single-pad FARP (JUNIPER) on the Houla plain, ~9.7 nm west of 1T, ~10 nm from the road.
- Two Hellfires + M3P gun, 181.4 kg (~400 lb) fuel — the collection's previously accepted armed-Kiowa fuel figure; not a performance certification.
- Success on MAGPIE kill; no required recovery. No time limit other than MAGPIE's arrival.
- Departure random between H+4 and H+8 minutes (briefed as a window).
- A convoy that is hit or opens fire speeds up and runs for Hama (simple, legible "you've been made" consequence).
- No civilian traffic, roadblocks, decoys or additional enemy forces yet.

## Requirements and start

Syria terrain and OH-58D. MQ-9 and all convoy vehicles are built-in AI. Single player. Player SHADOW-1 (Anvil 3-1) on SINGLE_HELIPAD ID 200 (FARP JUNIPER, 127.500 AM), TakeOffGroundHot / From Ground Area Hot, alt 0 RADIO, no parking link (the pattern used by Open Door / Green Lantern starts). A 150 m native trees-only clearing precedes the scripts. No ground services, warehouse stock or rearm promise. UHF preset 1 251.000; VHF AM preset 1 127.500.

## Geography and timing

Source of truth: WGS84 lat/lon in `src/config.json`, converted offline with `src/projection.mjs` (transverse Mercator, central meridian 39°E, k0 0.9996, false easting 282801 m, false northing −3879866 m — the pydcs Syria parameters). Sanity check: the converter puts the previously flown HAVEN site (x=19948, y=6806, observed ground 33 m) just inland of Baniyas and Open Door's FOOTHOLD in the foothills east of Jableh, consistent with the real map. Points are real-world estimates, not DCS terrain/road samples.

| Point | Lat/lon | Note |
| --- | --- | --- |
| FARP JUNIPER | 34.8780 N 36.5420 E | Houla plain; terrain unchecked |
| Convoy start | 34.7880 N 36.7215 E | M5 at Homs northern exit |
| Talbiseh | 34.8420 N 36.7290 E | route shaping point on the M5 |
| 1T proposed attack point | 34.9340 N 36.7270 E | expected M5 Orontes crossing |
| Destination | 35.0950 N 36.7360 E | Hama southern entrance |
| Pontiac orbit | 34.8800 N 36.7700 E | ~4 km east of the M5 |

Straight-line legs: FARP→1T 9.73 nm (~6.5 min at 90 kt); convoy start→1T 8.75 nm; 1T→Hama 9.66 nm; FARP→Hama 16.1 nm. Convoy 13.9 m/s (50 km/h, 27 kt): ~19 min start→1T, ~21 min 1T→Hama. With the H+4–8 departure, the convoy should reach 1T around H+23–27 and Hama around H+44–48 if undisturbed; alerted speed 20 m/s (72 km/h) shortens the remaining time by about 30%. Fuel: 400 lb is expected to cover ~10 nm out, loiter and return, but the reserve must be checked in the cockpit.

## Forces

- MAGPIE CONVOY (red, Good skill, late activation, hidden on planner/map/MFD): BRDM-2 lead, tt_DSHK, **UAZ-469 "MAGPIE HVT"** (third), Ural-375, Ural-375 ZU-23 (rear). ROE open fire, dispersal-under-fire disabled so it keeps driving. On Road route: Homs north → Talbiseh → 1T → Hama south at 13.9 m/s.
- PONTIAC (blue MQ-9 Reaper, Excellent): airborne at mission start at 5,500 m (18,000 ft) MSL, 70 m/s, Circle orbit at its start point, ROE weapon hold, no weapons. Above ZU-23/HMG reach.
- No other units.

## Mission state and interactions

Phases: `waiting` (player not yet seen) → `ready` → `rolling` (convoy activated) → `won` / `failed` (latched).

- Departure: Lua activates the convoy at `departAt = load time + delay`, delay uniform in [240, 480] s unless `LONG_SHADOW_DEPARTURE_DELAY` is set. If activation errors or MAGPIE has not appeared 30 s after activation, the mission reports a setup failure (no false win).
- Success: MAGPIE destroyed after it was seen alive (polling or S_EVENT_DEAD/UNIT_LOST, first observed wins). Flags 960 + 962.
- Failure: MAGPIE within 600 m of the destination; player death event; acquired player missing >10 s. Flag 961. No win while an acquired player is missing. Initial player delay is tolerated.
- Alert: first S_EVENT_HIT on a convoy unit, S_EVENT_SHOT/SHOOTING_START by a convoy unit, or an escort death after departure. One-time re-route from MAGPIE's position (via 1T if not yet passed) to Hama, On Road, 20 m/s. Re-route errors are logged and the convoy keeps its route; this never affects the result.
- Escort losses never end the round.

## Information and player feedback

- Labels off; friendly-only F10 map; all red groups hidden on the Mission Planner (shared helper + packed-archive check).
- Player flight plan: start point only. Kiowa target point 1T (`1T|1|UNK`) at the proposed attack point; it is not on any player route.
- Briefing: backstory, departure/destination/1T in degrees-decimal-minutes, departure window, order of march, threat ranges, alert behaviour, distances from JUNIPER.
- F10 markers after the player is seen: 1T, departure area, destination, FARP. Markers are not waypoints.
- Messages are coalition text (no audio). One-time: mission ready; Pontiac on station; departure; MAGPIE result.

## Support and player-feedback contract — Pontiac

| Item | Contract |
| --- | --- |
| Start | Airborne on station at mission start, 18,000 ft MSL, orbiting east of the M5. No transit, no dispatch command. |
| Knowledge | Scripted: while Pontiac is alive it "sees" MAGPIE. No sensor/LOS simulation. |
| Automatic calls | Departure (once, with composition and position in column); road distance short of 1T at 8, 6, 4, 3, 2, 1 nm (once each, tightest newly crossed threshold only); "passing 1T" (once); distance from Hama at 6, 4, 2, 1 nm (once each); convoy alerted (once). Each call: distance, label `by road` (DCS `land.findPathOnRoads`) or `direct` (fallback, labelled), speed in knots and ETA, or `convoy halted` below 2 m/s. |
| Passing rule | MAGPIE within 300 m of 1T, or more than 400 m farther than its closest approach after coming within 1.5 km. Latched. |
| On demand | F10 Other > Pontiac > Convoy report (one submenu, one command): pre-departure status, current progress, escorts remaining, alerted/unaware; mission result after the end. |
| Never | Coordinates, bearings, lasing, weapon release, internal unit names. |
| Loss / fault | Pontiac dead → one-time "Pontiac lost" and the report command says unavailable. Any Lua/API fault in drone reporting disables Pontiac reports with one message; departure, alert and result logic continue. |

## First playable slice and native flight checks

Spawn at JUNIPER → fly own plan to the M5 → Pontiac departure call → find and identify the UAZ → Hellfire or gun kill → success. Separately: let MAGPIE escape; trigger the alert dash; lose the drone. See [flight-checklist.md](flight-checklist.md). The highest-risk unverified items are the real coordinates against DCS roads (convoy start, 1T crossing), the late-activated convoy actually driving the M5, the FARP site terrain, and the UAZ-469 / Ural-375 ZU-23 type names (not previously used in this collection).

## Regression and change impact

Mock checks (tests/shadow-test.lua) cover departure hold and window, full call sequence and ordering, no repeats, escape, polling and event kills, event ordering, posthumous-win prevention, escort loss as alert only, alert sources and pre-departure immunity, pre/post-1T re-routes, drone loss and fault isolation, direct-distance labelling, activation/spawn failure, delayed/renamed/missing player, uneven pad warning, report non-disclosure, markers and the built-mission contract (one route point, 1T, loadout, convoy composition/route/planner hiding, unarmed orbiting drone, trees-only clearing order). Changing coordinates changes timing, fuel and briefing numbers together — they are generated, but re-read them.

## Acceptance criteria

- [x] Build and archive validation pass (offline, Linux Lua 5.1 — see verification.md).
- [x] Mission logic mock tests pass.
- [ ] Starts on JUNIPER pad cleanly; site level and clear.
- [ ] Loadout supports takeoff/hover and the sortie with reserve.
- [ ] Convoy spawns on the M5 at Homs north, drives the M5 through 1T to Hama; 1T sits on the road crossing.
- [ ] Pontiac orbits and its calls match what the pilot sees.
- [ ] Hellfire/gun kill of the UAZ registers success; escape registers failure; alert dash happens.
- [ ] Complete sortie flown.

## Open work

Possible later additions, after the first sortie: civilian traffic or a decoy vehicle (real identification problem), a checkpoint near Hama, randomised departure point or alternate route, a stronger covert-detection mechanic (e.g. convoy spotting the Kiowa before shots), FARP services. None are implemented.
