# Open Door instructions

- Read `design.md` before implementation. Distinguish confirmed user choices from proposals and pending decisions.
- This is a separate mission. Do not inherit another mission's coordinates, flight composition, start mode, loadouts, map settings or rescue distances without an explicit decision here.
- The Black Hawk must wait for explicit player F10 clearance. Guard defeat alone must not release it.
- The ground rescue is timed and simulated after the Kiowas defeat the guards; do not implement or promise a full infantry assault unless the user changes the design.
- Use a Syria village, scattered guards, ground reinforcements, heavy machine guns and one Strela-10 (SA-13) guided SAM, replacing the previous ZU-23. No friendly jets or enemy aircraft.
- Use four hot-start Kiowas with mixed Hellfire/gun/rocket loadouts, departing about 25 nm from the village. Preserve hostage vulnerability to gunfire and explosions. Exact loadouts and fuel need build-time validation.
- Test the built-in UH-60A's landing/departure behavior before relying on the full extraction sequence. Report actual observed behavior separately from mock tests.
- Six vulnerable hostages; about three minutes on the ground for the simulated rescue. Continue after casualties and report full/partial success by survivors returned. Escort the Black Hawk back to the departure FARP.
- Labels off and friendly-only F10 unit visibility. Precise satellite intelligence supplies named preplanned points, coordinates and static markers for the hostage building and one known air-defense site. This overrides the earlier approximate compound marker. Hide other enemy positions and avoid live tracking through intelligence markers or custom menus.
- The known air-defense prepoint identifies the Strela-10 launcher precisely. Keep target reference points separate from the Black Hawk's safe ingress route.
- This now has a development build. Use the collection deploy workflow after mission edits. Native AI following/holding, temporary landing/takeoff/recovery, terrain, FARP services and cockpit target-point import still require an actual DCS sortie; never report those as flight-verified.
- Preserve Kiowa target points `1T|1|SA13` (Strela) and `2T|1|UNK` (protected hostage building) separately from route waypoints. The manual confirms PREPT supports target points; importing them is not proof of cockpit alignment.

- Preserve the corrected FARP start scheme: five native visible SINGLE_HELIPAD/FARP objects; four Kiowas separated by 60 m; TakeOffGroundHot / From Ground Area Hot, alt=0 and alt_type=RADIO on units and first waypoint; no parking or helipad links on the ground-start waypoint. Black Hawk recovery remains linked to pad 200. Never reuse a prior unit BARO altitude as terrain elevation. Support must exist from mission start, independently of extraction initialization.

- Kiowa starting fuel is approximately 400 lb each (181.4 kg in the DCS payload). The user reported the previous 300 kg load overweight. Apply this to all four Kiowas; validate gross weight and mission endurance separately.
