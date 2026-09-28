# Self-hosted Cosmos compiler

The compiler implementation lives in readable Cosmos source under
[`compiler/src/`](../compiler/src/). The checked-in Prolog seed compiles these
same sources into Prolog and rebuilds itself. SWI-Prolog is currently the
execution platform.

This is a working **self-hosted core compiler** with no secondary compiler
runtime or fallback.

## Build and use

From the repository root, with Node and SWI-Prolog installed:

```sh
node compiler/build.mjs
node --test tests/compiler/compiler.test.mjs
swipl -q -s compiler/platform/cli.pl -- example.co example.pl
swipl -q -s compiler/platform/run.pl -- example.pl
```

Set `SWIPL` to the executable path if it is not on PATH. The build and test
scripts also recognize the usual Windows installation. The direct commands
above require `swipl` on PATH, or its explicit executable path.

`cli.pl` accepts an optional third argument naming the generated module. Otherwise
the output filename supplies that name. `run.pl` accepts the same optional module
name. Compiler/runtime paths resolve relative to the installation, so these
commands also work from another current directory. Input/output paths remain
relative to the caller. A compile error returns a nonzero status and leaves an
existing output file untouched. A failed program also returns a nonzero status.

For example, save this as `example.co`:

```cosmos
base=7
rel addBase(x,y)
    y=x+base
callback=addBase
callback(5,result)
export(result)
```

Running the generated program prints `12.0`.

The checked-in seed is the trust root for reproducible self-builds. The build
produces three generations and checks byte-for-byte equality between the final
two. Checked-in generated
artifacts allow use without rebuilding. `compiler/generated/manifest.json`
records the source, seed, and final artifact hashes. It is a reproducibility
record, not proof of full language compatibility.

## Compiler map

```text
compiler/src/parser.co       source → tokens → located functor AST
compiler/src/normalize.co    explicit/temporal state, branch joins, loop lowering
compiler/src/resolve.co      names, clause signatures, transitive captures
compiler/src/check.co        nominal functor schemas and static field checks
compiler/src/emit_prolog.co   expression/control lowering, closures, Prolog terms
compiler/src/compiler.co     public compile(source, module, text) relation
compiler/seed/*.pl           initial runnable compiler
            ↓ generated Cosmos compiler
compiler/stage1 → stage2 → generated/*.pl
```

For an in-process Prolog caller, load `compiler/platform/driver.pl`, call
`compiler_load('compiler/generated')` once, then
`compiler_compile(SourceString, ModuleString, PrologString)`. This calls the
exported Cosmos `compile` relation; the driver does not interpret the source.

### Revision session API

`compiler/platform/session.pl` is the lifecycle adapter for an embedding.  It
is deliberately separate from the legacy `src/comp.pl` table: that file is an
older compiler/REPL implementation and is not the API for the self-hosted
compiler.

Use a fresh prefix such as `cosmos_s12_r4` for every source revision:

```prolog
:- ensure_loaded('compiler/platform/session.pl').
compiler_session_compile('compiler/generated', Source, cosmos_s12_r4, Text),
% write Text and consult it in the embedding
compiler_session_entry(cosmos_s12_r4, Output),
compiler_session_dispose(cosmos_s12_r4).
```

`compiler_session_compile_file/4` performs the corresponding read/compile/write
operation. `compiler_session_dispose/1` removes predicates bearing that exact
revision prefix. This explicit lifecycle is required because generated files
are not SWI modules yet; loading a revision into a temporary module would not
isolate their unqualified predicates.

The browser bundle exposes the matching shape through
`CosmosSwipl.createSession()`: `compile`, `compileQuery`, `load`, `run`,
`query`, `invoke`, and `dispose`. `compileQuery` and `query` accept a Cosmos
fragment plus an ordered list of result-variable names; they call the exported
`compile_query` relation and return one tagged answer. Enumeration,
cancellation and structured term arguments are follow-up work. Its `hostDispatch` capability is
intentionally `false`: compilation and execution work, but `js::` operations
cannot yet dereference Canvas or DOM objects.

