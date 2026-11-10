# Mini HUD

A read-only status HUD for Road to Vostok and Metro Mod Loader.

This local 0.4.7 candidate adds VTK observation-contract v1 compatibility. It accepts exactly the integer `OBSERVER_CONTRACT = 1` on the live VTKHooks script, with concrete callback, registration, feed, and loader checks. UI or unrelated VTK source changes no longer require updating hashes for contract v1. Unknown markers and unexpected death callbacks/listeners remain unsupported.

The independent native final-blow observer is unchanged: no VTK counter, assist window, signal payload, or kill attribution is imported. The exact-source fallback for VTK 5.5.1, Murdie Lava Lamps 1.1.2, and AI Actually Loots 1.2.0 remains. Exact Metro 3.4.2 and 3.5.0 loader/wrapper families remain required.

The 5.6.4 baseline is a local build from official source commit `59a544adc57accd841e9e38ffd55e6e3ac202892`, not a verified published archive. Live gameplay acceptance of this new candidate is pending. This is contract-based interoperability, not an adversarial in-process sandbox or certification of arbitrary mods. Total Kills/Tally is not supported.

## Build

Run `python tools/build.py`. The deterministic VMZ is written to `dist/`. Entries are stored without compression so their bytes do not depend on host zlib versions. Only `src/` files are packaged. No game files, loader, companion mods, profiles, reports or QA helpers belong in the shipped package.

## Verification

Run `python -m unittest discover -s tests -v` for package checks. Native regression tests need separately obtained game/loader/companion-mod inputs and are described in `tests/native/README.md`. They use modeled combat, not gameplay. The previous 0.4.6 release had focused Metro 3.4.2 and 3.5.0 gameplay passes. Those are regression context, not acceptance of this candidate. See VALIDATION.md for the new test scope and the separate Lava-associated shutdown fault.

## Licensing

Mini HUD code and Phosphor Icons are MIT licensed; see the source licenses and notices. The synthetic test dispatch wrappers follow Metro's generated wrapper structure and retain Metro's MIT license in `tests/native/METRO-LICENSE.txt`. Native game scripts, archives and assets are never redistributed here.
