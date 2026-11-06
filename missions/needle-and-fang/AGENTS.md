# Needle and Fang instructions

- Read design, README, changelog, lessons and flight checklist before edits. This is a separate Syria duel; preserve other missions.
- One player OH-58D versus one built-in AI Mi-24V. No wingmen, combat jets, extra hostile patrols or time limit. Each side has exactly one defended DShK technical, stationary beside authored cover.
- Two defended vehicles are 8 nm apart. Fixed sites in config drive vehicle positions, briefing intelligence and Kiowa target 1T. Do not relocate the enemy vehicle at runtime or add it to the player flight route.
- Both helicopters start hot at separate fixed visible single helipads, alt=0/RADIO with TakeOffGroundHot / From Ground Area Hot. No parking/start links or relocation under occupied aircraft. Preserve trees-only FARP clearance before scripts and pad warehouses. Services are not promised without ground-service assets/native confirmation.
- Player: two Stingers, M3P gun/500 rounds, 181.4 kg fuel, 30 flares, PDU. Hind: High skill, two S-8 rocket pods/gun, 900 kg fuel; native sensing for helicopter encounters. No long-range ATGMs in this first slice.
- Hind waits uncontrolled until the player's first takeoff releases it once. Native objective attack and helicopter encounter tasks must not receive live player coordinates through Lua. Distinguish requested launch from observed takeoff.
- Victory requires both enemy assets destroyed while own vehicle/player survive. Own defended-vehicle loss fails immediately and takes precedence over simultaneous enemy kills. Never count missing initial units as destroyed; tolerate initial player delay, then handle acquired player loss with grace.
- Labels off, friendly-only map, exact enemy vehicle target 1T and marker. No Hind coordinates, live tracking or enemy unit names in menu replies. One shallow Duel/Status command; no smoke or required recovery.
- Build/deploy using shared runner slug needle-and-fang. Native terrain/cover fit, both pad starts, Hind attacks/encounters, missile/gun effectiveness and full sortie remain flight checks. Mock task acceptance never establishes a fair cat-and-mouse fight.
