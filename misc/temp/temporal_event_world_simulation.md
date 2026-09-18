# Temporal Event System for a Simulated Game World

## Overview

This document describes an event-driven simulation architecture for a persistent game world using:

- **Fluents** for state that persists over time
- **Events / actions** for state changes
- **Reactive rules** for condition-driven behavior
- **Temporal operators** such as `○` (next), `◇` (eventually), `□` (always), and `U` (until)
- **Scheduled events** for future world changes
- **Temporal monitors** for conditions that span multiple states
- **Simulation levels of detail** so distant maps and agents can remain cheap to simulate

The core idea is that most of the world should not require a conventional per-frame `update(dt)` loop. Instead, the world advances through meaningful state changes.

---

## 1. World State: Fluents

A **fluent** is a fact whose truth or value can change over time.

Examples:

```text
location(red_dragon, mountain)
sleeping(red_dragon)
health(red_dragon, 120)
owner(blacksmith, dwarven_city)
weather(north_valley, snow)
```

Fluents persist by **inertia**. If:

```text
location(red_dragon, mountain)
```

is true at one state, it remains true in later states until some event changes it.

This means unchanged state does not need to be recomputed every frame.

---

## 2. Events and Actions

Events represent discrete changes in the world.

Examples:

```text
wake(red_dragon)
depart(red_dragon, mountain, volcano)
arrive(red_dragon, volcano)
attack(red_dragon, knight)
open(gate)
rain(north_valley)
```

An event may initiate or terminate fluents.

Conceptually:

```text
depart(red_dragon, mountain, volcano)
    terminates location(red_dragon, mountain)
    initiates travelling(red_dragon, volcano)

arrive(red_dragon, volcano)
    terminates travelling(red_dragon, volcano)
    initiates location(red_dragon, volcano)
```

The runtime applies these changes when the event occurs.

---

## 3. Reactive Rules

Reactive rules cause actions or temporal requirements when their conditions become true.

Example:

```text
when hungry(red_dragon)
    hunt(red_dragon, sheep)
```

A temporal version can instead say:

```text
when hungry(red_dragon)
    ◇ hunt(red_dragon, sheep)
```

This means that once the dragon becomes hungry, hunting should eventually occur.

Another rule:

```text
when attacked(castle)
    ○ raise_alarm(castle)
```

means that if the castle is attacked, the alarm is raised in the next logical state.

Reactive rules should preferably be **dependency-driven**. A rule depending on `hungry(red_dragon)` should only be reconsidered when the relevant fluent changes.

---

## 4. Temporal Operators

### `○ p` — Next

`○ p` means that `p` should hold or occur in the next logical state.

Example:

```text
○ attack(dragon, knight)
```

Possible runtime representation:

```lua
{
    type = "next",
    targetStep = currentStep + 1,
    formula = attackDragonKnight
}
```

For a proposition such as:

```text
○ sleeping(dragon)
```

the runtime checks whether `sleeping(dragon)` holds in the next state.

---

### `◇ p` — Eventually

`◇ p` creates an outstanding future requirement.

Example:

```text
hungry(dragon) -> ◇ eat(dragon)
```

Once triggered, the system can keep an obligation such as:

```lua
{
    type = "eventually",
    formula = eatDragon,
    createdAt = worldTime,
    active = true
}
```

The obligation is removed once the required event or condition occurs.

For games, bounded eventuality is often more useful:

```text
◇[0, 3h] eat(dragon)
```

Meaning:

> The dragon should eat sometime within the next three game hours.

---

### `□ p` — Always

`□ p` means that `p` must remain true in every relevant state.

This is useful for invariants.

Example:

```text
□ not(
    location(dragon, mountain)
    and
    location(dragon, castle)
)
```

The runtime does not need to check this every frame. If the formula depends on `location`, it can be reevaluated only when a location fluent changes.

---

### `p U q` — Until

`p U q` means:

> `p` must continue to hold until `q` becomes true.

Example:

```text
travelling(dragon, volcano)
U
arrive(dragon, volcano)
```

A runtime monitor might contain:

```lua
{
    type = "until",
    maintain = travellingToVolcano,
    terminate = arrivedAtVolcano
}
```

On relevant state changes:

```text
if q is true:
    monitor succeeds and ends

else if p is true:
    monitor remains active

else:
    monitor is violated
```

If the fluent system already uses inertia, the temporal monitor does not need to repeatedly recreate `p`.

---

## 5. Explicit Time

The system can also support direct temporal expressions:

