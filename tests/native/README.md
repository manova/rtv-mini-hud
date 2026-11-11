# Native regression tests

These are owned synthetic fixtures plus Metro-style test dispatch wrappers. They exercise actual unchanged companion callbacks and actual native source-contract boot checks; damage bodies are modeled. They are not live combat or comprehensive mod-stack certification.

`python tools/run_native_tests.py --inputs inputs.local.json`

The private JSON must map these keys to local files: `engine` (RTV.exe), `game_pack` (RTV.pck), `loader` (official Metro 3.4.2 or 3.5.0 modloader.gd), `class_cache` (the game's global_script_class_cache.cfg), `mcm` (2.9.3 archive), `toolkit` (5.5.1 archive or the reproducible 5.6.4 source fixture), `lava` (1.1.2 archive), `aial` (1.2.0 archive), `captured_minimal` and `captured_broad` (locally generated native AI snapshots for minimal and registry layouts).

These inputs are excluded from version control. Obtain/run third-party software only with the necessary permission. The runner uses fresh profiles under `.local/`, independent executable/game copies, hidden Windows renderer activation, and retained logs/results. It never uses real saves. Existing `.local/runtime` copies must match input bytes. Run only one native matrix at a time.

The baseline observer reproduction uses a temporary nontrusted metadata sentinel when AIAL is absent solely to avoid the old missing-meta diagnostic; it grants no callback trust. Source-gate negative tests mutate and restore source text in the disposable process, not original archives. Fixture cleanup clears test-process Engine metadata to release companion resources before renderer shutdown.

Legacy exact-source checks deliberately reject modified/future companion versions; VTK contract v1 instead checks its exact marker and live structure. The declared assertions and source comparisons must pass; exit zero and fresh completion records alone are insufficient. Game files, generated native snapshots, other mods, profiles, private logs and screenshots must not be committed.

## VTK contract-v1 fixture

Obtain the GitHub source ZIP for official commit `59a544adc57accd841e9e38ffd55e6e3ac202892` from dgtball/rtv-mods separately and extract it without changing tracked bytes. A checkout with automatic newline conversion may not reproduce the pinned fixture. Build with `python tools/build_vtk_fixture.py --source <checkout>/mods/vostok-toolkit --output <private-dir>/VostokToolkit-5.6.4-source.vmz`. The helper reproduces upstream pack.ps1 entry selection/comment stripping with deterministic ZIP_STORED metadata, validates the complete resulting hash, and never executes upstream build code. This is a local source build, not verification of a released archive. No VTK source is redistributed in this repository or Mini HUD package.

The fixture SHA256 is `14228d1e461b6e3bc4e4b6034316849140bb5a884d8dbccee12dc3c81454e725`. The original legacy archive identity is still accepted separately. The runner reads the version from the actual input manifest, uses separate runtime copies per loader hash, rejects non-active legacy 5.5.1 feed fixtures, and supports `--feed-state active`, `inactive`, or `absent`. Absent state disables all three VTK HUD features in the fresh MCM profile before boot. Inactive state creates the real feed, then disables all three via the actual feature host. The callback remains connected. Active state exercises real feed row construction.

Run the six-stack legacy matrix for both loaders. Run the toolkit/combined/aial-combined v1 active stacks and combined v1 absent/inactive stacks for both loaders, developer mode off/on in every invocation. Existing native, lifecycle, nested dispatch, source, registry, NPC, corpse, AIAL and Lava regressions remain. New structural negatives cover missing/unknown/non-integer markers, malformed VTK registrations, invalid/missing callbacks and exact 4/2/2 method arities, feed identity/back-reference and irreversible incomplete displays. Source-only UI/dependency changes are accepted on v1 and still rejected on legacy. These are modeled combat assertions, not gameplay acceptance or proof against arbitrary runtime modification.
