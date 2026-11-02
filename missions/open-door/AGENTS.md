# Open Door instructions

- Read this mission's design, README, changelog and lessons. Preserve confirmed choices; do not inherit other missions' settings.
- Departure/recovery is FARP FOOTHOLD, 15 nm from the village. Four hot-start Kiowas use four fixed visible SINGLE_HELIPAD/FARP objects 60 m apart; Black Hawk has its own fifth. Starting pads must never relocate during initialization. Ground starts use TakeOffGroundHot / From Ground Area Hot, alt=0, alt_type=RADIO, no conflicting parking/helipad links. Black Hawk recovery stays linked to pad 200.
- FOOTHOLD frequency 129.500 AM; transport pad 129.000 AM. KEYSTONE is an alternate service base about 25 nm from the village, 128.500 AM; its four pad IDs 400–403 and support move together only after a whole-footprint terrain/scenery check. Use the actual F10 marker. Neither alternate landing nor service stops complete the rescue.
- Keep native trees-only clearing actions for all five FOOTHOLD departure pads, facilities and the initial departure lane; maintain both editor and compiled forms until the pinned authoring dependency supports the predicate. Do not clear buildings or move occupied pads. Native visual confirmation remains required.
- Both sites have native helipads, fuel/ammo/repair/crew facilities and unlimited warehouses. Departure services must exist from mission start, independently of extraction initialization.
- All four Kiowas start at approximately 400 lb fuel (181.4 kg). Lead/#2 have two Hellfires plus gun; #3/#4 gun and seven M151 rockets. Validate weight/performance/endurance separately.
- Village opposition: scattered guards, ground reinforcements, heavy machine guns and one Strela-10. No friendly jets or enemy aircraft.
- Black Hawk is built-in AI UH-60A. It must wait for explicit F10 clearance before extraction; guard defeat alone never grants clearance. Preserve wave-off/retry and abort/return behavior.
- Six vulnerable hostages; three-minute simulated rescue after landing. Continue after casualties, counting full/partial success on return to FOOTHOLD. Do not promise passenger or assault-team animation.
- Labels off, friendly-only map. Known building/SAM intelligence uses fixed markers and separate Kiowa target points 1T|1|SA13 and 2T|1|UNK. Enemy assets must not appear in the flight route.
- Route: FOOTHOLD → IP → planned LZ → FOOTHOLD. KEYSTONE is optional and marked on F10.
- Use the shared checked deployment workflow after mission edits. Native AI flight, cockpit target import, terrain appearance, starts and servicing need actual DCS confirmation; do not claim mock tests prove them.
