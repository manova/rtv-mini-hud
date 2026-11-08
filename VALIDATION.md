# Validation scope

## Runtime regression evidence

The candidate passed 3,250 assertions in 24 fresh native generation/activation phases: minimal, AIAL, Toolkit, Lava, Toolkit+Lava, and Toolkit+Lava+AIAL, each with developer mode off/on. These use modeled combat and actual unchanged companion callbacks, not gameplay. Fixture cleanup clears Engine metadata before exit; those clean exits do not establish ordinary game shutdown safety.

Tested inputs: game 0.2.3.1/build 26332724, native Windows engine 4.6.3, Metro 3.4.2, MCM 2.9.3; AIAL 1.2.0, Toolkit 5.5.1, Lava Lamps 1.1.2. Metro 3.5.0 and Total Kills/Tally are not validated.

Negative cases cover unknown/deferred/duplicate callbacks, changed priority, source, inherited dependencies and signal recipients, bound adapters, extra native-body dispatch, NPC/corpse attribution, unpaired/nested deaths, lifecycle interruption and immutable incomplete totals. Existing AIAL tests and both generated-source layouts pass. The final package also passed 551 combined-stack and 415 minimal-stack assertions through the portable runner; these repeat scenarios, not additional unique coverage.

## Manual gameplay, 8 November 2026

Fresh isolated launches used the exact candidate with Toolkit and Lava Lamps together, developer mode off. NPC-first play showed no credit for NPC deaths, one credit per player kill, and no extra credit for corpse shots. Retained traces explicitly confirm the first two player kills; screenshots show 0 to 1 to 2 to 3. One credited victim had prior NPC damage.

A separate fresh-process player-first run was observed directly by the tester: first player kill changed 0 to 1 and corpse shots left it at 1. Its log ended before combat and no new screenshot was captured, so this ordering is tester-observed, not independently trace-verified. Capture manifests matched all files. No further combat repetition is required for this focused manual gate.

## Separate shutdown limitation

Actual game-menu startup followed by native Loader.Quit, with no fixture cleanup, produced exit 0 for vanilla, Metro/MCM, Toolkit, and the Mini HUD candidate without companions. Lava Lamps alone, Toolkit+Lava without Mini HUD, and Toolkit+Lava+candidate with diagnostics off/on each produced access violation 0xc0000005. Windows crash events matched the gameplay-exit signature.

This establishes a Lava-associated shutdown fault in the tested D3D12/current-driver environment; Mini HUD is not required. Exact native ownership and any driver-update contribution remain unresolved. It is not a claim of universal Lava incompatibility. Original and captured logs end identically mid-line on 4-KiB boundaries; loss of buffered output on abnormal termination is the likely explanation, not a proven buffering diagnosis. No Mini HUD workaround was added.

## Release gates and limits

The focused gameplay gate is complete. Exact-commit PR/bot review and final release packaging/checks remain required before publication. CI covers package checks only; native tests require private local inputs. No evidence certifies arbitrary mods/versions, historical Punisher attribution, or all companion features. Compatibility validation is not a security sandbox against arbitrary in-process modification.

## Prepared 0.4.6 package

The final-version archive SHA256 is 7db707b883ef94398188d03ab084b5eeaed738c635cd9c887784005f6c45fa47. Only mod.txt and CHANGELOG.txt differ from the manually tested candidate; all runtime, asset and license bytes are identical. This exact archive passed 966 repeated native assertions across minimal and Toolkit+Lava stacks with developer off/on (eight fresh phases), plus five package checks. These use the explicitly cleaned fixture shutdown path, not normal gameplay quit. Publication remains unperformed.