```text
wake(dragon) at 1800
attack(orc_band, caravan) after 30m
◇[0, 6h] hunt(dragon, sheep)
```

A future event can be stored in a scheduler:

```lua
{
    time = 1800,
    type = "wake",
    actor = dragon
}
```

The scheduler should normally be ordered by execution time. A priority queue or binary heap is suitable.

---

## 6. Event Scheduler

The scheduler stores future events.

```text
current time
    |
    v

[ 1200 ] merchant_arrives
[ 1400 ] storm_begins
[ 1800 ] dragon_wakes
[ 2200 ] caravan_reaches_city
```

Pseudo-code:

```lua
while scheduler:peekTime() <= world.time do
    local event = scheduler:pop()
    world:execute(event)
end
```

This is especially useful for distant maps. A sleeping region can consume almost no CPU while still having meaningful future behavior.

---

## 7. Temporal Monitors

Temporal operators compile into runtime monitor objects.

Possible forms:

```text
NextMonitor
EventuallyMonitor
AlwaysMonitor
UntilMonitor
```

For example:

```text
hungry(dragon) -> ◇ eat(dragon)
```

could produce:

```lua
{
    type = "eventually",
    formula = eatDragon,
    dependencies = {"eat"},
    active = true
}
```

The monitor should not necessarily be checked every frame. Instead, it can subscribe to relevant changes.

---

## 8. Dependency Index

A dependency index avoids scanning every rule and monitor after every event.

Example:

```text
location
    -> location invariants
    -> travel rules
    -> arrival monitors

hungry
    -> hunting rules
    -> eventual-eating monitors

health
    -> death rules
    -> healing rules
```

Flow:

```text
event
  |
  v
fluent changes
  |
  v
dependency index
  |
  +--> affected reactive rules
  +--> affected always monitors
  +--> affected eventually monitors
  +--> affected until monitors
```

This scales much better than checking every rule every frame.

---

## 9. Logical Steps vs Render Frames

The simulation should distinguish between:

- **render frames**
- **physics updates**
- **logical world states**

A game may render at 60 FPS while the logical simulation advances only when needed.

A logical transition happens because something meaningful occurs:

```text
S0
location(dragon, mountain)

depart(dragon, mountain, volcano)

S1
travelling(dragon, volcano)

...

arrive(dragon, volcano)

S2
location(dragon, volcano)
```

The renderer may show many frames between these logical states.

---

## 10. Maps, Z-Levels, and Simulation Detail

The world can contain separate maps or regions.

```text
World
├── Overworld
├── Dwarven City
├── Dragon Mountain
└── Ancient Dungeon
    ├── Z0
    ├── Z-1
    ├── Z-2
    └── Z-3
```

Each map or region can have a simulation mode:

```text
FULL
COARSE
SLEEPING
```

### FULL

Used near the player.

May include:

```text
movement
collision
pathfinding
combat
animation
local AI
physics
```

### COARSE

Used for nearby or potentially relevant regions.

May include:

```text
region-level movement
simplified combat
reduced AI frequency
important scheduled events
approximate resource changes
```

### SLEEPING

Used for distant regions.

No per-frame entity updates.

Only:

```text
persistent fluents
scheduled events
temporal monitors
abstract state changes
```

---

## 11. Sleeping Maps

Suppose the player is in the capital while a dragon is in a distant volcano.

The distant map may hold only:

```text
location(red_dragon, volcano)
sleeping(red_dragon)
hungry(red_dragon)
treasure(red_dragon, 5200)
```

with a scheduled event:

```text
wake(red_dragon) at 1800
```

No movement or collision is simulated.

At time 1800:

```text
wake(red_dragon)
```

changes:

```text
sleeping(red_dragon)
```

to:

```text
awake(red_dragon)
```

This may trigger:

```text
awake(red_dragon)
and hungry(red_dragon)
->
◇[0, 6h] hunt(red_dragon, sheep)
```

The world continues logically without running the dragon's full AI every frame.

---

## 12. Catch-Up Simulation

A sleeping map stores:

```text
lastSimulatedTime
```

When activated again:

```text
elapsed = currentTime - lastSimulatedTime
```

The engine does **not** replay every missed frame.

Instead it:

1. Executes scheduled events that occurred during the interval.
2. Resolves temporal obligations whose deadlines passed.
3. Computes derived values from elapsed time.
4. Applies coarse simulation for important systems.
5. Materializes detailed entities only when the map becomes active.

Example:

```text
last update: 1200
current time: 1800
elapsed: 600
```

