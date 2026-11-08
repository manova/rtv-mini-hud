# Focused compatibility design

## Scope

Support the exact reviewed synchronous callbacks from Toolkit 5.5.1 and Lava Lamps 1.1.2 while preserving AIAL 1.2.0. Never use their reported kill totals, assist windows or bookkeeping as player-attribution evidence. The native source contract and existing observer decide whether the player's final blow caused a counted enemy death.

## Witness sequence

The observer witnesses damage pre last, Death pre first, Death pre last, Death post first, Death post last and damage post first. A new last-pre witness consumes exactly the one verified Toolkit callback, then rechecks health, alive/dead state, arguments, actor/target context, source/registry and lifecycle state. The following native Death interval must advance Metro's callback sequence by exactly one. The existing first-post witness remains strict. The last-post witness consumes only the reviewed AIAL and Lava callbacks, once each.

This prevents a bookkeeping callback budget from concealing an extra dispatch inside native Death. Unknown callbacks, deferred death callbacks, duplicates, changed priorities, bound adapters, altered source, native-resource replacement and changed registry identity remain unsupported. The observer never suppresses another mod's callback or changes native damage.

## Callback identity and dependency checks

The callback must be the standard method Callable on the expected live autoload node, with exact priority and Metro instance. Its actual loaded Script must match the reviewed normalized source. Script constants and inherited Script objects are recursively checked. Explicit source-defined inner classes are tied to names in their pinned parent, and their dependencies are checked. The Lava inheritance chain reaches LampData, which owns the boss-name list.

Toolkit emits a synchronous kill_event. Zero connections or its exact reviewed VTKFeed connection are permitted. Extra, deferred, adapted, substituted or changed recipients fail closed. The actual VTKUI source is also checked because the feed can call its icon helper dynamically. Signal connections earn no additional Metro sequence allowance.

Only SHA computation is cached: current source strings and paths are compared at every witness, and dependency graphs, node identities, connections and registries are still rechecked. A changed source invalidates eligibility. Returning to the original source does not restore an already incomplete observer total.

## Limits

This is source-pinned compatibility validation, not an adversarial in-process sandbox. Arbitrary runtime code/data changes and native bypasses are not guaranteed to be detected. Other companion versions, Total Kills/Tally, full mod stacks, general Toolkit/Lava behavior and historical Punisher encounter attribution remain outside this pass. A short manual gameplay pass and repository bot review remain release gates.
