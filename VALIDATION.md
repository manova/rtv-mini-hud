# Validation scope

## Local contract-v1 candidate, 10 November 2026

Candidate 0.4.7-vtk-contract.1 adds only the VTK contract recognition path and local verification tooling. All historical sections below describe 0.4.6 unless noted. New live gameplay and external repository review remain pending; no publication, merge, or normal installation has been performed.

The VTK baseline is a deterministic private build of official 5.6.4 source at `59a544adc57accd841e9e38ffd55e6e3ac202892`. GitHub exposes no release assets and the available VostokMods latest download resolves to 5.5.1, so no released 5.6.4 binary equivalence is claimed. `tools/build_vtk_fixture.py` reproduces selected upstream pack rules and verifies SHA256 `14228d1e461b6e3bc4e4b6034316849140bb5a884d8dbccee12dc3c81454e725`. The upstream document is the behavioral contract, not an attestation that arbitrary in-process modifications are safe.

The independent local code review found no blocking runtime findings. Its two nonblocking fixture gaps (wrong loaded Script paths and invalid legacy feed-mode combinations) were addressed before the contract matrix. The exact candidate passed 16,654 native assertion executions in 88 fresh generation/activation phases (44 isolated profiles), serially, with no failed checks or unexpected script errors. These fixture processes use modeled damage and actual unchanged companion callbacks, never gameplay or real saves.

Per Metro version (3.4.2 and 3.5.0), developer mode off/on throughout:

- Legacy 5.5.1, six stacks (minimal, AIAL, Toolkit, Lava, Toolkit+Lava, Toolkit+Lava+AIAL): 4,210 assertions, 24 phases.
- VTK v1 active feed, Toolkit / Toolkit+Lava / Toolkit+Lava+AIAL: 2,533 assertions, 12 phases.
- VTK v1 absent feed, Toolkit+Lava: 779 assertions, four phases.
- VTK v1 connected-but-inactive feed, Toolkit+Lava: 805 assertions, four phases.

That is 8,327 assertions per loader. These counts include repeated regression executions, not unique scenarios. Contract checks cover exact-int markers, missing/unknown/non-integer markers, callback registration identity/priority/multiplicity, replace hooks, loaded Hooks/feed Script paths, node paths/back-references, extra/deferred/adapted listeners, and permanent unavailable displays after repairing invalid structure. V1 source-only changes stay compatible while legacy changes fail closed. Existing player/NPC/corpse, native-source, lifecycle, nested-dispatch, AIAL and Lava cases remain. KillObserver.gd and NativeAIContract.gd are byte-identical to baseline 8ed255f.

All seven package tests passed, including an independent rerun. The reproducible VTK source fixture also matched its pinned hash on independent reconstruction. Remote CI and repository bots were not invoked because this branch remains unpublished. Live gameplay acceptance and source-build versus released-binary equivalence remain separate limits. Native fixture cleanup does not certify ordinary gameplay shutdown or resolve the known Lava-associated exit fault.

Candidate archive SHA256: `0506aac70db933caabd776fe4098fee01056d2ad8379f6bf73f8791fa94f442e`. Package checks verify the checksum, deterministic entry bytes, native-body boundary, exact version guard, exclusion of VTK count import/signal subscription, and default-off tracing.


## Runtime regression evidence

The candidate passed 3,250 assertions in 24 fresh native generation/activation phases: minimal, AIAL, Toolkit, Lava, Toolkit+Lava, and Toolkit+Lava+AIAL, each with developer mode off/on. These use modeled combat and actual unchanged companion callbacks, not gameplay. Fixture cleanup clears Engine metadata before exit; those clean exits do not establish ordinary game shutdown safety.

Tested inputs: game 0.2.3.1/build 26332724, native Windows engine 4.6.3, Metro 3.4.2, MCM 2.9.3; AIAL 1.2.0, Toolkit 5.5.1, Lava Lamps 1.1.2. Those original results did not validate Metro 3.5.0; see the additional assessment below. Total Kills/Tally remains unvalidated.

Negative cases cover unknown/deferred/duplicate callbacks, changed priority, source, inherited dependencies and signal recipients, bound adapters, extra native-body dispatch, NPC/corpse attribution, unpaired/nested deaths, lifecycle interruption and immutable incomplete totals. Existing AIAL tests and both generated-source layouts pass. The final package also passed 551 combined-stack and 415 minimal-stack assertions through the portable runner; these repeat scenarios, not additional unique coverage.

## Manual gameplay, 8 November 2026

Fresh isolated launches used the exact candidate with Toolkit and Lava Lamps together, developer mode off. NPC-first play showed no credit for NPC deaths, one credit per player kill, and no extra credit for corpse shots. Retained traces explicitly confirm the first two player kills; screenshots show 0 to 1 to 2 to 3. One credited victim had prior NPC damage.

