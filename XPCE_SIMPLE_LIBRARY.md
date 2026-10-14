# XPCE Simple Library — spec and introduction

A native desktop canvas for Cosmos, backed by SWI-Prolog's XPCE toolkit
(`library(pce)`). It gives a Cosmos program a real window with immediate-mode
2D drawing and a timer-driven game loop, with no browser, Electron or network
in the loop.

- **Library source:** `libs/space.co` — the module you `require('space', sp)`
- **Implementation:** `libs/space_xpce.co` (Cosmos wrapper) over
  `libs/space_xpce_prolog.pl` (raw Prolog/XPCE)
- **Compiled artifacts:** `libs/space.pl` + `libs/space.cif`,
  `libs/space_xpce.pl` + `libs/space_xpce.cif` (checked in; regenerate after
  editing either `.co`)
- **Backend internals and XPCE quirks:** `XPCE_BACKEND.md`
- **Worked example:** `misc/moving_rect.co`

---

## 1. Requirements

- SWI-Prolog built with the XPCE toolkit. `library(pce)` and `library(pce_main)`
  must load, which on Windows also means the XPCE/SDL3 DLLs must be reachable.
- On Windows the compiler stages that DLL closure next to any `--exe` it
  builds, so a built app is self-contained. A `--main` `.pl` run has no staging
  and relies on your system SWI-Prolog having the toolkit.

Verify the toolkit is present before anything else:

```prolog
?- use_module(library(pce)).
```

## 2. Install

Nothing to install — the library is source in this repository. Build it once:

```powershell
swipl -q -s compiler/platform/cli.pl -- libs/space.co libs/space.pl space
swipl -q -s compiler/platform/cli.pl -- libs/space_xpce.co libs/space_xpce.pl space_xpce
```

Each command writes a `.pl` and a `.cif` interface sidecar. The `.cif` is what
makes a consumer checked; see §7.

## 3. Quick start

A complete program needs two relations — `update` advances state, `draw` paints
it — plus a window and a loop. Run it with `cosmos -l file.co --xpce`:

```cosmos
require('space', sp)

rel update(dt, s, s2)
    s2 = {x = s.x + dt * 120}          // 120 px per second

rel draw(s)
    g = sp.graphics
    g.clear('#1b1b2f')
    g.setColor('#3050ff')
    g.rectangle('fill', s.x, 100, 80, 50)

sp.init(640, 480)
sp.start(16, {update=update and draw=draw}, {x=100})
```

```powershell
cosmos -l quickstart.co --xpce
```

That is the whole program — no `main`, and `require` at the top of the file.
`--xpce` is what makes this shape work; see §8 for why, and for the `--main`
alternative if you want program arguments.

`test4.co` is this program plus the event queue, so the arrow keys drive it
instead of a timer. `misc/moving_rect.co` is the same loop in the `--main`
shape.

## 4. The loop model

```
sp.init(width, height)                    size the window (created on start)
sp.start(intervalMs, callbacks, state)     fixed interval, in milliseconds
sp.startCanvas(fps, callbacks, state)      fixed frame rate, in frames/second
```

`callbacks` is a table with up to two entries, both optional:

| Key | Signature | Called |
| --- | --- | --- |
| `update` | `update(dt, state, newState)` | once per frame, before drawing; binds `newState` |
| `draw` | `draw(state)` | once per frame, with the state `update` produced |

Semantics that matter:

- **`dt` is in seconds**, not milliseconds, even though `start` takes
  milliseconds. It comes from `get_time/1`. Multiply your per-second rates by
  `dt` to stay frame-rate independent.
- If `update` is omitted, state passes through unchanged. If `draw` is omitted,
  the frame is cleared and nothing is painted.
- **The window is cleared and flushed around `draw`, automatically.** You do
  not call `refresh`. Clearing happens before `draw` using whatever background
  colour was last set, so `g.clear('#202020')` inside `draw` both paints and
  sets the background for subsequent frames.
