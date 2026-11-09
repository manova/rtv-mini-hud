# Mini HUD

A read-only status HUD for Road to Vostok and Metro Mod Loader.

This compatibility candidate retains the released HUD behavior and fails closed when native kill attribution is unavailable. It fixes generated-method comment boundaries and adds source-verified callback compatibility for Vostok Toolkit 5.5.1 and Murdie Lava Lamps 1.1.2, retaining AI Actually Loots 1.2.0 support. Exact Metro 3.4.2 and 3.5.0 source and wrapper families are recognized; unknown or altered loaders remain unsupported.

This is not compatibility with every version or mod, and not a sandbox against arbitrary in-process code changes. Total Kills/Tally is not supported by this candidate.

## Build

Run `python tools/build.py`. The deterministic VMZ is written to `dist/`. Entries are stored without compression so their bytes do not depend on host zlib versions. Only `src/` files are packaged. No game files, loader, companion mods, profiles, reports or QA helpers belong in the shipped package.

## Verification

Run `python -m unittest discover -s tests -v` for package checks. Native regression tests need separately obtained game/loader/companion-mod inputs and are described in `tests/native/README.md`. They use modeled combat, not gameplay. Focused Metro 3.4.2 and 3.5.0 manual gameplay passes are complete; see VALIDATION.md for evidence, limits, and the separate Lava-associated shutdown fault. Release packaging preserves the reviewed and gameplay-tested runtime bytes.

## Licensing

Mini HUD code and Phosphor Icons are MIT licensed; see the source licenses and notices. The synthetic test dispatch wrappers follow Metro's generated wrapper structure and retain Metro's MIT license in `tests/native/METRO-LICENSE.txt`. Native game scripts, archives and assets are never redistributed here.
