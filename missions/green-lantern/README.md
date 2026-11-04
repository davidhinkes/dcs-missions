# Operation Green Lantern

A fictional Syria rescue mission: lead a flight of three OH-58Ds from FARP HAVEN, recover downed pilot Sparrow while enemy vehicles hunt him, then return to the separate FARP LANTERN. Carrier fighters, SEAD and CAS support the extraction; MiGs and Hinds contest the area.

Requires **DCS World, Syria and OH-58D**. Single-player lead with two AI wingmen. No external mission framework, DCS-MCP installation or additional aircraft purchase is required to play.

## Install and fly

[Download the mission file](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/green-lantern/dist/Operation-Green-Lantern-Syria-OH58D.miz), copy it into `%USERPROFILE%\Saved Games\DCS\Missions` (or your DCS profile's `Missions` folder), then open it through DCS's **Missions** screen. Steam and standalone DCS use the same mission file. No developer setup, submodules or Lua hook is needed by players.

All three helicopters start hot on separate pads at HAVEN. Lead and #2 carry two Hellfires and a .50-cal gun; #3 carries a .50-cal gun and seven M151 rockets. All carry 270 kg fuel. Lead has the PDU enabled.

Read the [full briefing](dist/Operation-Green-Lantern-Briefing.txt) for timing, radios and threats. Departure is about 13 nm from the search area; return to LANTERN is about 25 nm. Labels are off and the F10 map shows friendly assets only.

## Rescue

WP3 marks an approximate last-known position. Sparrow is placed safely within 200 m. Request green smoke once within 2 km, locate him, and land within 400 m at less than 1 m/s. Remain still: boarding takes 20 seconds within 100 m and up to two minutes at 400 m. After pickup, follow blue smoke at WP4 to LANTERN's actual pad and remain landed within 100 m for 15 seconds.

## F10 menu

Under **Other**:

- **Rescue:** status / return directions, request survivor smoke (green), request recovery smoke (blue).
- **Air Support:** launch carrier package, request CAS near me, request radar suppression, hold fire / cancel CAS.

STENNIS starts 70 nm northwest of extraction, 20 nm closer than before. Allow roughly 12–18 minutes for launch, climb and transit; actual AI timing varies.

Request the carrier package before departure and hold at WP2 if cover has not arrived. Takeoff automatically launches it as a fallback. CAS requires your clearance. Normal wingman radio commands control your two Kiowas.

## Development status

This is a development build. Previous versions were flown successfully by the owner; the latest combined revision still needs a full sortie. Offline validation and simulated logic checks do not prove AI tactics, FARP servicing or the newest hot-start behavior. See [design](design.md) for details and outstanding work.