- **An exception in `update` or `draw` is caught, printed as a warning, and the
  loop continues.** A throwing callback will not stop the app; check stderr.
- **Closing the window quits**, and so does `sp.quit()`; both halt the process.
  There is no need to stop a timer or destroy the picture — never try to close
  the window programmatically, it crashes the process outside the event loop.
- **One window per process.** Every generated call passes an unbound prefix,
  which the backend resolves to `default`, so all Space state is shared. Calling
  `init` again resizes the existing window; two concurrent Spaces are not
  supported.

## 5. API

Everything hangs off the `sp` table. `sp.graphics`, `sp.input`, `sp.keyboard`,
`sp.mouse` and `sp.timer` are sub-tables; `input`, `keyboard` and `mouse` are
the same table under three names, matching the browser Canvas vocabulary.

### Top level

| Call | Notes |
| --- | --- |
| `sp.init(width, height)` | Size in pixels. The window is created on `start`, or resized if one already exists. |
| `sp.start(intervalMs, callbacks, state)` | Fixed-interval loop. |
| `sp.startCanvas(fps, callbacks, state)` | Fixed-fps loop; `intervalMs = 1000/fps`. |
| `sp.quit()` | End the process. Same as closing the window. |
| `sp.dispose()` | Currently just another name for `quit`. |
| `sp.loadImage(source, name)` | Loads via XPCE `image/1`; see §6. |

### `sp.graphics`

| Call | Notes |
| --- | --- |
| `setBackgroundColor(c)` / `getBackgroundColor(c)` | Getter returns the fixed `#000000`. |
| `setColor(c)` / `getColor(c)` | Current ink; sticky until changed. Getter returns `#ffffff`. |
| `clear(c)` | Paint background and clear. |
| `rectangle(mode, x, y, w, h)` | |
| `line(points)` | Flat `[x1,y1,x2,y2,…]`. |
| `circle(mode, x, y, r)` | `r` is a **radius**. |
| `ellipse(mode, x, y, rx, ry)` | `rx`/`ry` are **radii**. |
| `arc(mode, arcType, x, y, r, angle1, angle2)` | Angles in radians. |
| `polygon(mode, points)` | Flat `[x1,y1,…]`; filled by even-odd scanline. |
| `print(text, x, y)` | |
| `printf(text, x, y, width, align)` | `width`/`align` ignored. |
| `newFont(size, family, style, font)` | Returns a font handle; result is the **last** parameter. |
| `setFont(font)` / `getFont(font)` | |
| `getDimensions(size)` | `{width, height}`. |
| `getWidth(w)` / `getHeight(h)` | |
| `push()` / `pop()` | Transform stack. |
| `origin()` | Reset the transform. |
| `translate(x, y)` / `rotate(angle)` / `scale(x, y)` | Scale also affects shape sizes. |
| `shear(x, y)` | No-op. |
| `setLineWidth(w)` / `getLineWidth(w)` | |
| `setLineStyle(style)` | No-op. |
| `setScissor(x, y, w, h)` / `clearScissor()` / `getScissor(scissor)` | Recorded, **not enforced**. |
| `draw(image, x, y)` | |
| `refresh()` | Unnecessary; the loop flushes each frame. |

`mode` is `'fill'` or `'line'`. Fill also strokes the outline.

### `sp.input` / `sp.keyboard` / `sp.mouse`

These read the state the event layer maintains, so they only report real
values after the first input event has arrived (see `sp.event`).

| Call | Notes |
| --- | --- |
| `isDown(key)` | Succeeds while the named key is held. |
| `getX(x)` / `getY(y)` / `getPosition(pos)` | Last known pointer position. |
| `buttonDown(button)` | Succeeds while that button is held. Buttons are `1` left, `2` middle, `3` right. |

### `sp.event` - the PyGame-style queue

XPCE has no polling API in this build, so input arrives as callbacks into the
backend and is queued here.

