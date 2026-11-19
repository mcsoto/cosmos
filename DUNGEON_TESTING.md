# Dungeon - a Space tile crawler

`xpce/dungeon.co` is a turn-based dungeon crawler written against the Space
library (`require('space2', sp)`) and the Cosmos language.

```
cosmos -l xpce/dungeon.co --xpce
```

The `--xpce` is not optional.  It is what makes the compiler emit the launch
entry - the code that loads the backend and then runs the file's top-level
goals.  A bare `cosmos -c file.co` leaves a `.pl` without that entry, and
running that one dies with `Unknown procedure: space_xpce_init/3`, because the
backend is never loaded.

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
| Q | quit - see issue 1 in `xpce/ENGINE_ISSUES.md`, this does not work yet |

## The level

`xpce/dungeon.co` holds the level as a list of row strings.  The characters
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
`traceFlag` to 1) in `xpce/dungeon.co` and run it; the trace is written to
`dungeon_log` in the working directory:

```
turn=28.0 gems=4.0 pos=15.0,15.0 over=1.0 won=0.0 status=Caught. Press R to try again.
```

The turn and the cell in that line vary from run to run; the outcome does not.

`dungeon_log` rather than stdout, because the game loop never returns and
buffered stdout is lost when the process is stopped.  Writing it needs
`pl::open/4` with real Prolog atoms - `xpce/ENGINE_ISSUES.md` issue 2 has the
details.

Two things about the trace:

* **It writes one line per frame, not per turn.**  `diag/1` is called at the
  top of the update, so a frame that changes nothing still writes a line.
* **The trace slows the game down.**  Every line opens the file, appends and
  closes it again, and the game logic already costs about three seconds per
  turn (see "How slow is it" below), so a traced run takes minutes to reach
  the end of a game.

The end of the game can also be reached without a window and without the
trace, by driving the compiled `update` relation from Prolog - this is what
`test/dungeon_autoplay.pl` does:

```
swipl -q -g "main" -t "halt" test/dungeon_autoplay.pl
```

It prints the same lines and it checks that the pack catches the player.

### How slow is it

One turn of the autoplay costs about **3 seconds**, and the cost is in the
game logic, not in the drawing:

| what | how long |
| --- | --- |
| one `flow_field` sweep (a breadth-first distance field over the 28x19 map) | 1.4 s |
| one turn (two sweeps: the scent field and the objective field) | 3.0 s |
| one `tile_at` (reading one cell) | 0.15 ms |
| one `lst_put` at the end of a 532 element list | 2.3 ms |

The sweep is dominated by two things.  The distance field is a plain list and
`dist_put/6` writes through `lst_put/4`, which copies the list up to the
index, so filling the field is quadratic - 532 writes of up to 532 elements
each, about half a second of the sweep.  The rest is the per-neighbour
`walkable` check, which reads one character through a host call; the BFS asks
for four neighbours per cell, so that is another few hundred milliseconds.

A mutable field, or a difference array, would make the field linear, and
reading the map once into a table of characters would remove the host calls.


This is pre-existing and unchanged by the callback rewrite: the pathfinding
code is identical in `xpce/dungeon.co` and in `xpce/dungeon_queue.co`.


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
| the keys arrive through the callback | `test/dungeon_input.pl`: a press lands on the queue, the queue keeps the order the keys were typed, one key is played per frame, a press moves the player one cell, a restart puts the turn counter back to zero |
| the autoplay ends in a capture | `test/dungeon_autoplay.pl`: the game ends with the player caught, `over` is 1, `won` is 0, and the status says `Caught` |

Two things the autoplay does *not* do: it does not win, and it does not
survive.  It walks straight at the objective and the pack catches it.  That is
the expected outcome of a greedy pathfinder in a game with hunters, not a
defect in the search - the search is verified by the distance checks above.
The turn it is caught on varies between runs (21 in the old run, 28 in the
runs since), and so does the cell: the enemies that are out of scent walk with
`rand_dir/2`, which draws from the random generator, so the pack closes in at
a slightly different place and time each time.  What does not vary is the
outcome: the player is caught, `over` is 1, `won` is 0, and the status says
`Caught`.

## How the keys get in

The keys arrive through a **callback**.  `keypressed` is registered in the
`sp.start` map under its own name, the way `xpce/test1.co` does it:

```
sp.start(16, {update=update and draw=draw and keypressed=keypressed}, gameState)
```

The backend calls it once for every key the user presses and hands it the key
name and the state; the callback returns the new state.  The game is turn
based, so one key press is one turn: the callback *appends* the key name to
the queue in the state, and the update takes one key off the queue per frame.

Two things follow from that:

* **The queue keeps the order the keys were typed.**  Appending, not
  prepending: a burst of three keys is played in the order it was typed.
* **The backend delivers every event exactly once.**  The polling queue is
  only peeked at, so `sp.event.get()` still finds an event that the callback
  has already seen.  A program that uses both styles sees the event twice.

`xpce/dungeon_queue.co` is the same game in the older shape: it polls the
event queue with `sp.event.getType('keydown', ...)` every frame and keeps the
keydown EVENT TABLES in the queue.  It is kept as the reference for the old
shape; `xpce/dungeon.co` is the one to run.

## Things that will bite you if you edit this file

Most of them are compiler behaviour rather than game design; they are collected
in `xpce/ENGINE_ISSUES.md`.  The ones that shaped the code here:

* **The `dirty` flag says the next draw has to repaint.**  The update clears
  it, because by the time the update runs the draw of the frame before it has
  already happened; the first frame and every 45th one keep it set.  When the
  flag was never cleared the whole map was redrawn every frame - 762 XPCE
  rectangles a frame and 4.5 fps.  See `xpce/ENGINE_ISSUES.md` issue 9;
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
