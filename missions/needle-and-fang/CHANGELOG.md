# Changelog

## Mission Planner concealment — 2026-11-06

- Explicitly hid all red aircraft, objective, service vehicles and static FARP groups from the preflight Mission Planner, including their routes. Retained the player's deliberate 1T ground-target intelligence.
- Added an all-red-group visibility regression check; in-flight map/label settings and gameplay remain unchanged.

## Native departure-base/contact correction — 2026-11-05

- User reports full-service single-helipad revision still lacks Ground Crew contact. Replaced BLUE single pad with conventional FARP and explicitly linked the one Kiowa to native hot parking slot 1; preserve support camp and duel rules.
- Corrected contact instructions to local/intercom Communications > F8 Ground Crew; VHF 128.500 is ATC, not a Ground Crew workaround.
- Added native landed-state status after the round and startup base-registration/coalition diagnostics. Native FARP spawn/contact/rearming remain unverified.

## Departure FARP service correction — 2026-11-05

- User reported rearming unavailable in the installed ammo-only revision. Added command Hummer/post, M978 tanker/fuel depot, separate M818 power/repair trucks and repair tent around the existing BLUE departure pad. All are same-coalition, active at start and within 150 m.
- Set Kiowa VHF AM preset 1 to BLUE FARP 128.500. Preserve unlimited warehouse stock, ground starts and the ground-target race.
- Added an integrated check of the packed archive's warehouse file and complete service-role coverage. Native Ground Crew replenishment still needs confirmation.

## Ground-target race and rearm support — 2026-11-05

- Changed victory to first ground-target destruction: red technical lost wins immediately, blue technical lost fails immediately; Hind kills are optional. Native target-death events resolve the race in observed order, with a final latched result and best-effort AI ceasefire.
- Added unarmed ammunition trucks and ammo canopies at both FARPs alongside unlimited warehouses. Logistics losses do not count as objective losses.
- Added race-order, ground-only win, Hind-only continuation and service-placement regression checks; native rearm interaction remains a flight check.

## First development test slice — 2026-11-05

- Added Syria Kiowa-versus-Hind duel with one armed technical objective per side, 8 nm apart.
- Added separate visible hot-ground FARP starts, two-Stinger/gun Kiowa, rocket/gun Hind and exact enemy-objective prepoint 1T.
- Hind release follows player takeoff; native tasks attack the defended vehicle and engage detected helicopters.
- Added both-enemy victory, immediate defended-vehicle failure, delayed-unit protections and one shallow status command.
- Added self-contained build inputs, mock regression checks and staged native flight checklist. No in-game acceptance claimed.