| Call | Notes |
| --- | --- |
| `get(events)` | Drains everything delivered since the last call. |
| `getType(type, events)` | Drains only events of one kind. |
| `peek(events)` | Does **not** drain. This is what the frame tick uses. |

Each event is a table with at least a `type` field:

| `type` | Extra fields |
| --- | --- |
| `'mousemotion'` | `posx` `posy` `x` `y` `button` `clicks` `mod` |
| `'mousedown'` | as above |
| `'mouseup'` | as above |
| `'mousewheel'` | as above, plus `wheel` (always `0` - see section 6) |
| `'keydown'` | `key` `char` `mod` |

A field an event does not carry reads back as `null` rather than failing, so
`ev.posx` on a keydown is harmless.

`key` is the lower-case name (`'a'`, `'space'`, `'escape'`, `'left'`, `'f1'`),
`char` is the character as typed, and `mod` is any of `"s"` (shift), `"c"`
(control), `"m"` (meta). Shift is already folded into the character, so
shift+A arrives as `key='a'`, `char='A'`, `mod='s'`.

```cosmos
rel update(_dt, s, s2)
    sp.event.get(events)
    list.each(events, show, _out)   // each/3 calls p(index, element, result)
    s2 = s
```

There is **no `'keyup'`**: this XPCE build's `@event_tree` has no release
events under `keyboard/`, so only presses are ever delivered.

### Callbacks (Love2D style)

Pass an `on` table to `sp.start` and each event of that type is handed to the
relation, before `update` runs for that frame:

```cosmos
rel on_keydown(ev)
    print(['key ', ev.key])

sp.start(33, {update=update and draw=draw and on={keydown=on_keydown}}, s)
```

The tick **peeks** at the queue for this, so a polling program that drains
with `get()` decides which frame sees which event.

### `sp.timer`

| Call | Notes |
| --- | --- |
| `getTime(time)` | Seconds. |
| `getDelta(delta)` | Seconds since the previous frame. |
| `getFPS(fps)` | |

## 6. Drawing conventions

- **Colours** are `'#rrggbb'` strings or `[R,G,B]` numeric lists. Anything
  else silently becomes **white** — a mistyped colour will not raise.
- **Images** are loaded by XPCE's `image/1`, so the format support is XPCE's:
  GIF, JPEG and XPM work, PNG needs `library(pce_image)`. A path that cannot be
  loaded is swallowed, so `loadImage` succeeds and `draw` then shows nothing.
- **Coordinates** are pixels, rounded to integers; a non-number becomes `0`.
  The origin is the top-left corner, `y` grows downward.
- **`circle` and `ellipse` take radii**, whereas raw XPCE's `circle/1` and
  `ellipse/2` take a bounding-box size. This is the one place the API
  deliberately departs from XPCE so the numbers mean what they say.
- **`newFont` returns its result last**, which is what lets
  `g.setFont(g.newFont(24,'sans','normal'))` work in value position.
- **Transforms** apply to coordinates *and* to shape sizes, so `scale` inside a
  `push`/`pop` pair magnifies what you draw.

## 7. Compile-time checking

`require('space', sp)` is the supported entry point and gives the same checking
as requiring `space_xpce` directly:

| Source | Result |
| --- | --- |
| `sp.init(320,480)` | accepted |
| `sp.init(320)` | `Wrong arity for sp.init` |
| `sp.graphics.clear('#fff')` | accepted |
| `sp.graphics.clear()` | `Wrong arity for sp.graphics.clear` |
| `sp.nosuch(1)` | `Unknown imported member: sp.nosuch` |

Checking only happens when the interface sidecar is reachable, and the compiler
looks for `<name>.cif` **next to the file being compiled**. `misc/` has no
`space.cif`, so the apps there are not checked. Copy `libs/space.cif` and
`libs/space_xpce.cif` beside a program to check it:

```powershell
Copy-Item libs\space.cif, libs\space_xpce.cif <your-dir>\
```

