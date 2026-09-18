# V2 in the self-hosted compiler

This guide describes the compiler in `compiler/src/*.co`. See the
[build guide and compiler map](compiler-bootstrap.md) for installation and the
[typed functor and query value guide](compiler-v2-types.md) for schemas and codecs.
The legacy Lua compiler has a separate [v2 guide](guide-v2.md).

## Callables and contracts

```cosmos
rel increment(In Number x, Out Number y)
    y=x+1
increment(2,result)
export(result)
```

`In` requires a ground argument on entry. `Out` requires a fresh variable on
entry and a nonvariable result on success; it does not require a deeply ground
result. `InOut` permits either binding direction. Inline types are checked at
runtime, with delayed guards for unbound values. Named callbacks and typed
anonymous `rel` closures retain their contracts. A contract violation raises
an exception rather than silently becoming logical failure.

The compiler also checks known calls before execution. It propagates types and
definite bindings through straight-line code, including simple callback aliases.
It rejects known argument-type mismatches, occupied `Out` positions, and a
definitely fresh `Out` parameter passed into an `In` position. Unknown parameter
types are rejected at declaration time. Facts from uncertain branches, dynamic
calls, and imported code still require runtime validation.

Standalone signatures describe alternative calling modes without duplicating
the implementation:

```cosmos
Relation In Out copy
Relation Out In copy
rel copy(a,b) a=b
copy(7,forward)
copy(backward,9)
export([forward,backward])
```

Each word after `Relation` describes one parameter; its arity must match the
named declaration. A mode word preserves the parameter's inline type, if any.
The runtime selects a compatible contract on entry, including callback calls.
Standalone signatures currently apply to top-level named declarations with
named parameters, not arbitrary imported values or parameter patterns.

| Category | Implemented behavior |
| --- | --- |
| `rel` | Preserves failure and alternative solutions. |
| `bool` | Selects the first solution, or fails. |
| `fun`, `function` | Selects the first solution; failure raises an exception. Its `if` commits to the successful condition. |
| `void` | Uses the same success requirement as a function, for effect-oriented calls. |

These are operational rules, not static proofs that a function always succeeds.
Anonymous closures and table methods support all five category keywords and
optional determinism suffixes. Each callable uses its own category; an anonymous
`rel` inside a function retains relational behavior. For example,
`test=bool(x) x>0` creates a boolean callback, while
`exact=rel(Out Number x) det x=1` creates a checked deterministic relation.
Nested named callable declarations can recurse through their local binding.
An independent internal name on a closure expression is not yet a self binding.

Named declarations accept a determinism suffix:

```cosmos
rel one(Out Number x) det
    x=1
```

`det` means exactly one answer, `semidet` zero or one, `multi` at least one,
and `nondet` any number. Checking is opt-in: use `cosmos.bat -d -q SOURCE`,
or set `nb_setval(cosmos_debug_contracts,true)` in the Prolog embedding.
The checks observe the callable's operational answers; function/bool selection
has already limited their alternatives. A `det`/`semidet` check may execute a
second solution, including its effects. These checks are intended for debugging,
not a replacement for static determinism analysis.

`assert(Goal)` and `assert(Goal,'message')` require one successful solution and
raise an assertion exception otherwise. Successful bindings remain available.

## Explicit state and iteration

```cosmos
rel advance(!x)
    !x+=1
count=0
while(count<3)
    advance(!count)
export(count)
```

The compiler lowers `!` to fresh logical variables. A `!` parameter or call
argument expands into an input/output pair. `!x=expression` replaces the current
version; `!x+=expression` and the corresponding `-=`, `*=`, `/=`, `%=` forms
derive a new version. `!object.field+=1` creates an updated object value.
Ordinary `=` remains unification. Updates are threaded left to right, and
branches join the changed versions, carrying an unchanged value when needed.

`while(condition)`, `for(initial;condition;advance)`, and `for(item in collection)`
carry explicitly updated state between iterations. Loop-local variables are
fresh on each invocation. Conditions select their first success; relation bodies
can retain alternatives. Collection iteration uses the existing runtime iterator
interface for lists, strings, tables, and providers.

`some(item in collection) Goal` enumerates matching items, preserving duplicate
solutions. It is existential search, not a state accumulation loop. State
updates in `some`, conditions, and negation are rejected. A successful program
without an export returns `[]`; this is distinct from failure.

## Temporal loops: `init` and `next`

```cosmos
init x=1
init y=2
init i=0
while(i<1)
    next x=y
    next y=x
    x=1
    y=2
    next i+=1
export([x,y]) // [2,1]
```

`init x=value` supplies the input for the following loop. Inside that loop,
plain `x` denotes the current iteration's value. `next x=value` assigns the
following iteration's value without changing current reads. After the loop,
`x` denotes its final value. Updates therefore happen simultaneously at the
iteration boundary; the example swaps the two values.

Use `init` explicitly. A plain assignment before a temporal loop constrains
the final value rather than supplying an initial value. Without `init`, the
temporal input is a fresh logical variable. Loop conditions still use the
runtime's first-success selection; this is not a general relational search over
all possible iteration counts.

