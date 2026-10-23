# Profiling a Cosmos program

`--profile` runs a program under the sampling profiler that is built into
SWI-Prolog and writes a report: where the time went, which predicates were
called how often, and how much of it belongs to the Cosmos program, to the
XPCE backend underneath it, and to the SWI-Prolog machinery.

```
cosmos -l misc/dungeon.co --xpce --profile
cosmos -r test4 --xpce --profile --profile-out test4.profile.txt
```

| option | meaning |
| --- | --- |
| `--profile` | turn the profiler on |
| `--profile-out FILE` | report file (default `cosmos_profile.txt`) |
| `--profile-frames N` | write the report every N frames (default 300) |
| `--profile-seconds N` | write the report once, N seconds into the run |
| `--profile-top N` | rows per table (default 25) |

The report is written to a temporary file and renamed, so a reader never
sees half a report, and it is rewritten every `--profile-frames` frames: a
Space program runs until its window closes, so the report on disk is
always the most recent snapshot and the program never has to stop to be
inspected.

## How it works

* The sampler is the kernel's own (`profiler/2`, `'$prof_statistics'/7`,
  `prolog_statistics:profile_procedure_data/2`).  The library
  `library(prolog_profile)` is a presentation layer over exactly these,
  and it is not used here because the saved `cosmos.exe` is built with
  `autoload(false)`: a library that is not embedded in the image cannot be
  loaded at run time.
* The profile is per thread.  A watchdog thread cannot read it, so the
  report has to be taken by the thread that runs the program.  That is
  why the Space backend calls `space_profile_frame/1` once per frame:
  the profiler counts the frames there and writes the report from inside
  the loop.  `compiler/platform/profile.pl` installs itself as that hook
  when it starts, and the hook is a no-op when nobody is profiling.
* The call counts are exact - the sampler counts every call on the call
  port.  The *times* are sampled (about 100 samples a second on Windows),
  so a predicate that is called a handful of times shows 0.0 ms, and a
  cheap predicate that happens to be running when the timer fires gets a
  whole sample attributed to it.  Treat the times as an attribution, not
  as a measurement of a single call.

## What the report says

```
 Time by category
 category          calls  self ms        %
 swi system      1802724   1140.3  80.2
 space backend    143926    157.3  11.1
 swi library      764673    125.0   8.8
```

The categories are the point of the report:

| category | what it is |
| --- | --- |
| `program` | the Cosmos relations of the program itself (`test4::update/4`) |
| `cosmos library` | the Cosmos libraries it uses (`string::at/3`) |
| `space bridge` | the Cosmos side of the Space library (`space::rectangle/6`) |
| `space backend` | the XPCE backend (`space_xpce_rectangle/6`) |
| `xpce core` | XPCE itself (`pce:send/3` and friends) |
| `cosmos runtime` | the runtime between the generated code and the backend (`cosmos_get/3`, `cosmos_method/3`) |
| `host` | the generated code's own helpers in `user` |
| `swi system` / `swi library` | SWI-Prolog underneath |
| `profiler` | the measurement itself; excluded from the predicate tables |

"The game is slow" is not actionable.  "The game spends half of its time
creating XPCE rectangles" is.

---

# What the profiles say

Three programs were profiled on this machine (SWI-Prolog 10.0.2, Windows).
The raw reports are in `docs/profiles/`.

The two fixes below (the dirty flag in `misc/dungeon.co` and the per-frame
state in `libs/space_xpce_prolog.pl`) came out of these measurements; each
section says what the numbers were before and after.

## 1. `test4` - the port's own overhead

`cosmos -r test4 --xpce --profile`, 2400 frames, 38.8 s wall,
8,277,232 inferences.

| category | self ms | % |
| --- | --- | --- |
| swi system | 6989.6 | 84.0 |
| space backend | 734.9 | 8.8 |
| swi library | 516.0 | 6.2 |

The hot list is not the program:

| predicate | calls | self ms | % |
| --- | --- | --- | --- |
| `system:assertz/1` | 18662 | 3455.7 | 41.5 |
| `system:retractall/1` | 16851 | 2314.2 | 27.8 |
| `system:'$garbage_collect'/1` | 806 | 594.2 | 7.1 |
| `user:space_frame/4` | 2401 | 547.3 | 6.6 |
| `system:catch/3` | 68683 | 453.5 | 5.5 |

