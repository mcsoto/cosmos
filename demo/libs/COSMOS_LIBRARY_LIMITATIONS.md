Standard libs.


# Cosmos UI and Pathfinder limits

`ui.co` and `pathfinder.co` are compiled by the self-hosted compiler and can be imported with
`require('ui', ui)` and `require('pathfinder', pathfinder)`.

## UI

The Cosmos UI library creates declarative command tables (`panel`, `rect`,
`label`, and `button`).  It deliberately does not draw pixels itself: the
current Cosmos-to-Prolog runtime has no general callback bridge from a
generated Prolog program into a browser or Love2D canvas.  A Space host must
consume those command tables and call its drawing API.

## Pathfinder

`pathfinder.co` currently supplies a deterministic, four-way Manhattan route
and route-point lookup.  It is useful for simple movement and confirms that
the public API compiles through the native compiler.

An obstacle-aware A* implementation with walkability callbacks,
diagonal/corner rules, weighted terrain, and a binary heap has not yet been
ported because the present
standard Cosmos library surface lacks a practical mutable priority queue and
the generated Prolog runtime cannot call an arbitrary host-side walkability
function on each candidate cell.
