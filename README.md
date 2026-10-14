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
