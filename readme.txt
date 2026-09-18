=== Cosmos ==

# The Cosmos compiler (bootstrap)

A Cosmos compiler in Cosmos. Uses SWI-PL.

Good for prototyping and can be used for scripting.

==

Examples:

>cosmos.bat -l test

>cosmos.exe -l test1

# build

Added the native build target to Makefile

```powershell
make exe
```

==

# Space/Canvas

Test case for the compiler.

UI programs that can be written with html/SWI-WASM. It's provided with an editor.

See canvas/.

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
