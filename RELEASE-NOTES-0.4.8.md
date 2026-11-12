# Mini HUD 0.4.8 release notes draft

- Added separate **Show trader timer** and **Show kill counter** options in MCM. Both are on by default, preserving the current layout.
- Hide either cell for a smaller HUD, or hide both for a compact watch-based clock. The panel shrinks to fit the visible cells.
- Hiding the kill counter only hides its display. Tracking continues with the same attribution and reset rules. Trader timers, watch requirements, shortcuts and existing display modes are unchanged.
- Retains the 0.4.7 VTK observer-contract v1 and reviewed legacy compatibility behavior.

The focused in-game checks passed, including all four layouts, hidden-count continuity and saved preferences after relaunch. The previously documented Lava-associated shutdown issue remains outside this update.

Publication status: unreleased draft for pull-request review. Merge, release upload and normal-installation updates require separate authorization.
