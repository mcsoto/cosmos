# Space API

## Starting an application

Import the Space facade and set the logical canvas size before starting:

```cosmos
require('space', sp)

width=640
height=360
initial={x=40 and speed=2}

rel update(dt,s,s2)
    s2={x=s.x+s.speed and speed=s.speed}

rel draw(s)
    sp.graphics.clear('#07111f')
    sp.graphics.setColor('#7cf4cb')
    sp.graphics.rectangle('fill',s.x,40,48,48)

sp.init(width,height)
sp.start(16,{update=update and draw=draw},initial)
```

`sp.start(milliseconds,callbacks,state)` uses a fixed update interval in
milliseconds. `sp.startCanvas(fps,callbacks,state)` is the FPS convenience
form. Rendering is scheduled with `requestAnimationFrame`.

`sp.startLoop(seconds,game,callbacks,state)` is the `xp.main_loop/1` shape:
the `game(_)` relation opens the window itself (`sp.init` + `sp.open`) and the
loop dispatches until it is closed. The interval is in seconds here.

```cosmos
rel game(_)
    sp.init(width,height)
    sp.open()

sp.startLoop(0.016,game,{update=update and draw=draw},initial)
```

Version 2 update callbacks receive elapsed step time:

```text
update(dt,state,state2)
```

`dt` is in seconds. It is clamped to a few frame intervals, so a callback that
took a long time cannot hand the next frame a huge step and make a game jump
across the screen.

The compatibility form remains supported:

```text
update(state,state2)
```

`draw(state)` runs after the update and must perform its effects once. Canvas
effects are not undone if a Cosmos relation later backtracks.

### Exported-table compatibility

Older programs may export an application table instead of calling `sp.start`:

```cosmos
app={
    width=640 and height=360 and tick=16 and state=initial
    init=init and update=update and draw=draw and mouseup=mouseup
}
export(app)
```

Space adapts this to the same retained callback/state runtime. If present,
`init(width,height)` is called before the loop.

## Lifecycle and input callbacks

The input callbacks are registered in the `sp.start` table under their own
names, next to `update` and `draw`:

```cosmos
rel keypressed(key,state,state2)
    state2 = state

sp.start(16, {update=update and draw=draw and keypressed=keypressed}, initial)
```

All state-changing callbacks receive the current state as their penultimate
argument and produce the next state as their final argument:

```text
update(dt,state,state2)
draw(state)

mousepressed(x,y,button,state,state2)
mousereleased(x,y,button,state,state2)
mousemoved(x,y,dx,dy,state,state2)
wheel(dx,dy,state,state2)

keypressed(key,state,state2)
keyreleased(key,state,state2)
textinput(text,state,state2)
focus(state,state2)
blur(state,state2)
resize(width,height,state,state2)
```

The state is threaded through the input callbacks: each one is called with the
state the previous one produced, and `update` then runs with the state the
input callbacks left behind. A callback that does not care about the state may
leave the last two arguments out, and one that does not care about anything
else may take only the leading ones.

Input is local to the app canvas. Keyboard events are forwarded only while it
has focus. Coordinates use logical canvas pixels even when CSS scales the
canvas. `resize` is dispatched when an embedding calls the shared runner's
`resize(width,height)` method; the standalone window does not implicitly change
the application's declared logical resolution.

Mouse buttons use Space numbering:

```text
1  left
2  right
3  middle
```

For existing applications, these aliases are supported:

```text
mousepressed(x,y,button,...)  -> mousedown(x,y,...)
mousereleased(x,y,button,...) -> mouseup(x,y,...)
```

The compatibility adapter intentionally removes the button argument because
legacy `mousedown` and `mouseup` relations use `(x,y,state,state2)`.

A per-type handler table is supported as well, and receives the whole event
table instead of separate arguments:

```cosmos
rel on_keydown(ev)
    print(['key ', ev.key])

sp.start(16, {update=update and draw=draw and on={keydown=on_keydown}}, initial)
```

## Events

`sp.event` is a PyGame-style queue of the input that arrived since the last
drain:

```text
sp.event.get(events)        drain everything
sp.event.getType(type,events)  drain the events of one type only
sp.event.peek(events)       look without draining
sp.event.clear()            throw every pending event away
sp.event.clearType(type)    throw the pending events of one type away
sp.event.has(type,found)    found is 1 when one is waiting, 0 otherwise
sp.event.count(type,n)      how many of that type are waiting
sp.event.size(n)            how many events are waiting in all
```

`getType` leaves the other events queued, so asking for the key events does
not throw the mouse or resize events away.

The queue holds at most 256 events; the oldest is dropped when it overflows.
A program that polls every frame never reaches the limit.

