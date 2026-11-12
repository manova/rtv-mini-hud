# Display and settings checks

Run `python tools/run_ui_tests.py --engine <licensed-local-Godot-engine.exe>`.

The runner creates a fresh adjacent-PCK fixture in `.local/ui/`, using the exact production Model, Settings, Panel and icon bytes. It uses the supplied engine (tested with the game 4.6.3 binary), headless, without mounting the game pack or starting gameplay. The isolated process uses separate APPDATA/LOCALAPPDATA/TEMP/TMP paths. It never reads or writes normal saves/settings. No game executable, assets or private results are committed.

Assertions cover on-by-default install/upgrade behavior, preservation of saved preferences and false values across ConfigFile roundtrips, invalid entries, all four visibility combinations, repeated live changes, pre-ready configuration, stable reading indices, hiding long/multiline trader content, scale/position bounds and default permadeath space, tint isolation, mouse/focus passthrough, and existing display-mode/context rules. The font is the engine fallback because this fixture does not mount game assets. Native-font visual review and in-game MCM/equipment behavior are separate checks.

Read `.local/ui/latest.json` and its fresh result/log paths. Exit zero alone is insufficient: the runner requires the passing assertion result and no unexpected script/engine errors. The script has a bounded frame/time limit. These checks do not establish real gameplay or native timer/kill correctness.