`test4` polls the key queue and draws three rectangles per frame.  It
costs **3450 inferences and 16 ms a frame**, and **69% of that is the
backend rewriting its own global state**: `space_xpce_tick/2` retracts and
re-asserts `space_frame/4` and `space_last/2` on every frame, and
`space_xpce_set_color/3` retracts and re-asserts `space_ink/2` on every
colour change - eight `assertz/1` and seven `retractall/1` calls per
frame, each of them rebuilding a term on the global stack and leaving
garbage behind (the 7.1% in the collector).

The Cosmos program itself does not reach the top of the list.  **For a
program this small the port costs more than the program.**

### Fixed: the per-frame state lives in globals

The state, the ink, the clock and the event queue are now non-backtrackable
globals (`nb_linkval/2`, which stores a value *without copying it*).  The
queue is kept newest-first, so adding an event is constant time instead of
copying the list.

Measured on the same run (1200 frames):

| | before | after |
| --- | --- | --- |
| sampled work per frame | 9.20 ms | **3.57 ms** |
| inferences per frame | 3888 | 3569 |
| `assertz/1` calls | 18662 | 4261 |
| `retractall/1` calls | 16851 | 0 |

The dynamic-fact rewrite was not just slow, it was the *dominant* cost of a
small program.  `nb_linkval/2` does not copy the value, which matters: the
Cosmos state of a Space program is a table holding the level and the flow
field, and copying it every frame was the single biggest cost in the
backend.

### Still there: `catch/3`

The backend wraps every XPCE call that can raise in `catch/3`: 37 per
frame in `test4`, 3900 per frame in the dungeon.  The XPCE calls that are
actually unsafe are few; the rest could be called directly.

## 2. `misc/dungeon.co` - a full repaint every frame

`cosmos -l misc/dungeon.co --xpce --profile`, 240 frames, 54.5 s wall,
241,796,108 inferences, **13.6 s** to compile the source.

| category | self ms | % |
| --- | --- | --- |
| swi system | 17677.0 | 42.0 |
| swi library | 15442.0 | 36.7 |
| space backend | 3813.6 | 9.1 |
| cosmos library | 3204.1 | 7.6 |

| predicate | calls | self ms | % |
| --- | --- | --- | --- |
| `system:'$garbage_collect'/1` | 341 | 9706.0 | 23.1 |
| `assoc:is_assoc/4` | 1632217 | 8393.1 | 20.0 |
| `user:'string::get'/3` | 130343 | 2297.5 | 5.5 |
| `system:(@<)/2` | 36779097 | 1953.7 | 4.6 |
| `system:retractall/1` | 187431 | 1203.5 | 2.9 |
| `user:space_show_shape/6` | 184747 | 1187.8 | 2.8 |

Two things stand out.

**The map is repainted on every frame.**  `space_xpce_rectangle/6` was
called 182,835 times in 240 frames: **762 rectangles a frame**, which is
the whole 28x19 map plus the gems, the enemies and the status bar.  The
game is supposed to skip the repaint when nothing changed:

```cosmos
// draw only repaints when a turn resolved.  A frame that changes
// nothing is skipped entirely ...
```

but the `dirty` flag is never cleared.  `newGame` sets `dirty = 1`, and
every path through `update` either sets it to 1 again or copies the old
value (`put(c, s.dirty, s2)`), so it stays 1 forever and the guard in
`draw` never fails.  The optimisation is dead code.

**The state is read far too often.**  `assoc:is_assoc/4` (the Cosmos
table accessor) was called 1.6 million times - **6800 table reads per
frame** - and 36.8 million term comparisons came with them.  The state
table is read once per drawn cell instead of once per frame, because
`draw_cell` goes through `field_is/4`, which reads the field into a
local *for every field name it is asked about*.

### Fixed: the dirty flag

`update` now clears the flag, because by the time the update runs the
draw of the frame before it has already happened.  Two frames keep it
set: the first one (nothing has been painted yet) and every 45th one (so
a window expose or a resize is not left blank).

The same run after the fix:

| | before | after |
| --- | --- | --- |
| frame rate | 4.4 fps | **55 fps** |
| inferences per frame | 1,007,484 | **40,250** |
| sampled work per frame | 222.5 ms | **6.71 ms** |
| XPCE rectangles per frame | 762 | **17** |
| table reads per frame | 6,800 | **164** |

The game now runs at the timer's own limit (see below) instead of at four
frames a second.

