Everything is in place. Here's where the work landed.

## The four capabilities

**1. Modifier keys are now visible** — as events *and* via `isDown`.

XPCE never delivers events for modifier keys (its own manual says a modifier "generates neither"), so the backend synthesises them: a modifier going down produces an ordinary `keydown` event whose `key` is the modifier name, and letting go produces the matching `keyup`. Modifier state is tracked from the event's button mask (control `0x1`, shift `0x2`, meta `0x4`) combined with a per-frame keyboard-device poll.

Per your instruction, the vocabulary is XPCE-native — `shift`, `ctrl`, `alt`, with `control`/`meta` as synonyms and **no** `'Left Shift'`-style aliases; arrows remain the only alias exception. The SDL names exist purely internally to speak to the XPCE device. There is deliberately **no** `gui` modifier: the event mask has no bit for it and this build's device doesn't know the key name, so polling it raises an XPCE error that kills the frame.

**2. Top-level callbacks now fire.** `keypressed`, `keyreleased`, `mousepressed`, `mousereleased`, `mousemoved`, `wheel`, `textinput`, `focus`, `blur`, `resize` are dispatched from the `sp.start` map under their own names. The state is threaded through them and `update` runs with whatever state they left. The legacy `mousedown`/`mouseup` forms are dispatched without the button argument, and the `"on"` handler map keeps working unchanged.

**3. `rgb(...)` functor accepted** in `setColor`, `clear` and `setBackgroundColor` — `rgb(255,0,0)` and `rgba(r,g,b,a)`. The functor is exported from `libs/space.co`, so programs that `require('space', sp)` can use it without declaring it. This also fixed a pre-existing bug: `space_xpce_colour_string/2` used an invalid `format/2` pattern that raised `format_character '.' does not exist` for every non-string colour.

**4. Event-queue companions added**: `sp.event.clear()`, `clearType(type)`, `has(type,found)`, `count(type,n)`, `size(n)`, alongside the already-fixed `getType`.

## Verification

- `test/space_xpce_input.pl` — 43 checks, **all pass**. One check needed fixing: it still asserted a four-name modifier list including `gui`, which contradicts your "keep to the XPCE API" decision; it now asserts the set is exactly `{shift, ctrl, alt}`.
- `xpce/input.co` runs under `--xpce`: prints `color,#ff0000`, and `sp.event.size()`/`sp.event.has()` report correctly.
- Your `xpce/test.co` runs clean — only `resize` events, no phantom key presses, empty stderr.
- `libs/space.co`, `libs/space_xpce.co`, `xpce/input.co`, `xpce/test.co` all compile; `.pl`/`.cif` regenerated. `compiler/` untouched.

## Docs

`XPCE_SIMPLE_LIBRARY.md` §5 gained the modifier table, the `rgb()`/`rgba()` colour forms, the expanded `sp.event` table (`clear`/`clearType`/`has`/`count`/`size`), the event field table with `dx`/`dy`, and a rewritten callbacks section covering both the named callbacks and the `on` table. `docs/space-api.md` gained an `## Events` section (it had none), the `rgb()` colour forms, the modifier names, and the callback registration/state-threading semantics.

## Two things I could not prove here

Synthetic keystrokes never reach the XPCE window in this environment — `SendInput`/`keybd_event` produced only `resize`/`focus`/`blur`, no key events at all. So **the modifier delivery and `keypressed` need a manual check with real key presses on your machine**; they're covered by the Prolog suite but not end-to-end here. Second, `meta` is mapped to the physical **Alt** key (mask bit `0x4`), which follows XPCE's own modifier naming but I couldn't confirm empirically for the same reason.

==

The report is too categorical. XPCE is primarily a GUI toolkit, but that does not mean it lacks mouse and keyboard input. It supports GUI events, including button presses, keyboard input, and pointer interaction.

The distinction is between two different approaches:

- Event-driven input: XPCE notifies your application when the user presses a key, clicks a mouse button, or moves the pointer.
- Polling input: Your game loop asks every frame whether a key or button is currently held and retrieves the current pointer position.

XPCE's GUI-oriented design makes event-driven input natural. Whether your current Cosmos backend can support polling through its existing API is a separate question.

The official documentation confirms this: XPCE represents user actions as event objects and supports both primitive event handlers and higher-level recognisers.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.swi-prolog.org\&sz=32)

SWI-Prolog

