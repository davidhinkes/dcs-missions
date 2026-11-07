# Working on this mission collection

- Read `docs/lessons-learned.md` and the selected mission's `AGENTS.md`, `design.md`, `README.md`, `CHANGELOG.md` and `lessons-learned.md` (when present) before changing it.
- For a new mission, use `docs/mission-design-template.md` and the staged workflow in `docs/mission-rework-review.md`. Define support activation and player feedback before implementing them; identify the first playable slice and native DCS checks. Record unavailable checks as pending, not passed.
- Source belongs in `missions/<slug>/src`; mission tests in `tests`; playable builds and player briefings in `dist`.
- Use the project-local DCS-MCP submodule at the parent repository's pinned commit. Do not add global installations, or dependencies on personal Saved Games missions, for authoring. `npm run setup` initializes the submodule and installs/builds its packages locally.
- Update source and design together. Never silently overwrite manual Mission Editor changes with a generated build; inspect and reconcile them first.
- Rebuild after changes. Run meaningful checks appropriate to the change. Distinguish archive validation, simulated logic tests, and an actual DCS sortie in reports.
- Preserve existing user decisions unless asked to change them. Preferences in this mission are not mandatory defaults for every future mission.
- Keep aircraft preferences, force composition, gameplay thresholds and implementation history in the relevant mission directory. Top-level instructions and lessons must apply across missions; do not promote one mission's decisions into collection-wide defaults.
- Do not put secrets, local logs, tracks, personal paths, or runtime caches in Git. Tool discovery paths for standard DCS installations are acceptable.
- Do not leave uncommitted changes inside the DCS-MCP submodule. Tooling changes need an upstream/fork commit and an intentional parent gitlink update. Record why and test the upgrade. Move mission logic into shared helpers only when another mission needs it.
- After implementing mission edits, run `node shared/tools/mission.mjs deploy <slug>` by default so the user can fly the update immediately. Omit this only if the user requests an artifact/source-only change. Deployment builds once, runs the mission logic tests and archive verifier, then copies the verified file to DCS and confirms its SHA-256. Do not report deployed if any step fails.
- Default deployment detects one standard Saved Games DCS profile. Use `DCS_MISSIONS_DIR` for a custom or ambiguous profile; never guess between profiles. Request filesystem permission through the environment when needed. Existing installed revisions, including Mission Editor edits, are preserved under the target folder's `.mission-backups` before replacement; inspect/reconcile manual edits as appropriate.
- Report the actual deployment destination and remind the user to restart the mission to load the update. Copying a file does not update a running mission. Never restart DCS or load a mission automatically unless requested.
- Use GitHub Releases for stable playable versions, recording the tested commit and requirements. Public publishing requires the user's instruction.

- Collection-wide player preference: enemy groups/routes must be hidden from the preflight Mission Planner. Use shared/tools/planner.mjs in every builder; the shared verify/deploy command checks the packed archive. Preserve deliberate briefing intelligence, search areas and player target prepoints. This does not conceal assets from the full Mission Editor.