Arity and member existence are what get enforced. **No parameter in the API
carries a type annotation**, so argument types are not checked today. Annotate
`space.co` and `space_xpce.co` together or neither, or the two entry points
will disagree about what compiles.

`libs/space.co` is a forwarding layer over `libs/space_xpce.co` because
re-exporting a `require`d module directly does not work — the compiler records
no members for it. See `compiler_issue.txt`. **If you add a method to
`space_xpce.co`, add a matching forwarder to `space.co`**, or it stays invisible
to anyone requiring `'space'`.

## 8. Build and run

### The short way: `cosmos -l file.co --xpce`

```powershell
cosmos -l test4.co --xpce
```

`-l` compiles a `.co` and runs it; `--xpce` picks the **top-level-goals
entry**, which runs the file's own top-level goals instead of naming an entry
relation. That is what lets a program be written header-only:

```cosmos
require('space', sp)
...
sp.init(640, 480)
sp.start(16, {update=update and draw=draw}, {x=280 and y=215})
```

`require` and `sp.init` / `sp.start` sit at the top of the file, with no `main`
relation anywhere. See `test4.co` for a complete example.

### The long way: `cli.pl` directly

Useful when you want the `.pl` or a standalone `.exe` instead of running
straight from source. Three shapes, via `compiler/platform/cli.pl`:

```powershell
$SWIPL = 'C:/Program Files/swipl/bin/swipl.exe'

# 1. Compile check only - no entry point, so this cannot be run.
& $SWIPL -q -s compiler/platform/cli.pl -- test4.co test4.pl test4

# 2. Runnable .pl with an argv entry point (needs a `main` relation).
& $SWIPL -q -s compiler/platform/cli.pl -- test4.co test4.pl test4 --main

# 2b. Same, but for a header-only program: --xpce instead of --main.
& $SWIPL -q -s compiler/platform/cli.pl -- test4.co test4.pl test4 --xpce

# 3. Standalone .exe - stages the XPCE DLL closure next to the binary.
& $SWIPL -q -s compiler/platform/cli.pl -- test4.co test4.exe test4 --main --exe
```

Then run it:

```powershell
& test4.exe                   # option 3, self-contained
swipl -q -s test4.pl          # options 2 and 2b
```

**Option 1 produces a file that will not run.** The XPCE backend is not
embedded — loading PCE at build time poisons a saved image — so it is loaded at
*runtime* from a path recorded in the entry template, and that only happens for
an entry shape. Build with `--main`, `--xpce` or `--exe`. The compiler adds the
backend load on its own, by noticing that the output calls
`cosmos_require("space", _)`.

### Choosing between `--main` and `--xpce`

| | `--main` | `--xpce` |
| --- | --- | --- |
| Entry | calls `Module:main/1` with the argv list | runs the file's top-level goals |
| Needs a `main` relation | yes | no |
| Where `require` goes | inside the rel bodies | top of the file |
| Program arguments | `main(_args)` receives them | not available |
| Use when | you want argv, or a reusable module | you want the shortest possible program |

Pick one per program. `--exe` implies `--main`, not `--xpce`.

Use option 1 purely to type-check while iterating; it is the fastest of the
three.

### Worked examples

| File | Shape | What it shows |
| --- | --- | --- |
| `test4.co` | `--xpce`, header-only | the arrow-key-controlled rectangle; §3's loop with the event queue |
| `misc/moving_rect.co` | `--main` | the `ui2.pl` port, a rectangle on a fixed step |
| `misc/simple_xpce.co` | `--main` | one-shot drawing, no loop |
| `misc/demo_space_xpce.co` | `--main` | every primitive, plus transforms, fonts and scissor |

`test4.co` opens a 640×480 **Cosmos Space** window with a green 80×50 rectangle
in the middle; the arrow keys move it 10 px per press, clamped to the edges.
`misc/moving_rect.co` is the hand-written original it sits next to:

```powershell
swipl-win -q -f ui2.pl -g start
```

## 9. Two rules that will bite you

Both come from Cosmos language rules, not from this library.

