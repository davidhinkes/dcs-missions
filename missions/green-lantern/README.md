# Operation Green Lantern

A Syria CSAR mission: recover downed pilot Sparrow while enemy vehicles hunt him. Two flights of two OH-58Ds operate from HAVEN, with carrier fighter/SEAD/CAS and AWACS support. Requires DCS World, Syria and OH-58D; no additional aircraft purchase, MCP hook or external mission framework is needed to play.

## Install and fly

[Download the mission](https://github.com/davidhinkes/dcs-missions/raw/refs/heads/main/missions/green-lantern/dist/Operation-Green-Lantern-Syria-OH58D.miz), copy it into your DCS Saved Games Missions folder and open it through Missions. Restart the mission after updates.

- **Anvil / RESCUE:** player plus one normal AI wingman, hot on HAVEN pads 1/2. Player has two Hellfires and gun; wingman has seven M151 rockets and gun. Use normal radio commands for your wingman.
- **Longbow / LONGBOW:** separate Excellent-skill AI pair on pads 3/4, two Hellfires and gun each. They launch when you take off and hold in an area centered 3 nm south of WP3. Scripted attacks use missiles only. They return to HAVEN after pickup.
- Each aircraft now sits on its own visible native SINGLE_HELIPAD, arranged in a 60 m-spaced square. Starts use zero-AGL hot ground mode and explicit separated coordinates; shared parking allocation is not used. Native trees-only clearing prepares the departure area. Each pad has warehouse resources, and service vehicles remain within 150 m of all four pads.
- All four Kiowas retain 270 kg fuel and 30 flares; check loaded performance and fuel reserve in the cockpit. Lead has the PDU.

## Rescue and medical delivery

Fly WP2 then WP3, about 13 nm from HAVEN. WP3 is the centre of a **2.5 km search region**: each start picks one of several possible crash sites inside it, so Sparrow can be up to about 2.4 km from WP3. Use **Rescue > Contact Sparrow** within about 15 km for a rough bearing and range from your position. The fix sharpens as you close and can be repeated every 30 seconds. Request green smoke when within 2 km of Sparrow himself, locate him and land within 400 m at less than 1 m/s. Boarding takes 20 seconds within 100 m and up to two minutes at 400 m; movement resets progress.

After boarding, fly to **WP4: the exact fixed LANTERN landing pad**, about 25 nm southwest. Land within 100 m and remain still for 15 seconds. The F10 LANTERN marker identifies the same pad. There is no recovery smoke or recovery-smoke command. Fuel, rearm and repair facilities are configured at both FARPs; native services and terrain fit still require flight acceptance.

## F10 assignments

Under Other:

- **Rescue:** Status / return directions; Contact Sparrow (direction fix); Request survivor smoke (green).
- **Overwatch:** Engage vehicles near me; Hold fire / resume overwatch; Return to HAVEN.
- **Air Support:** Launch carrier package; Request CAS near me; Request radar suppression; Hold fire / cancel CAS.

For Longbow, get within 2 km of the vehicles you want attacked, then select **Overwatch > Engage vehicles near me**. This requests one target near your call position, without exposing enemy names or a target list. Longbow waits for an airborne shooter with missiles, terrain sight line and 6.5 km slant range, and excludes targets within 700 m of Sparrow or any of the four Kiowas. Requests can remain pending; cancel explicitly if needed. One target request does not authorize automatic follow-on attacks.

Longbow holds around a staging point, not a guaranteed stationary firing position. Native AI may maneuver to fire; the script breaks off if its leader closes within 4 km of Sparrow, when separation becomes unsafe, on target destruction or after 90 seconds. Hold fire cannot recall a released missile. Accuracy, guidance, vegetation/building masking and native aircraft behavior require a DCS flight check.

STENNIS starts 70 nm northwest of extraction. Request the carrier package before departure; takeoff launches it as a fallback. Allow roughly 12–18 minutes for fighter launch/climb/transit; Bruiser launches three minutes later and needs CAS clearance. Hold at WP2 if cover has not arrived. Labels are off; F10 shows friendly units only.

## Development status

Mock mission logic and archive checks verify configuration and state transitions, not native AI combat or terrain. The four-pad launch, new Longbow attack behavior, fixed recovery pad and complete sortie need in-game acceptance. Read the [full briefing](dist/Operation-Green-Lantern-Briefing.txt), [design](design.md) and [verification record](verification.md).

## Mission Planner visibility

Enemy groups and their routes are hidden from the preflight Mission Planner; deliberately briefed search areas, objective markers and player target prepoints remain available. The full Mission Editor can still inspect authored assets. Native planner GUI confirmation remains pending.
