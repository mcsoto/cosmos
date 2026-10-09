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

A complete program is three relations: `update` advances state, `draw` paints
it, and `main` opens the window and starts the loop.

```cosmos
rel update(dt, s, s2)
    s2 = {x = s.x + dt * 120}          // 120 px per second

rel draw(s)
    require('space', sp)
    g = sp.graphics
    g.clear('#1b1b2f')
    g.setColor('#3050ff')
    g.rectangle('fill', s.x, 100, 80, 50)

rel main(_args)
    require('space', sp)
    sp.init(640, 480)
    sp.start(16, {update=update and draw=draw}, {x=100})
```

`misc/moving_rect.co` is this program, with the comments stripped off and a
fixed-step variant of the motion. Read it for the annotated version.

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

| Call | Notes |
| --- | --- |
| `isDown(key)` | Succeeds while held. **Always fails in v1** (see §6). |
| `getX(x)` / `getY(y)` / `getPosition(pos)` | Always `(0, 0)`. |
| `buttonDown(button)` | Always fails in v1. |

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

Three build shapes, via `compiler/platform/cli.pl`:

```powershell
$SWIPL = 'C:/Program Files/swipl/bin/swipl.exe'

# 1. Compile check only - no entry point, so this cannot be run.
& $SWIPL -q -s compiler/platform/cli.pl -- misc/moving_rect.co misc/moving_rect.pl moving_rect

# 2. Runnable .pl with an argv entry point. Needs a system SWI that has XPCE.
& $SWIPL -q -s compiler/platform/cli.pl -- misc/moving_rect.co misc/moving_rect.pl moving_rect --main

# 3. Standalone .exe - stages the XPCE DLL closure next to the binary.
& $SWIPL -q -s compiler/platform/cli.pl -- misc/moving_rect.co misc/moving_rect.exe moving_rect --main --exe
```

Then run it:

```powershell
& misc\moving_rect.exe            # option 3, self-contained
swipl -q -s misc/moving_rect.pl   # option 2
```

**Option 1 produces a file that will not run.** The XPCE backend is not
embedded — loading PCE at build time poisons a saved image — so it is loaded at
*runtime* from an absolute path, and that path only gets written into the
`--main` / `--exe` entry template. Build with `--main` or `--exe`. The compiler
adds the backend load on its own, by noticing that the output calls
`cosmos_require("space", _)`.

Use option 1 purely to type-check while iterating; it is the fastest of the
three.

A window titled **Cosmos Space** opens at 640x480 and a blue 80x50 rectangle
slides right at 2 px every 16 ms, wrapping at the right edge. Close the window
to quit.

To reproduce the original hand-written XPCE program this is modelled on:

```powershell
swipl-win -q -f ui2.pl -g start
```

## 9. Two rules that will bite you

Both come from Cosmos language rules, not from this library.

1. **`require` goes inside rel bodies**, never at the top level, in any program
   built with `--main`. A top-level `require` captures the bound table into
   every relation, which turns `main/1` into `main/2` and breaks the argv entry
   point.
2. **A relation's result is its last parameter.** That is what makes
   `newFont(size, family, style, font)` usable in value position, and it is why
   getters take an out-parameter rather than returning a value. Note the three
   getters in this API were briefly declared with no parameter at all, which
   made them return nothing; the arities here are the corrected ones.

## 10. Limits

Known and deliberate for this version:

- **Input is stubbed.** `isDown/1` and `buttonDown/1` always fail (XPCE offers
  no safe polling through this layer), so they read as "nothing held".
  `getX`/`getY`/`getPosition` always report `(0,0)`. There is no keyboard or
  mouse input, which also means there is no in-app quit key.
- **`setScissor` records but does not clip.**
- **`shear` and `setLineStyle` are no-ops**; `getLineStyle`-style accessors do
  not exist.
- **Rotating an ellipse** moves its centre; the shape stays axis-aligned.
- **No window title control.** The title is always `Cosmos Space`.
- **Image loading is format-limited and fails silently** — see §6.
- **No overloading inside a table literal.** Two `rel` with one name collapse,
  last one wins. That is why there is exactly one `rel` per method name.
- **No audio, no input events, no multiple windows, no z-order control.**

## 11. Troubleshooting

| Symptom | Cause |
| --- | --- |
| `Unknown imported member: sp.…` | An interface `.cif` is reachable but stale, or you called a method that does not exist. Regenerate `libs/*.cif`, or remove the `.cif` beside your program to compile unchecked. |
| `Unknown procedure: space_xpce_…` | The Prolog backend was never loaded. It is loaded at *runtime* from an absolute path written into the `--main` / `--exe` entry template; a plain compile has no entry point and will fail this way. Rebuild with `--main`. |
| Window opens but nothing is drawn | A `draw`/`update` exception is being swallowed as a warning. Read stderr. |
| Shapes have the wrong size | You passed a diameter where a radius is expected, or `scale` is still active from an unbalanced `push`. |
| A colour came out white | The value was neither `'#rrggbb'` nor `[R,G,B]`. |
| `main/2` where you expected `main/1` | A top-level `require`. Move it into the rel bodies (§9). |
| Process crashes on shutdown | Something tried to close or destroy the window from outside the event loop. Let process exit reclaim it. |

## 12. See also

- `XPCE_BACKEND.md` — backend layout, XPCE quirks found by probing, build
  integration, verification commands.
- `compiler_issue.txt` — the compiler gaps this library works around.
- `misc/simple_xpce.co` — one-shot drawing, no loop.
- `misc/demo_space_xpce.co` — every drawing primitive, plus transforms, fonts
  and scissor.
- `misc/moving_rect.co` — the animated example from §3.