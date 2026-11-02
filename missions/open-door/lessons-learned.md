# Open Door lessons

- A route waypoint alone is not the same authoring concept as a preloaded target record. The installed OH-58D guide confirms that MMS PREPT accepts waypoints, control points and target points. Section 24.4 imports target points via group `NavTargetPoints`, with comments formatted `#T|quantity|subtype`; local Mission Editor serialization confirms the `index`, `x`, `y`, `text_comment` fields. This mission uses `1T|1|SA13` and `2T|1|UNK`. Cockpit import/alignment still needs verification.
- Protect neutral hostages from intentional guard AI targeting while preserving vulnerability to stray fire and explosions. The hostage building must be neutral too; a friendly military building among red guards can trigger unintended fighting before the player arrives. Model disablement is not invulnerability.
- The authoring library falls back to USA country ID for unknown country names. Explicitly supply UN Peacekeepers country ID 7 for neutral hostages/structures, and check country consistency in tests.
- The local Mission Editor action database describes temporary helicopter landing as `Land`, with `point`, `durationFlag`, `duration` and `combatLandingFlag`. Use an indefinite land task and let the rescue state machine assign departure after 180 actual landed seconds; merely setting a duration does not prove boarding conditions. Native cancellation/takeoff needs flight verification.
- A 25 nm departure becomes about 50 nm round trip before combat/holding/rescue. Record the actual geometric distance, select fuel within capacity and leave endurance/performance acceptance to cockpit and sortie checks.
- Four Kiowas fill four FARP pads. The transport needs separate linked parking and a separate recovery point, even though both pads belong to the same departure installation.
- Reinforcement activation is not arrival. Routes must actually approach a tactically relevant area; a group stopping too far away cannot create the intended extraction pressure. Tests check both activation delay and destination.
- A delayed-spawn test must remove the player before the script first sees it. Removing a previously acquired player correctly exercises player loss instead. Keep these as distinct cases.
- Terrain-aware LZ selection can vary while satellite target references stay fixed. Never silently relocate the building or SAM just to simplify terrain placement. Failure to find a safe main site must be reported; optional service failure must not abort rescue initialization.

## First in-game attempt: start/crash and setup failures

The user's flight reported hovering about 10 ft above the start and crashing. The debrief confirms lead pilot death around 2.32 s; the log also reports no clear LZ within the original search. The exact physics cause was not independently reproduced. Replacing copied BARO heights and parking starts with explicit zero-AGL hot ground starts on separate visible native helipads avoids relying on those heights/links. Facilities must be available at time zero rather than depend on a later rescue setup function. Added assertions cover all start parameters, pad matching/spacing and support proximity. Native spawn stability still needs user confirmation.

The original 45 m scenery clearance and 300 m search found no LZ in the actual mountainous scene. Updated to 18 m rotor clearance, a 2.5 m elevation-difference limit at 25 m samples, and a 1500 m bounded search. A test obstructs the original region to exercise the larger search. This is not evidence that the new site has been flight-tested; F10/smoke identify the final site and timed rescue remains an abstraction.

## Fuel versus gross weight

The user reported that the 300 kg Kiowa fuel load made the armed aircraft overweight. Reduced all four Kiowas to about 400 lb (181.4 kg), using an explicit pounds-to-kilograms conversion because DCS mission payloads store kilograms. A tank-capacity check does not validate loaded aircraft weight. Treat cockpit gross weight/hover performance and fuel reserve for the 50 nm round trip as separate checks; the new fuel quantity is a user-selected starting load, not a verified endurance guarantee.