+2



## What XPCE actually supports

| Capability                                | XPCE support                                   | Implication for Cosmos                      |
| ----------------------------------------- | ---------------------------------------------- | ------------------------------------------- |
| Mouse button down/up                      | Yes                                            | Track button state from events              |
| Mouse clicks and double-clicks            | Yes                                            | Implement click actions                     |
| Keyboard input                            | Yes                                            | Bind keys or handle keyboard events         |
| Mouse movement and drag                   | Yes                                            | Update pointer coordinates                  |
| Event position (`x`, `y`)                 | Yes                                            | Read coordinates from events                |
| Polling “is key held?” every frame        | Yes, since XPCE 10.0.0                        | `get(@keyboard_device, key_down, Key, @on)` |
| Polling “is button held?” every frame     | Not the main event model                       | Maintain state from press/release events    |
| Current pointer position without an event | Requires a separate query or tracking approach | Verify the relevant XPCE window/display API |

**Key polling is available.** XPCE 10.0.0 added the `keyboard` input device
class, reachable as `@keyboard_device`, and it answers whether a key is
held down right now:

```prolog
get(@keyboard_device, key_down, Key, @on)    % held
get(@keyboard_device, key_down, Key, @off)   % not held
```

`Key` is a name XPCE understands: `RET`, `ESC`, `TAB`, `BS`, `DEL`, `space`,
`insert`, `pause`, `cursor_home`, `end`, `page_up`, `page_down`,
`cursor_left`, `cursor_right`, `cursor_up`, `cursor_down`, `f1`..`f24`, a
single character, or the name SDL uses for the key (`"Left Shift"`). A name
XPCE does not know makes the get fail with `Unknown key`, so the name has to
be checked against that list before it is polled.

This is the call XPCE's own games use — `prolog/demo/asteroids.pl` in the
XPCE package does exactly this:

```prolog
key_down(Key) :- get(@keyboard_device, key_down, Key, @on).
```

**Key releases exist as well.** The release event is `key_up`, and it sits
under `any` in `@event_tree` rather than under `keyboard/` — which is why
looking only under `keyboard/` makes it look like the build has no releases
at all. Its id is the atom `key_up`; the key it releases comes from
`event <-key`, which answers the Emacs-style name of the matching key-down
(`"a"`, `"A"`, `"RET"`, `"<f1>"`).

Sources: [XPCE recognisers](https://www.swi-prolog.org/packages/xpce/UserGuide/recogniser.html), [XPCE event attributes](https://www.swi-prolog.org/pldoc/doc_for?object=xpce%28event%2Civar%2Cid%29) and the XPCE 10.0.0 source (`src/evt/inputdevice.c`, `src/sdl/sdlevent.c`).&#x20;

[image](https://www.google.com/s2/favicons?domain=https://eu.swi-prolog.org\&sz=32)

SWI-Prolog

+1



## How I'd implement input in the Cosmos backend

For a game-like `Space` API, I would keep the existing Cosmos-facing functions and implement them using XPCE events.

XPCE event handler

Mouse down/up · Key down/up · Pointer movement

Backend input state

Held keys · Held buttons · Last pointer coordinates

Cosmos API

`isDown(key)` · `buttonDown(button)` · `getX()` · `getY()` · `getPosition()`

The key detail is that XPCE can deliver input events asynchronously through its event loop. A handler records that a key was pressed; another records its release. The regular frame callback then reads the stored state. This avoids needing to poll XPCE's underlying native input system directly. XPCE's gesture machinery already handles press–drag–release sequences.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.swi-prolog.org\&sz=32)

SWI-Prolog

+1



There are some implementation details to handle correctly:

- Focus and missed releases: clear or reconcile held state if the window loses focus, so a key doesn't remain logically pressed.
- Coordinates: use the event's position and account for the window/canvas coordinate system.
- Key identity: define how Cosmos key names map to XPCE keyboard event identifiers.
- Quit: add a key handler, such as Escape, that requests orderly shutdown. This is separate from the window close button.

## Verdict on the report

The report is right that these functions are currently stubbed, assuming the inspected implementation is accurate. But its explanation that XPCE offers no safe input mechanism is misleading.

The limitation is in the current Cosmos XPCE backend, not a general lack of input support in XPCE. Event-driven input is a normal, documented part of XPCE. The main work is implementing the event handlers and connecting them to the existing API.