# Mission title

## Intent and player experience

Describe the role, setting, objective, expected duration and what makes the mission interesting.

## Requirements and start

Aircraft, terrain, assets/mods, single-player/multiplayer, cold/hot/air start, location and loadout.

## Forces and roles

Friendly flights, support, enemy forces, skills and rules of engagement. Distinguish player-facing information from spoilers.

## Geography and timing

Route, distances, speeds, fuel planning, support transit, trigger gates and time limits. Record coordinate conventions.

## Mission state and interactions

Phases, triggers, menus, smoke, target designation, success/failure and recovery behavior.

## Realism and difficulty decisions

What is simulated or abstracted, information available to the player, randomization, spotting aids and rationale.

## Support and player-feedback contract

For each support asset specify start location/altitude, automatic or requested departure, transit estimate, arrival criteria and one-time report, available tactical commands, loss/timeout behavior and whether its failure can affect the main objective. Separate a request from observed arrival/action.

List complete F10 paths and their selection count. For each phase state the cue, next player action, blocked-action explanation and retry behavior. Specify text versus actual audio and what intelligence may be disclosed. Use cockpit-usable coordinates/directions.

## First playable slice and native flight checks

Describe the smallest start → distinctive objective interaction → recovery sortie. Before expanding it, identify the checks that require DCS: occupied-pad safety and forest/rotor clearance, servicing, loadout/gross weight and hover performance, support arrival, sensor/weapon acquisition and recovery. Record unavailable checks as pending, with a concrete flight checklist.

## Regression and change impact

Cover delayed player availability, abort/retry, time/radius boundaries while moving, optional asset/API failure, cleanup, stale/lost targets and repeated reports. Changes to bases/routes/aircraft count must update fuel/timing, separation, recovery, markers, briefing and affected checks together. Do not assume existing missions' coverage applies to this one.

## Acceptance criteria

- [ ] Build and archive validation pass.
- [ ] Relevant mission-logic tests pass.
- [ ] Starts in the correct aircraft/location/configuration in DCS; pads, facilities and departure lane are clear.
- [ ] Intended loadout supports takeoff/hover and the route with a checked reserve.
- [ ] Distinctive native AI/sensor mechanic works in DCS, beyond mocked task acceptance.
- [ ] Menus are shallow and phase reports explain the next action; optional support faults preserve the objective.
- [ ] Normal objective and recovery can be completed.
- [ ] Relevant failure/retry paths behave as intended.

## Verification record

Date, Git revision, DCS version, check type, result, limitations. Automated checks and actual flights must be separate entries.

## Open work

Proposals and known issues, clearly distinguished from implemented behavior.

## Mission Planner concealment

Use the collection shared planner helper before packing. Hide all enemy groups/routes, including aircraft, support and statics. Preserve explicitly briefed intelligence/search areas/player prepoints. Pass the packed-archive planner check and record native GUI confirmation separately. Current player side is blue/opposition red; review the helper and policy if a future mission uses another player coalition.