Temporal state works with `while`, `for(init i=0;i<3;next i+=1)`, and collection
`for` loops. Nested loops have their own next-state slots. An initialized value
is preserved when there are no iterations or it is never updated. A branch
that omits an update carries the current value to the next iteration.

`next x+=n` means `next x=x+n`. `next object.field=value` and
`next object.field+=n` construct an updated table for the following iteration.
Only `=` and `+=` are accepted temporal assignment operators. Multiple updates
to the same variable on one possible path are rejected, including updates to
different fields of the same owner. Build one replacement table when several
fields must change together. Mutually exclusive branches may each assign it.

In an expression, `next x` refers to the shared next-state variable. It may be
unified with a local variable before the assignment occurs; operations that
require a concrete value must wait until it is bound. Field reads such as
`value=next object.field` work after that next object has been assigned.

`next` assignments are rejected outside loop bodies, in conditions or negation,
and inside an escaping callback. `some` does not carry temporal updates. Use
`init`/`next` throughout a temporal loop body; mixing it with `!` in that same
body is rejected. This implements iteration-based temporal state, not an
asynchronous scheduler or reactive temporal-logic engine.

## Protocols

```cosmos
protocol(Positive,{
    Number size
    rel accept(In Number x)
        x>2
})
Positive value={size=3,rel accept(x) true}
value.accept(3)
export(value.size)
```

A protocol specifies fields and method signatures. Put field declarations on
separate lines or separate them with commas. Known table literals are checked
at compilation; a typed binding also validates structure and creates a checked
view. Calls through that view enforce parameter contracts, including calls
through a method retrieved as a value. A protocol method body is a behavioral
contract, not an implementation: it runs after successful calls only when debug
contracts are enabled. Output parameters are checked after the implementation.

`value is Positive` checks conformance. Raw object references do not acquire
checked dispatch merely because another reference has a protocol annotation.
Complete static compatibility checks between implementation modes and protocol
signatures are not implemented. Known literal implementations are checked for
conflicting input/output modes and incompatible parameter types; dynamic
implementations retain runtime validation. Protocol method declarations accept
callable categories and determinism suffixes. Debug checks apply determinism
to the implementation's answers, separately from the behavioral postcondition.

## Constructors and explicit prototypes

```cosmos
class(Point,{
    rel new(this,result,x)
        result=object.create(this,{x=x})
    rel read(this,result)
        result=this.x
})
Point point=new Point(7)
point.read(result)
point is Point
export(result)
```

Class construction calls `new(this,result,...arguments)` and gives the result
nominal identity. Class methods receive the object as their implicit receiver.
`object.create(prototype,fields)` explicitly installs prototype lookup; `new`
does not install it automatically. Inherited methods bind to the receiving
object. Functional field updates preserve the object's wrappers and identity.

A plain table can also be a constructor:

```cosmos
Factory={rel new(result,x) result={x=x}}
product=new Factory(2)
product is Factory
export(product.x)
```

Its constructor receives the result before the user arguments, with no implicit
class receiver. The compiler checks visible constructors and known arities.
Imported interfaces currently carry schemas and exported callable signatures,
but imported or dynamically resolved constructor-member interfaces are not yet
checked completely.
The default `object` facade currently provides `create`; it does not expose the
entire legacy object library.

## Intended behavior still unsupported

- Whole-program mode/type inference and static success/determinism proofs.
  Current flow analysis is conservative and does not infer complete contracts
  from unannotated bodies or uncertain control-flow joins.
- Complete imported member interfaces and automatic recursive compilation of
  dependencies. Existing `.cif` interfaces already carry schemas and exported
  callable signatures when the platform driver supplies them.
- Asynchronous/reactive temporal scheduling beyond iteration-based `init`/`next`.
- General constructive negation, and general loop `break`/`continue`/`return`.
- Complete protocol compatibility proofs across dynamic and imported values.
- Dynamic overload resolution, complete arbitrary local relation-name shadowing,
  and named recursive anonymous closures.
- Asynchronous host calls, live host-value codecs, and editor integration.

The intended direction is to diagnose these contracts statically wherever
possible and preserve explicit checks at dynamic boundaries. Current runtime
checks and a reproducible self-build do not establish full v2 compatibility.

## Checking across files

Compiling a module writes a data-only `.cif` interface beside its generated
`.pl` file. Compile a dependency first, placing its interface beside the source
that imports it with `require('dependency',api)`. The native driver loads that
interface without executing the dependency. In-process callers can instead
supply interface tables to `compile_unit`.

Interfaces include exported callable signatures and data-field types, including
nested tables and tables exported through a local variable. For example,
`export({title='text',count=3})` lets an importing file reject a numeric operation
on `api.title`. Known noncallable fields and missing exported members also produce
compile errors. Older interfaces without field metadata retain dynamic checking.
Dependency compilation is still explicit; automatic rebuilding of missing or
stale dependencies is not implemented.

Undeclared direct calls produce a located compile error. In `test3.co`,
`p(x,y)` reports `Cannot find relation p` at line 3. After removing that call,
`x=''` followed by `x=1-2` reports the conflicting string and numeric types at
line 2. These are ordinary source checks and behave identically after renaming
or copying the file.
