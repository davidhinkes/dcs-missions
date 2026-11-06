# Changelog

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
