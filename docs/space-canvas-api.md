# Space Canvas API

Space is a provisional LÖVE-inspired API backed by HTML Canvas2D. It is not a
complete or byte-compatible implementation of LÖVE. The portable API is
`space`; `canvas` provides concise drawing relations, while `js::context`
remains an explicit Canvas2D escape hatch.

The OS and standalone `space.bat` runner execute these callbacks through the
compiled SWI-WASM runtime. Drawing calls cross `cosmos_host_op/3`; applications
do not need Lua.

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

Version 2 update callbacks receive elapsed step time:

```text
update(dt,state,state2)
```

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
setBackgroundColor(color | r,g,b[,a])
getBackgroundColor()
setColor(color | r,g,b[,a])
getColor()
clear([color | r,g,b[,a]])

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

Colors accept a CSS color string, a component list, normalized components in
`0..1`, or byte components in `0..255`. If any component is greater than one,
the entire component set is treated as byte values.

Text coordinates use a top-left convention. The backend offsets the native
Canvas baseline by the active font size.

## Relation-friendly canvas helpers

The global `canvas` receiver and `sp.canvas` refer to the native canvas host.
Space installs these convenience methods on it:

```text
canvas.rect(x,y,width,height,color)
canvas.rect_border(x,y,width,height,color[,lineWidth])
canvas.rectBorder(x,y,width,height,color[,lineWidth])
canvas.line(x1,y1,x2,y2,color[,lineWidth])
canvas.circle(x,y,radius,color)
canvas.circle_border(x,y,radius,color[,lineWidth])
canvas.circleBorder(x,y,radius,color[,lineWidth])
canvas.print(text,x,y)
canvas.label(text,x,y,color)
```

The helpers temporarily apply their color and line width, draw, and restore the
previous graphics state. They are convenient inside recursive relations:

```cosmos
rel draw_cell(x,y,color)
    canvas.rect((x-1)*32,(y-1)*32,30,30,color)
```

`js::canvasLegacy` exposes only this helper object when native canvas fields
are not wanted.

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

## Direct Canvas2D access

Advanced, browser-specific applications can obtain native handles:

```cosmos
native_canvas=js::canvas
context=js::context
context.fillStyle='#7cf4cb'
context.fillRect(10,10,80,40)
```

Available host roots are:

```text
js::space
js::canvas
js::canvasLegacy
js::context
js::graphics
js::keyboard
js::mouse
js::timer
```

Direct Canvas2D access is intentionally non-portable. Prefer `sp.graphics` for
applications intended to run on another future Space backend.

## Host ABI

Compiled host access uses opaque handles and four operations:

```text
root([domain,name])             -> handle
get([handle,key])               -> value or handle
set([handle,key,value])         -> true
method([handle,key,arguments])  -> value or handle
```

SWI-WASM implements `cosmos_host_op/3` by forwarding these operations to the
active Space Canvas host. `sp.start` and `sp.startCanvas` are intercepted by
the Prolog adapter so callback closures and application state remain Prolog
terms rather than being converted into JavaScript objects.

## Current provisional limits

- Audio, shaders, canvases-as-render-targets, particles, and sprite batches are
  not implemented.
- `printf` aligns one Canvas text run but does not perform full LÖVE-compatible
  word wrapping.
- Font measurement functions live on a JavaScript font handle and are not yet
  wrapped as relation-friendly Cosmos calls.
- Image loading needs an explicit application-level preload convention.
- Canvas rendering effects are imperative and cannot be reversed by Prolog
  backtracking.
