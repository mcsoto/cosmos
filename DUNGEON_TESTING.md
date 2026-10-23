# Dungeon - a Space tile crawler

`misc/dungeon.co` is a turn-based dungeon crawler written against the Space
library (`require('space', sp)`) and the Cosmos language.

```
cosmos -l misc/dungeon.co --xpce
```

Collect the six gems, then reach the exit.  Enemies hunt by scent: once per turn
the game builds a **breadth-first flow field** rooted at the player's tile - the
number in each cell is how many steps that cell is from the player, and -1
where the player cannot reach it - and every enemy inside its notice radius
descends that gradient one step.  One search drives the whole pack.  Walk far
enough away and the scent goes cold, which is the whole tactic.

| key | action |
| --- | --- |
| arrows / WASD | move one cell |
| `.` or space | wait a turn |
| G | toggle the scent overlay (the cells the pack can currently smell) |
| P | hand the controls to autoplay |
| R | restart |
| Q | quit - see issue 1 in `docs/ENGINE_ISSUES.md`, this does not work yet |

## The level

`misc/dungeon.co` holds the level as a list of row strings.  The characters
are:

| character | meaning |
| --- | --- |
| `#` | wall |
| `.` | floor |
| `@` | player start |
| `E` | exit |
| `*` | gem |
| `a` | grunt, notice radius 7 |
| `b` | hunter, notice radius 14 |

Every row is exactly `mapWidth` characters wide and the map is `mapWidth` by
`mapHeight` cells; the renderer and both searches index the rows positionally,
so that is the invariant to preserve when editing the level.

The window is 672x522: 28x19 cells of 24 pixels, plus a 66 pixel status bar.

## How the pathfinding works

Two searches, both breadth-first, both over the same 4-connected grid:

* **The scent field**, rooted at the player, rebuilt every turn.  The enemies
  descend it.  `flow_field/6` produces it: `open_scan/10` marks a cell's
  unvisited neighbours, `expand/8` drains one ring of the frontier, and
  `drain/7` repeats until nothing new opens.
* **The objective field**, rooted at the next gem (or at the exit once the
  gems are gone).  Autoplay descends it.  The same `flow_field/6` is reused
  with a different root, so the two fields are independent and the game does
  two sweeps per turn while autoplay is on.

`flow_step/7` then picks the best of the four neighbours.  It is deliberately
unrolled and non-recursive: it scores the four neighbours with `cand_move/8`
and takes the best of the four with `pick2/3`, so no value has to survive a
recursive call.

## Verifying it

The game is verified by letting it play itself.  Set `autoplayFlag` to 1 (and
`traceFlag` to 1) in `misc/dungeon.co` and run it; the trace is written to
`dungeon_log` in the working directory:

```
turn=21.0 gems=4.0 pos=15.0,15.0 over=1.0 won=0.0 status=Caught. Press R to try again.
```

`dungeon_log` rather than stdout, because the game loop never returns and
buffered stdout is lost when the process is stopped.  Writing it needs
`pl::open/4` with real Prolog atoms - `docs/ENGINE_ISSUES.md` issue 2 has the
details.

What was checked, and how:

| behaviour | check |
| --- | --- |
| the level is read correctly | the gem scan finds the six gems at the six intended cells |
| the flow field is a real distance field | distance from the player to the exit is 42, to the first gem 43, and the field is symmetric (the same distance from the other end) |
| the flow field reaches every cell | a sweep from the player's start reaches the exit, all six gems, and the far corner |
| enemies hunt | with autoplay on, the pack closes in and the player is caught; the status line says so and `over` is 1 |
| gems are collected | the gem count falls one at a time as the player walks over them, and the gems that are not under the player survive |
| the exit is locked until the gems are gone | on the exit with gems left, the status is `Gems left: n` and `won` is 0 |
| the win is detected | on the exit with no gems left, `won` is 1, `over` is 1, and the status is `Escaped in n turns` |
| the state is threaded through the loop | the turn counter advances, and the position and gem count change with it |

Two things the autoplay does *not* do: it does not win, and it does not
survive.  It walks straight at the objective and the pack catches it.  That is
the expected outcome of a greedy pathfinder in a game with hunters, not a
defect in the search - the search is verified by the distance checks above.

## Things that will bite you if you edit this file

Most of them are compiler behaviour rather than game design; they are collected
in `docs/ENGINE_ISSUES.md`.  The ones that shaped the code here:

* **The `dirty` flag says the next draw has to repaint.**  The update clears
  it, because by the time the update runs the draw of the frame before it has
  already happened; the first frame and every 45th one keep it set.  When the
  flag was never cleared the whole map was redrawn every frame - 762 XPCE
  rectangles a frame and 4.5 fps.  See `docs/ENGINE_ISSUES.md` issue 9;
  `docs/PROFILING.md` has the measurement.
* **A table field must not be compared inside a condition.**  `if(s.gems = [])`
  writes to the state instead of testing it, and empties the gem list.  Every
  field test goes through `field_is/4`, which reads the field into a local
  first.
* **`l[i]` is a table read.**  It is `cosmos_get/3`, and on a plain list it
  answers something else.  Lists are read with `lst_get/3` and characters with
  `string.at/3`.
* **No consecutive `_` parameters** in a relation head - the compiler shortens
  that clause by one parameter.
* **No relation body that is `false`.**  Answer a flag instead.
* **One clause per list-walking relation.**  The list test is an `if` inside
  the body rather than a second clause with a literal head, so the base case
  cannot be dropped.
* **The last parameter of a relation is its result.**  `rel f(a, out)` answers
  through `out`.
* **`if` runs its condition twice** when the condition is a call.  The
  expensive checks are therefore computed into a local first.
