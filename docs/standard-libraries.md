# Standard libraries

Load a standard library with `require('name', alias)`.  Library exports are
tables, so their relations are called through the chosen alias: `alias.name(...)`.

## `logic`

Logical and term-inspection operations.  `logic.type(value, kind)` classifies a
value as `Number`, `String`, `List`, `Table`, `Functor`, or `Any` (an unbound
value).  The library also provides `instantiated`, `size`, `get`, `apply`,
`applyOnce`, `applyCatch`, `listOf`, `forall`, `range`, `toString`, `throw`,
and `functor`.

## `os`

Effectful process and environment operations are intentionally separate from
`logic`:

- `os.exec(command)` runs a host shell command.
- `os.halt()` and `os.exit()` stop the process.
- `os.load(file)` asks the Prolog host to load a file.
- `os.searchPath(path)` obtains the Cosmos library search path.

## Other bundled libraries

`io` supplies console input/output; `list`, `string`, `table`, `set`, and
`data` supply collection helpers; `math` supplies numeric functions and
ranges; `mutable`, `object`, `events`, `space`, `debug`, and `utils` provide
their corresponding runtime facilities.  The complete maintained module API
is in the [user guide](guide.md#supported-library-modules).

Third-party libraries belong in `userlibs/` and are loaded with the same
`require` form.
