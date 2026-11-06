# Operation Quiet Tide

A dawn ship-to-shore SEAL insertion on Syria. Lead two OH-58Ds from **Tarawa**, scout the coast, clear an AI Black Hawk into a landing zone, then escort it back and recover aboard the moving ship. Two AI F/A-18Cs launch from nearby **Stennis** and provide requested support.

**Development test slice: native shipboard operations are not yet flight-verified.** Requires OH-58D and Syria. Built-in AI UH-60A, LHA Tarawa and Stennis are intended to require no helicopter mod or Supercarrier module. Actual deck compatibility and service behavior must be confirmed in DCS.

## Install and fly

Copy [the mission](dist/Operation-Quiet-Tide-Syria-OH58D.miz) to your active DCS Saved Games Missions folder, then open it in DCS. Restart after updating it. Read the [complete briefing](dist/Operation-Quiet-Tide-Briefing.txt) before flight.

1. Check all three helicopter starts and deck clearance. Hornet launch is requested automatically. Take off from Tarawa; Lifeline launches automatically and holds offshore.
2. Fly toward WP3 and scout the **actual insertion marker**. The planned site may refine within 1 km after a bounded terrain check. Labels are off and enemy units are hidden from the friendly-only map.
3. **F10 Other > Insertion > Clear transport to insert** authorizes the approach. You must be within 8 km, with no known hostile ground unit within 500 m of the LZ. Lifeline never enters automatically.
4. Protect one continuous landed minute at the LZ. Movement, takeoff or departure from the landing radius resets progress; renewed close threats force a wave-off and fresh clearance. Six SEALs deploy through a timed abstraction, without passenger animation or a simulated ground raid.
5. Escort the empty Black Hawk back to **Tarawa's current position**, then land aboard yourself. Both aircraft must remain landed near the moving ship with low ship-relative speed for 20 seconds. SEALs stay ashore. Aborting before insertion returns the team and does not award success.

**F10 Other > Air Support** offers one strike request near the LZ, cancel/hold fire, and Hornet return to carrier. Requests select one eligible target, require support within range, and exclude targets within 700 m of friendly helicopters. Released weapons cannot be recalled. Requests expire after 90 seconds; air support is optional and no new strikes are accepted after insertion.

Package 251.000 AM; Tarawa 128.500 AM; Stennis 127.500 AM. Expected initial route about 22 nm each way; plan **35–45 minutes** at approximately 90 kt with scouting/insertion/recovery. This is a planning estimate. Starting Kiowa fuel 181.4 kg with gun/Hellfires on lead and gun/rockets on wingman; loaded weight, deck hover performance and actual reserve remain flight-check items.

## Deliberate first-version scope

One primary LZ, fixed small opposition, single-player lead with AI wingman and AI Hornets. No multiplayer readiness, automatic copilot observer, selectable alternate LZ, detection model, evolving alarm, or SEAL ground combat is claimed. Those features come after proving departure → insertion → recovery. Text reports only, no recorded voices.

See [design](design.md), [verification](verification.md) and [flight checklist](flight-checklist.md). Portable validation and mocked logic cannot certify native deck fit, AI launch/landing, aircraft performance or the route's scenery.
