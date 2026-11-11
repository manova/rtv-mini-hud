# Validation scope

## Prepared 0.4.7 release, 11 November 2026

The manually played `0.4.7-vtk-contract.1` candidate is the gameplay baseline. Fresh review identified a nonblocking callback-validity/arity gap: a marker-v1 script with changed parameter counts could pass structural recognition while its VTK callback silently did nothing. The prepared package adds a v1-only guard for valid standard callbacks with the agreed 4/2/2 argument counts and negative fixtures. This does not change the independent native final-blow witness. All other runtime scripts, icons and licenses retain the played candidate bytes; version metadata and changelog are updated. The final guard is covered by native regression below, not a claim of another human gameplay pass. Release preparation is not publication or permission to merge.

Prepared archive SHA256: `b3be4ab5d0986ad06d4cada024d1e358c274d9bbb740b3c8e249cae3ed3cb15e`. The fresh complete serial rerun passed **17,434 native assertion executions in 88 generation/activation phases across 44 isolated profiles**. Every phase returned exit 0, fresh passing results, and no unexpected script errors. The exact prepared archive was used in all eight matrix invocations. Seven package tests passed, and a rebuild from committed Git bytes reproduced the archive exactly. Public CI and bot-review status are tracked on [PR #2](https://github.com/manova/rtv-mini-hud/pull/2); the native results remain local because their inputs are private.

Per loader (Metro 3.4.2 and 3.5.0), developer mode off/on: legacy six-stack matrix 4,210 assertions; v1 active Toolkit/combined/AIAL-combined 2,767; v1 absent combined 857; v1 inactive combined 883. That is 8,717 per loader. Counts include repeated executions, not unique scenarios. The 39 added callback-shape assertions run in each of 20 v1 profiles. KillObserver.gd and NativeAIContract.gd remain byte-identical to baseline 8ed255f. These are modeled-combat fixtures with explicit cleanup, not live combat or ordinary shutdown certification.

The first release-matrix attempt completed 18 phases and 2,987 assertions, then a headless generation process terminated before fixture execution (`ntdll.dll`, `0xc0000409`, offset `0x5a114`). Its output contains only the engine banner. This failed startup is retained and excluded from passing totals. It is distinct from the prior NVIDIA startup failure and the Lava-associated gameplay exit signature; its cause remains unresolved.

### Focused gameplay acceptance

Two isolated user-run processes used the exact candidate, pinned VTK 5.6.4 source build, Metro 3.5.0, MCM 2.9.3 and Lava Lamps 1.1.2. Both capture manifests verified without mismatches (65 and 69 entries), and mounted archives matched their pinned identities. Both logs confirm native observer installation.

- Active HUD: screenshots show Village Mini HUD count 0 then 1, with VTK's player-to-bandit event visible at 1. The tester observed an NPC kill excluded from Mini HUD, then a player kill counted once.
- Same-process HUD disabled: the tester turned off all three VTK HUD features. Screenshots show Highway count reset to 0 while the VTK counter was still visible, then Mini HUD at 1 with VTK visuals hidden. They do not establish whether the reset occurred before or after disabling the settings.
- Fresh process with all three features off: screenshots show Village count 0 then 1 without VTK visuals. Saved VTK configurations confirm all three settings false; the second log records a death and reload. The tester reported player kills working after that reload.

These passes support focused observable compatibility in all three configured HUD states. No trace-level attribution records were captured: the preparation helper's encoding defect stranded a true trace entry outside the valid Bool section, whose effective trace value was false. MCM consequently emitted unsupported-section warnings. This test-kit defect does not invalidate screenshots or the tester's observations, but exact final-shot causality, NPC exclusion and ordering remain tester-observed rather than trace-proven. Actual feed-node absence is verified structurally offline, not established merely by hidden visuals. Corpse-shot repetition, live Metro 3.4.2 and additional ordering combinations are not claimed as new manual coverage.

The isolated test-kit instrumentation was repaired after preserving all retained captures: the malformed section was removed, the effective trace setting and F9 were verified, and the helper now reads/writes explicit BOM-free UTF-8. A separate disposable native fixture emitted actual trace records with clean exit; this was not a new gameplay run. Normal installed files, normal-profile files and VTK settings were unchanged.

### Shutdown and publication limits

Both processes generated Windows `ntdll.dll` / `0xc0000005` crashes at exit with the same offset as the previously isolated Lava-associated fault. Shader/resource cleanup errors were recorded by the tester, not retained in the Godot logs. The new logs end at complete lines, unlike the earlier 4-KiB-boundary examples below. This is consistent with the known shutdown issue; changed Windows and VTK versions mean it is not fresh isolation of its exact cause. No shutdown fix or crash-free stack claim is made.

VTK 5.6.4 remains a reproducible source fixture, not a verified official release archive. Future VTK releases can remain compatible with integer contract v1 and the agreed behavior/structure; this is not a guarantee for unknown builds. Private captures, profiles, local input paths, game files and companion archives are not included in the public repository or package.

## Initial local contract-v1 candidate, 10 November 2026

Candidate 0.4.7-vtk-contract.1 adds only the VTK contract recognition path and local verification tooling. All historical sections below describe 0.4.6 unless noted. At that checkpoint, new live gameplay and external repository review remained pending; no publication, merge, or normal installation had been performed. See the newer preparation and gameplay evidence above.

The VTK baseline is a deterministic private build of official 5.6.4 source at `59a544adc57accd841e9e38ffd55e6e3ac202892`. On 10 November, GitHub exposed no release assets and the available VostokMods latest download resolved to 5.5.1, so no released 5.6.4 binary equivalence is claimed. `tools/build_vtk_fixture.py` reproduces selected upstream pack rules and verifies SHA256 `14228d1e461b6e3bc4e4b6034316849140bb5a884d8dbccee12dc3c81454e725`. The upstream document is the behavioral contract, not an attestation that arbitrary in-process modifications are safe.

The independent local code review found no blocking runtime findings. Its two nonblocking fixture gaps (wrong loaded Script paths and invalid legacy feed-mode combinations) were addressed before the contract matrix. The exact candidate passed 16,654 native assertion executions in 88 fresh generation/activation phases (44 isolated profiles), serially, with no failed checks or unexpected script errors. These fixture processes use modeled damage and actual unchanged companion callbacks, never gameplay or real saves.

Per Metro version (3.4.2 and 3.5.0), developer mode off/on throughout:

- Legacy 5.5.1, six stacks (minimal, AIAL, Toolkit, Lava, Toolkit+Lava, Toolkit+Lava+AIAL): 4,210 assertions, 24 phases.
- VTK v1 active feed, Toolkit / Toolkit+Lava / Toolkit+Lava+AIAL: 2,533 assertions, 12 phases.
- VTK v1 absent feed, Toolkit+Lava: 779 assertions, four phases.
- VTK v1 connected-but-inactive feed, Toolkit+Lava: 805 assertions, four phases.

That is 8,327 assertions per loader. These counts include repeated regression executions, not unique scenarios. Contract checks cover exact-int markers, missing/unknown/non-integer markers, callback registration identity/priority/multiplicity, replace hooks, loaded Hooks/feed Script paths, node paths/back-references, extra/deferred/adapted listeners, and permanent unavailable displays after repairing invalid structure. V1 source-only changes stay compatible while legacy changes fail closed. Existing player/NPC/corpse, native-source, lifecycle, nested-dispatch, AIAL and Lava cases remain. KillObserver.gd and NativeAIContract.gd are byte-identical to baseline 8ed255f.

All seven package tests passed, including an independent rerun. The reproducible VTK source fixture also matched its pinned hash on independent reconstruction. At this initial checkpoint, remote CI and repository bots had not been invoked because the branch was unpublished, and live gameplay acceptance was still pending. The later results are recorded above and on PR #2. Source-build versus released-binary equivalence remains a separate limit. Native fixture cleanup does not certify ordinary gameplay shutdown or resolve the known Lava-associated exit fault.

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
