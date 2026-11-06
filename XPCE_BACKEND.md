# Space XPCE backend (native canvas)

Native desktop graphics backend for the Cosmos Space API, implemented with
SWI-Prolog's XPCE toolkit (`library(pce)` + `library(pce_main)`).

## Layout

| File | Role |
| --- | --- |
| `libs/space.co` | Public entry point. A forwarding layer: one `rel` per method delegating to `space_xpce`, re-exported as a nested table so consumers are type/arity checked. See `XPCE_SIMPLE_LIBRARY.md`. |
| `libs/space_xpce.co` | Cosmos wrapper. One `rel` per method name (table literals cannot overload), calling `pl::space_xpce_*` predicates. Requiring this module directly gives full compile-time checking of `sp.init` / `sp.graphics`. |
| `libs/space_xpce_prolog.pl` | Raw Prolog implementation (window, retained-object drawing, timer loop). Loaded at **runtime** from an absolute path recorded at build time (see below). Never embedded via `qsave`: a saved image containing `library(pce)` does not start. |
| `libs/space_xpce.pl` / `.cif` | Compiled form of `space_xpce.co` (checked in, like other libs). |
| `misc/simple_xpce.co` | Minimal app: one rect, circle, ellipse, line, text. |
| `misc/moving_rect.co` | Animated app: the Cosmos equivalent of `ui2.pl`'s moving rectangle. |
| `test4.co` | Header-only app (`--xpce`): arrow-key-controlled rectangle, driven by the event queue. |
| `misc/demo_space_xpce.co` | Full demo: rect/circle/ellipse/arc/polygon/line, transforms, fonts, scissor record. |
| `misc/*.exe` + `misc/*.dll` | Built apps plus staged XPCE native libraries. |

## API covered

`sp.init(w,h)`, `sp.start(ms,callbacks,state)`, `sp.startCanvas(fps,callbacks,state)`,
`sp.quit/dispose/stop/loadImage`, `sp.beginFrame/sp.endFrame`,
`graphics.clear/setColor/setBackgroundColor/getColor/getBackgroundColor/rectangle/line/point/points/circle/ellipse/arc/polygon/print/printf/push/pop/origin/translate/rotate/scale/shear/setLineWidth/getLineWidth/setLineStyle/getLineStyle/setScissor/clearScissor/getScissor/draw/refresh`,
plus `newFont/setFont/getFont`, `getDimensions/getWidth/getHeight`, timer (`getTime/getDelta/getFPS`),
input (`isDown/isMouseDown/getX/getY/getPosition/buttonDown`) and the event queue
(`event.get/getType/peek`, plus the `on` callback table passed to `sp.start`).

Event types delivered: `mousemotion`, `mousedown`, `mouseup`, `mousewheel`
(with a real wheel amount), `keydown`, `keyup`, `textinput`, `focus`, `blur`
and `resize`.

## Input

XPCE 10.0.0 has two ways to see the keyboard, and the backend uses both.

**Polling.** The `keyboard` INPUT DEVICE class is reachable as
`@keyboard_device` and answers whether a key is held down right now:

```prolog
get(@keyboard_device, key_down, Key, @on)    % held
get(@keyboard_device, key_down, Key, @off)   % not held
```

`Key` is a name XPCE understands: one of its own event names (`RET`, `ESC`,
`TAB`, `BS`, `DEL`, `space`, `insert`, `pause`, `cursor_home`, `end`,
`page_up`, `page_down`, `cursor_left`, `cursor_right`, `cursor_up`,
`cursor_down`), `f1`..`f24`, a single character, or the name SDL uses for
the key (`"Left Shift"`). A name XPCE does not know makes the get fail with
`Unknown key`, so the name is checked against the list XPCE accepts before
it is polled. This is the same call XPCE's own games use — see
`prolog/demo/asteroids.pl` in the XPCE package.

There is still no `push_event/4`, `push_global_event/4`, `get_event/3` or
`key_name/2`; those do not exist in this build. But the keyboard device
covers the one thing they would have been used for.

**Events.** The hook is the `->event` method of class `graphical`, redefined
on a subclass of `picture`:

```prolog
:- op(1200, xfx, :->).
:- pce_begin_class(space_picture, picture, "...").
event(G, Ev:event) :->
    (   space_xpce_capture(G, Ev)
    ;   true
    ),
    (   send_super(G, event, Ev)
    ;   true
    ).
:- pce_end_class.
```

Two constraints shape the whole implementation, and both are expensive to
rediscover:

1. **An XPCE error raised while the loop is running opens a MODAL dialog**
   that blocks dispatch for good. `catch/3` does not help: the error is
   raised in C++ and aborts the goal rather than becoming a Prolog
   exception. One bad call freezes the app with no way back, so every call
   in `space_xpce_read/4` is verified against this build.
2. **`?/2` does not exist here.** It raises
   `existence_error(procedure, (?)/2)` even after
   `use_module(library(yall))`. Use `get/3` and `send/2,3` only.

