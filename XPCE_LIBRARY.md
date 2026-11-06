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
| `get(handle, attr, value)` | Reads an attribute into `value`. A live object comes back as an integer **handle**, never as a raw reference, so the value can be used again straight away. |
| `free(handle)` | Destroys the object, forgets the handle. Never on an open window outside the event loop — close it instead. |
| `color(spec, handle)` | `'#rrggbb'` or a colour name. For XPCE compounds Cosmos cannot spell. |
| `point(x, y, handle)` | Same. |
| `size(w, h, handle)` | Same. |
| `font(family, style, size, handle)` | Same, e.g. `font('helvetica', 'roman', 14, f)`. |
| `on_click(handle, callback)` | Fires a 1-argument relation per button click (arg: the button). |
| `on_select(handle, callback)` | Same mechanism for menu items (their `message` slot). |
| `on_event(handle, callback)` | Fires a 1-argument relation per XPCE event of the object: a key press, a key release, a mouse click. The argument is a table with the event fields (`type`, `key`, `char`, `x`, `y`, `button`, `clicks`). The object has to be one that reports its events, so create it as `xp.create('xpce_canvas', ['Title'], handle)` rather than as a plain `'picture'`. |
| `key_down(key, down)` | Is the key held down right now? Answers 1 or 0. The key is a name XPCE understands: `'RET'`, `'ESC'`, `'TAB'`, `'cursor_left'`, `'f1'`..`'f24'`, a single character, or the SDL name of a modifier key such as `'Left Shift'`. Asks the keyboard itself, so it is right even when the program missed a press or a release. |
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

## Menus and text editing: `xpce/notepad.co`

The `xpce/` folder holds full GUI programs built on this library. The
notepad is a frame with a menu bar (`File`: Save/Load/Quit) above an
editor area, run with:

```powershell
cosmos -l xpce/notepad.co --xpce
```

Its assembly is the canonical XPCE one (frame → dialog → menu_bar →
popup → menu_items; frame → view, view below the dialog, with the view's
own lazily created editor). Save/Load move the buffer's `contents`
through `io.readFile` / `io.writeToFile` on `notepad.txt` in the working
directory. There is no built-in file dialog (`finder` does not exist in
this XPCE build), so the path is fixed and documented in the app.

One environment note, handled in `libs/xpce_prolog.pl`: labelled popups
die in `initialise` converting the submenu-arrow program default, because
this install keeps its bitmaps outside XPCE's built-in image path. The
bridge preloads `ms_left_arrow.png` from the toolkit home (`@pce` →
`home`) once at load; harmless where bitmaps resolve already.

Views create their own editor lazily: fetch it with `get` *after* opening
the window (`xp.get(vw, 'editor', ed)` then `xp.get(ed, 'text_buffer',
tb)`). Do not attach an editor explicitly — replacing the placeholder
prints XPCE's harmless `@nil →destroy` chatter on stderr.

## Limits

- **Keyboard input is bridged, but thinly.** `on_event` reports key presses
  and key releases, and `key_down/2` polls the keyboard device. Both need an
  object that reports its events — create it as `'xpce_canvas'`, not as a
  plain `'picture'`. Key names are **XPCE's own** (`'RET'`, `'cursor_left'`,
  `'f1'`, `'Left Shift'`), not the lowercase Love2D names the Space library
  uses. Buttons, text fields (`text_item`, read via `selection` on Enter) and
  timers cover the rest of the GUI input.
- **No generic message construction.** Callbacks attach through `on_click`,
  `on_select` and `timer` only; anything fancier needs a bridge addition.
- **No window titles after creation**, no multiple displays, no z-order
  control beyond XPCE's own layout (dialog appends stack vertically;
  picture needs explicit `display` positions).
- Like Space: never destroy an open window programmatically. Integral
  floats are rounded at the boundary, so pass fractions where XPCE must
  see a float (timer intervals are exempt from rounding anyway).