Rather than performing thousands of updates, the game may determine:

```text
dragon woke at 1500
dragon hunted at 1600
dragon returned at 1700
dragon is currently sleeping
```

and materialize only the final relevant state.

---

## 13. Derived Fluents

Some values should not require repeated updates.

Instead of incrementing hunger every frame:

```text
hunger = hunger + rate * dt
```

store:

```text
lastMeal(dragon, 1200)
```

and derive:

```text
hunger(dragon, T)
    = hungerRate * (T - 1200)
```

This is useful for:

```text
hunger
fatigue
cooldowns
crop growth
construction progress
travel progress
weather duration
resource production
```

The value is calculated only when needed.

---

## 14. Example Fantasy Simulation

Initial state:

```text
location(red_dragon, mountain)
sleeping(red_dragon)
hungry(red_dragon)
location(knight, castle)
```

Reactive rule:

```text
when hungry(red_dragon)
    ◇[0, 6h] hunt(red_dragon, sheep)
```

Scheduled event:

```text
wake(red_dragon) at 1800
```

Travel rule:

```text
depart(red_dragon, mountain, valley)
    initiates travelling(red_dragon, valley)
    terminates location(red_dragon, mountain)
```

Arrival rule:

```text
arrive(red_dragon, valley)
    terminates travelling(red_dragon, valley)
    initiates location(red_dragon, valley)
```

Temporal invariant:

```text
□ not(
    location(red_dragon, mountain)
    and
    location(red_dragon, valley)
)
```

Travel requirement:

```text
travelling(red_dragon, valley)
U
arrive(red_dragon, valley)
```

Possible execution:

```text
T=1800
wake(red_dragon)

T=1810
depart(red_dragon, mountain, valley)

T=1810..1900
travelling(red_dragon, valley)
persists through inertia

T=1900
arrive(red_dragon, valley)

T=1910
hunt(red_dragon, sheep)
```

No detailed movement is required while the dragon is in a sleeping region.

If the player enters the valley during the journey, the abstract travel state can be converted into an exact position and full simulation can resume.

---

## 15. Suggested Runtime Architecture

```text
World
│
├── Fluent Store
│   └── current persistent state
│
├── Event Scheduler
│   └── future timed events
│
├── Event Processor
│   └── applies state changes
│
├── Dependency Index
│   └── finds rules affected by changes
│
├── Reactive Rule Engine
│   └── condition -> action / temporal requirement
│
├── Temporal Monitor Manager
│   ├── ○ next
│   ├── ◇ eventually
│   ├── □ always
│   └── U until
│
├── Region / Map Manager
│   ├── FULL
│   ├── COARSE
│   └── SLEEPING
│
└── Renderer / Local Simulation
    └── only detailed active entities
```

---

## 16. Example World Step

A logical world step could look approximately like:

```lua
function World:step()
    self.scheduler:runDueEvents(self.time)

    local changed = self.fluents:applyPendingChanges()

    local affected = self.dependencies:getAffected(changed)

    self.rules:evaluate(affected.rules)
    self.monitors:update(affected.monitors)

    self.regions:updateRelevantRegions()

    self.time = self.time + 1
end
```

A more optimized implementation may skip `World:step()` entirely when nothing needs to happen and instead jump directly to the next scheduled time.

Example:

```text
current time = 1000
next scheduled event = 1400
```

If nothing else is active:

```text
time = 1400
```

and the event is processed immediately.

---

## 17. Core Optimization Principle

> Do not simulate the passage of time when the result can be derived from state, events, and elapsed time.

A conventional engine often asks:

```text
What should every object do this frame?
```

This architecture instead asks:

```text
What changed?
What rules depend on that change?
What future events are scheduled?
What temporal requirements remain active?
Which parts of the world currently need detailed simulation?
```

This makes it suitable for persistent worlds containing many NPCs, monsters, dragons, settlements, maps, Z-levels, weather systems, economies, quests, and factions without requiring every entity and location to update continuously.

---

## 18. Summary

The architecture combines:

```text
LPS-style fluents
        +
event/action transitions
        +
inertia
        +
reactive rules
        +
temporal operators
        +
event scheduling
        +
dependency-based monitors
        +
simulation level of detail
```

The result is an event-driven persistent-world simulation.

Nearby entities can behave like ordinary game objects with detailed movement and physics.

Distant entities can exist primarily as logical state plus scheduled and temporal behavior.

The same entity can transition between these representations as it becomes more or less relevant to the player.