Verified accessors: `get(Ev, id, _)`, `get(Ev, position, _)` followed by
`get(Pt, x, _)`, `get(Pt, y, _)`, `get(Ev, button, _)`,
`get(Ev, multiclick, _)`, `get(Ev, key, _)`,
`get(Ev, rotation, _)`, `send(Ev, is_a, mouse)`,
`send(Ev, is_a, key_up)`, `send(Ev, is_down|is_up|is_drag)`
(zero-argument behaviours, so `send/2`), and
`send(Ev, has_modifier, s|c|m)` — bare atoms; `e` is not accepted. Absent:
`event <-modifiers`, `event <-click_time`, `event <-dy`.

Event ids come from `@event_tree`: mouse press/release/drag as
`ms_left_down` and friends, `loc_move`, `loc_still`, `wheel`, `area_enter`;
keys as the **ASCII code** (an integer) or a named atom (`f1`,
`cursor_left`, `'ESC'`). Shift is already folded into the code, so shift+A
arrives as `65` with modifier `s`.

**Key releases exist.** The release event is `key_up`, and it sits under
`any` in `@event_tree` rather than under `keyboard/` — which is why looking
only under `keyboard/` makes it look like the build has no releases at all.
Its id is the atom `key_up`; the key it releases comes from `event <-key`,
which answers the Emacs-style name of the matching key-down (`"a"`, `"A"`,
`"RET"`, `"<f1>"`). The backend turns that into the same Love2D name a key
press reports, so a press and its release agree.

The wheel *rotation amount* is read from `event <-rotation`, which is an
ordinary get method: it answers the rotation in fifteenths of a notch and a
non-number for every event that is not a wheel.

**The event queue is copied, not linked.** The queue is a Cosmos table per
event (a Prolog assoc), and an event table is built *inside* XPCE's event
dispatch. The cells of that dispatch do not survive it, so a queue that only
*refers* to those tables comes back as half-built trees: assocs whose keys and
values have turned into unbound variables. A half-built table is not an assoc
any more, so `get_assoc/3` fails on it, the type filter drops the event, and
the program never sees it. The queue is therefore stored with `nb_setval/2`
(which copies into the protected area of the global variable space) and read
back through a `copy_term/2`, so no caller ever holds cells that the next
event can free.

The symptom was confusing, because it only hit the *newest* event: the tables
that had been in the queue for a few frames were still intact, and a program
that reads the whole queue still saw most of it. A program that asks for one
kind of event (`sp.event.getType('keydown', Keys)`) always asks for the
newest one, so it always got nothing — which is why the keyboard looked dead
while the mouse still worked. `test/space_xpce_events.pl` reproduces the whole
path (inject an event with `frame->sdl_test_event`, read it back on the next
frame) and fails without the copy.

**Synthetic events.** `graphical->generate_event/1` posts an event with the
given id to a graphical, which is the same path a real key press takes:

```prolog
send(Window, generate_event, 119)    % the key 'w'
```

XPCE dispatches it, the `->event` method captures it, and it lands in the
Space queue like any other event. `test/space_xpce_events.pl` uses it to
check the keyboard path without a keyboard.

Deliberate limits:

- `setScissor` only records the rect; clipping is not enforced.
- `setLineStyle` only remembers the style: XPCE has no rough/smooth switch of
  its own, so the style is answered back unchanged.
- Rotation of ellipses only moves the centre (shape stays axis-aligned).
- `getFont` reports the font that was set, but the family and style are
  XPCE's own (`sans`, `serif`, `mono`; `normal`, `bold`, `italic`).

## Compile-time checking

`require('space', sp)` is the supported entry point and is checked: arity and
member existence are both enforced. That works because `libs/space.co` is a
**forwarding layer** — one `rel` per method, delegating to `space_xpce`, behind
a nested `export` table that mirrors `space_xpce`'s own shape.

It has to be a forwarding layer, because `export` of a `require`d alias records
nothing in the interface and `export({member = sp.member})` records a bare
field with no parameters. Both compiler gaps are written up in
`compiler_issue.txt`. `misc/` has no `space.cif`, so the apps there are still
compiled unchecked; copy `libs/space.cif` and `libs/space_xpce.cif` beside a
program to check it.

Adding a method to `space_xpce.co` means adding a forwarder to `space.co` too,
or it stays invisible to anyone requiring `'space'`.

The user-facing spec is `XPCE_SIMPLE_LIBRARY.md`.

## Cosmos rules this code depends on

- **No overloading in table literals**: two `rel` with the same name collapse
  (last wins). Every method name exists exactly once per table.
- **Value-position calls append the result**: `g.newFont(24,'sans','normal')`
  nested inside `setFont(...)` only works because the rel is declared
  `newFont(size, family, style, font)` with the out-param last.
- **`cut`, not `!`**; no `(cond -> a ; b)` goal syntax.
- Single-quoted literals are **strings**, not atoms. Prolog predicates that
  need atoms (e.g. `current_prolog_flag`) must convert via `atom_string`.