### Still there: the state is read per drawn cell

`field_is/4` tests the field *name* with a chain of `if`s; with five
names that is five comparisons and five table reads per call, and the draw
calls it once per cell.  Reading the fields into locals once per frame
would take the table reads from 164 a frame to about 15.

## 3. `misc/dungeon.co` with autoplay - the turn logic

The same game with `autoplayFlag` set to 1, so it plays itself: 11 turns
in 45.8 s, **4.1 seconds a turn**, 250,184,199 inferences (22.7 million
a turn).  The fixes above do not touch this: the turn cost is the game's
logic, not the rendering.

| category | self ms | % |
| --- | --- | --- |
| swi library | 23773.9 | 71.1 |
| swi system | 6689.8 | 20.0 |
| cosmos library | 2110.1 | 6.3 |

**70% of a turn is spent in SWI-Prolog's rational-arithmetic normaliser**
(`nf_r:nf/2`, `nf_r:submit_eq_c1/3`, `nf_r:nf_mul_k/3`, ...), reached
from two places:

* `compiler/swi.pl` loads `library(clpr)` and every arithmetic helper is
  written with the curly-brace form: `add_(X,Y,Z) :- {Z = X+Y}.`  The
  measured cost of that against native arithmetic:

  | form | per call |
  | --- | --- |
  | `{Z = X+Y}` (CLP(R)) | 1.727 us |
  | `Z is X+Y` (native) | 0.164 us |

  CLP(R) arithmetic is **about ten times more expensive** than `is/2`.
  The dungeon does 7 million of them a turn.
* `dif/2` - the inverse of `=` in the `if` lowering - is CLP(R)'s `?=`,
  so it normalises both sides before comparing.  13.3 million calls over
  the twelve turns - 1.1 million a turn - at 0.175 us each.

Replacing the two hottest `if`s (`lst_get/3` and `lst_put/4`) with
`choose` was measured as a control: the generated code loses its `dif/2`
(`A=[]->C=0.0;...`) and the frame time moves from 3990 ms to 3702 ms -
7%, because the arithmetic, not the comparison, is what costs.

### The flow field is O(n^2)

The field is a flat list of 28x19 distances, and every update copies it.
One sweep is therefore O(n^2) in the number of cells: the profile shows
6 million `r_sub/3` calls a turn (one per list step) and 1.1 million
`dif/2` calls (the `if` in the list walker, once per step).

The alternatives, in the order they are worth trying:

* **A Cosmos table keyed by `y*w+x`.**  The table is an assoc, so a
  lookup is O(log n) instead of O(n) and the functional update
  `t = t.key:value` copies one path instead of the whole list.  This is
  the fix `docs/ENGINE_ISSUES.md` already recommends.
* **Keep the list but stop copying it.**  The field is rebuilt from
  scratch every turn anyway, so the copy only has to happen once per
  sweep - but the current code updates it cell by cell, which copies the
  list once per cell.
* **A direction field instead of a distance field.**  The enemies only
  need to know which way is downhill; a sweep that writes one direction
  per cell needs the same number of steps, so this does not help by
  itself.

### `choose` instead of `if`

`if(A) B else C` lowers to `(A, B ; dif(A), C)`: the condition is
evaluated twice, and the second time through `dif/2`, which is CLP(R)'s
`?=` and normalises both sides before comparing.

`choose(A) B else C` lowers to `(A -> B ; C)`: the condition is evaluated
once and `dif/2` never appears.  Measured on a *false* condition (the
branch that pays):

| condition | plain `if` | `choose` | reif `if_/3` |
| --- | --- | --- | --- |
| two floats | 0.529 us | 0.150 us | 0.180 us |
| two strings | 0.333 us | 0.181 us | 0.199 us |
| a string against an atom | 0.267 us | 0.150 us | 0.171 us |

`choose` is in the language today, so this is available without touching
the compiler.  It is *committed* though (`->`), while `if` is relational -
so it changes the semantics of a relation that can have more than one
solution.

### What library(reif) does and does not have

`library(reif)` is not in this SWI-Prolog installation; the project
carries its own copy in `compiler/reif.pl`.  Its exports are:

```
if_/3, cond_t/3, =/3, dif/3, ','/3, ;/3, memberd_t/3,
tmember/2, tmember_t/3, tfilter/3, tpartition/4
```

**There is no reified `<`, `>`, `=<` or `>=/3`** - so the reified
arithmetic comparisons do not exist, and cannot be written on top of the
reified equality.