A separate fresh-process player-first run was observed directly by the tester: first player kill changed 0 to 1 and corpse shots left it at 1. Its log ended before combat and no new screenshot was captured, so this ordering is tester-observed, not independently trace-verified. Capture manifests matched all files. This completes the original 3.4.2 manual gate. The later 3.5.0 runtime guard change requires a separate short smoke test.

## Separate shutdown limitation

Actual game-menu startup followed by native Loader.Quit, with no fixture cleanup, produced exit 0 for vanilla, Metro/MCM, Toolkit, and the Mini HUD candidate without companions. Lava Lamps alone, Toolkit+Lava without Mini HUD, and Toolkit+Lava+candidate with diagnostics off/on each produced access violation 0xc0000005. Windows crash events matched the gameplay-exit signature.

This establishes a Lava-associated shutdown fault in the tested D3D12/current-driver environment; Mini HUD is not required. Exact native ownership and any driver-update contribution remain unresolved. It is not a claim of universal Lava incompatibility. Original and captured logs end identically mid-line on 4-KiB boundaries; loss of buffered output on abnormal termination is the likely explanation, not a proven buffering diagnosis. No Mini HUD workaround was added.

## Release gates and limits

The original 3.4.2 gameplay gate and later 3.5.0 smoke test are complete. Runtime commit 357ad2148372da7076b2d72aff40594dbfd8d7b6 passed Codex and Cursor review, with no unresolved findings. Final release metadata and package checks are separate from runtime validation. CI covers package checks only; native tests require private local inputs. No evidence certifies arbitrary mods/versions, historical Punisher attribution, or all companion features. Compatibility validation is not a security sandbox against arbitrary in-process modification.

## Earlier prepared 0.4.6 package (superseded by Metro update)

The earlier archive SHA256 was 12935bd89a229564b849236c753cfd2d2fa3c5e1b85d40b735960d51ffa275c9. Only mod.txt and CHANGELOG.txt differ from the manually tested candidate; all runtime, asset and license bytes are identical. This exact archive passed 966 repeated native assertions across minimal and Toolkit+Lava stacks with developer off/on (eight fresh phases), plus five package checks. These use the explicitly cleaned fixture shutdown path, not normal gameplay quit. Publication remains unperformed.

Archive entries use ZIP_STORED with pinned platform and permission metadata. Python 3.12 and 3.13 on Windows reproduce the same checksum; CI verifies the committed checksum across Python 3.12, 3.13 and 3.14 on Linux. Compression encoding changes do not alter extracted runtime bytes.

## Metro 3.5.0 assessment

The exact official 3.5.0 release loader SHA256 is 1fa1d7d9dd3029582758a76b00f5d70428fd915e2d54a58a64ca0fdf2f0cd3e7. The prior candidate reproduced N/A in both minimal and Toolkit+Lava stacks: its source-pinned loader and wrapper contracts did not recognize this release. The complete minimal generated AI source differs only by four wrapper local identifier renames. Native bodies and header are unchanged.

The added compatibility accepts the exact official loader and one coherent exact wrapper family, retaining rejection of mixed families, changed bodies, unknown loaders and reflective fields. 3.4.2 regression matrix passed 4,210 assertions across six stacks, each developer off/on. The 3.5.0 matrix also passed 4,210 assertions; both matrices cover six stacks with developer mode off/on, 48 fresh generation/activation phases in total. Refreshed exact-runtime-head Codex and Cursor reviews passed. Fixtures now use the appropriate real developer probe for each Metro version; the old camera argument-conversion regression is exercised by an explicit fixture on 3.5.0, where that released probe no longer exists.

One initial 3.5.0 activation terminated in NVIDIA nvoglv64.dll with 0xc0000409 before assertions; it is excluded, not called a pass. This is distinct from the previously documented Lava exit fault. A subsequent serial run reached the assertions.

The fresh 3.5.0 gameplay smoke is complete: retained traces confirm seven player kills against seven distinct targets, with totals 1 through 7. Corpse damage after credited kills produced no additional acceptance; the final screenshot shows seven kills. The game randomly initialized the Nomad pool to zero, so NPC-versus-NPC exclusion was not observed in this run. Earlier 3.4.2 live evidence and both-loader native regression coverage remain relevant, without claiming a 3.5.0 live NPC test. Capture integrity verified all 68 manifest entries. The archived observations form was blank; the tester completed the separate working observations afterward.

A system reboot preceded this smoke. Windows still recorded the same ntdll.dll/0xc0000005 exit fault for the isolated game, despite no visible quit error; the log ended mid-line after the seventh kill. This does not establish that reboot or Metro 3.5.0 resolved the separate Lava-associated shutdown issue.
