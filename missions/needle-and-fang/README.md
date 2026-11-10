# Operation Needle and Fang

A compact Syria duel: **your OH-58D against an AI Hind**. Each side defends an armed technical. Destroy **the enemy technical first** to win immediately. Killing the Hind is optional and does not end the round. Losing your vehicle or helicopter fails the mission. No required landing after the win.

Requires **Syria and OH-58D**. The Mi-24V is a built-in AI asset; no Hind purchase, mod, MCP server or hook is needed to play. This is a development test slice, with native combat/terrain acceptance pending.

## Install and fly

[Download the mission](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/needle-and-fang/dist/Operation-Needle-and-Fang-Syria-OH58D.miz), copy it into your DCS Saved Games Missions folder and open it through Missions. Restart after updates. Read the [full briefing](dist/Operation-Needle-and-Fang-Briefing.txt).

- Start hot on the ground on your own BLUE FARP helipad. Only your aircraft uses this base. The Hind starts hot on a separate RED FARP and waits for your first takeoff to release its attack.
- You carry **two Stingers and a .50-cal gun with 500 rounds**, 30 flares and about 400 lb fuel. Use Stingers against the Hind and the gun against the unarmored technical. Check actual loaded weight, hover performance and reserve in the cockpit.
- The defended vehicles are **8 nm apart**. Both can shoot back. Each is stationary near an authored outbuilding; sight lines, trees and terrain need an actual DCS check.
- The Hind has rockets and its gun, with no long-range antitank missiles. It hunts your defended vehicle and may engage your Kiowa if it detects you. Its position is not shown or reported by coordinates.
- Your exact enemy-vehicle prepoint is **1T**. On the MMS, select PREPT, R2 PPT, enter 1T and press Enter. The F10 marker identifies the same fixed position. Sensor import/alignment still needs cockpit verification.
- Enemy groups/routes and support assets are explicitly hidden from the preflight **Mission Planner**. Your deliberate 1T target fix remains available. Labels are off and the F10 map shows friendly units only, except for the deliberate fixed enemy-objective intelligence marker. No live enemy tracking.

**F10 Other > Duel > Status / objectives** reports the objective state, not the Hind's location. The first ground-target death event decides the round and later losses cannot reverse it. If both targets disappear without ordered events between checks, friendly loss takes precedence. Flying continues after the result; WP3 marks optional home recovery. BLUE FARP now has a complete departure service camp: ammunition truck/canopy, command Hummer/post, fuel tanker/depot, ground-power/repair trucks and repair tent, all within 150 m of your existing pad. Stocks are unlimited. RED FARP retains its ammunition support. Land/park on your pad and open the **local/intercom Communications menu**, then **F8 Ground Crew > Rearm & Refuel** to replenish Stingers and gun ammunition. Logistics are separate from the defended objectives. VHF AM preset 1 is **128.500**, matching BLUE FARP ATC; this frequency is not the Ground Crew contact path; UHF package stays 251.000. An earlier single-helipad revision failed Ground Crew contact, and the later four-pad parking start spawned you in the air; this revision returns to the single helipad, ground start. If Ground Crew is missing, **Duel > Status / objectives** reports whether DCS considers the aircraft LANDED or AIRBORNE. Actual contact/replenishment and the new spawn still need an in-game check.

Allow roughly **15–25 minutes**, depending on tactics. There is no deadline. The native AI may fail to launch, detect or attack as intended; the [flight checklist](flight-checklist.md) identifies the checks needed before calling this a validated duel. See [design](design.md) and [verification](verification.md).