Each event reaches the input callbacks **exactly once**. The frame tick fires
the events the callbacks have not seen yet, and only peeks at the queue
itself, so a program that drains it with `get()` still finds the event. Using
both styles in one program means seeing the event twice: once as a callback
and once from the queue.

Each event is a table with a `type` field and, depending on the type, these
fields:

| `type` | Extra fields |
| --- | --- |
| `'mousemotion'` | `posx` `posy` `x` `y` `dx` `dy` `button` `clicks` `mod` |
| `'mousedown'` | as above |
| `'mouseup'` | as above |
| `'mousewheel'` | as above, plus `wheel` |
| `'keydown'` | `key` `char` `mod` |
| `'keyup'` | `key` `mod` |
| `'textinput'` | `text` |
| `'focus'` | |
| `'blur'` | |
| `'resize'` | `width` `height` |

A field an event does not carry reads back as `null` rather than failing.

## Graphics

The LÖVE-like graphics object is `sp.graphics`:

```cosmos
g=sp.graphics
g.setColor('#ffffff')
g.rectangle('line',10,10,100,50)
g.print('Space',18,20)
```

Implemented methods:

```text
setBackgroundColor(color | r,g,b[,a] | rgb(r,g,b) | rgba(r,g,b,a))
getBackgroundColor()
setColor(color | r,g,b[,a] | rgb(r,g,b) | rgba(r,g,b,a))
getColor()
clear([color | r,g,b[,a] | rgb(r,g,b) | rgba(r,g,b,a)])

rectangle(mode,x,y,width,height[,radiusX,radiusY])
line(x1,y1,x2,y2,...)
point(x,y)
points(x1,y1,...)
circle(mode,x,y,radius)
ellipse(mode,x,y,radiusX,radiusY)
arc(mode,arcType,x,y,radius,angle1,angle2)
polygon(mode,x1,y1,x2,y2,...)

print(text,x,y)
printf(text,x,y,width,alignment)
newFont(size[,family,style])
setFont(font)
setFont(size[,family,style])
getFont()

getDimensions()
getWidth()
getHeight()

push()
pop()
origin()
translate(x,y)
rotate(angle)
scale(x[,y])
shear(x,y)

setLineWidth(width)
getLineWidth()
setLineStyle('smooth'|'rough')
setScissor([x,y,width,height])
clearScissor()
getScissor()

draw(image,x,y[,rotation,scaleX,scaleY,originX,originY])
refresh()
```

Drawing modes are `'fill'` and `'line'`. Angles are radians. `arcType` accepts
`'open'` and `'pie'`; other values currently behave like an open Canvas arc.
`refresh()` is a no-op because Canvas presents commands immediately.

Colors accept a CSS color string, a component list, the `rgb(r,g,b)` and
`rgba(r,g,b,a)` functors, normalized components in `0..1`, or byte components
in `0..255`. If any component is greater than one, the entire component set is
treated as byte values. The `rgb` functor is exported by the library, so a
program that requires `space` can use it without declaring it.

Text coordinates use a top-left convention. The backend offsets the native
Canvas baseline by the active font size.

## Keyboard, mouse, and timer polling

```text
sp.keyboard.isDown(key,...)

sp.mouse.getX()
sp.mouse.getY()
sp.mouse.getPosition()
sp.mouse.isDown(button,...)

sp.timer.getTime()
sp.timer.getDelta()
sp.timer.getFPS()
```

Keys are lowercase LÖVE-style names. DOM arrow keys are normalized to `'left'`,
`'right'`, `'up'`, and `'down'`; other examples include `'enter'` and `'r'`.
Polling accepts either `'left'` or the DOM alias `'arrowleft'`. Held key and
mouse-button state is cleared when the canvas loses focus.

The three modifier keys are named `'shift'`, `'ctrl'` and `'alt'`, with
`'control'` and `'meta'` accepted as synonyms. There is no `'gui'` modifier:
the native backend has no way to see that key, so it is not offered. Because
that backend delivers no events for the modifier keys, it synthesises them —
a modifier that goes down produces an ordinary `keydown` event whose `key` is
the modifier name, and letting go produces the matching `keyup`. So a
modifier is visible both as an event and through `isDown`.

`getTime()` returns seconds since backend creation. `getDelta()` currently
returns the fixed update interval in milliseconds, matching the `dt` supplied
to the Cosmos update callback. `getFPS()` reports the corresponding target FPS.

## Images and frame helpers

```text
sp.loadImage(source[,name])
sp.beginFrame()
sp.endFrame()
sp.stop()
sp.dispose()
```

`loadImage` is asynchronous at the JavaScript host level and registers the
result under `name`. A registered name can be passed to `graphics.draw`.
Cosmos-level asset preloading and failure callbacks are not yet stabilized.

`beginFrame` saves the context and resets its transform. `endFrame` restores
it. The compiled runner manages scheduling, so applications normally do not
call these methods themselves.