`compiler/platform/terms.pl` constructs, inspects and serializes Prolog terms and
provides fresh variables and cells. `driver.pl` handles files and diagnostics;
`runtime.pl` provides field/call/host dispatch used by generated programs. These
files contain no replacement parser or hand-written Prolog compiler. The core
language runtime and precompiled libraries remain `compiler/swi.pl` and `libs/*.pl`.
Compile application dependencies separately into `.pl`; automatic recursive
compilation of imported `.co` files is not implemented.

## Supported behavior

| Feature | Current behavior |
| --- | --- |
| Relations | Named and recursive relations, multiple clauses, list/literal/functor parameter patterns. Clauses share one arity and capture convention. |
| Relation values | Exported/named callbacks and anonymous closures carry lexical captures, including dependencies through other named relations. Parameter bindings shadow relation names. |
| Values | Strings, numbers, lists with tails, functors, immutable tables, field/index reads and functional field updates using `object.field:value`. |
| Typed functors | Explicit parent subtypes and field types; declaration cycles, unknown types, arity and statically known field mismatches are rejected. Unknown constructor fields receive delayed runtime guards. |
| Callable contracts | Inline and standalone modes/types, conservative static call checks, named/anonymous/table categories, assertions, and opt-in debug determinism checks. |
| State and iteration | Explicit `!` state, temporal `init`/`next`, branch joins, `while`, C-style `for`, collection iteration, and existential `some`. |
| Protocols and objects | Structural protocol views, debug behavioral contracts, classes, constructors, explicit prototypes, and nominal `is` checks. |
| Expressions | Relational arithmetic `+ - * / %`, unary signs, sizes, nested calls and expressions inside data structures. |
| Goals | Unification, disequality, numeric comparison, conjunction, disjunction, membership, `true`, `false`, cut, `once`, `unsafeNot`. |
| Control | `choose`, `soft_if`; relational `if` with supported complementary conditions; `when` retains its alternative branch. |
| Modules | One exported value, namespaced generated predicates, explicit `require` of compiled libraries. Named call arities are checked. |
| Hosts | `pl::`/`c::` call Prolog predicates. `js::` preserves its namespace and emits host-root operations. Embeddings supply `cosmos_host_op/3`. |
| Platforms | Native SWI and the repository's shipped SWI WASM engine execute the same generated compiler. |

`space.canvas = js::canvas` lowers to host property assignment when `space` is
an opaque `host(...)` value supplied by an embedding. Ordinary Cosmos table
field equality remains unification. This dispatch currently checks the runtime
value, not a statically verified `Host` annotation. No JavaScript, Space, editor,
or LÖVE implementation is provided by the compiler itself.

## Intended behavior that is not supported yet

- Whole-program mode/type inference, static determinism proofs, and imported
  type interfaces. Runtime contracts implement only part of the intended guarantees.
- Asynchronous/reactive temporal scheduling and general loop `break`/`continue`/`return`.
- General constructive negation. `not` currently supports equality and numeric
  comparison complements; complex conditions can be rejected. `unsafeNot` is
  Prolog negation as failure, with its usual instantiation sensitivity.
- Full protocol mode compatibility proofs, dynamic overloading, named recursive anonymous closures, and full
  shadowing of relation names by arbitrary local assignments.
- Asynchronous host calls, capability policy and host type checking. Host
  operations are a runtime extension contract only; the result codec below
  handles compiler values, not live JavaScript host objects.
- Incremental compilation, module dependency builds, source maps, complete
  diagnostic locations and editor query/cancellation services.

Unsupported parsed goals/expressions report compilation errors. Syntax outside
the parser's grammar reports parse errors. This support list should expand only
with execution tests; rebuilding the compiler alone is not sufficient evidence.

See [V2 in the self-hosted compiler](compiler-v2.md) for executable examples,
precise runtime semantics, and the remaining intended behavior.
