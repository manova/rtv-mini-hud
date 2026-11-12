# Mini HUD

A read-only status HUD for Road to Vostok and Metro Mod Loader.

## Prepared 0.4.8: optional cells

The Time-slot clock remains the foundation. MCM now has independent **Show trader timer** and **Show kill counter** settings. Both default to on, including upgrades with no saved value for the new keys. Hide either for a two-cell row, or both for a compact clock-only panel. The existing watch requirement, unavailable placeholder, optional equipment bypass, Toggle/Always on modes, saved shortcut, scale and placement remain unchanged.

These are presentation options: kill tracking, attribution safeguards and reset rules continue while the counter is hidden. Hiding the trader timer does not modify native timers. This is not a way to disable kill-observer hooks or bypass compatibility checks. Source changes are confined to Settings and Panel, plus release metadata. The 0.4.7 compatibility information below remains applicable.

This is an unreleased 0.4.8 candidate prepared for draft pull-request review. Focused automated validation is recorded in [VALIDATION.md](VALIDATION.md). The focused in-game acceptance test is complete, including hidden-count continuity and preference persistence after relaunch. Public CI and review results are tracked in the pull request; merge and publication require separate authorization. The existing Lava-associated shutdown caveat remains; see the evidence limits in VALIDATION.md. No game, loader, companion mods, profile or test artifacts are distributed in the VMZ.

## Compatibility baseline

The 0.4.7 compatibility baseline adds VTK observation-contract v1 compatibility. It accepts exactly the integer `OBSERVER_CONTRACT = 1` on the live VTKHooks script, with concrete callback, registration, feed, and loader checks. UI or unrelated VTK source changes no longer require updating hashes for contract v1. Unknown markers and unexpected death callbacks/listeners remain unsupported.

The independent native final-blow observer is unchanged: no VTK counter, assist window, signal payload, or kill attribution is imported. The exact-source fallback for VTK 5.5.1, Murdie Lava Lamps 1.1.2, and AI Actually Loots 1.2.0 remains. Exact Metro 3.4.2 and 3.5.0 loader/wrapper families remain required.

The 5.6.4 baseline is a local build from official source commit `59a544adc57accd841e9e38ffd55e6e3ac202892`, not a verified published archive. Earlier candidate gameplay on Metro 3.5.0 supports numeric counts with VTK HUD active, disabled mid-session, and off before a fresh launch. A further light smoke used the exact final 0.4.7 archive with VTK feed active: screenshots show a player kill counted and an NPC event excluded, while the tester reports no extra credit for a corpse shot. These are screenshot/tester observations, not combat-trace proof: the earlier profiles had a trace-setting defect, and the final profile enabled tracing but retained only pre-combat records. See [VALIDATION.md](VALIDATION.md) for the evidence and limits. This does not add live Metro 3.4.2 or released-VTK-binary coverage. This is contract-based interoperability, not an adversarial in-process sandbox or certification of arbitrary mods. Total Kills/Tally is not supported.

## Build

Run `python tools/build.py`. The deterministic VMZ is written to `dist/`. Entries are stored without compression so their bytes do not depend on host zlib versions. Only `src/` files are packaged. No game files, loader, companion mods, profiles, reports or QA helpers belong in the shipped package.

## Verification

Run `python -m unittest discover -s tests -v` for package checks. Run `python tools/run_ui_tests.py --engine <licensed-local-engine.exe>` for isolated Godot display and settings tests; see `tests/ui/README.md`. Native regression tests need separately obtained game/loader/companion-mod inputs and are described in `tests/native/README.md`. They use modeled combat, not gameplay. The previous 0.4.6 release had focused Metro 3.4.2 and 3.5.0 gameplay passes. Those remain separate historical regression evidence. See VALIDATION.md for the new test scope and the separate Lava-associated shutdown fault.

## Licensing

Mini HUD code and Phosphor Icons are MIT licensed; see the source licenses and notices. The synthetic test dispatch wrappers follow Metro's generated wrapper structure and retain Metro's MIT license in `tests/native/METRO-LICENSE.txt`. Native game scripts, archives and assets are never redistributed here.
