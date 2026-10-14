# Pure XPCE library

Use SWI-Prolog's XPCE GUI toolkit normally from Cosmos: windows, boxes,
buttons, text fields, timers, and Cosmos relations as event callbacks.

This is **not** Space (`libs/space*.co`): no canvas, no game loop, no
drawing primitives, no backend state. Just objects, messages, callbacks,
and the event loop. For the drawing/game-loop API see `XPCE_SIMPLE_LIBRARY.md`;
both are built with `cosmos -l <file>.co --xpce`.

- **Library:** `libs/xpce.co` — `require('xpce', xp)`
- **Bridge:** `libs/xpce_prolog.pl` — raw Prolog, loaded automatically
- **Compiled:** `libs/xpce.pl` + `libs/xpce.cif` (regenerate after editing)
- **Example:** `xpce-example.co` (repo root)
- **Test:** `tests/compiler/xpce_lib.co` (headless, runs in the suite)

Requires SWI-Prolog with `library(pce)`: `?- use_module(library(pce)).`

## Quick start

```cosmos
require('xpce', xp)

xp.create('dialog', ['Hello'], win)
xp.create('text', ['Pure XPCE, driven from Cosmos'], label)
xp.send(win, 'append', [label])
xp.create('button', ['Quit'], quit)
xp.on_click(quit, do_quit)
xp.send(win, 'append', [quit])
xp.send(win, 'open', [])
xp.loop()

rel do_quit(_btn)
    require('xpce', xp)
    print('quit clicked')
    xp.quit()
```

```powershell
cosmos -l xpce-example.co --xpce
```

## API

Everything hangs off the `xp` table. One rel per name — table literals
cannot overload, so there are no optional arguments.

| Call | Notes |
| --- | --- |
| `create(cls, args, handle)` | `cls` is a class name string, `args` a flat list. Answers an integer **handle**, never the raw reference. |
| `send(handle, method, args)` | `method` is a string; handles inside `args` resolve back to objects. Builds `method(args...)` and sends it. |
| `get(handle, attr, value)` | Reads an attribute into `value`. |
| `free(handle)` | Destroys the object, forgets the handle. Never on an open window outside the event loop — close it instead. |
| `color(spec, handle)` | `'#rrggbb'` or a colour name. For XPCE compounds Cosmos cannot spell. |
| `point(x, y, handle)` | Same. |
| `size(w, h, handle)` | Same. |
| `font(family, style, size, handle)` | Same, e.g. `font('helvetica', 'roman', 14, f)`. |
| `on_click(handle, callback)` | Fires a 1-argument relation per button click (arg: the button). |
| `timer(seconds, callback, handle)` | Repeating timer; the callback gets the timer's handle, so a one-shot frees itself. |
| `set_data(key, value)` / `get_data(key, value)` | Named shared slots; values stored untouched. |
| `loop()` | Pumps the display until the process ends. Never returns. |
| `poll()` | Pumps the display exactly once. For tests and custom loops. |
| `quit()` | Ends the process. |

## Values across the bridge

- **Handles** are small integers. They survive a trip through Cosmos
  arithmetic (`3` vs `3.0` both resolve) and fail loudly when unknown.
- **Numbers** pass through; integral floats are rounded, since XPCE slots
  usually want ints. Genuine fractions (timer intervals, arc angles) are
  untouched — except `xpce_timer`, which never rounds.
- **Strings become atoms** on the way in (XPCE accepts atoms everywhere a
  name or text is needed) and **come back as strings**, so Cosmos string
  operations work on everything `get` returns.
- **Live objects come back as fresh handles**; empty (`@nil`) reads back
  as null.

## Callbacks

A Cosmos closure is an ordinary Prolog term, so the bridge files it under
an id and hands XPCE `message(@prolog, xpce_cosmos_fire, Id, Handle)`.
When XPCE fires, the relation runs with its source handle:

```cosmos
rel do_greet(_btn)
    require('xpce', xp)
    xp.get_data('namefield', nf)
    xp.get(nf, 'selection', who)
    print(['hello, ', who])
```

Three rules, all load-bearing:

1. **Exactly one argument.** A 0-argument relation misses the call; a
   2-argument one (e.g. mentioning a top-level binding — see 2) does too.
2. **No top-level bindings inside a callback.** `require('xpce', xp)` at
   the top of the file captures `xp` into every relation that mentions
   it, changing its arity. Require inside the callback body instead.
3. **Shared state goes in `set_data`/`get_data`**, for the same reason.

A throwing callback prints a warning and the loop continues — except
`halt`/abort, which are rethrown so `quit()` really quits.

## Event loop

`xp.loop()` dispatches until the process ends. The bridge wires
`done_message` to halt when it creates a top-level window
(`picture`/`frame`/`dialog`), so closing the window quits, like Space.
Unlike `pce_main_loop/1`, windows may be created *before* the loop starts:
nothing is tracked, the display is just pumped.

## Limits

- **No raw keyboard events.** Buttons, text fields (`text_item`, read via
  `selection` on Enter) and timers cover GUI input; XPCE key recognisers
  are not bridged yet.
- **No generic message construction.** Callbacks attach through `on_click`
  and `timer` only; anything fancier needs a bridge addition.
- **No window titles after creation**, no multiple displays, no z-order
  control beyond XPCE's own layout (dialog appends stack vertically;
  picture needs explicit `display` positions).
- Like Space: never destroy an open window programmatically. Integral
  floats are rounded at the boundary, so pass fractions where XPCE must
  see a float (timer intervals are exempt from rounding anyway).
