# Focused compatibility design

## Scope

Support VTK observer contract v1 and the exact reviewed legacy callbacks from Toolkit 5.5.1 and Lava Lamps 1.1.2 while preserving AIAL 1.2.0. Never use their reported kill totals, assist windows or bookkeeping as player-attribution evidence. The native source contract and existing observer decide whether the player's final blow caused a counted enemy death.

## Witness sequence

The observer witnesses damage pre last, Death pre first, Death pre last, Death post first, Death post last and damage post first. A new last-pre witness consumes exactly the one verified Toolkit callback, then rechecks health, alive/dead state, arguments, actor/target context, source/registry and lifecycle state. The following native Death interval must advance Metro's callback sequence by exactly one. The existing first-post witness remains strict. The last-post witness consumes only the reviewed AIAL and Lava callbacks, once each.

This prevents a bookkeeping callback budget from concealing an extra dispatch inside native Death. Unknown callbacks, deferred death callbacks, duplicates, changed priorities, bound adapters, altered native or legacy-pinned source, native-resource replacement and changed registry identity remain unsupported. The observer never suppresses another mod's callback or changes native damage.

## Callback identity and dependency checks

The callback must be the standard method Callable on the expected live node and loaded Script path, with exact priority and Metro instance. Legacy VTK 5.5.1 and Lava require the reviewed normalized source. Script constants and inherited Script objects are recursively checked. Explicit source-defined inner classes are tied to names in their pinned parent, and their dependencies are checked. The Lava inheritance chain reaches LampData, which owns the boss-name list.

Toolkit emits a synchronous kill_event. Zero connections or its exact reviewed VTKFeed connection are permitted. Extra, deferred, adapted, substituted or changed recipients fail closed. Legacy VTK also requires the exact VTKUI source because that feed can call its icon helper dynamically. Contract v1 covers the full VTK-owned synchronous path instead. Signal connections earn no additional Metro sequence allowance.

On the legacy path, only SHA computation is cached: current source strings and paths are compared at every witness, and dependency graphs, node identities, connections and registries are still rechecked. A changed source invalidates eligibility. Returning to the original source does not restore an already incomplete observer total.

## VTK contract v1

The agreement is [OBSERVER_CONTRACT.md at 59a544a](https://github.com/dgtball/rtv-mods/blob/59a544adc57accd841e9e38ffd55e6e3ac202892/mods/vostok-toolkit/OBSERVER_CONTRACT.md). The marker is independent of VTK release version. Only integer 1 is accepted; missing markers can use only the existing exact-hash 5.5.1 path. Explicit unknown markers never fall back, and floats, strings and booleans are rejected.

The live VTKHooks node and Script path, `_on_ai_death` Callable, priority 100 and `_lib` identity are checked at every witness. Each of the three agreed damage/death pre registrations must be present exactly once on that owner, with the expected standard method and priority. Replace hooks remain unsupported. Unknown Death callbacks cannot consume VTK's sequence allowance.

The three standard observation Callables must be valid and expose the agreed 4/2/2 argument counts. Wrong arities cannot receive an allowance merely because Metro advances its dispatch sequence.

Zero kill_event listeners is valid when VTK HUD has never been enabled. Otherwise the only permitted listener is the standard `_on_kill_event` method on `VTKKC_Canvas/VTKFeed`, with the agreed Script path, flags 0 and `_hooks` back-reference. An existing disabled feed remains valid. The listener snapshot must stay unchanged through the event. The explicit named feed baseline is 5.6.4; unnamed 5.6.3 feed nodes are not claimed here.

Contract v1 deliberately does not hash VTK UI, callback or dependency source. The version marker is VTK's behavioral promise for its complete synchronous observation path; it is not proof that arbitrary scripts are harmless. Reading structural properties can execute getters. Mini HUD adds no signal listener, invokes no VTK attribution method and reads no VTK kill count/payload. Consequently payload validation is not an attribution gate: Mini HUD never consumes that payload.

The native witness sequence and all native-source/lifecycle/player/enemy checks remain unchanged. New trust does not grant any extra dispatch allowance across the native Death body. A detected gap keeps the applicable display unavailable after structure is restored; it cannot show a partial resumed total.

## Limits

This combines versioned-contract compatibility with legacy source pins, not an adversarial in-process sandbox. Arbitrary runtime code/data changes and native bypasses are not guaranteed to be detected. Unknown VTK contract versions, other Lava/AIAL versions, Total Kills/Tally, full mod stacks, general Toolkit/Lava behavior and historical Punisher encounter attribution remain outside this pass. The previous 0.4.6 gameplay/repository-bot reviews do not certify this local candidate. New live gameplay acceptance remains pending.

## Metro 3.5.0 compatibility

Pin the complete normalized official loader source for both 3.4.2 and 3.5.0. Reviewed dispatch still increments its sequence per callback and retains priority and caller semantics. The three generated damage/death wrappers changed only four local identifiers in the compared minimal output. Accept either complete exact wrapper fingerprint family, never individual mixed families; native bodies, declarations and reflective-method exclusions are unchanged. This is deliberately narrow compatibility, not normalization of arbitrary generated code.
