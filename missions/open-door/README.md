# Operation Open Door

A Syria hostage rescue: four OH-58Ds clear a fictional village compound, then call in a waiting Black Hawk for a timed rescue while enemy ground reinforcements approach.

**First playable development build.** Requires Syria and OH-58D. The Black Hawk is DCS's built-in AI UH-60A; no helicopter mod or MCP hook is needed to play.

## Install

[Download the mission](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/open-door/dist/Operation-Open-Door-Syria-OH58D.miz), copy it to your DCS Saved Games `Missions` folder, and open it through **Missions**. The agent deploy workflow also installs the current build locally. Restart the mission after an update.

## Fly the rescue

- Four hot Kiowas start on four separate visible DCS helipads at FARP FOOTHOLD, 60 m apart, 15 nm from the objective. Ground starts use zero terrain-relative altitude; the Black Hawk has its own fifth pad. Set your physical collective fully down before pressing Fly. Lead/#2 have two Hellfires and a .50-cal gun; #3/#4 have gun and seven M151 rockets. Each has approximately 400 lb (181.4 kg) of fuel. Check cockpit performance and reserve; tank-capacity checks are not flight performance certification.
- Lifeline launches after you lift off, accompanies the flight and holds outside the objective area. It needs explicit clearance; eliminating the defenders never sends it in automatically.
- Clear the known Strela and nearby guards. Hostages and their building are vulnerable. Avoid rockets or gunfire into the marked building. Defeating every reinforcement is optional.
- Use **F10 > Other > Transport > Clear Black Hawk to land**. Actual LZ location is terrain-checked near WP5 and marked on F10; request green smoke under **Rescue**.
- Cover Lifeline for three continuous minutes while it is landed. Threats force wave-off; movement/takeoff resets progress. Team movement and boarding are simulated with timing/messages.
- Escort Lifeline back to its separate pad at the departure FARP FOOTHOLD. Landing there for 20 seconds completes the rescue: six hostages = full success, one to five = partial. No survivors or loss of the lead/Black Hawk is failure.

## FARP facilities

Visible fuel depots/tankers, ammunition trucks/canopies, ground crew Hummers, command posts and repair tents are present from the start. Each pad has an unlimited warehouse entry. Service vehicles for the four Kiowas are within 150 m of each pad. Use the Ground Crew radio menu while parked; shut down for repair. Actual service interaction still needs an in-game check.

## Start and service bases

**FOOTHOLD is now the departure and recovery base**, exactly 15 nm from the village (about ten minutes at 90 knots). Four hot-start Kiowas occupy four fixed visible pads 60 m apart; Lifeline has its own fifth pad. Fuel, ammunition, ground crew, repair tents, depots and command posts are available from the start. The pads under starting aircraft are never moved by the setup script. FOOTHOLD: **129.500 AM**; transport pad: **129.000 AM**.

**KEYSTONE remains an alternate service base**, about 25 nm from the village and 10 nm behind FOOTHOLD. It has four pads and full fuel/ammo/repair support, with a whole-camp terrain/scenery search within 1 nm of its planned location. Use its actual F10 marker. KEYSTONE: **128.500 AM**. Landing there does not complete the rescue; escort Lifeline home to FOOTHOLD.

Native trees-only scenery actions clear the five departure pads, facilities and an initial 600 m lane toward the IP at mission start. Restart the mission to apply this revision; tree appearance/collision clearance still needs an in-game check.

Starting fuel remains about 400 lb per Kiowa. Park and use Ground Crew; shut down for repair. Terrain appearance, native services and the new FOOTHOLD start location still require an in-game check.

## Use the Kiowa's MMS prepoints

The build includes actual **Navigation Target Fix Points**, in addition to the flight route:

| Target ID | Meaning |
| --- | --- |
| **1T** | Strela-10 launcher, subtype SA13 |
| **2T** | Hostage building, protected location — do not fire |

