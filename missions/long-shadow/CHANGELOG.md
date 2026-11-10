# Long Shadow changelog

## Pontiac laser — 2026-11-10

- Pontiac can now lase MAGPIE's vehicle on request (F10 Other > Pontiac > Lase MAGPIE, code 1688) once you are within 3 nm of the convoy. The spot follows the UAZ and switches off automatically if you open beyond 3 nm, Pontiac loses line of sight, the drone or target is lost, or the round ends; Stop lasing turns it off. Pontiac still gives no coordinates.

## Convoy robustness — 2026-11-10

- The alert dash now starts from the leading surviving vehicle. It previously started at MAGPIE's position (third in column), which could turn the lead vehicles back.
- A convoy that stops short of Hama no longer leaves the mission open forever: Pontiac reports it after 5 minutes halted, and 15 minutes without moving ends the round as a failure. Moving again resets the timer.

## Departure randomness fix — 2026-11-08

- Departure-time selection now discards three random draws first. Under DCS's Lua the first draw after a small or missing seed is near zero, so the convoy would have left at about H+4 nearly every time.
- Fixed the random-departure test: its `opts.random and nil or …` override always fell back to the fixed 300 s, so randomness was never exercised. It now also checks that seeds 1–40 reach every quarter of the window.

## First development test slice — 2026-11-08

- New Syria OH-58D convoy-interception mission: MAGPIE convoy Homs → Hama on the M5, proposed attack point 1T at the expected Orontes crossing north of Ar-Rastan.
- Player flight plan has only its start point; one Kiowa target point (1T) plus briefing intel and F10 markers.
- Pontiac MQ-9 on station from start: automatic departure, distance-to-1T, passing and distance-to-Hama calls with speed/ETA; one on-demand report command; loss/fault isolation.
- Late-activated five-vehicle convoy with random departure in the briefed H+4–8 window; one-time alert dash to Hama when hit or firing.
- Win on MAGPIE kill; fail on arrival in Hama or player loss.
- Geography from WGS84 lat/lon via a mission-local DCS Syria projection; briefing numbers generated from config.
- Mock regression suite and native flight checklist. Not flown; not deployed to DCS.
