# Cosmos engine and compiler issues found while building `misc/dungeon.co`

Everything below was reproduced against this checkout. Each item says how to
reproduce it, what the symptom was, and what the fix or workaround is. The
"worked around in" column points at the place in the game where the issue had to
be designed around.

Reproductions live in `docs/repro/` as small standalone `.co` files; the exact
commands are in `docs/repro/README.md`.

---

## 1. `sp.quit()` does not end the process - it orphans it

`libs/space_xpce_prolog.pl:969`

```prolog
space_xpce_quit(_) :- halt.
```

`halt/0` is called from inside the XPCE timer callback, i.e. from within
`space_xpce_tick/1`. It stops the event loop, but the process stays alive with
an orphaned window and has to be killed from the task manager.

Reproduce: a program that calls `sp.quit()` from `update`. The marker printed
before the call appears, nothing is printed afterwards, and the process is still
running.

```
repro/quit.co
```

The comment above `space_xpce_quit/1` claims this was already fixed ("Retracting
the window fact alone is not enough: pce_main_loop keeps dispatching, the tick
guard then fails, and the result is a frozen orphan window with a live process
that has to be killed from the task manager. halt lets process exit release the
window."). It is not fixed: `halt` unwinds the XPCE dispatch but never reaches
`pce_main_loop`'s caller, so `space_xpce_start_loop/4` never reaches its own
`halt(0)`.

**Workaround used in the game:** the only reliable way out is the window's own
close button. `Q` still calls `sp.quit()`, and the game does keep running, so
the key is documented but not relied on.

**Suggested fix:** the tick should not call `halt` from inside the XPCE event
handler. Have `space_xpce_quit/1` retract the frame and close the window, and
let `pce_main_loop` return normally so `space_xpce_start_loop/4` reaches its
`halt(0)`.

---

## 2. `libs/io.co`: `open`, `appendToFile` and `writeToFile` are broken

`libs/io.co:30` calls `c::fopen(name, mode, f)`, which is XPCE's `open/3`. XPCE
wants an XPCE *mode object*, not the atom `append`:

```
ERROR: [Thread main] Unknown message: "not a correct mode for 'open'."
```

So `io.appendToFile/2` and `io.writeToFile/2` throw on every call. The notepad
application in `xpce/` documents `io.writeToFile` as its save path
(`XPCE_LIBRARY.md`, "Save/Load move the buffer's `contents` through
`io.readFile` / `io.writeToFile`"), so its Save button cannot work.

**Workaround used in the game:** write the trace with `pl::open/4` directly. Two
snags:

* Cosmos string literals are Prolog **strings**, and `open/4` wants atoms for
  the mode. Convert first: `pl::atom_string(Mode, 'append')`. The `:Name` syntax
  does *not* give an atom - it produces an `fc_` functor, so
  `pl::open(:myfile, ...)` creates a file literally called `fc_myfile`.
* `pl::write/2` needs its argument instantiated. A string built with `+` is a
  *frozen* term (`delay_add` in `compiler/swi.pl` defers the concatenation), so
  `pl::write(S, 'a' + b)` raises `write/2: Arguments are not sufficiently
  instantiated`. Force it first with `pl::atom_string/2`.

---

## 3. `compiler/swi.pl:376` - `int/2` does not convert to an integer

```prolog
int(X,Y) :- Y is floor(X).
```

`floor/1` of a float is a float, so `pl::int(1.0, X)` answers `1.0`, not `1`.
Every Prolog predicate that insists on a real integer then rejects it:

```
ERROR: [Thread main] Type error: `integer' expected, found `0.0' (a float)
```

This bites `pl::nth0/3` (the usual way to read a list element), `pl::halt/1`,
`pl::sub_string/5` and anything else with a strict integer argument.

`compiler/swi.pl:380` has a second version, `int_(X, Y) :- {Y1=X}, Y is floor(Y1).`
- but it has the same problem, because `floor/1` still answers a float.

**Workaround used in the game:** avoid host calls that need integers. The
breadth-first field is a plain Cosmos list, read with a hand-written index
instead of `pl::nth0/3`, and the level is scanned with `string.at/3` rather
than with `pl::sub_string/5`.

**Suggested fix:** `int(X,Y) :- Y is truncate(X).` - `truncate/1` answers an
integer. Or `integer(Y, Y1), Y = Y1`.

---

## 4. `l[i]` is a *table* read, not a list read

`docs/LOWERING_TABLE.md` says `X = table[K]` lowers to `getnil(table, K, X)`.
The generated code calls `cosmos_get(table, K, X)`, which is the accessor for a
Cosmos **table** (a Prolog assoc). On a plain Prolog list, or on a string, it
answers something else entirely.

Two symptoms seen in this project:

* `row[x]` on a level row returned `#` for a cell that is `.` further along the
  row, so the level was read as if it were shifted.
* `field[i]` on the breadth-first distance field returned a non-distance, so
  every cell looked "already visited" and the search stopped after one ring.

Both look exactly like a broken pathfinder, which is how they were first
misread.

```
repro/indexing.co
```

**Workaround used in the game:** `string.at/3` for characters
(`str.at(row, x, ch)`) and a hand-written recursive index for lists.

**Suggested fix:** either make `getnil/3` handle lists, or document that
indexing is table-only and give lists an explicit accessor.

---

## 5. `if(A) B else C` evaluates `A` twice

The lowering is a complemented disjunction, so the condition is recomputed in
the else branch:

```prolog
( walkable(...), ... ; \+ walkable(...), ... )
```

For a cheap condition that is merely wasteful. For a condition with a cost
(the breadth-first sweep calls `walkable` for every cell) it doubles the work.
It also means the else branch sees a *recomputed* condition, not the original
one.

`choose/3` is the committed form and evaluates the condition once:

```
repro/choose.co
```

| construct | lowering | condition evaluated |
| --- | --- | --- |
| `if(A) B else C` | `(A, B ; \+A, C)` | twice |
| `when(A) B else C` | `(A, B ; C)` | once, and the else branch does not re-test |
| `choose(A) B else C` | `(A -> B ; C)` | once, committed |
| `soft_if(A) B else C` | `(A *-> B ; C)` | once, soft commit |

All three of `when`, `choose` and `soft_if` were verified to work; see
`repro/choose.co`.

**Workaround used in the game:** conditions are computed once into a local and
the `if` tests the local, so the expensive part is not repeated.

**Suggested fix:** document `choose` as the default conditional, and keep `if`
for the cheap cases.

---

## 6. `A != B` is `dif(A, B)`, which needs both sides bound

`A != B` lowers to `dif(A, B)`, and `dif/2` fails when either argument is a
variable. So `if(x != y)` with an unbound `x` does not take the "they differ"
branch - it fails, and the whole relation fails with it.

This is the documented lowering, so it is a sharp edge rather than a bug, but it
combines badly with `if`: the else branch of an `if` is usually the one that
should run when the comparison cannot be made.

---

## 7. `cut` is in the lowering table but is not usable

`docs/LOWERING_TABLE.md` lists `cut` as a source construct that lowers to `!`.
The parser rejects it:

* `!` as a goal - `Parse error at 29:10: Expected term`.
* `cut` as a relation name - `Parse error at 23:10: Expected goal operator`
  (the word is reserved).

```
repro/cut.co
```

**Consequence:** Cosmos relations are nondeterministic and there is no cut, so
every recursive clause needs an explicit guard. The classic shape

```prolog
rel len([], n)   n = 0
rel len([_|t], n) len(t, m), n = m + 1
```

works only because the first clause's head does not unify with a non-empty
list. As soon as two clauses can both match, the relation goes exponential or
loops. In this project every list-walking relation is written as a single
clause that tests the list with an `if`, which makes the base case explicit and
removes the need for a cut.

**Suggested fix:** either implement `cut` (the lowering table already says what
it should do) or remove it from the table.

---

## 8. A run of underscore parameters in a relation head: seen once, not reproduced

While auditing the generated Prolog, one build emitted a relation whose two
clauses disagreed on arity:

```prolog
% source: 5 parameters
rel u([], _, _, acc, out)
    out = acc
rel u([h|t], _, _, acc, out)
    u(t, _, _, acc, out2)
    out = [h|out2]

% generated, in that build
'u'([],A,B,C):-D=C.
'u'([A|B],C,D,E):-'u'(B,G,H,E,I),F=[A|I].
```

Clause 1 takes four arguments, clause 2 takes four, but the recursive call
inside clause 2 passes five - so the arguments after the run of underscores are
shifted by one and the result parameter is dropped.

**This did not reproduce.** The same source, recompiled in a later build,
emits five-argument clauses that agree with each other and with the wrapper,
and the relation behaves correctly (`docs/repro/underscore.co` passes). The
same source also behaved correctly in an earlier build.

So: a real arity inconsistency was observed in the generated code once, and
could not be reproduced afterwards. It is recorded here because the shape is
worth avoiding until it is understood, not because it is confirmed.

**Workaround used in the game:** no relation head contains two adjacent
underscores, and every ignored parameter has a name.

---

## 9. The `dirty` flag is never cleared, so the map is repainted every frame

`misc/dungeon.co` - **fixed**

The game is written to repaint only when a turn resolved:

```cosmos
// The game is turn based, so draw only repaints when a turn resolved.  A frame
// that changes nothing is skipped entirely, which keeps the XPCE box churn at
// one screenful per keypress instead of sixty per second.
```

The guard is `field_is(s, 'dirty', 1, dirty)` at the top of `draw`, and
`newGame` sets `dirty = 1`.  But nothing ever sets it back to 0: every
path through `update` either sets it to 1 again or copies the old value
(`put(c, s.dirty, s2)`), so the flag stays 1 for the life of the game and
the guard never fails.

The profile shows the consequence - `space_xpce_rectangle/6` was called
182,835 times in 240 frames, which is **762 XPCE rectangles a frame**:
the whole 28x19 map, the gems, the enemies and the status bar, sixty
times a second.  The game ran at 4.5 fps and spent 23% of its time in
the garbage collector.

**The fix:** `update` clears the flag, because by the time the update
runs the draw of the frame before it has already happened.  Two frames
keep it set: the first one, because nothing has been painted yet, and
every 45th one, so a window expose or a resize is still repainted.

| | before | after |
| --- | --- | --- |
| frame rate | 4.4 fps | 55 fps |
| inferences per frame | 1,007,484 | 40,250 |
| XPCE rectangles per frame | 762 | 17 |
| table reads per frame | 6,800 | 164 |
---

## 10. Every arithmetic operation goes through CLP(R)

`compiler/swi.pl`

The runtime loads `library(clpr)` and writes its arithmetic helpers in
the curly-brace form:

```prolog
add_(X,Y,Z) :- ...,{Z = X+Y}.
r_sub(X,Y,Z) :- {Z = X-Y}.
r_lt(X,Y)    :- {X < Y}.
```

`{}/1` is CLP(R), not `is/2`, so every addition, subtraction and
comparison in a Cosmos program is normalised as a rational number
first.  Measured on this machine:

| form | per call |
| --- | --- |
| `{Z = X+Y}` (CLP(R)) | 1.727 us |
| `Z is X+Y` (native) | 0.164 us |

**CLP(R) arithmetic is about ten times more expensive than `is/2`.**

`dif/2` - the inverse of `=` in the `if` lowering - is CLP(R)'s `?=`, so
it normalises both sides before it compares them (0.175 us against
0.095 us for `\==`).

In the dungeon with autoplay on, **69% of a turn** is in SWI-Prolog's
rational-arithmetic normaliser, reached from 7 million arithmetic
operations and 1.1 million `dif/2` calls a turn.  See
`docs/PROFILING.md`.

**Suggested fix:** this is the numeric-domain decision `todo.txt` is
still open about ("An all-real Cosmos numeric domain fits CLP(R)").  It
is the single most expensive thing in the engine: plain floats with
`is/2` would make every arithmetic operation ten times cheaper, at the
price of exact rationals.

---

## 11. The Space backend rewrites its own state on every frame

`libs/space_xpce_prolog.pl` - **fixed**

The backend kept its state in dynamic predicates and rewrote them
rather than updating them:

```prolog
space_xpce_tick(Prefix) :-
    ...
    retractall(space_frame(Prefix, _, _, _)),
    assertz(space_frame(Prefix, Ms, Callbacks, NewState)),
```

and `space_xpce_set_color/3` did the same for the ink:

```prolog
    retractall(space_ink(Prefix, _)),
    assertz(space_ink(Prefix, Colour)).
```

In `test4` - a program that polls the key queue and draws three
rectangles - that was **eight `assertz/1` and seven `retractall/1` calls
per frame**, and **69% of the sampled time**: `assertz/1` 41.5%,
`retractall/1` 27.8%, and 7.1% more in the collector, because every
rewrite leaves a term behind on the global stack.  The dungeon calls
`setColor` twice per cell, so it paid the ink rewrite 1500 times a frame.

The retraction is the expensive half, not the assertion: measured on this
machine, rewriting one small fact cost 2.2 us with `retract/1` and 616 us
with `retractall/1` - the pattern scan is what costs.

**The fix:** the state, the ink, the clock and the event queue are now
non-backtrackable globals.  `nb_linkval/2` stores a value *without
copying it*, which matters because the Cosmos state of a Space program is
a table holding the level and the flow field; copying it every frame was
the single biggest cost in the backend.  The event queue is kept
newest-first, so adding an event is constant time instead of copying the
list and re-asserting it.

| | before | after |
| --- | --- | --- |
| sampled work per frame in `test4` | 9.20 ms | 3.57 ms |
| `assertz/1` calls in `test4` | 18662 | 4261 |
| `retractall/1` calls in `test4` | 16851 | 0 |
---

## Optimisation notes

* **`choose` instead of `if` when the condition is a call.** `if` runs the
  condition twice (issue 5). In the breadth-first sweep the condition is
  `walkable/6`, which is called once per cell per ring, so this is a factor of
  two on the hottest loop in the program.
* **Read the condition into a local first.** `if(walkable(...))` becomes
  `walkable(..., Ok), if(Ok = 1)`, which is one call instead of two.
* **Avoid `l[i]` on lists** (issue 4). `pl::nth0/3` is not a substitute either
  unless the index is a real integer (issue 3), so a hand-written index over a
  Cosmos list is the practical option.
* **The breadth-first field is the hot spot.** It is a flat list of `w*h`
  distances, and every update copies the list, so one sweep is O(n^2) in the
  number of cells. At 28x19 that is ~280k list cells per sweep, and the game
  does two sweeps per turn (one rooted at the player for the enemies, one rooted
  at the objective for autoplay). A flow field kept as a Cosmos *table* keyed
  by `y*w+x` would make the update O(1) instead of O(n); the functional update
  `t = t.key:value` is already the shape the compiler uses for field updates.
* **Two sweeps per turn is the other cost.** The enemy field and the autoplay
  field have different roots, so they cannot be shared. If autoplay is not
  enabled, only one sweep per turn is needed.
* **Draw only when something changed.** The game marks the state dirty and
  repaints only on a dirty frame. A full repaint is ~550 `rectangle` calls, and
  each one is an XPCE object, so repainting on every frame at 60Hz is what
  makes a Space program crawl. The game also forces a repaint every 45th frame
  so a window expose or resize is not left blank. **The dirty flag is never
  cleared, so this does not happen - see issue 9.** The profile measured 762
  rectangles a frame and 4.5 fps.
* **`draw`/`update` are called at ~60Hz whatever the program does.** A turn
  based game should do its work in `update` and leave `draw` cheap.

These notes are backed by measurements now: `docs/PROFILING.md` has the
profiles of `test4` and `misc/dungeon.co`, the reports are in
`docs/profiles/`, and the profiler itself is `--profile` (see the same
document).

---

## Things that are *not* bugs, but cost hours if you do not know them

These are language and compiler behaviours that are correct but surprising.
They are recorded because most of the debugging time in this project went into
them.

* **`=` is unification, not assignment.** `x = 5` binds `x`; it does not
  store.  A test has to be written as a comparison inside `if`.
* **A relation's result is its last parameter.** `rel f(a, out)` answers through
  `out`; there is no value-returning form.
* **Cosmos string literals are Prolog strings, not atoms.** XPCE wants atoms
  (`atom_string/2` in the Space backend converts), Prolog's `open/4` wants
  atoms, and `number_string/2` wants a number.
* **Numbers are floats.** `12` is `12.0` at runtime, which is why `1 = 1.0`
  succeeds but `pl::nth0(0.0, ...)` throws.
* **`%` is a floating-point modulus.** `5.5 % 4` is `1.5`, not `1`. Round
  first if an integer index is wanted.
* **A relation body that is `false` makes the relation fail.**  A `false` in a
  helper that is called from an `if` was observed to end up at the end of the
  *caller's* body during inlining, which made the caller always fail.
  Rewriting the helper so its body never fails (answer a flag instead) avoids
  the whole class of problem.
* **The `--xpce` entry is only `sp.init` plus `sp.start`.** Building the first
  state in a top-level goal before them works, but a top-level goal that fails
  silently stops the program from starting, with nothing on stderr.
* **A Cosmos table is a Prolog assoc.** `get_assoc/3` works on it, and the
  Space backend relies on that.
* **Headless testing of a Space program changes the program.** Stripping the
  `require('space', sp)` from a file to test its logic in isolation changes the
  capture structure, and therefore the arities, of every relation that
  mentions `sp` - so the headless build is *not* the program that ships. Test
  the real file: compile it, and query the relations with
  `cosmos -l file.co -q "relation(args)"`.
* **`cosmos -l file.co -q "goal"` runs the file's top-level goals first**, so a
  Space file opens a window before the query runs.  For a headless query, use a
  copy of the file with the top-level goals removed - but see the note above
  about captures before trusting the result.