But the arithmetic comparisons do not need them.  The compiler already
lowers the inverse of `<` to `>=` (`r_ge`), of `<=` to `>`, and so on -
the only comparison whose inverse is `dif/2` is `=`, and `!=` is `dif/2`
by definition.  So the equality case is the *only* one that reif could
improve, and reif is exactly the library that has a reified equality.

reif's `if_/3` expansion tests `X \= Y` first, which is SWI's cheap
"cannot be unified" check (0.088 us against `dif/2`'s 0.175 us), and only
falls back to `dif/2` when the two terms are neither identical nor
unifiable - which is the case where the *constraint* semantics are
actually needed.  So it keeps the semantics and drops the CLP(R) cost for
ground comparisons.

Two caveats:

* reif's `if_/3` is **committed** (it uses `->`), so using it for the
  equality case would make the Cosmos `if` committed too.
* The reified `=/3` is the alternative: it binds a boolean instead of
  choosing a branch, so it can be used without changing the commitment.

### Comparing "dif via reif" instead of changing the compiler

The other way to get the same effect is to leave the compiler alone and
change what `dif/2` *means* at run time.  SWI's `dif/2` is
`?=(X,Y), !, X \== Y` - the CLP(R) comparison - while `\=/2` is a plain
unifiability check that never touches CLP(R).  A runtime replacement

```prolog
dif(X, Y) :-
    (   X == Y
    ->  fail
    ;   X \= Y
    ->  true
    ;   <the real dif/2>      % one of the terms is a variable
    ).
```

is semantically the same for ground terms (identical fails, unifiable
fails, everything else succeeds) and keeps the constraint behaviour for
the unbound case, at half the cost of the CLP(R) version - and it would
cover the `!=` operator as well as every `if` else-branch, without a
compiler change.

It has two costs of its own: it shadows a standard predicate (SWI warns
when the definition replaces an autoloaded one), and it is a semantic
change to a predicate the language leans on.  Doing it in the engine
(`libs/`) rather than the runtime (`compiler/swi.pl`) keeps the change
inside the XPCE port.

## 4. The game loop

`sp.start(16, ...)` asks for a 16 ms interval, which is a 62.5 frames per
second cap.  The backend turns it into an XPCE timer, so the tick fires
whenever the previous frame is done - the timer does not queue up, a slow
frame simply pushes the next one back.

What that means in practice:

* **The interval is a ceiling, not a rate.**  The dungeon now costs 6.7 ms
  a frame and runs at 55 fps, i.e. at the ceiling.  Before the fixes it
  cost 222 ms a frame and ran at 4.4 fps, i.e. the timer was irrelevant.
* **A turn-based game does not need 62.5 fps.**  The dungeon only changes
  when a key is pressed.  A 33 ms interval (30 fps) would halve the CPU
  and change nothing that the player can see - except that the forced
  repaint is counted in *frames*, so it would come every 1.5 s instead of
  every 0.75 s.  Counting the forced repaint in seconds rather than in
  frames is the better fix.
* **The input latency is one interval.**  A key press is seen by the next
  tick, so 16 ms of latency at 62.5 fps and 33 ms at 30 fps.
* **The tick measures its own delta.**  `space_xpce_tick/1` takes the
  wall clock twice a frame and hands the delta to `update`, so a program
  that wants real time gets real time whatever the interval is.

## 5. The pipeline itself

`cosmos -l misc/dungeon.co --xpce` spends **13.6 seconds in the
compiler** before the window opens.  The generated `misc/dungeon.pl` is
38 kB of Prolog; the source is 30 kB of Cosmos.  Compiling is not the
bottleneck for a game that runs for minutes, but it is a long time to
wait for a one-line change, and it is the first thing to look at if the
edit/compile/run loop starts to hurt.

---

# Reproducing

```
# a Space program: the report is refreshed every 300 frames
cosmos -l misc/dungeon.co --xpce --profile --profile-out dungeon.profile.txt

# a generated program
cosmos -r test4 --xpce --profile --profile-out test4.profile.txt

# the same thing without the launcher
swipl -q -s compiler/platform/repl.pl -- -r test4 --xpce --profile
```

A Space program cannot be stopped from inside its own event loop
(`docs/ENGINE_ISSUES.md` issue 1), so the runs above are stopped by
killing the process; the report on disk is the last snapshot written
before that.
