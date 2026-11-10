# Changelog

## Player-loss grace — 2026-11-10

- Losing track of your Kiowa no longer fails the insertion instantly: a 10-second grace (as in the other missions) tolerates a brief disappearance such as a slot change. The script also finds your Kiowa if its slot was renamed from ANVIL-1, for the loss check, the 8 km clearance check, Sword's friendly-separation check and deck recovery. Transport and ship loss still fail immediately.

## Mission Planner concealment — 2026-11-06

- Applied the collection-wide enemy planner-concealment rule to all red groups, preserving deliberate mission intelligence and friendly planning. Deployment now checks the delivered archive.

## Initial development test slice — 2026-11-05

- Added separate Quiet Tide mission: Tarawa-based Kiowas/UH-60A, nearby Stennis-based AI Hornets, one SEAL insertion site and moving-ship recovery.
- Added explicit clearance, continuous landed deployment, wave-off/abort, optional single-target support and live ship markers.
- Added self-contained data templates, source, briefing, mocked regression tests and native flight checklist. No native flight acceptance or PC deployment claimed.
