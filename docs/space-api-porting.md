# Space API and Lua-sample port matrix

Companion to the [compiler and Space migration plan](compiler-space-plan.md). All `space.*` v2 names below are **proposed contracts**, not claims about the current runtime. Existing APIs are documented in [canvas/api.txt](../canvas/api.txt); LÖVE usage is listed in [canvas/_api.txt](../canvas/_api.txt).

## Two complementary surfaces

Use `space.graphics` for portable drawing and a short `space.isDown(...)` for keyboard polling. Use native JavaScript through `js::` when a Space wrapper would merely duplicate an existing API.

```cosmos
// Target configuration; requires the new Host setter and JS bridge.
Host space=js::space
space.canvas=js::canvas
```

Here `space.canvas` is the app's canvas host handle. `space.graphics` wraps Canvas2D with stable Space conventions. `space.canvas.getContext("2d")` reaches native Canvas2D through the host bridge. Additional registered `js::` roots can expose image loading, DOM components, audio or other browser services without adding language keywords.

The source inventory uses `love.keyboard.isDown`, not `love.isDown`. The intended port is `space.isDown("left")`; `space.mouse.isDown(1)` remains distinct. Boolean-valued host signatures support goal use such as `if(space.isDown("left"))`, with JS false mapped to a failed Boolean test rather than a successful effect call.

