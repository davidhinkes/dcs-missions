# Operation Open Door

A Syria hostage rescue: four OH-58Ds clear a fictional village compound, then call in a waiting Black Hawk for a timed rescue while enemy ground reinforcements approach.

**First playable development build.** Requires Syria and OH-58D. The Black Hawk is DCS's built-in AI UH-60A; no helicopter mod or MCP hook is needed to play.

## Install

[Download the mission](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/open-door/dist/Operation-Open-Door-Syria-OH58D.miz), copy it to your DCS Saved Games `Missions` folder, and open it through **Missions**. The agent deploy workflow also installs the current build locally. Restart the mission after an update.

## Fly the rescue

- Four hot Kiowas start at FARP KEYSTONE, 24.96 nm from the objective. Lead/#2 have two Hellfires and a .50-cal gun; #3/#4 have gun and seven M151 rockets. Each has 300 kg fuel. Check cockpit performance and reserve; tank-capacity checks are not flight performance certification.
- Lifeline launches after you lift off, accompanies the flight and holds outside the objective area. It needs explicit clearance; eliminating the defenders never sends it in automatically.
- Clear the known Strela and nearby guards. Hostages and their building are vulnerable. Avoid rockets or gunfire into the marked building. Defeating every reinforcement is optional.
- Use **F10 > Other > OPEN DOOR > Transport > Clear Black Hawk to land**. Actual LZ location is terrain-checked near WP5 and marked on F10; request green smoke under **Rescue**.
- Cover Lifeline for three continuous minutes while it is landed. Threats force wave-off; movement/takeoff resets progress. Team movement and boarding are simulated with timing/messages.
- Escort Lifeline back to its separate pad at the departure FARP. Landing there for 20 seconds completes the rescue: six hostages = full success, one to five = partial. No survivors or loss of the lead/Black Hawk is failure.

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

Route: WP1 KEYSTONE, WP2 IP/hold, WP3 SAM reference, WP4 protected building, WP5 planned LZ, WP6 home. Do not follow the route blindly over target-reference waypoints. Package UHF 251.000 AM; KEYSTONE 128.500 AM; transport pad 127.500 AM. Read the [full briefing](dist/Operation-Open-Door-Briefing.txt).

## Status and limitations

All 20 printed logic scenarios and archive checks pass. These simulate DCS APIs and inspect mission data; they do not establish real AI flight/combat or terrain appearance. The new compound/transport pad, FARP services, UH-60A follow/hold/land/takeoff/recovery and Kiowa target import still need a complete sortie. Hostages use disabled neutral infantry stand-in models. See [design](design.md) and [verification](verification.md).
