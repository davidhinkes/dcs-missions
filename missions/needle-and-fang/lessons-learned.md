# Needle and Fang lessons

- The installed OH58D UnitPayloads file confirms the two-Stinger/gun combination: OH58D_FIM_92_R on pylon 5 and OH58D_M3P_L500 on pylon 1. A remembered generic pylon layout is weaker evidence than the installed preset.
- The inherited Hind template's B919B0F4 loadout is two AT-6 missiles per rack, not rockets. This mission explicitly replaces it with two B-8V20 S-8 pods rather than describing an inherited payload incorrectly.
- An 8 nm duel with a gun-armed Kiowa needs a gun-vulnerable objective. A DShK technical supplies return fire without introducing an armored target or extra air-defense unit. Actual gun effectiveness/fairness remains a flight check.
- Enemy unit absence during loading must not count as destruction. Acquire all mandatory units first, separate startup waiting from player loss, and evaluate friendly loss before awarding simultaneous enemy-kill success.
- Native attack tasks and release messages are not evidence of launch, detection, weapon release or a fair opponent. Verify the distinctive AI duel in DCS before adding complexity. Fixed target intelligence cannot silently follow a runtime-relocated asset.

- A first-target race needs event ordering rather than only periodic casualty snapshots: two target losses between polls can otherwise reverse the actual first kill. Native death events now latch the result; polling is a fallback with an explicit unresolved-simultaneous-loss policy. Warehouses alone do not establish native FARP rearming: nearby ammo-service vehicles and stock are configured, and real replenishment remains an in-game check.

## Reported ammo-only rearm failure

The user flew the first-target-race revision and reported no rearm service. Installed archive hash matched the previous checked deployment. Logs show mission readiness/release/results, but no conclusive rearm diagnostic. Ammunition stock/one truck alone did not establish working services in this flight. BLUE FARP now has command, fuel, power and repair support as well as ammunition. The official DCS User Manual ground-services table lists distinct service roles within 150 m: https://www.digitalcombatsimulator.com/upload/iblock/ed6/87v22jwd1xh51i3rgki944xsf503istq/DCS_User_Manual_EN_2020.pdf (printed p313). This supports the complete configuration; it does not independently establish which missing role caused the observed failure. Regression checks now read the actual packed warehouse and check all service roles, coalition, proximity and VHF preset. Real ammunition replenishment remains the acceptance test.

## Full support did not resolve contact

The user reports the complete service camp still failed: Ground Crew was missing or nobody answered. Installed file matched the previous deployment. The installed OH58D comm.lua delegates to Scripts/UI/RadioCommandDialogPanel/Config/Common/Ground Crew.lua; that builder hides Ground Crew while Unit:inAir() is true and selects the local/intercom communicator. Thus neither a tuned ATC frequency nor more supply trucks establishes contact. BLUE now uses a conventional FARP and explicit native hot parking, with one aircraft/slot; RED keeps its ground start. Status/log diagnostics expose native landed/base-registration state without claiming service readiness. The installed DCS bridge was read-only reachable but at the menu, so this revision was not flight-verified. Do not infer the exact prior failure cause from the new configuration passing offline checks.

- Mission Planner visibility is a separate contract from friendly-only F10 and hiddenOnMFD. The installed editor removes hiddenOnPlanner groups and their map objects. Apply the flag to aircraft and support/static groups as well as ground objectives; retain deliberate player prepoints independently. Source-level flag verification does not replace native planner GUI acceptance.


## Airborne spawn from a parking start — 2026-11-10

The FARPS parking start (TakeOffParkingHot, slot 1) with a BARO altitude copied from another mission spawned the player about 20 ft up; the aircraft fell and crashed. Native parking did not correct the altitude. Use zero-AGL RADIO ground starts unless a parking spot's spawn height has been measured in DCS.
