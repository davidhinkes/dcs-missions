# Build inputs

`config.json` defines positions, fuel and timing. `templates.json` stores baseline DCS mission settings and an OH-58D unit configuration, copied as data during authoring from the existing local mission collection so this builder does not depend on another mission directory or personal Saved Games files. The collection's previous template provenance applies; no donor mission or external aircraft mod is needed at runtime.

`build.mjs` creates the standalone archive and embeds generated configuration plus `rescue.lua`. No mission framework is required. The UH-60A is authored using its built-in DCS unit type. Ground/temporary-landing schemas and Kiowa navigation-target fields were checked against locally installed DCS editor code and the module manual. That schema evidence is not an in-game test.
