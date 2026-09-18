# Cosmos language compiler map

This map covers the active compiler under `compiler/`. Cosmos source in
`src/*.co` implements the language rules. The Prolog files in `platform/`
provide file I/O, term construction, runtime operations, and command-line
entry points.

## Compilation path

```text
.co source text
  │
  ├─ platform/driver.pl reads adjacent .cif dependency interfaces
  │
  ▼
src/parser.co          tokens + indentation → Program(surface AST)
  ▼
src/normalize.co       callable modes; ! state versions; temporal loops
  ▼
src/check.co           imported schemas; types, modes, calls; .cif metadata
  ▼
src/resolve.co         top-level bindings; relation signatures and captures
  ▼
src/emit_prolog.co     Prolog clauses and module entry predicate
  │
  ├─ generated .pl      executable SWI-Prolog source
  └─ generated .cif     compile-time interface for consumers
```

`src/compiler.co` coordinates these stages through `compile_unit/4`. It parses
the source, normalizes the AST, adds imported functor declarations, checks the
program, resolves names, and emits Prolog. The platform adapter writes the
resulting `prolog` and `interface` fields to `.pl` and `.cif` files.

## Source modules

| File | Main responsibility | Useful entry points |
| --- | --- | --- |
| `src/parser.co` | Lexes strings, numbers, comments, delimiters, and indentation; parses declarations, goals, and expressions into functor AST nodes with `Loc(line,column)` positions. | `parse/2`, `lex/2` |
| `src/normalize.co` | Expands standalone mode signatures and lowers explicit `!` updates and `init`/`next` loops to fresh logical variables and helper calls. | `normalize/2` |
| `src/check.co` | Builds nominal functor, protocol, class, and constructor schemas; checks known types, modes, arities, members, and calls; computes import/export metadata. | `analyze/4`, `interface/5`, `imports/2`, `imported_functors/2` |
| `src/resolve.co` | Partitions relation declarations from top-level goals, collects variables, merges relation signatures, and computes transitive captures. | `analyze/2`, `variables/2`, `scope_variables/2` |
| `src/emit_prolog.co` | Lowers expressions, goals, control flow, calls, closures, contracts, and captures into Prolog terms, then serializes clauses. | `generate/4` |
| `src/compiler.co` | Exposes the compiler API and orders the stages. | `compile/3`, `compile_unit/4`, `imports/2`, `compile_query/4` |

The parser uses functors such as `RelationDecl`, `UnifyGoal`, `CallExpr`, and
`VarExpr` for semantic AST structure. Checker schemas, inferred call
signatures, version maps, and the returned compilation unit use tables.

## Outputs and interfaces

- A generated `.pl` contains prefixed relation predicates, helper predicates,
  and an entry predicate named for the requested module. The entry evaluates
  top-level goals and returns the final `export` value, or `[]` when absent.
- A `.cif` is a data-only Prolog term with `format`, `module`, `schemas`,
  `exports`, and `fields`. An importing source reads a dependency's `.cif`
  from its own directory. Dependencies must be compiled first.
- `compile_query/4` accepts a goal fragment plus an ordered list of variable
  names. It returns a table containing the module, entry, variables, source,
  and generated Prolog.

## Platform and execution

| File | Role |
| --- | --- |
| `platform/driver.pl` | Loads the generated compiler, reads source and interfaces, writes `.pl`/`.cif`, reports errors, and adds optional application entry code. |
| `platform/terms.pl` | Constructs and inspects Prolog terms, allocates compiler cells, and serializes generated clauses. |
| `platform/runtime.pl` | Supplies operations used by compiled programs: calls, objects, types, contracts, tracing, loops, and the generic host bridge. |
| `platform/cli.pl`, `build.pl`, `run.pl`, `repl.pl` | Thin command-line compile, bootstrap, run, and interactive entry points. |
| `platform/session.pl` | Compiles revision-scoped embedded programs and disposes their generated predicates. |
| `platform/codec.pl`, `swi-result.mjs` | Tag and decode results so success, failure, errors, strings, lists, and variables remain distinct. |

The generated compiler is self-hosted. `seed/*.pl` is the checked-in bootstrap
stage. `build.mjs` compiles all six `src/*.co` modules through `stage1`,
`stage2`, and `generated`, then verifies that the final two Prolog generations
are byte-identical. `generated/*.pl` and `generated/*.cif` are build artifacts;
edit `src/*.co` for language changes. `generated/manifest.json` records input
hashes.

## Where to change a language behavior

| Change | Start here | Also inspect |
| --- | --- | --- |
| Token, comment, or indentation rule | `src/parser.co` lexer | Parser tests |
| New syntax or AST shape | `src/parser.co` | `normalize.co`, `check.co`, `resolve.co`, `emit_prolog.co` |
| State update or loop semantics | `src/normalize.co` | `emit_prolog.co`, `platform/runtime.pl` |
| Type, mode, or imported-member diagnostic | `src/check.co` | `.cif` generation and loading in `platform/driver.pl` |
| Lexical captures or relation signatures | `src/resolve.co` | `emit_prolog.co` environment and relation emission |
| Generated call or control-flow behavior | `src/emit_prolog.co` | `platform/runtime.pl` |
| Runtime value or host operation | `platform/runtime.pl` | `platform/codec.pl` when values cross an embedding boundary |

Production behavior must be independent of the source file's name or contents.
Every graphical `.co` program uses this same compiler and generic host bridge.

## Current review hotspots

These are reproducible issues identified during review; the map does not imply
they are fixed:

1. `resolve.co` propagates a callee's capture names into callers without
   distinguishing a caller parameter of the same name. `emit_prolog.co` can
   consequently emit one Prolog variable for both positions. A global `x=1`,
   a `q` that reads global `x`, and a `p(x, result)` that calls `q` fail at
   `p(2, y)`.
2. `parser.co` skips indentation processing when a line starts with `/*`.
   A relation body line like `    /* comment */ x=1` fails with
   `expected INDENT` when it is the first body line.

## Verification

From the repository root:

```powershell
node compiler/build.mjs
node --test tests/compiler/compiler.test.mjs
node --test tests/compiler/guide.test.mjs
```

The compiler suite exercises native compilation, static checks, interfaces,
state and temporal loops, runtime contracts, queries, executable entry points,
and the generated compiler in SWI-WASM.
