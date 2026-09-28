Yes. **XPCE is a particularly plausible native graphical backend for Cosmos/Space when the target is the native `cosmos.exe`/SWI-Prolog runtime.** It is actually closer to what you're doing than introducing a separate GUI framework.

SWI describes XPCE as its native Prolog GUI toolkit: its graphics kernel is implemented in C, while application classes and methods can be defined in Prolog. It provides windows, dialogs, drawing primitives, events, layout, etc. ([SWI-Prolog][1])

The important qualification is that **XPCE would be a native/Desktop Space backend, not a replacement for the browser Canvas backend**.

## How it could fit Cosmos

Your current architecture is already almost set up for this:

```text
                   Cosmos
                     │
              compiler / emitter
                     │
                  Prolog
                     │
          ┌──────────┴──────────┐
          │                     │
       SWI native            SWI-WASM
          │                     │
       XPCE backend        JS/Canvas backend
          │                     │
       Windows/X11          Browser
```

So instead of making Space fundamentally a JavaScript/Canvas API, define **Space as the abstract graphics/event API**, with implementations underneath it.

For example:

```cosmos
space = xpce::display

window = space.window(800, 600)
canvas = window.canvas()

canvas.fillRect(10, 10, 100, 50)
canvas.line(0, 0, 100, 100)
```

and the native lowering could ultimately become something conceptually like:

```prolog
new(Window, window(...)),
send(Window, open),
send(Canvas, ...).
```

XPCE itself uses `new/2`, `send/2`, `get/3`, and `free/1` as its basic object interface. ([SWI-Prolog][2])

### note: see if instead of xpce::, the existing pl:: is enough

## One important caveat for `cosmos.exe`

You'd want the executable builder to explicitly include XPCE when producing a graphical native image.

Something along the lines of:

```prolog
:- use_module(library(pce)).
```

before `qsave_program/2`, rather than assuming XPCE will be discovered dynamically.

SWI's own initialization machinery conditionally initializes XPCE when a GUI is available or the `xpce` flag is enabled. ([SWI-Prolog][5])

So the native build could eventually have two modes:

```text
make exe
     → core Cosmos executable

make exe GUI=xpce
     → Cosmos + XPCE executable
```

or simply make XPCE part of the graphical distribution.

### Bottom line

**Yes, I think XPCE is worth investigating for the native Space backend.** It has an unusually good architectural fit:

* native to SWI-Prolog;
* C-backed graphics;
* Prolog-native object/event model;
* works with saved SWI states;
* Windows/Linux support;
* doesn't reintroduce Lua;
* maps naturally onto your opaque host-object model;
* gives `cosmos.exe` a genuine native GUI capability. ([SWI-Prolog][1])

The clean architecture would be:

```text
                 Cosmos Space
                      │
             ┌────────┴────────┐
             │                 │
        NativeSpace        BrowserSpace
             │                 │
           XPCE          JS/HTML Canvas
             │                 │
          SWI native        SWI-WASM
```

I'd treat **XPCE as the first native implementation of Space**, rather than making XPCE itself the Space API. That preserves the possibility of other native backends later while giving `cosmos.exe` a real graphical runtime.

[1]: https://www.swi-prolog.org/packages/xpce/?utm_source=chatgpt.com "XPCE: the SWI-Prolog native GUI library"
[2]: https://ww1.swi-prolog.org/packages/xpce/examples.md?utm_source=chatgpt.com "XPCE Examples"
[3]: https://www.swi-prolog.org/pldoc/doc_for?object=xpce%28graphical%2Civar%2Cdevice%29&utm_source=chatgpt.com "graphical-device"
[4]: https://www.swi-prolog.org/download/xpce/doc/prolog/userguide.pdf?utm_source=chatgpt.com "Notes on XPCE for MS-Windows"
[5]: https://www.swi-prolog.org/pldoc/doc/_SWI_/swipl.rc?public_only=false&utm_source=chatgpt.com "swipl.rc -- Associate XPCE with SWI-Prolog"

----

Yes. **XPCE is not just a widget/GUI toolkit**; it has a fairly complete 2D drawing layer that can serve as the native backend for a Cosmos `Space` API.

The primitives include:

* lines
* rectangles / filled rectangles
* arcs and ellipses
* polygons
* images
* text
* clipping
* graphics state / pen / colors
* moving and composing graphical objects

