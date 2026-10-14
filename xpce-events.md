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
| Polling “is button held?” every frame     | Not the main event model                       | Maintain state from press/release events    |
| Current pointer position without an event | Requires a separate query or tracking approach | Verify the relevant XPCE window/display API |

Sources: [XPCE recognisers](https://www.swi-prolog.org/packages/xpce/UserGuide/recogniser.html) and [XPCE event attributes](https://www.swi-prolog.org/pldoc/doc_for?object=xpce%28event%2Civar%2Cid%29).&#x20;

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