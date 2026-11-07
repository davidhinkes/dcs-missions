# GitHub backup and releases

Repository: https://github.com/davidhinkes/dcs-missions (public, as requested by the owner).

The initial upload uses the connected GitHub integration because local command-line authentication is not configured. The repository contains source, designs, tests and the playable mission. Local dependencies, caches and flight logs are ignored.

## Change workflow

The repository has one shared branch, `main`. There are no pull requests and no remote topic branches. Pushing `main` publishes source and playable builds; it does not install anything in DCS (that is `node shared/tools/mission.mjs deploy <slug>`, run on the DCS machine).

1. Start each topic from the latest `main` on a **local** branch: `git fetch origin main && git checkout -b <topic> origin/main`. One topic per branch, for example one mission change. Commit source, design, changelog and the rebuilt playable build together; messages explain why.
2. Before merging, for every mission the change touches: rebuild, run its logic test and run the archive verifier (`node shared/tools/mission.mjs verify <slug>`; `deploy` does all three where DCS is installed). For shared tooling also run `npm run test:tools` and rebuild every mission. Report checks that could not run, such as native Mission Editor checks without DCS, as pending.
3. Keep finished but waiting work on its topic branch. Immediately before pushing, `git fetch origin main`, rebase the topic onto `origin/main`, re-run affected checks if anything new landed, then fast-forward local `main` (`git checkout main && git merge --ff-only <topic>`).
4. Push `main` only (`git push origin main`), never a topic branch, and never with `--force`. Delete the local topic branch afterwards.
5. Report the pushed commit, and whether it was also deployed to DCS.

Ask the user before deleting anything (remote branches, tags, releases, missions or files outside the change) and before publishing a Release. Initial local commits are attributed to the automation; set your Git name and email before making your own commits if they are not configured.

## Stable release

Complete a sortie of the exact candidate build. Record DCS version, Git revision and results in the mission design. Create a tag such as `green-lantern-v1.0.0` and a GitHub Release with the mission and briefing attached. List module requirements and known issues. DCS User Files can link back to this repository.
