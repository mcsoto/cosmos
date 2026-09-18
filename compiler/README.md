# Cosmos compiler

Implementation: [`src/*.co`](src/). Build with `node compiler/build.mjs`.
The build starts from the checked-in Prolog seed and has no Lua dependency.

See the [user guide, architecture map, and support limits](../docs/compiler-bootstrap.md).
The [v2 functor and result guide](../docs/compiler-v2-types.md) covers the changes
requested in `compiler/issues.txt` and their current limits.

Run checks with `node --test tests/compiler/compiler.test.mjs` from the repository root.

The [self-hosted v2 guide](../docs/compiler-v2.md) documents callable contracts,
explicit state, loops, protocols, constructors, and remaining implementation gaps.

## Query fragments

The exported compiler API includes `compile_query(source, variables, module,
query)`. It compiles a Cosmos goal fragment by appending an ordered
`export([...])` for `variables`. `query` is a table with `module`, `entry`,
`variables`, `source`, and `prolog`, so a caller can load the code and decode
the answer without relying on a separately reconstructed convention.

`variables` must be a list of identifier strings; its order is the answer
order. For example, selecting `["y", "x"]` makes the generated entry return
`[y, x]`.

## Command-line applications

Pass `--main` when compiling an application to add a generic command-line
entry point for `rel main(args)`. `args` is the conventional argv list: its
zero element is the executable and `args[1]` is the first user argument.

```
cosmos.bat -c app --main
cosmos.bat -c app --exe
```

`--exe` implies `--main`, writes `app.pl`, and uses SWI-Prolog's saved-state
utility to create `app.exe`. The executable invokes the generated `main/1`
relation; no source filename or program-specific behavior is involved.
