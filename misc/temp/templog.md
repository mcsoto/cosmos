# UTF-8 rewrite:

It replaces:
X with ○ — next
G with □ — always
F with ◇ — eventually
U remains U — until

# LPS-style temporal logic sketches

This is executable-design pseudocode, not a commitment to one temporal-logic
parser. `○` means next, `□` always, `◇` eventually, `U` until, and `init` defines
initial fluents. Actions are the validated commands exposed by each profile.

## Shared generic MMO kernel

```text
init day(1) & minute(start_minute) & at(P, initial_place(P))
init available(P, C) <- person(P) & command(C) & command_guard(C, P)

□ tick(T) -> ○ tick(T + 1)
□ (minute(M) & advance(D) & M + D < 1440) -> ○ minute(M + D)
□ (minute(M) & advance(D) & M + D >= 1440) -> ○ (day(Day + 1) & minute((M + D) mod 1440))

□ cycle(P) -> observe(P, O) ; think(P, O, I) ; validate(P, I) ; act(P, I)
□ proposed(P, I) & not available(P, command(I)) -> ○ intent(P, wait)
□ move(P, To) -> at(P, From) U arrived(P, To)
□ arrived(P, To) -> ○ at(P, To)
□ say(P, Text, local) -> ○ heard(Q, Text) for each Q where at(Q, place(P))
□ due(Event, P) -> ◇ (at(P, event_place(Event)) | declined(P, Event))
□ provider_failure(P, Slot) -> ○ use_local_policy(P, Slot)
```

Safety/liveness intent:

```text
□ (act(P, I) -> validated(P, I))
□ not(at(P, A) & at(P, B) & A != B)
□ (accepted_move(P, To) -> ◇ arrived(P, To))
```

## `temp/21/7` — early Astral Academy

```text
init at(student, dining) & energy(student, configured_energy)

□ active_event(P, E) -> event_destination(E) overrides schedule_destination(P)
□ energy(P, E) & E < 20 -> ○ intent(P, move(common))
□ schedule_destination(P, R) & not at(P, R) -> ○ intent(P, move(R))
□ duel_event(P) & energy(P, E) & E >= 8 -> ◇ cast(P, preferred_affinity_spell(P))
□ travelling(P, R) -> travelling(P, R) U arrived(P, R)
□ arrived(P, R) -> ○ activity(P, scheduled_or_event_activity(P, R))
```

## `temp/7 v1.2` — expanded Astral Academy

```text
init memory(P, []) & relationship(P, Q, 0) & mastery(P, Spell, seeded(P, Spell))

□ recent_incident(P) -> ○ cautious(P) U recovered_focus(P)
□ duel_event(P) & not recent_spell_failure(P) -> ◇ (cast(P, S) | event_ends)
□ spell_failure(P, S) -> ○ remember(P, spell_incident(S))
□ witnessed(Q, spell_failure(P, S)) -> ○ remember(Q, witnessed_failure(P, S))
□ social_context(P) & nearby(P, Q) & cooldown_ready(P) -> ◇ socialize(P, Q)
□ socialize(P, Q) -> ○ relationship(P, Q, Score + social_delta)
□ class_together(P, Q) -> ○ acquainted(P, Q)
□ full_think(P) & ota_trigger(P) -> ◇ (api_intent(P, I) | local_fallback(P))
□ api_intent(P, I) -> validate(I) ; (act(P, I) | ○ local_fallback(P))
```

## `temp/22mmo` — Starling City

```text
init resident(P) -> at(P, configured_location(P)) & follows(P, configured_schedule(P))

□ observe(P, O) -> ○ layer1_intent(P, choose(O, personality(P), goals(P)))
□ layer1_intent(P, move(Place)) -> ○ layer2_path(P, astar(current(P), Place))
□ layer2_path(P, Path) -> following(P, Path) U arrived(P, Place)
□ local_say(P, Text) -> ○ heard(Q, Text) iff same_place(P, Q)
□ private_say(P, Q, Text) -> ○ heard(Q, Text)
□ community_market_active & participant(P) -> ◇ at(P, town_square)
□ model_output(coordinates(_)) -> ○ reject_output & local_fallback(P)
```

## `temp/generic_mmo` — data-defined Crossroads example

```text
init at(ada, square) & at(borin, inn)

□ energy(P, E) & E < 20 -> ○ move(P, inn)
□ active_event(ada, ruins_expedition) -> ◇ at(ada, ruins)
□ schedule_due(P, Place) & not at(P, Place) -> ○ move(P, Place)
□ at(P, Place) & nearby(P, Q) -> ◇ say(P, greeting(Q), local)
□ inspect(P) -> ○ remember(P, inspection(current_place(P)))
□ no_rule_matches(P) -> ○ wait(P)
```

These formulas make the key division explicit: temporal rules and model/local
policy propose semantic commands; validation and game adapters remain the only
authority that mutates the simulated world.
