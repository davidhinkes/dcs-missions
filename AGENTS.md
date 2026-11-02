# Working on this mission collection

- Read the mission's `design.md`, `README.md`, `CHANGELOG.md`, and `docs/lessons-learned.md` before changing it.
- Source belongs in `missions/<slug>/src`; mission tests in `tests`; playable builds and player briefings in `dist`.
- Use the project-local vendored DCS-MCP library. Do not add global installations, or dependencies on personal Saved Games missions, for authoring.
- Update source and design together. Never silently overwrite manual Mission Editor changes with a generated build; inspect and reconcile them first.
- Rebuild after changes. Run meaningful checks appropriate to the change. Distinguish archive validation, simulated logic tests, and an actual DCS sortie in reports.
- Preserve existing user decisions unless asked to change them. Preferences in this mission are not mandatory defaults for every future mission.
- For Green Lantern: three hot-start Kiowas on separate FARP pads; lead and #2 have two Hellfires plus gun; #3 gun plus rockets; 270 kg fuel each; lead PDU enabled; no labels; friendly-only F10 map; generic threat reports without enemy identities/counts; randomized survivor within 200 m; pickup allowed within 400 m; recovery at a different FARP.
- Do not treat the discussed wingman scripting, spotting dots, or approximate contact reports as already implemented.
- Do not put secrets, local logs, tracks, personal paths, or runtime caches in Git. Tool discovery paths for standard DCS installations are acceptable.
- Do not modify vendored tooling without recording why and the upstream revision. Move mission logic into shared helpers only when another mission needs it.
- Copying an updated build into the user's DCS Missions directory is separate from building. Report whether that copy was actually performed.
- Use GitHub Releases for stable playable versions, recording the tested commit and requirements. Public publishing requires the user's instruction.
