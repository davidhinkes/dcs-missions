# GitHub backup and releases

Repository: https://github.com/davidhinkes/dcs-missions (public, as requested by the owner).

The initial upload uses the connected GitHub integration because local command-line authentication is not configured. The repository contains source, designs, tests and the playable mission. Local dependencies, caches and flight logs are ignored.

## Change workflow

`main` is the shared branch; changes reach it through pull requests from topic branches (user decision, 2026-11-10, replacing the earlier push-`main`-only workflow). Merging to `main` publishes source and playable builds; it does not install anything in DCS (that is `node shared/tools/mission.mjs deploy <slug>`, run on the DCS machine).

1. Start each topic from the latest `main`: `git fetch origin main && git checkout -b <topic> origin/main`. One topic per branch, for example one mission change. Commit source, design, changelog and the rebuilt playable build together; messages explain why. Automated sessions use the branch name they were assigned.
2. Before opening the PR, for every mission the change touches: rebuild, run its logic test and run the archive verifier (`node shared/tools/mission.mjs verify <slug>`; `deploy` does all three where DCS is installed). For shared tooling also run `npm run test:tools` and rebuild every mission. Without DCS, `DCS_LUA` may point at a portable Lua 5.1 for logic/archive checks; say so, because it does not stand in for `luae.exe` randomness or Mission Editor checks.
3. Rebase the topic onto the latest `origin/main` (re-run affected checks if anything new landed), then push it: `git push -u origin <topic>`. Never push `main` directly, and never force-push `main`.
4. Open a PR into `main`. The body states the problem, the change, checks that passed, and checks still pending (native DCS behaviour, deployment).
5. Merge with **rebase merge** to keep history linear, once the user has asked for the merge. Afterwards `git fetch origin main` so local `main` matches GitHub.
6. Report the PR, the merged commit, and whether it was also deployed to DCS.

Ask the user before deleting anything (remote branches, tags, releases, missions or files outside the change) and before publishing a Release. Initial local commits are attributed to the automation; set your Git name and email before making your own commits if they are not configured.

## Stable release

Complete a sortie of the exact candidate build. Record DCS version, Git revision and results in the mission design. Create a tag such as `green-lantern-v1.0.0` and a GitHub Release with the mission and briefing attached. List module requirements and known issues. DCS User Files can link back to this repository.
