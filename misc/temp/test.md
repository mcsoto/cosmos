agent slime {
    i. pos(1,2)
    i. dir(right)
    i. state(idle)

    see(player) ->
        n. state(chase)

    state(chase) ->
        n. move_toward(player)

    low_health ->
        n. state(flee)
}

The folder contains a small Love2D event-driven world simulation. Its core is [world.lua](D:\Computer\Documents\loader\temp\world.lua), while [sample.lua](D:\Computer\Documents\loader\temp\sample.lua) defines the demo scenario and [game.lua](D:\Computer\Documents\loader\temp\game.lua) renders the dashboard.

The system works like this:

1. **Fluents hold persistent state**

   Facts such as:

   ```text
   location(red_dragon, mountain)
   sleeping(red_dragon)
   hungry(red_dragon)
   ```

   are stored in `World.fluents`. State remains unchanged until an event sets or removes it.

2. **Events represent discrete changes**

   Future events are stored in `World.events` through `World:schedule(...)`.

   The sample schedules:

   - Dragon wakes at 18:00.
   - Storm reaches the valley at 19:00.
   - The dragon later departs, arrives, and hunts.

   Events are sorted by time, so the system always processes the earliest event first.

3. **`advanceTo` jumps through inactive time**

   `World:advanceTo(target)` processes every scheduled event up to the target time, then moves the clock directly to that time.

   Thus, the simulation does not update every frame or every minute. It jumps from meaningful event to meaningful event.

4. **Events modify fluents**

   Each event has effects such as:

   ```lua
   {op='unset', name='sleeping', args={'red_dragon'}}
   {op='set', name='awake', args={'red_dragon'}}
   ```

   The event processor applies these effects and records which fluent names changed.

5. **Reactive rules respond to changed dependencies**

   A rule is registered with a dependency:

   ```lua
   w:addRule('awake', predicate, produce, label)
   ```

   It is evaluated only when the `awake` fluent changes. When the dragon becomes awake while still hungry, the rule schedules departure, arrival, and hunting events.

   The chain is:

   ```text
   wake
     → awake + hungry detected
       → depart scheduled
         → arrive scheduled
           → hunt scheduled
   ```

6. **Temporal monitors validate behavior**

   The sample uses three monitor types:

   - `eventually`: the dragon must become fed before a deadline.
   - `always`: the dragon must not have multiple locations.
   - `until`: travelling must remain true until arrival.

   Monitors are checked only when their dependency changes or when their deadline is reached.

7. **Regions have simulation detail levels**

   Regions can be:

   - `FULL`: detailed, active simulation.
   - `COARSE`: simplified simulation.
   - `SLEEPING`: mainly persistent state and scheduled events.

   In the sample, the capital is full-detail, the valley is coarse, and the mountain/dungeon are sleeping. The region mode currently affects dashboard presentation and bookkeeping; it does not yet implement separate physics or AI behavior.

8. **The dashboard controls the event loop**

   [game.lua](D:\Computer\Documents\loader\temp\game.lua) provides:

   - `Next event`: jumps to the next scheduled event.
   - `Run`: repeatedly processes upcoming events.
   - Time-jump buttons.
   - Event queue, fluent state, monitors, history, and simulation-cost counters.
   - Text commands parsed by [scenario.lua](D:\Computer\Documents\loader\temp\scenario.lua).

In short, the implementation is a discrete-event simulation:

```text
scheduled event
    → fluent changes
        → affected rules and monitors
            → new events or validation results
```

The key optimization is that time passes by jumping between meaningful events instead of continuously updating every entity.
