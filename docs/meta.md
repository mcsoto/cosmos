# Meta Syntax Templates

`meta` declares a compile-time syntax template. Parameters use syntax
categories rather than runtime types:

```cosmos
meta unless(Goal condition, Goal body):binary
    if not condition
        body

meta twice(Expr value):unary
    value + value
```

The body is implicitly quoted syntax. A parameter name appearing in the body
splices the corresponding invocation syntax; no explicit `quote` is required.

```cosmos
ready() unless start()
total=twice price
```

Function-style invocation is also supported:

```cosmos
unless(ready(), start())
total=twice(price)
```

## Declarations

```text
meta name(Category parameter, ...)
meta name(Category parameter):unary
meta name(Category left, Category right):binary
```

- Categories are `Goal` and `Expr`.
- No suffix enables function-style invocation only.
- `:unary` requires one parameter; `:binary` requires two.
- Unary operators bind more tightly than arithmetic operators.
- Binary operators bind less tightly than arithmetic and associate left.
- A binary operator and its left operand must be on the same source line.
- Declarations are file-scoped and may appear before or after use.
- Duplicate declarations, recursion, arity, fixity, and category mismatches are
  compile errors.

## Temporal Syntax

Templates can construct existing temporal syntax through compiler-only forms:

```cosmos
meta initialize(Goal assignment):unary
    temporal(init, assignment)

meta advance(Goal assignment):unary
    temporal(next, assignment)

meta repeatUntil(Goal body, Goal condition):binary
    temporal(until, condition, body)
```

`temporal(init, goal)` and `temporal(next, goal)` create the existing temporal
nodes. `temporal(until, condition, body)` creates `while(not condition)` before
normal temporal state lowering.

Expansion runs after parsing and before state normalization, resolution,
checking, and Prolog emission. Meta declarations do not exist at runtime.