The XPCE documentation explicitly exposes primitives such as `draw_arc`, `draw_box`, `draw_fill`, `draw_image`, `draw_line`, `draw_poly`, and `draw_text`. ([SWI-Prolog][1])

So conceptually, you could make Cosmos `Space` look more like a small **SDL/SFML-style 2D API**, while XPCE is merely the native implementation:

```cosmos
window = space.window(800, 600)
canvas = window.canvas()

canvas.clear()
canvas.line(10, 10, 100, 100)
canvas.rect(20, 20, 80, 50)
canvas.fillRect(120, 20, 80, 50)
canvas.circle(200, 100, 30)
canvas.arc(250, 100, 50, 0, 180)
canvas.polygon(...)
canvas.image(...)
canvas.text("Hello", 20, 200)
```

`circle()` in particular wouldn't be an awkward fit: XPCE has `circle`/`ellipse` graphical objects and the underlying drawing system supports ellipse/arc operations. ([SWI-Prolog][2])

### This could fit Space quite well

I'd separate it into roughly:

```text
Cosmos Space API
│
├── Window
├── Canvas
│   ├── clear
│   ├── pixel
│   ├── line
│   ├── rect
│   ├── circle
│   ├── ellipse
│   ├── arc
│   ├── polygon
│   ├── image
│   └── text
│
├── Input
│   ├── mouse
│   ├── keyboard
│   └── events
│
└── GUI
    ├── button
    ├── text
    ├── menu
    └── etc.
```

Then:

```text
                 Space
                   │
          ┌────────┴────────┐
          │                 │
     Native backend    Browser backend
          │                 │
         XPCE          HTML Canvas/DOM
```

That distinction is useful because **Space doesn't have to become "the XPCE API"**. XPCE provides the native implementation, while the Cosmos API remains portable.

XPCE is also fairly low-level underneath its higher-level GUI facilities, so this isn't merely theoretical: its graphics layer is specifically designed to expose primitive drawing operations while handling redraw and clipping for you. ([SWI-Prolog][3])

One interesting current detail is that modern XPCE itself has moved to an SDL-based graphics implementation internally. The current SWI changelog refers to SDL3 support and SDL-based image/window functionality. ([SWI-Prolog][2])

So for Cosmos, **XPCE may actually be considerably closer to the native "SDL-compatible graphics backend" you were looking for than I initially implied**. You could have a fairly thin `space.xpce` implementation rather than building a whole graphics system around GUI widgets.

[1]: https://www.swi-prolog.org/download/xpce/doc/userguide/userguide.pdf?utm_source=chatgpt.com "Dept. of Social Science Informatics (SWI)"
[2]: https://www.swi-prolog.org/ChangeLog?branch=development&from=9.3.31&to=10.1.10&utm_source=chatgpt.com "SWI-Prolog Changelog from version 9.3.31 to 10.1.10"
[3]: https://www.swi-prolog.org/packages/xpce/?utm_source=chatgpt.com "XPCE: the SWI-Prolog native GUI library"

Right — the likely issue is that `start/0` creates the XPCE window but **doesn't enter XPCE's event loop** in the saved executable. Your earlier `swipl-win ui2.pl` invocation had the normal interactive Prolog to keep the process alive.

Use `pce_main_loop/1` as the saved program's `goal/1`:

```bat
$(SWIPL) -q -s ui2.pl -g "qsave_program('ui2.exe',[emulator(swi('bin/xpce-stub.exe')),goal(pce_main_loop(start)),stand_alone(true),autoload(true)])" -t halt
```

But `goal/1` should ideally be a callable predicate, so I'd make a wrapper:

```prolog
run :-
    pce_main_loop(start).
```

Then the one-liner becomes:

```bat
$(SWIPL) -q -s ui2.pl -g "qsave_program('ui2.exe',[emulator(swi('bin/xpce-stub.exe')),goal(run),stand_alone(true),autoload(true)])" -t halt
```

with:

```prolog
start :-
    new(P, picture('Moving rectangle')),
    send(P, size, size(640, 480)),
    ...
```

The flow is then:

```text
ui2.exe
  │
  └─ run
      │
      └─ pce_main_loop(start)
             │
             ├─ start → create window
             └─ XPCE event loop keeps process alive
```

That distinction matters: `goal(start)` merely executes `start/0` and, once it succeeds, the standalone process can terminate. `pce_main_loop(start)` runs `start/0` **as an XPCE application** and keeps processing GUI events.

