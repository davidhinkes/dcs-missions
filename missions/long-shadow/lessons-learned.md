# Long Shadow lessons

- The vendored serializer writes JS arrays as 0-indexed Lua tables (`[0] = ...`). Lua `ipairs` and `#` then skip the first element, silently dropping the 8 nm call and the first convoy type in the first build. A count-based test agreed with the bug; explicit first-element assertions caught it. Runtime lists are now converted to 1-based tables in the builder.
- Real-world lat/lon converted with the Syria projection is plausible offline evidence only. DCS road geometry, river crossings and town edges can differ by tens to hundreds of metres. The script logs surface type and nearest-road distance for each route point so the first sortie produces evidence.
- A drone that reports road distance must label a straight-line fallback as such; `land.findPathOnRoads` is used when present, and the mock tests run both paths.
