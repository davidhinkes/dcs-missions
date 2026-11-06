# Quiet Tide native flight checklist

Record archive SHA-256, Git revision (or uncommitted status), DCS version and module versions with results. Do not overwrite manual editor changes without preserving them.

1. **Deck/start:** open the actual delivered archive in the Mission Editor and DCS. Confirm all ships are at sea with a safe full route; Kiowa player slot present; Tarawa slots 1/2/3 do not overlap; correct deck height, rotor/obstacle clearance, hot-start condition and service interactions. Inspect loadout gross weight/hover capability and fuel plan. Any overlap/airborne spawn blocks flying this revision.
2. **Launch:** observe SWORD's actual native launch and offshore orbit, then Anvil takeoff. Confirm wingman launch, transport startup and unobstructed Tarawa departure. Observe transport offshore hold without automatic insertion. Do not infer flight from a startup message.
3. **LZ:** inspect actual marker, ground surface/slope/scenery and route; validate runtime land/site search. Check clearance rejection at distance and with nearby threats. Confirm it can land after explicit clearance, wait a continuous minute, and take off when insertion completes.
4. **Recovery:** compare live Tarawa marker with initial WP4; confirm native route follows/reaches the moving ship. Observe transport deck landing and land lead. Confirm recovery only after both are landed with ship-relative velocity matched for 20 seconds. Check remaining fuel and naval services. No success from merely hovering near the ship.
5. **Retry/abort/support:** wave off and re-clear; interrupt deployment; abort before deployment and recover with aborted outcome. Observe one Hornet attack and hold-fire behavior; preserve separation from released weapons. Observe Hornet RTB to Stennis and optional support loss without objective failure.

If native DCS rejects a model/task/slot, record the symptom and logs before changing configuration. Current Linux development checks do not execute any of these flight steps.
