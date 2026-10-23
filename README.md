# Cosmos

# Installation

- Install Swi-Prolog (10.0.2+) with xpce.
- `make exe`

# The Cosmos compiler (bootstrap)

A bootstrap Cosmos compiler. Uses SWI-PL.

# Introduction

A relational programming language.

Building
==

```powershell
$ make exe

$ cosmos.exe -l test1
```

==

Examples:

>cosmos -l test
>cosmos -q x=1 --vars x
| [1.0]

Testing the graphics library (space) in xpce. 
>cosmos -l test3 --xpce

# Example programs

`misc/dungeon.co` is a turn-based tile crawler built on Space. Enemies hunt by
scent: one breadth-first flow field is rebuilt from the player's tile every
turn, and every enemy inside its notice radius descends that gradient.

>cosmos -l misc/dungeon.co --xpce

`DUNGEON_TESTING.md` covers the level, the pathfinding and how the game is
verified. `docs/ENGINE_ISSUES.md` collects the engine and compiler issues that
came up while writing it: `sp.quit()` leaving an orphaned process, `libs/io.co`
not being able to open a file, `l[i]` being a table read rather than a list
read, `if` running its condition twice, and the `choose` / `cut` operators the
lowering table mentions.

# Profiling

`--profile` runs a program under the sampling profiler and writes a report:
where the time went, which predicates were called how often, and how much of it
belongs to the Cosmos program, to the XPCE backend underneath it, and to
SWI-Prolog.

>cosmos -r test4 --xpce --profile
>cosmos -l misc/dungeon.co --xpce --profile --profile-out dungeon.profile.txt

The report is refreshed every 300 frames, so a Space program - which runs until
its window closes - can be inspected while it runs. `docs/PROFILING.md` explains
the report and has the measurements for `test4` and `misc/dungeon.co`; the
reports are in `docs/profiles/`.

# build

Added the native build target to Makefile

```powershell
make exe
```

== V2 ==

v1 is a functional-logic core. It includes supports for tables; json-like structures.

v2 aims to support multiple styles of programming, such as (pseudo-) imperative through ! mutable states, and temporal IR 'init'.

-- 0.82X --

• Implemented more v2 support:

  - Static type/mode checks, including callback aliases.
  - Standalone alternative Relation signatures.
  - Anonymous/table callable categories.
  - Protocol determinism and known mode/type compatibility checks.

  All 14 test groups pass, including WASM. The compiler rebuilds identically without Lua.

  Updated the guide (docs/compiler-v2.md). Whole-program inference and imported interfaces remain unfinished.

#

Cosmos is compiled by the self-hosted compiler in [`compiler/src`](compiler/src)
and runs on SWI-Prolog. The active compiler has no Lua dependency.

See the [current compiler user guide](compiler/GUIDE.md) for language syntax,
classes, protocols, modules, applications, the REPL, and host integration.

Compile a program on Windows:

```powershell
cosmos -c input.co output.pl module_name
```

Or invoke the platform directly:

```powershell
swipl -q -s compiler/platform/cli.pl -- input.co output.pl module_name
```

Rebuild and test:

```powershell
node compiler/build.mjs
node --test tests/compiler/compiler.test.mjs
```

The retired Lua compiler and its historical documentation are isolated under
[`legacy/lua-compiler`](legacy/lua-compiler). Nothing in the active compiler,
launcher, tests, or installer requires that folder.
