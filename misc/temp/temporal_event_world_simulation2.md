# Temporal Event World 2

## An LPS-like event and reactive simulation model

This document describes the event-driven simulation used by the project. It combines persistent fluents, discrete events, reactive rules, temporal logic, scheduled time, and region-level simulation detail.

The central principle is:

> Advance the world when something meaningful happens; derive the effects of elapsed time instead of updating every object every frame.

## 1. Persistent fluents

A fluent is a fact that persists until an event changes it:

```prolog
initially(location(red_dragon, mountain)).
initially(sleeping(red_dragon)).
initially(hungry(red_dragon)).
initially(health(red_dragon, 120)).
initially(weather(valley, clear)).
```

Fluents use inertia. If `location(red_dragon, mountain)` is true at one logical state, it remains true in later states unless an event terminates it.

## 2. Events and their effects

Events are discrete occurrences. They may be scheduled at a particular world time:

```prolog
happens(wake(red_dragon), 1080).
happens(storm(valley), 1140).
```

An event can initiate or terminate fluents:

```prolog
initiates(wake(red_dragon), awake(red_dragon)).
terminates(wake(red_dragon), sleeping(red_dragon)).

initiates(storm(valley), weather(valley, storm)).
terminates(storm(valley), weather(valley, clear)).
```

In the Lua runtime, these effects are represented by `set` and `unset` operations attached to a scheduled event.

## 3. Reactive rules

Reactive rules express what should happen when a condition becomes true:

```prolog
if awake(red_dragon), hungry(red_dragon)
then eventually hunt(red_dragon, sheep).
```

A bounded version requires the action within a time interval:

```prolog
if awake(red_dragon), hungry(red_dragon)
then eventually[0, 360] hunt(red_dragon, sheep).
```

Rules should be dependency-driven. A rule depending on `awake` is reconsidered when `awake` changes, rather than on every render frame.

## 4. Temporal logic operators

The language uses UTF-8 temporal-logic symbols.

### `○ p` — next

`○ p` means that `p` must hold or occur in the next logical state.

```prolog
if attacked(castle)
then ○ raise_alarm(castle).
```

### `◇ p` — eventually

`◇ p` creates an outstanding future obligation. It remains active until `p` becomes true.

```prolog
if hungry(red_dragon)
then ◇ eat(red_dragon).
```

Bounded eventuality is written as:

```prolog
◇[0, 360] eat(red_dragon).
```

This means that the dragon must eat within the next 360 simulation minutes.

### `□ p` — always

`□ p` expresses an invariant that must hold in every relevant logical state:

```prolog
□ not(
    location(red_dragon, mountain),
    location(red_dragon, valley)
).
```

The runtime checks this only when one of its dependencies changes.

### `p U q` — until

`p U q` means that `p` must remain true until `q` becomes true:

```prolog
travelling(red_dragon, valley)
U
location(red_dragon, valley).
```

The monitor succeeds when the arrival condition becomes true and is violated if travelling stops first.

## 5. Example LPS-like world file

```prolog
% Initial state
initially(location(red_dragon, mountain)).
initially(sleeping(red_dragon)).
initially(hungry(red_dragon)).
initially(location(knight, capital)).

% Timed events
happens(wake(red_dragon), 1080).
happens(storm(valley), 1140).

% Wake effects
initiates(wake(red_dragon), awake(red_dragon)).
terminates(wake(red_dragon), sleeping(red_dragon)).

% Reactive travel rule
if awake(red_dragon), hungry(red_dragon)
then ○ depart(red_dragon, mountain, valley).

initiates(depart(red_dragon, mountain, valley),
          travelling(red_dragon, valley)).
terminates(depart(red_dragon, mountain, valley),
           location(red_dragon, mountain)).

% Arrival and hunting
happens(arrive(red_dragon, valley), 1190).
initiates(arrive(red_dragon, valley), location(red_dragon, valley)).
terminates(arrive(red_dragon, valley), travelling(red_dragon, valley)).

if location(red_dragon, valley), hungry(red_dragon)
then ◇[0, 60] hunt(red_dragon, sheep).

initiates(hunt(red_dragon, sheep), fed(red_dragon)).
terminates(hunt(red_dragon, sheep), hungry(red_dragon)).

% Temporal requirements
□ not(
    location(red_dragon, mountain),
    location(red_dragon, valley)
).

travelling(red_dragon, valley)
U
location(red_dragon, valley).
```

## 6. Scheduler and logical time

The scheduler keeps future events ordered by time:

```text
1080  wake(red_dragon)
1140  storm(valley)
1190  arrive(red_dragon, valley)
```

When advancing to a target time, the runtime processes every event whose time is less than or equal to that target. If there is no event between two times, the clock jumps directly across the idle interval.

Conceptually:

```lua
while scheduler:peekTime() <= target do
    world:execute(scheduler:pop())
end
world.time = target
```

## 7. Event-processing pipeline

```text
scheduled event
    ↓
apply initiations and terminations
    ↓
record changed fluent names
    ↓
evaluate dependent reactive rules
    ↓
update dependent temporal monitors
    ↓
schedule resulting events
```

This is the practical LPS-like cycle implemented by `world.lua`.

## 8. Temporal monitors

Temporal formulas are represented at runtime as monitors:

```lua
{
    kind = "eventually",
    dep = "fed",
    deadline = 1440,
    status = "active"
}
```

Possible monitor states are:

```text
active → satisfied
active → violated
```

The dashboard displays these states in the Temporal Monitors panel and records successes or violations in world history.

## 9. Regions and simulation detail

Each region can use a different level of detail:

```prolog
region_mode(capital, full).
region_mode(valley, coarse).
region_mode(mountain, sleeping).
region_mode(dungeon, sleeping).
```

- `full` supports detailed movement, collision, combat, and local AI.
- `coarse` uses simplified movement and important events.
- `sleeping` retains fluents, scheduled events, and temporal monitors without per-frame entity updates.

When a sleeping region becomes relevant, its abstract state can be materialized into detailed entities.

## 10. Derived values

Values such as hunger, fatigue, cooldowns, crop growth, and travel progress need not be updated every frame. Store a reference time and derive the current value when needed:

```text
last_meal(red_dragon, 900)
hunger(red_dragon, T) = hunger_rate × (T - 900)
```

## 11. Logical states and render frames

The simulation distinguishes logical transitions from rendering:

```text
S₀: location(red_dragon, mountain)
    ↓ depart(red_dragon, mountain, valley)
S₁: travelling(red_dragon, valley)
    ↓ arrive(red_dragon, valley)
S₂: location(red_dragon, valley)
```

A renderer may display many frames between `S₀`, `S₁`, and `S₂`; those frames do not need to create additional logical states.

## 12. Summary

The system combines:

```text
LPS-like fluents
    + event/action transitions
    + inertia
    + reactive rules
    + UTF-8 temporal operators: ○ ◇ □ U
    + scheduled events
    + dependency-triggered monitors
    + region simulation levels
```

The result is a persistent event-driven world in which nearby activity can be simulated in detail while distant activity is represented compactly by state, events, obligations, and elapsed time.