1. Set the MMS Mode Selector to **PREPT**.
2. Use **Manual/Slave** as needed until the MMS advisory reads **PREPT**.
3. Press **R2 — PPT**, enter **1T** or **2T** on the multifunction keyboard, then **Enter**.
4. The MMS should slew toward the selected stored position. Select TIS separately for thermal, then identify what you are looking at.

This follows installed OH-58D manual sections 13.4.3, 21.1.7 and 24.4. Native cockpit loading/alignment remains to be checked in-game. A stored point is not an automatic track or weapons lock; intelligence markers do not follow moving targets.

Route: WP1 FOOTHOLD, WP2 IP/hold, WP3 planned LZ, WP4 FOOTHOLD/home. Enemy sites are target points 1T/2T only and are not part of the flight route. Package UHF 251.000 AM; FOOTHOLD 129.500 AM; transport pad 129.000 AM; KEYSTONE alternate 128.500 AM. Read the [full briefing](dist/Operation-Open-Door-Briefing.txt).

## Status and limitations

All 24 printed logic scenarios and archive checks pass. These simulate DCS APIs and inspect mission data; they do not establish real AI flight/combat or terrain appearance. The new compound/transport pad, FARP services, UH-60A follow/hold/land/takeoff/recovery and Kiowa target import still need a complete sortie. Hostages use disabled neutral infantry stand-in models. See [design](design.md) and [verification](verification.md).

## Sentinel drone support — 2026-11-03

An unarmed MQ-9 stages 15 nm from the objective at 20,000 ft MSL. It automatically heads overhead when the mission starts; no dispatch command is needed. Allow roughly seven minutes at 70 m/s; native AI flight determines actual arrival. Once within 2.5 km of the objective and 500 m of its assigned altitude, it announces readiness. High altitude reduces short-range threat exposure but does not guarantee concealment.

Use **Designate next target**, **Laser status**, and **Stop lasing** in the same Drone menu. Match your Hellfire seeker to **1688**, follow the Kiowa's remote-laser engagement procedure, and positively identify the target. Requests cycle through eligible hostile ground units, starting with the known SAM. Terrain line of sight and 15 km slant range are required. Targets within 100 m of hostages/their building or 300 m of friendly helicopters are excluded; these buffers do not guarantee safe weapon effects. No auto-fire or automatic Black Hawk clearance. Target death, masking, unsafe proximity, station departure or drone loss stops lasing; request a new designation. The drone is optional and its loss does not fail the rescue. Native orbit, obstruction by structures/vegetation and remote laser acquisition need an actual DCS flight check.

### Drone reliability and target reports

Optional drone tasking or laser API errors disable Sentinel support without failing the rescue. Sentinel announces its initial arrival once. It enters station within 2.5 km / 500 m of assigned altitude and remains on station until beyond 4 km / 750 m; leaving the envelope stops designation. Laser status explicitly reports a lost/unavailable drone. Target reports give decimal-degree latitude/longitude and true bearing/range in nautical miles from the lead Kiowa. If geographic conversion is unavailable, bearing is explicitly labeled grid. Native orbit and remote-laser engagement still need a DCS flight check.

### Target talk-ons and Lifeline progress

Sentinel's laser reports describe a generic vehicle/infantry target and its approximate grid direction/distance from the hostage building, followed by coordinates and Kiowa-relative bearing/range. They do not claim unverified road or scenery landmarks. Lifeline reports final approach within 1.5 km, landed rescue start, halfway through each uninterrupted rescue attempt, timer interruption, actual airborne return with survivor count, and recovery approach within 2 km. These are on-screen messages, not recorded voice audio. Existing menus and explicit landing clearance are unchanged.

## Mission Planner visibility

Enemy groups and their routes are hidden from the preflight Mission Planner; deliberately briefed search areas, objective markers and player target prepoints remain available. The full Mission Editor can still inspect authored assets. Native planner GUI confirmation remains pending.
