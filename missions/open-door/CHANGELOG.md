# Changelog

## Unreleased development build — 2026-11-01

- Promoted FOOTHOLD to departure/recovery base, 15 nm from the village; all four Kiowas and the Black Hawk now start there. KEYSTONE remains an alternate service base.
- Shortened route to FOOTHOLD / IP / LZ / FOOTHOLD; known enemies remain target points only. Departure pads are fixed and excluded from runtime base relocation.

- Added FARP FOOTHOLD about 15 nm from the village, with four spaced helipads, fuel/ammo/repair/crew facilities, unlimited pad warehouses and whole-camp terrain/scenery checks.
- Removed enemy sites from the flight route; retained dedicated MMS target points 1T/2T. Added FOOTHOLD as WP2 and an actual-location F10 marker.

- Reduced all four Kiowas from 300 kg starting fuel to approximately 400 lb (181.4 kg) after the user reported an overweight load. Briefing now displays pounds and kilograms.

- Fixed reported airborne hot-start/crash configuration: five visible single helipads, four Kiowas 60 m apart, native hot-ground starts at zero terrain-relative altitude, no copied BARO start height or parking links. Added fuel/ammo/repair/command facilities and immediate support vehicles plus all five pad warehouses.
- Log also showed extraction setup failure: widened LZ search to 1500 m and used an 18 m rotor-clearance radius with retained land/slope checks.
- Added regression checks for ground start parameters, unique matching pads, spacing, start-time facilities, support ranges and expanded LZ search.

- Built and deployed the first playable mission with four Kiowas, one AI UH-60A, fixed Strela/hostage intelligence, guarded compound, ground reinforcements, explicit clearance, wave-off/retry and full/partial rescue outcomes.
- Added separate Kiowa MMS-compatible target points: 1T for Strela-10 (SA13), 2T for the protected hostage building.
- Automated logic/archive checks passed; native flight and cockpit verification remain pending.

## Design draft — 2026-11-01

- Replaced approximate compound intelligence with precise satellite-reported hostage-building and air-defense navigation points, briefing coordinates and static markers. The known air-defense point identifies the confirmed Strela-10 launcher.
- Proposed Operation Open Door as a separate Syria hostage rescue.
- Confirmed explicit F10 clearance for the waiting Black Hawk, a timed simulated ground rescue, and village defenders with reinforcements and limited anti-aircraft defenses.
- Confirmed four hot-start Kiowas with mixed weapons, a departure FARP about 25 nm away, and hostages vulnerable to gunfire and explosions.
- Confirmed machine guns and one Strela-10 (replacing the initially chosen ZU-23), six hostages, a three-minute simulated rescue and return to the departure FARP.
- Corrected extraction helicopter to a Black Hawk; plan uses the locally available built-in AI UH-60A.
- Confirmed helicopter-only operation, continuation after hostage casualties with partial success, labels off, friendly-only map; precise satellite intelligence subsequently replaced the approximate compound marker.
