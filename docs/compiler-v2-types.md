# Typed functors and query values

Implemented from [`compiler/issues.txt`](../compiler/issues.txt).

## Functor subtypes

```cosmos
functor(Exp,Functor)
functor(Op,Functor)
functor(Binary,Op String Exp Exp)
functor(Unary,Op String Exp)
functor(Var,Exp String)
functor(Call,Exp Exp List)

export(Binary('+',Var('x'),Call(Var('f'),[])))
```

The first name after the comma is the parent type; remaining names describe
the fields. `Binary` is an `Op`, and `Op` is a `Functor`. `Var` and `Call` are
`Exp` values. Both parent and field types may be declared later in the same file.
The compiler rejects undeclared types, cyclic parents, conflicting declarations,
wrong constructor arities and known field mismatches such as `Var(42)`.
Typed relation parameters provide known types when used as constructor fields.

For compatibility with the compiler's bootstrap sources, `functor(Name,Functor)`
retains its legacy open-arity behavior. It also explicitly introduces a subtype.
Use a parent subtype and explicit fields for checked constructors. A declaration
such as `functor(Empty,Exp)` describes a zero-field constructor.

Semantic AST nodes remain functors with their existing source locations.
`check.co` stores declaration facts in a schema table keyed by name; each entry
has `parent`, `fields`, `open`, and `location`. These are extensible compiler
metadata, not extra arguments added to every semantic AST constructor.

Unknown fields in checked constructors receive delayed runtime type guards.
For example, `node=Var(x)` can succeed with an unbound `x`, but later binding
`x=7` raises a type exception. Inline typed callable parameters also retain
runtime checks through callback values. See the [v2 guide](compiler-v2.md).

**Not yet supported:** whole-program type inference, imported type interfaces,
abstract-only type declarations, and complete static type checks at arbitrary
relation calls. An unbound value is not proof of its eventual type, and residual
type constraints are not serialized by the query codec.

## SWI results and strings

`compiler/platform/swi-result.mjs` exports `swiResult(answer)` to normalize SWI
WASM answers. Exceptions produce `status: 'error'`, logical failure produces
`status: 'failure'`, and successful answers—including empty lists—produce
`status: 'success'`. Check status before reading bindings. This adapter is
provided for embeddings; existing editor pages are not changed.

Native session callers can use `compiler_session_result(Prefix, Result)` for
one answer with the same three statuses. Its successful `value` is explicitly
tagged by `codec.pl`: strings, numbers, lists, atoms, functors, tables and shared
variables have distinct representations. Large integers and rationals preserve
their exact values. `decodeValue` converts the tagged result for JavaScript,
using `Map` for tables and shared tagged objects for repeated variables.

`"AB"`, `[65,66]` and `[]` remain different values. There is no heuristic that
converts numeric lists to strings. Cyclic values report an error rather than
recursing indefinitely. Source-text arguments alone retain an explicit legacy
conversion from code-point lists; invalid text arguments raise type errors.

The codec reports residual variables but does not serialize their constraints,
live closures for remote invocation, or host-object capabilities. Session result
retrieval currently selects the first solution; it is not a streaming query API.