1. **Match `require`'s placement to the entry you build with.** With `--main`,
   `require` goes inside the rel bodies: a top-level `require` captures the
   bound table into every relation, `main/1` becomes `main/2`, and the argv
   adapter has to call it with that capture. With `--xpce` there is no `main`
   relation and the `require` goes at the top of the file, which is the whole
   point of that flag. Picking the wrong pairing is the usual reason a Space
   program opens a window and then does nothing.
2. **A relation's result is its last parameter.** That is what makes
   `newFont(size, family, style, font)` usable in value position, and it is why
   getters take an out-parameter rather than returning a value. Note the three
   getters in this API were briefly declared with no parameter at all, which
   made them return nothing; the arities here are the corrected ones.

A related detail, since it looks like a bug and is not: when `require` is at the
top level, `update` and `draw` gain the captured `sp` as a trailing argument.
The callback table stores them as closures, and `call_cl/2` appends a closure's
captures as the final argument, so the runtime's 3-argument `update` call still
lands on the right predicate. Nothing to work around.

## 10. Limits

Known and deliberate for this version:

- **Input arrives as events, not polling.** `sp.event.get()` drains the queue
  and `sp.input` reads the state it maintains, so `isDown/1`, `buttonDown/1`
  and `getX`/`getY`/`getPosition` only report real values after the first
  event arrives. There is no `'keyup'`, and `wheel` is always `0`. See the
  event section above.
- **`setScissor` records but does not clip.**
- **`shear` and `setLineStyle` are no-ops**; `getLineStyle`-style accessors do
  not exist.
- **Rotating an ellipse** moves its centre; the shape stays axis-aligned.
- **No window title control.** The title is always `Cosmos Space`.
- **Image loading is format-limited and fails silently** — see §6.
- **No overloading inside a table literal.** Two `rel` with one name collapse,
  last one wins. That is why there is exactly one `rel` per method name.
- **No audio, no multiple windows, no z-order control.**

## 11. Troubleshooting

| Symptom | Cause |
| --- | --- |
| `Unknown imported member: sp.…` | An interface `.cif` is reachable but stale, or you called a method that does not exist. Regenerate `libs/*.cif`, or remove the `.cif` beside your program to compile unchecked. |
| `Unknown procedure: space_xpce_…` | The Prolog backend was never loaded. It is loaded at *runtime* from a path written into the entry template; a plain compile has no entry point and will fail this way. Rebuild with `--main` or `--xpce`. |
| Window opens but nothing is drawn | A `draw`/`update` exception is being swallowed as a warning. Read stderr. |
| Shapes have the wrong size | You passed a diameter where a radius is expected, or `scale` is still active from an unbalanced `push`. |
| A colour came out white | The value was neither `'#rrggbb'` nor `[R,G,B]`. |
| `main/2` where you expected `main/1` | A top-level `require` with a `--main` build. Move it into the rel bodies, or build with `--xpce` (§9). |
| Process crashes on shutdown | Something tried to close or destroy the window from outside the event loop. Let process exit reclaim it. |

## 12. See also

- `XPCE_LIBRARY.md` — the **other** XPCE library, `libs/xpce.co`
  (`require('xpce', xp)`). That one is the raw toolkit: objects, messages,
  callbacks and the event loop, with no canvas, no drawing primitives and no
  game loop. Reach for it when you want XPCE widgets; reach for this one when
  you want to draw. Both use `cosmos -l <file>.co --xpce`.
- `XPCE_BACKEND.md` — backend layout, XPCE quirks found by probing, build
  integration, verification commands.
- `compiler_issue.txt` — the compiler gaps this library works around.
- `test4.co` — the arrow-key example, in the `--xpce` header-only shape.
- `misc/simple_xpce.co` — one-shot drawing, no loop.
- `misc/demo_space_xpce.co` — every drawing primitive, plus transforms, fonts
  and scissor.
- `misc/moving_rect.co` — the animated `ui2.pl` port.