Choose normalized RGBA channels in `[0,1]` for v2, matching modern LÖVE. Keep `sp.setRGB`/`setRGBA` as explicit byte-color v1 adapters. This avoids silently treating `255` as a normalized value. LÖVE documents normalized colors and the earlier byte-color convention in [setColor](https://love2d.org/wiki/love.graphics.setColor); keyboard polling is documented in [isDown](https://love2d.org/wiki/love.keyboard.isDown).

## API mapping

The 50 textual `love.*` names include `keyboard` and `system` namespace checks and callback declarations. The table groups them by implementation dependency. Chained font calls and callbacks defined on `Game`/UI tables are additional requirements.

| Existing sample API | Proposed Space surface | Required semantics / implementation |
| --- | --- | --- |
| `love.conf(t)` | App manifest and exported metadata | Width/height/title/API version; preload settings before initialization. No Lua config execution. |
| `love.load`, `Game:load(host)` | `app.init(space,stateOut)` | Run once per instance; replace module-global state with app state and resource handles. |
| `love.update(dt)`, `Game:update(dt)` | `app.update(dt,state,nextState)` | Seconds; deterministic fixed-step option; no translation to “one unit per frame”. |
| `love.draw`, `Game:draw()` | `app.draw(state)` | Render real Cosmos logic; commit a command batch after success. |
| `love.keypressed` | Key event or `app.keypressed(key,scan,repeat,state,next)` | Normalize arrow aliases, preserve repeat/scancode information; focused app only. |
| `love.mousepressed`, `mousereleased`, `mousemoved` | Corresponding event adapters | Canvas-local logical coordinates; button mapping; dx/dy; retain event order. |
| `love.wheelmoved` | `app.wheelmoved(dx,dy,state,next)` | Normalize browser wheel units; do not forward arbitrary pixel/line deltas as equal steps. |
| `love.window.setTitle` | `space.window.setTitle(title)` | Update that app's window; do not rename unrelated windows. |
| `love.event.quit` | `space.quit()` | Close current Space app; do not terminate the whole desktop. |
| `love.graphics.setBackgroundColor` | `space.graphics.setBackgroundColor(color)` | Per-app background; explicit clear behavior. |
| `love.graphics.clear` | `space.graphics.clear(color)` / no-arg variant | Support sampled table and component arguments through adapter signatures; reset frame clear consistently. |
| `love.graphics.setColor` | `space.graphics.setColor(color)` / `(r,g,b,a)` | RGBA `[0,1]`; default alpha 1; normalize record/list forms once. |
| `love.graphics.newFont` | `font=space.graphics.newFont(size)` | Font handle; deterministic family configuration and readiness. |
| `love.graphics.setFont`, `getFont` | Same names on `space.graphics` | Per-app draw state; explicit font lifecycle. |
| `font:getHeight()`, `font:getWidth(text)` | `font.getHeight()`, `font.getWidth(text)` | Receiver-preserving HostMethod; measurements correspond to configured font. Cache reusable metrics. |
| `love.graphics.getDimensions` | `size=space.graphics.getDimensions()` | Return `{width,height}`; do not copy Lua's implicit multi-return convention. |
| `love.graphics.getWidth` | `space.graphics.getWidth()` | Logical canvas width. Add symmetric `getHeight` even if absent from the scanned names. |
| `love.graphics.setDefaultFilter` | `space.graphics.setDefaultFilter(min,mag)` | Map supported filtering to Canvas2D image smoothing; report approximations where min/mag cannot differ. |
| `love.graphics.setLineStyle` | `space.graphics.setLineStyle(style)` | Record/document Canvas2D approximation; no promise of pixel-identical LÖVE rasterization. |
| `love.graphics.setLineWidth` | `space.graphics.setLineWidth(width)` | Logical units affected by the transform as documented. |
| `love.graphics.print` | `space.graphics.print(text,x,y)` | Drawing text, distinct from Cosmos console `print`. Define top-left origin/baseline conversion. |
| `love.graphics.printf` | `space.graphics.printf(text,x,y,width,align)` | Wrapping and left/center/right alignment; measure text, not guessed character widths. |
| `love.graphics.push`, `pop` | Same names on `space.graphics` | Implement sampled transform/state behavior explicitly; pair saves/restores and reset at frame boundaries. |
| `love.graphics.translate`, `rotate`, `scale` | Same names on `space.graphics` | Radians and ordered transforms; coordinate transforms tested with camera ports. |
| `love.graphics.rectangle` | `space.graphics.rectangle(mode,x,y,w,h,rx,ry)` | `fill`/`line`, rounded corners, omitted-radius variants. |
| `love.graphics.line` | `space.graphics.line(points)` plus fixed-arity adapters | Polyline point list; preserve segment order. |
| `love.graphics.circle`, `ellipse` | Same names on `space.graphics` | Fill/outline; logical coordinates/radii. |
| `love.graphics.arc` | `space.graphics.arc(mode,arcType,x,y,r,a1,a2)` | Support sampled arc closure forms; map open/closed/pie geometry explicitly. |
| `love.graphics.polygon` | `space.graphics.polygon(mode,points)` | Accept point list; adapt existing scalar forms; ordered path. |
| `love.graphics.points` | `space.graphics.points(points)` | Define point size/rasterization and batched rendering. |
| `love.graphics.getScissor`, `setScissor`, `intersectScissor` | Same names on `space.graphics` | Store clip state in facade; Canvas2D has no equivalent direct “get current scissor”. Handle no-arg reset and nested clips with save/restore. |
| `love.keyboard`, `love.keyboard.isDown` | `space.input`, `space.isDown(key)` / `(keys)` | Input snapshot; any-key semantics for a supplied list; do not require variadic Cosmos calls. |
| `love.mouse.getPosition` | `position=space.mouse.getPosition()` | `{x,y}` record in app coordinates; also available in event snapshot. |
| `love.mouse.isDown` | `space.mouse.isDown(button)` / `(buttons)` | Separate keyboard/mouse naming; LÖVE button 1 maps to browser primary-button state. |
| `love.timer.getTime` | `space.time()` | Monotonic seconds; inject deterministic clock in tests. |
| `love.system`, `getClipboardText` | `space.clipboard.readText()` | Async host operation; user-gesture/platform behavior exposed as structured errors. Queue into event processing. |
| `love.filesystem.getInfo` | `space.files.info(path)` | App/package-relative metadata; distinguish absent file from read error. |
| `love.filesystem.read`, `write` | `space.files.readText(path)`, `writeText(path,text)` | Promise-backed storage; package assets read-only, app data writable; browser/Electron implementations share contract. |
| `love.filesystem.load` | **No executable-Lua replacement** | Port Lua save payloads to versioned structured data; see persistence section. Source imports use compiler/module resolution. |

Also implement `keyreleased`, `textinput` (including composed Unicode input), `resize`, and `focus`: helper and desktop code uses these even when a `love.*` textual count omits them. Joystick/gamepad forwarding is described by the old launcher notes but is not required by the scanned game implementations; add it when a port actually needs it.

### Existing Space compatibility

| Existing call | Adapter behavior |
| --- | --- |
| `require('space',sp)` | Resolve versioned Space facade/interface; no missing `space.pl` disguised by a source-preview fallback. |
| `sp.start(interval,callbacks,state)` | Register a v1 app; interval remains milliseconds. |
| `sp.init(w,h)` | Configure app canvas dimensions; app manifest is preferred in v2. |
| `canvas.rect(x,y,w,h,color)` | Legacy facade fills a rect with CSS color. It is distinct from native `js::canvas`. |
| `sp.rect`, `sp.rectBorder` | Filled/outlined rectangle using current legacy color. |
| `sp.setRGB`, `sp.setRGBA` | Byte channels converted to normalized color, including alpha. |
| `sp.clear`, `sp.refresh` | Clear/flush compatibility; presentation scheduling remains host-owned. |
| `sp.loadImage`, `sp.drawImage` | Asset preload/handle plus draw operation; old output-argument calls get an arity adapter. |
| `sp.delay` | Async yielding wait outside drawing; no blocking browser loop. |
| `sp.test` | Explicit development hook; not an application dependency. |

## Porting language/state rules

Port the game state machine into Cosmos, not into the JS facade. JS owns drawing/input/storage primitives. Use explicit `state,nextState` relation parameters; `!state` may shorten sequential updates once that compiler feature is reliable. Temporal loops continue to use `init`/`next` rather than unsupported `!` inside loops.

For each port, replace Lua module globals and `self` mutation with an instance state record. Keep old state immutable. Arrays must get an explicit indexing decision: preserve a Lua-style one-based helper during porting or convert every index and boundary consistently. Board row/column calculations need tests, not just syntax changes.

Lua's `and/or` value selection, nil/default idioms, truthiness of `0` and empty strings, `pairs` iteration order, multi-return functions and early returns require explicit translation. Use typed records/options for functions such as `winner -> (mark,line)`; never assume a JS/Cosmos Boolean model is interchangeable with Lua. Carry seeded RNG state for repeatable tests rather than relying on `math.randomseed(os.time())`.

Port shared dependencies once:

- `canvas/root/comp/ui.lua` → Space text/layout/input/clipping UI helpers; three sample UI copies should become one dependency with parity tests.
- `canvas/root/comp/camera.lua` → reusable camera state/update/transform helpers for city builder and similar ports.
- Sample-specific random/math/table/string operations → a small tested Cosmos support library. Port additional physics/pathfinder/scheduler modules only when an app requires them; their presence does not make them mandatory for this migration.
- Original `load.os` and `main.lua` wrappers → package manifests and exported `.co` app descriptors; preserve unique package identities, including `user1/app` versus `user2/app`.

### Persistence

Five user1 apps save best scores as text. Preserve their behavior with app-local paths and structured load/save errors. Preload state in `init`; queue saves after state transitions rather than awaiting storage in every draw.

Pharaoh's Depths writes and executes Lua save code using `love.filesystem.load`. Replace it with a versioned JSON/data schema and validation. Specify a one-time legacy import tool or explicitly document that legacy saves are not imported; do not keep a mandatory Lua evaluator merely to load saves. Snapshot tests should cover save, reload, missing/corrupt data, and migration behavior.

Browser storage can use IndexedDB behind async methods; Electron uses app-scoped files through preload IPC. Keep the storage codec shared. Clipboard and asset loads use the same async host/query scheduling contract.

## Complete sample-package inventory and waves

Source root: `canvas/lua-sample/`. A lexical scan found 34 `.lua` files across the following 26 packages. Counts include helpers/configuration, not just entry files. Paths below are relative to that root. Every row receives a target under `canvas/apps/<same-relative-path>/`, with `main.co`, any helper `.co` files, an app manifest, assets, and port tests. Preserve package identity even where display titles change.

| Wave | Source package | Lua files | Main port gate |
| --- | --- | ---: | --- |
| 1 | `user1/tictactoe` | 1 | Gridlock pilot: rules, AI win/block/center behavior, scores, hover and reset. Do not substitute the existing simplified JS board game. |
| 1 | `user2/app` | 1 | Basic drawing and mouse movement; small callback/instance-state check. |
| 1 | `user2/app2` | 1 | Shapes, text, keyboard/mouse event handling. |
| 1 | `user2/app4` | 1 | Input plus line/font state. |
| 1 | `user2/app5` | 1 | Basic graphics/text and interaction. |
| 1 | `user2/minesweeper` | 1 | Grid bounds, reveal/flag behavior, title, restart and reproducible generation. |
| 2 | `ashvault` | 1 | Text/font-heavy drawing, event quit, update timing. |
| 2 | `user2/chess` | 1 | Preserve the sample's actual rule set; pointer hit testing and turn state. Do not infer full chess rules from its title. |
| 2 | `user2/chronicle` | 1 | Text/state/event rendering fidelity. |
| 2 | `mahjong` | 1 | Larger rules/state port; pointer position, font/filter/line-style compatibility. |
| 3 | `arcane_duel` | 1 | Arcs, transforms, pointer aiming, time-dependent animation. |
| 3 | `user1/aetherdeep` | 1 | Continuous input, transforms, arcs/ellipses and monotonic time. |
| 3 | `user2/app3` | 1 | Points/polygons, rotation, timer and transform stack. |
| 3 | `user2/echo_thread` | 1 | Held-key input and continuous simulation. |
| 3 | `user2/platformer` | 1 | Physics/collision/timing; deterministic movement and jump traces. Use as the continuous-input pilot. |
| 4 | `user1/app` | 1 | Best-score persistence plus held keys/transforms. Use as the storage pilot. |
| 4 | `user1/lucent_array` | 1 | Persisted scores, pointer events and transforms. |
| 4 | `user1/night_rail` | 1 | Persistent scores and timed simulation. |
| 4 | `user1/orbit_loom` | 1 | Persistence, held input, mouse and transforms. |
| 4 | `user1/phase_lantern` | 1 | Persistence and held-input progression. |
| 5 | `terraforge` | 1 | Mouse drag/polling, wheel, polygons/arcs; sustained scene draw cost. |
| 5 | `user2/ember_command` | 3 | `conf`/launcher migration, camera scaling, drag/release/wheel handling. |
| 5 | `user2/city_builder` | 2 | Resolve external `ui`/`camera`; clipping, panning, drag placement and resize. Use as shared-UI pilot. |
| 6 | `user1/jade_frontier legacy` | 3 | Shared UI, clipping, clipboard/text input, simulation and launcher replacement. |
| 6 | `user1/sands_of_kemet` | 2 | Shared UI/text input, scissor intersections, transforms and keyboard polling. |
| 6 | `user2/pharaohs_depths legacy` | 3 | Shared UI plus executable-Lua save migration; most involved persistence gate. |

Wave order is based on API/dependency risk, not line count. Several Lua files put substantial logic on one line. The compiler/Space pilot sequence may take one representative from waves 3–5 early to expose timing, persistence and clipping problems before porting every simpler app.

## Definition of a completed port

1. The package compiles with the new compiler and launches from the editor and desktop using the same compiled exports.
2. It runs without Lua/Wasmoon and without a JS branch identifying its name or source pattern.
3. The original gameplay/state transitions, input semantics, rendering and persistence are checked against recorded Lua behavior; deviations are documented with intent.
4. Resources and app state are isolated per instance; stop/restart/reload leave no active callbacks, loops or stale handles.
5. All required host APIs are implemented or the port remains explicitly blocked. An API stub or recognizable static screenshot is not completion.

## Implementation artifacts to produce next

Create a machine-readable `space-host-api.json` signature registry and a `ports.json` tracker from this map during implementation. Each API entry should state argument/result types, receiver rules, sync/async/effect behavior, arity adapters, version, implementation location and tests. Each port entry should state source/target, dependencies, API coverage, save migration, verification results and remaining blockers. Generate the public API reference and coverage report from these registries so they stay consistent.
