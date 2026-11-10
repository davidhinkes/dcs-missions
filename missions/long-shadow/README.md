# Operation Long Shadow

A covert convoy hunt in Syria. **MAGPIE**, a fictional weapons-network coordinator, is being driven from **Homs to Hama on the M5** in a five-vehicle escorted convoy. Fly your OH-58D low and unseen to the highway, find the convoy, pick out MAGPIE's **UAZ jeep (third vehicle)**, follow it and destroy it before it reaches Hama.

Requires **Syria and OH-58D**. Everything else is built-in AI. Development test slice: not yet flown.

## Install and fly

[Download the mission](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/long-shadow/dist/Operation-Long-Shadow-Syria-OH58D.miz), copy it into your DCS Saved Games `Missions` folder and open it from **Missions**. Restart the mission after updates. Read the [full briefing](dist/Operation-Long-Shadow-Briefing.txt).

- **You plan the route.** Your flight plan has no waypoints except your start at FARP JUNIPER, a covert pad on the Houla plain about 9.7 nm west of the proposed attack point. Use the Mission Planner to choose your own approach, hides and battle positions.
- **1T is the proposed attack point**: where the M5 is expected to cross the Orontes north of Ar-Rastan. MMS: PREPT, R2 PPT, enter 1T, Enter. It is a likely passage point, not a vehicle — attack wherever you like.
- **The convoy** leaves the M5 northern exit of Homs between **H+4 and H+8 minutes**, about 27 kt (50 km/h): roughly 19 minutes to 1T, then about 21 to Hama. BRDM-2, DShK technical, **MAGPIE's UAZ**, Ural truck, ZU-23 truck. Stay outside about 2 km of the guns. If you shoot at it or it shoots at you, it runs for Hama at about 72 km/h.
- **Pontiac**, an unarmed MQ-9 high overhead, calls the convoy's departure and its road distance and ETA to 1T at 8, 6, 4, 3, 2 and 1 nm, when it passes 1T, and its distance from Hama after that. **F10 Other > Pontiac > Convoy report** gives an update any time. Pontiac never gives coordinates — finding the convoy is up to you. Once you're within 3 nm of the convoy, **Pontiac > Lase MAGPIE** lases MAGPIE's vehicle on code 1688 for your Hellfires (match the missile code and identify the UAZ first). It stays on while you're within 3 nm and Pontiac can see the target; **Stop lasing** turns it off.
- Two Hellfires, M3P .50-cal (500 rounds), 30 flares, about 400 lb fuel. No rearm. Check weight, hover margin and reserve.
- **Win**: MAGPIE's vehicle destroyed. **Lose**: MAGPIE reaches Hama, or you lose the Kiowa. Escorts are optional; flying home afterwards is optional.
- Enemy units are hidden from the Mission Planner; labels off; F10 shows friendlies plus intel markers (1T, departure area, destination, FARP).

See [design](design.md), [flight checklist](flight-checklist.md) and [verification](verification.md). Coordinates come from real-world positions and still need an in-game check against DCS roads.