- A top-level `require('space', sp)` captures `sp` into every rel, turning
  `main/1` into `main/2` and breaking the `--main`/`--exe` argv adapter. Keep
  `require` **inside** rel bodies for programs built with `--main`, or build
  with `--xpce` instead and keep `require` at the top of the file (see Build
  integration). The captured callbacks are fine either way: `call_cl/2`
  appends a closure's captures as the final argument, so `update` and `draw`
  still land on the right predicates.

## XPCE facts found by probing (SWI-Prolog 10)

- `picture` has `display/clear/flush/background/foreground/pen(int)` and
  counts as a `toplevel` frame for `pce_loop`.
- Use **retained objects** (`box/circle/ellipse/arc/line/text/path`) with
  `fill_pattern/colour/pen/font` + `display`. Verified safe.
- Never call device `draw_*`, `clip`, `graph_device`, `push_state`,
  `pointer`, or `destroy` on an opened window from outside the event loop:
  some crash the process instead of failing.
- `circle(R)`/`ellipse(W,H)` take **bounding-box** sizes: pass diameter
  (`2*radius`) and display at `(x-r, y-r)` (verified: `circle(30)` reads back
  radius 15; `ellipse(160,80)` reads back 160x80).
- A `box/2` with no `fill_pattern` draws **nothing but a default-pen outline**,
  so it disappears against a dark background. This is how a misrouted `'fill'`
  mode presents as "nothing is drawn" rather than as an error.
- Colours: `new(C, colour(@default, R, G, B))`.
- Loop entry must be `pce_main_loop(BootGoal)` (from `library(pce_main)`)
  where the boot goal **creates the window**: `pce_loop` only dispatches
  frames created by that goal, and it calls `call(Goal, Argv)` (so the goal
  needs exactly one extra argument).
- Closing the window halts via `done_message` → `message(@prolog, halt)`.
  `space_xpce_quit/1` halts for the same reason: it used to only retract the
  window fact, which left `pce_main_loop` dispatching against a missing window
  — a frozen orphan window and a process that had to be killed by hand.

## Build integration (`compiler/platform/driver.pl`, `compiler/swi.pl`)

- `--main`, `--xpce` and `--exe` all share one entry template, and each records
  the library/source templates at build time (exe-dir-relative `../libs` breaks
  when the exe is not in a subdirectory) and runs `abolish_all_tables` first
  (the tabled module loader otherwise poisons standalone runs).
- That same template appends `ensure_loaded(.../libs/space_xpce_prolog.pl)`,
  but **only when the compiled output contains `cosmos_require("space`** — the
  compiler detects a Space program by that string. Consequence: a Space program
  compiled with **no** entry flag has no entry point at all, so it cannot load
  the backend and dies with `Unknown procedure: space_xpce_…`.
- Three entry kinds, chosen by flag (`compiler_add_entry/3`):
  - `main` — call `Module:main/1` with the argv list. Implied by `--exe`.
  - `xpce` — call the module goal itself, i.e. run the file's top-level goals.
  - `none` — bare compile, no entry point, not runnable.

  `xpce` exists so a program can be written header-only: a top-level
  `require('space', sp)` captures `sp` into every relation, which would turn
  `main/1` into `main/2` and leave the `--main` argv adapter calling it with the
  wrong arity. Running the top-level goals avoids naming `main` at all, so
  `require`, `sp.init` and `sp.start` can sit at the top of the file. It is not
  a different renderer — same window, same loop.
- `load_any` uses the non-tabled `cload` for the same reason.
- `compiler_stage_xpce_dlls/2` copies the probed `pl2xpce` closure
  (SDL3/cairo/pango/glib/fontconfig/freetype stack + `libswipl.dll`,
  resolved from the running SWI installation via `pe_imports.py`-verified
  import tables) next to Space exes. Plain console exes are unaffected.
  The exe dir is derived from the `.pl` output path: SWI path predicates
  only treat `/` as a separator, so backslash spellings are absolutized
  first (a bare `file_directory_name` on `D:\...\x.exe` returns `.`).
- The backend `.pl` is loaded at runtime, never embedded (see above).

## Verify

```text
swipl -q -s compiler/platform/cli.pl -- misc/simple_xpce.co misc/simple_xpce.pl --main --exe
misc/simple_xpce.exe        # window "Cosmos Space", draws, loop runs
```

Same for `misc/demo_space_xpce.co` (60 fps animated demo, no stderr output).
`node --test tests/compiler/compiler.test.mjs`: 26 pass / 1 fail (the fail
is the pre-existing v2 contract case, reproduced on the pristine tree).
The two JS-canvas/WASM tests live in their own bundle,
`node --test tests/canvas/canvas.test.mjs` (`make test-canvas`), which
skips cleanly when `canvas/prolog-wasm/swipl-bundle.js` is absent — so
`make test` no longer depends on the browser side. The build audit fixed
4 of the original 7 failures (`--exe` DLL staging; trace, compile_query
and `-l -q` exit codes via the repl halt-ball fix).
