
# Built-in

`Host` is an opaque reference owned by a JavaScript embedding. `js::name` gets
one property from the JavaScript root and produces a `Host`; a nested object
obtained through `Host.key` remains opaque. Properties and calls use the generic
host operations and are not treated as Cosmos tables or closures.

functor(T, Functor) //any tuple
functor(Tuple, Functor)
functor(Pair, Functor Any Any)

functor(Some, Option Any)
functor(None, Option Null)

Built-in functors.

# Files

The compiler writes a short interface header at the start of every generated
`.pl` file. These are Prolog comments generated from analysis of the Cosmos
source; the user does not type them in the `.co` file.

`file1.pl`:

```prolog
% Any
% Pair Functor; T Functor
%
```

`file2.pl`:

```prolog
% Table {compile.Relation Any;interpreter.Relation;query.Relation Any;run_pl.Relation Any}
% Var Functor; F Functor; Functor Any Any
%
```

The three header lines have fixed meanings:

1. Type inferred for `X` in `export(X)`. A composite `Table` type lists its
   known fields and their types. If analysis cannot refine the exported value,
   the public type is `Any`.
2. Semicolon-separated functor declarations needed to interpret the exported
   type. An empty line is written as `%`.
3. Mode/determinism declarations. Reserved; currently written as `%`.

They must be the first three physical lines, before `style_check` or any other
Prolog directive, so tools can read an interface without parsing Prolog.

Types are erased from executable Prolog. The header is a compile-time module
interface and has no runtime effect.

## Multiple-file analysis

For `require("module", value)`, when the module name is a string literal, the
compiler resolves it using the same search order as runtime `crequire/3` and
binds `value` to the required file's exported type. A dynamic module expression
cannot be resolved statically and gives the result type `Any`.
Implicit default-library receivers use those libraries' interfaces in the same
way as an explicit literal `require`.

Compilation uses a per-build module graph and interface cache:

1. Parse the root and collect literal `require` edges.
2. Resolve each edge to one canonical module identity. Different spellings of
   the same path must not create different nominal types.
3. Prefer analysis of an available `.co` source. If only a generated `.pl` is
   available, read its three-line interface header without loading or running
   the Prolog file.
4. Collect declarations and initial interfaces for the whole graph before
   checking bodies. This permits cyclic imports.
5. Refine exported and member types to a fixed point, then check calls and
   unifications using the final interfaces.
6. Generate each `.pl` interface header and executable body.

The analyzer needs an internal `Unknown` state distinct from the source type
`Any`: `Unknown` may be refined during graph analysis, while explicit or final
`Any` accepts every type. This prevents the first traversal of an import cycle
from permanently losing type information.

If neither source nor a valid generated interface is available, ordinary
compilation reports the unresolved module. A permissive/tooling mode may use
`Any` and issue a warning instead. A malformed header is an interface error,
not executable Prolog to be inspected heuristically.

Functor types imported from another file have a canonical qualified identity
internally, such as `(module-id, Var)`, even if diagnostics print the short name
`Var`. Structural table types may pass between files directly. Reading a
functor declaration from an interface makes its type understandable; it does
not automatically introduce its constructor name into the importing source.

The compiler API therefore needs a compilation context containing the root file,
search paths, module cache, diagnostics, and strict/permissive interface mode.
`compile(source, module_name)` may remain as the single-file convenience API;
file-aware compilation supplies the context and source filename explicitly.

# Modes

reserved 'In/Out/InOut' keywords.

#rel

General relation mode.

#bool
bool p(...)

Unclear. reserved keyworld.

#function

A function is understood to be deterministic and not fail. Some checks are made.

fun p(...)
	if( cond )
		query
	once q

A nondeterministic relation A placed inside a function, must
- Be a function.
- Be inside if (converted to ´choose´).
Throw error for nondeterministic calls, unless it fits criteria.

- 'not A' can only be in a function if placed inside if.

#temporal keywords

init A
next A
A until B
eventually A
always A

reserved operators. 'init/next' have meaning in iterators. No semantics for the others.

#Category

| Category              | Examples                                       |
| --------------------- | ---------------------------------------------- |
| Term/value expression | `x`, `1`, `x+2`, `a[i]`, `{x=1}`               |
| Goal                  | `p(x)`, `x=2`, `x<3`, `not p(x)`, `once q(x)`  |
| Goal combinator       | `and`, `or`, `not`, `once`, temporal operators |
| Declaration           | `rel`, type/protocol declarations              |
| Statement sugar       | `while`, `for`, possibly assignment-like forms |




update=table.mixin
class(Env,{
	
	rel new(env, o)
		o = env + {x=1}
		
	rel inc(x,o)
		o=this.x:2
})

#
!x+=1
next x+=1?
+=
?:



| Goal | Complement |
| --- | --- |
| `true` | `false` |
| `false` | `true` |
| `A = B` | `dif(A, B)` |
| `A != B` | `A = B` |
| `A < B` | `A >= B` |
| `A <= B` | `A > B` |
| `A > B` | `A <= B` |
| `A >= B` | `A < B` |
