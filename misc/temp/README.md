# Temporal Event World

An independent Love2D app based on `temporal_event_world_simulation.md`. Run `main.bat`.

The dashboard exposes region detail levels, persistent fluents, the future-event queue, temporal monitors, dependency-triggered rules, history, and simulation cost. **Next event** jumps directly through idle time instead of replaying frames.

The description box accepts one statement per line:

```text
red_dragon sleeps in mountain
knight is in capital
wake red_dragon at 18:00
storm in valley at 19:00
sleeping dungeon
```

Supported region modes are `full`, `coarse`, and `sleeping`. Times may be minutes or `HH:MM`.

`world.lua` has no Love2D dependency and can be embedded separately from the dashboard.
