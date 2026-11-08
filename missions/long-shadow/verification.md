# Long Shadow verification

## First slice — 2026-11-08 (offline, cloud Linux container)

Built from base 6a1c431 with the new mission files uncommitted. DCS-MCP pinned at 7da70f3e54dc48e1139096fae61a08a8bbbeca57, set up locally with `npm run setup`. No DCS installation: `DCS_LUA` pointed at a stock Lua 5.1 interpreter (`/usr/bin/lua5.1`), not DCS's `luae.exe`.

Passed:
- Build validator: zero errors/warnings; three groups (player, Pontiac, convoy).
- Archive verifier: Mission Editor `fixUnitsPos` harness opens the mission (8 units), all three compiled trigger chunks are valid Lua, convoy heading/types/route checks pass; packed-archive planner check: 1 enemy group hidden.
- Mock logic suite: 23 printed groups pass (see design.md regression list).

Not done:
- Deployment: no DCS Saved Games folder exists here; `node shared/tools/mission.mjs deploy long-shadow` has not been run. The mission is not installed.
- No DCS-native check of any kind: terrain/roads, spawn, AI driving, drone orbit, weapons, Mission Planner GUI. The installed-DCS Lua interpreter was not used. Vehicle type names UAZ-469 and Ural-375 ZU-23 are standard DCS names but are new to this collection and unverified here.
