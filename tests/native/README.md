# Native regression tests

These are owned synthetic fixtures plus Metro-style test dispatch wrappers. They exercise actual unchanged companion callbacks and actual native source-contract boot checks; damage bodies are modeled. They are not live combat or comprehensive mod-stack certification.

`python tools/run_native_tests.py --inputs inputs.local.json`

The private JSON must map these keys to local files: `engine` (RTV.exe), `game_pack` (RTV.pck), `loader` (official Metro 3.4.2 or 3.5.0 modloader.gd), `class_cache` (the game's global_script_class_cache.cfg), `mcm` (2.9.3 archive), `toolkit` (5.5.1 archive), `lava` (1.1.2 archive), `aial` (1.2.0 archive), `captured_minimal` and `captured_broad` (locally generated native AI snapshots for minimal and registry layouts).

These inputs are excluded from version control. Obtain/run third-party software only with the necessary permission. The runner uses fresh profiles under `.local/`, independent executable/game copies, hidden Windows renderer activation, and retained logs/results. It never uses real saves. Existing `.local/runtime` copies must match input bytes. Run only one native matrix at a time.

The baseline observer reproduction uses a temporary nontrusted metadata sentinel when AIAL is absent solely to avoid the old missing-meta diagnostic; it grants no callback trust. Source-gate negative tests mutate and restore source text in the disposable process, not original archives. Fixture cleanup clears test-process Engine metadata to release companion resources before renderer shutdown.

The exact-source checks deliberately reject modified/future companion versions. The declared assertions and source comparisons must pass; exit zero and fresh completion records alone are insufficient. Game files, generated native snapshots, other mods, profiles, private logs and screenshots must not be committed.
