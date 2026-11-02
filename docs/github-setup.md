# GitHub backup and releases

Repository: https://github.com/davidhinkes/dcs-missions (public, as requested by the owner).

The initial upload uses the connected GitHub integration because local command-line authentication is not configured. The repository contains source, designs, tests and the playable mission. Local dependencies, caches and flight logs are ignored.

## Normal work

Commit source, design, changelog and the current playable build together. Synchronize through the GitHub integration or configure local GitHub authentication to push with Git. Initial local commits are attributed to the automation; set your Git name and email before making your own commits if they are not configured.

## Stable release

Complete a sortie of the exact candidate build. Record DCS version, Git revision and results in the mission design. Create a tag such as `green-lantern-v1.0.0` and a GitHub Release with the mission and briefing attached. List module requirements and known issues. DCS User Files can link back to this repository.
