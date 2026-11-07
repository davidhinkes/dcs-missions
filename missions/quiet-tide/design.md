# Operation Quiet Tide design

## Intent and player experience

A restrained dawn reconnaissance/insertion sortie, distinct from a hostage rescue. The Kiowa lead decides whether the site is safe; the transport carries six SEALs who remain behind enemy lines. Ship departure and recovery are central. Current implementation is the first native-mechanic test slice, not a completed stealth campaign.

## Requirements and start

Syria, OH-58D; single-player lead with AI wingman. Two hot-start Kiowas and built-in AI UH-60A use Tarawa deck slots 1/2/3 linked to the ship unit. Two AI Hornets use Stennis slots 1/2. No mod or Supercarrier requirement intended; actual slot geometry/height/compatibility require DCS. Lead gun/two Hellfires, wingman gun/seven rockets, each 181.4 kg fuel. Capacity compliance is not loaded-weight, hover or endurance certification.

## Geography and timing

Syria local 05:45, 15 June 2026. Tarawa starts x=42000/east=-25000, Stennis x=50000/east=-33000; both proceed north on steady routes at 6 and 10 m/s. Planned LZ x=42000/east=16000; offshore hold x=42000/east=-10000. Coordinates are DCS planar metres (world z corresponds to mission y). Route, coastline, sunrise visibility and sea placement require native inspection. Runtime setup rejects non-water initial ship positions.

The initial direct route is 22.1 nm, about 15 minutes at 90 kt each way before maneuvers. Briefed duration 35–45 minutes; actual moving-ship recovery changes distance. These estimates revise the earlier shorter concept to match configured geometry. Validate fuel reserve in flight. Occupied ship starts never relocate through script; the LZ searches up to 1 km for land/slope/20 m scenery clearance. No trees-removal zone is assumed to prove an actual landing site.

## Forces and roles

ANVIL: two Kiowas, reconnaissance/escort. LIFELINE: one AI UH-60A, six abstract passengers, transport holds fire. SWORD: two Maverick-armed Hornets from Stennis, optional requested single-target support. Ground opposition: two hidden DShK technicals and four infantry around the insertion region. No hostile aircraft or SAM claimed in this first slice. Enemy identities/counts are design information, not revealed in player-facing callbacks.

## Support and interaction contract

SWORD launch is requested automatically at setup and follows its native route to coastal support orbit; no claim of observed launch from a task call. ROE holds fire until one strike is requested. One request expires in 90 seconds, waits for a surviving shooter within 20 km, searches known hostiles within 2.5 km of the LZ and excludes targets within 700 m of all three helicopters. Revalidate while assigned, stop on unsafe proximity/death/timeout, and block follow-ons after insertion. Optional native API failures disable support with best-effort hold-fire cleanup. No laser guidance, guaranteed hits or recall of released weapons. Hornet recovery is available through a separate linked RTB command.

LIFELINE starts after lead takeoff, transits to offshore hold and needs explicit clearance. Clearance requires lead within 8 km and no known enemy within 500 m. Deployment requires native landed status, speed below 1 m/s and distance within 80 m for 60 uninterrupted seconds. Renewed nearby threat forces a hold and fresh clearance; motion/flight resets the timer. After deployment it returns empty using a ship-linked landing route. Success requires both lead and transport landed within 180 m of current Tarawa position and horizontal velocity relative to the ship below 2 m/s for 20 seconds. These are scripted completion conditions, not proof of native deck collision fidelity. Team remains ashore. Aborted recovery is distinct from success. Lead/transport/Tarawa loss after acquisition fails the mission; initial spawn delay is tolerated.

Menus: F10 Other > Insertion > Status / next action; Clear transport to insert; Wave off / hold; Abort / return to ship. F10 Other > Air Support > Request one strike near LZ; Cancel / hold fire; Return Hornets to carrier. Seven commands, no mission-name layer. Text explains phase, clearance rejection, start/halfway/deployment and recovery result. Map marker follows actual Tarawa position every 30 seconds. Linked landing references are authoritative over initial WP4 coordinates.

Flags: 940 success, 941 failure, 942 aborted, 943 team inserted. Flying continues after result. Deployment is timed abstraction, not a physical team disembarkation or completed SEAL raid. Labels off; friendly-only map; actual LZ and friendly ship are marked.

## First playable slice and acceptance

- [x] Source-contained build, zero-error portable archive validation.
- [x] Simulated logic checks cover completion, abort, interruption, threats, optional support errors, moving recovery and delayed player.
- [ ] Native deck slot separation, ship models, services and rotor clearance.
- [ ] Native Hornet launch, Black Hawk launch/hold/insertion/ship recovery.
- [ ] Actual primary/hold/sea route and rotor/scenery clearance.
- [ ] Cockpit loadout, hover performance and reserve.
- [ ] Full normal sortie and relevant retry/abort in DCS.

See flight-checklist.md. Alternate LZ selection, noise/attack escalation, sophisticated patrol/detection behavior and multiplayer remain proposed. Do not treat this mock suite as validation of those features or of native flight. Check actual geometry before layering on complexity.

## Mission Planner policy — 2026-11-06

Enemy groups and their routes are hidden from the preflight Mission Planner; deliberately briefed search areas, objective markers and player target prepoints remain available. The full Mission Editor can still inspect authored assets. Native planner GUI confirmation remains pending. All red aircraft, ground, ship and static groups use hiddenOnPlanner/hidden/hiddenOnMFD. The shared deployment verifier checks the actual packed archive, independently of the in-flight F10 filter. No routes, target records or trigger zones are removed.
