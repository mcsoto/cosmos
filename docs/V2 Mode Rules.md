- lowercase class/protocol
- fun step1(s, !i, info, info2, z)
->
step1(s, In i0, Out i1, info, info2, z)

e.g.
rel p(!x)
	!x=x+1
print(p(1))//2

## V2 Mode Rules

Modes describe how arguments are expected to be instantiated when a relation is called.

Modes are separate from ordinary types and separate from determinism.

### Parameter modes

```cosmos
rel p(In Number x, Out Number y)
```

Supported modes:

```text
In
    Argument must be sufficiently instantiated before the call.

Out
    Argument is expected to be produced by the call.

InOut
    Argument may already contain information and may be further
    instantiated by the call.
```

Internally, modes may be represented compactly as:

```text
In      +
Out     -
InOut   ?
```

Example:

```cosmos
rel concat(In A, In B, Out C)
```

may be represented internally as:

```text
concat(+A,+B,-C)
```

The source language should normally use `In`, `Out`, and `InOut`.

---

### Modes precede types

The mode appears before the parameter type:

```cosmos
rel p(In Any x)
rel get(In Table t, In Any key, Out Any value)
rel has(In List l, InOut Any x)
```

If no mode is declared, the parameter has no explicit mode constraint.

Mode inference may still determine an effective mode for checking or optimization.

---

### Multiple modes

A relation may support more than one valid calling mode.

For example:

```text
concat:
    (In, In, Out)
    (In, Out, In)
    (Out, In, In)
    (Out, Out, In)
```

These are distinct mode signatures of the same relation.

The compiler should select a compatible mode from the known instantiation state at the call site.

If no declared mode is compatible, report a mode error.

---

### Determinism

Determinism describes the possible number of successful solutions for a particular mode.

```text
det
    Exactly one solution.

semidet
    Zero or one solution.

multi
    One or more solutions.

nondet
    Zero or more solutions.
```

Determinism belongs to a mode signature rather than to the relation name alone.

Example:

```text
has(In list, In value)   semidet
has(In list, Out value)  multi
```

The same relation can therefore have different determinism depending on how it is called.

---

### Standard mode examples

# Note: this is user documentation/illustratory. Do not hard-implement modes for those relations.

#### `size`

```text
size(In collection, Out size)  det
size(In collection, In size)   semidet
```

Surface syntax:

```cosmos
n = #list
```

may lower to:

```text
size(list,n)
```

---

#### `concat`

```text
concat(In A, In B, Out C)    det
concat(In A, Out B, In C)    semidet
concat(Out A, In B, In C)    semidet
concat(Out A, Out B, In C)   multi
```

The first mode represents ordinary concatenation.

The last mode represents relational decomposition.

---

#### `get`

For:

```cosmos
x = table[key]
```

with logical form:

```text
get(table,key,x)
```

useful modes include:

```text
get(In collection, In key, Out value)    semidet
get(In collection, Out key, Out value)   multi
get(In collection, Out key, In value)    multi
```

If invalid indexing is defined to throw rather than fail, the first mode may instead be treated as `det` with an exceptional case.

---

#### `has`

```cosmos
x in l
```

lowers to:

```text
has(l,x)
```

Useful modes:

```text
has(In collection, In value)   semidet
has(In collection, Out value)  multi
```

A compact declaration may therefore use:

```cosmos
rel has(In Collection l, InOut Any x)
```

while retaining the more precise mode signatures internally.

---

### Mode checking

Mode checking tracks whether variables are sufficiently instantiated at each program point.

Example:

```cosmos
rel p(Out Number x)
    x=2
```

After the call:

```cosmos
p(x)
```

`x` is considered produced/instantiated according to the selected mode.

An `In` parameter cannot be supplied with a value that is insufficiently instantiated for that mode.

---

### `function`

`function` introduces a stronger callable contract than an ordinary `rel`.

A function is expected to execute deterministically and not accidentally expose logical failure or multiple solutions.

Example:

```cosmos
function wait()
    print("> ") and io.read(x)

    if(x="halt")
        c::halt()
```

Here:

```text
print(...)      det
io.read(...)    det
x="halt"        semidet
```

The equality is valid as the condition of `if`, because failure is expected and consumed by the conditional.

This is potentially invalid:

```cosmos
function wait()
    print("> ")
    io.read(x)
    x="halt"
    c::halt()
```

because `x="halt"` can fail and therefore makes the function itself potentially fail.

---

### Failure-consuming contexts

A `semidet` or `nondet` goal may appear where its failure is intentionally handled.

Examples include:

```cosmos
if(p(x))
    ...

not p(x)

once p(x)

p(x) or q(x)
```

A function-mode checker should distinguish these contexts from an unguarded potentially failing goal.

The rule is not specific to equality.

It applies to any goal whose determinism permits failure.

---

### Void operations

`Void` is not an argument mode.

It describes an operation whose result is used only for its effect.

For example:

```text
print(In Any) : det, void
```

A void operation may still be deterministic or nondeterministic independently of being void.

Thus:

```text
Mode          In / Out / InOut
Determinism   det / semidet / multi / nondet
Result use    value-producing / void
```

are separate properties.

---

## V2 protocol / Interface Rules

A protocol describes structural requirements on a value and may optionally define behavioral constraints.

Example:

```cosmos
protocol(Moving,{
    Number x

    rel p(x)
        x>2
})
```

A protocol may contain:

- required fields;
- required relation/function members;
- type requirements;
- mode requirements;
- optional behavioral constraints.

---

### Structural members

A declaration without an implementation body is an ordinary interface requirement.

Example:

```cosmos
protocol(Moving,{
    Number x
    rel move(In Number dx, In Number dy)
})
```

A conforming value must provide:

```text
x
    compatible with Number

move
    callable with a compatible relation signature
```

No runtime behavior is specified beyond the signature.

---

### Behavioral relation constraints

A protocol relation with a body describes a constraint on the corresponding implementation.

Example:

```cosmos
protocol(Moving,{
    Number x

    rel p(x)
        x>2
})
```

means that a conforming object must provide a compatible `p`, and successful calls to that `p` must satisfy:

```text
x > 2
```

The body is therefore a contract/constraint, not the implementation of `p`.

---

### Runtime contract checking

Given:

```cosmos
ship.p(x)
```

and protocol constraint:

```cosmos
rel p(x)
    x>2
```

debug-mode execution may behave conceptually as:

```text
call ship.p(x)
then check x>2
```

If `ship.p(x)` succeeds but the protocol constraint fails, this is a protocol violation.

The protocol body should not be interpreted as relation equality such as:

```text
p(x) = ship.p(x)
```

Instead it constrains the successful behavior of the implementation.

---

### Static versus runtime checking

protocol conformance should be checked statically when enough information is available.

For example:

```cosmos
Moving ship = expression
```

requires the compiler to verify that `expression` conforms to `Moving` as far as statically possible.

If some requirement cannot be established statically, a runtime check may be retained.

Behavioral constraints may be checked in debug/runtime-contract mode even when the structural interface is statically known.

---

### `is`

```cosmos
ship is Moving
```

is a conformance predicate.

Its ordinary mode is:

```text
is(In value, In type/protocol) : semidet
```

It succeeds when the value conforms to the requested nominal type or protocol.

Example:

```cosmos
if(ship is Moving)
    ship.move(1,0)
```

If conformance is already proven statically, the compiler may simplify:

```cosmos
ship is Moving
```

to `true`.

Otherwise it emits the required runtime check.

---

### Nominal type checks

`is` may also check nominal types:

```cosmos
ship is Ship
```

For values introduced through:

```cosmos
ship = new Ship(1,2)
```

the compiler already knows:

```text
ship : Ship
```

and may eliminate the check.

Nominal type identity and protocol conformance are distinct:

```text
ship is Ship
    nominal/type identity or declared conformance

ship is Moving
    protocol/interface conformance
```

A value may satisfy a protocol without having that protocol as its nominal type.

---

### protocol compatibility

A value conforms structurally when every required member exists with a compatible signature.

For fields:

```text
Number x
```

the actual `x` must have a compatible type.

For relations:

```cosmos
rel p(In Number x, Out Number y)
```

the implementation must support a compatible mode and type signature.

Its determinism must also be compatible with the protocol promise.

For example, an implementation declared `nondet` should not satisfy a protocol member that promises `det`.

---

### Mode compatibility in protocols

Modes are part of a callable protocol member's interface.

Example:

```cosmos
protocol(Source,{
    rel read(In String path, Out String text)
})
```

An implementation must accept the required input/output use.

A relation that only supports:

```text
read(Out,In)
```

does not satisfy the interface.

An implementation may support additional modes beyond those required by the protocol.

---

### Determinism compatibility

protocol declarations may specify determinism.

Conceptually:

```text
rel lookup(In Key, Out Value) semidet
```

requires an implementation that does not produce more solutions than promised.

A useful compatibility ordering is:

```text
det      satisfies det, multi
semidet  satisfies semidet, nondet
multi    satisfies multi
nondet   satisfies nondet
```

In practice, exact or conservative compatibility checking is preferable initially.

A protocol promising `det` should never be implemented by a mode that may fail or return multiple solutions.

---

### protocol declarations versus implementations

Inside a normal table/object:

```cosmos
rel p(x)
    implementation
```

defines executable code.

Inside a protocol:

```cosmos
rel p(x)
```

declares only a required callable member.

Inside a protocol:

```cosmos
rel p(x)
    constraint
```

declares a callable member plus a behavioral contract.

The enclosing `protocol(...)` context determines the interpretation.

---

## V2 `new` / Object Rules

### `new`

```cosmos
ship = new Ship(1,2)
```

means:

```text
1. resolve Ship
2. require Ship.new
3. call Ship.new(ship,1,2)
4. bind/type-check ship as Ship
```

Conceptually:

```text
x = new T(args...)
→
T.new(x,args...)
type(x) = T
```

`new` does not implicitly invoke `object.create`.

`new` does not itself enable prototype inheritance.

If `T.new` does not exist, `new T(...)` is a compile-time error.

---

### Explicit object creation

Prototype-oriented programming remains opt-in through `object.create`.

Example:

```cosmos
Ship ship = object.create(Ship,{
    x=1
    y=2
})
```

This explicitly creates an object using `Ship` as its prototype/template while also requiring the resulting value to type-check as `Ship`.

The type annotation itself does not create the object.

---

### Typed binding

```cosmos
Ship ship = expression
```

means:

```text
evaluate expression
check expression against Ship
bind ship : Ship
```

This may be used independently of `new` or `object.create`.

---

### Separation

```text
new T(...)
    constructor call + T type information

T x = Expr
    static type requirement

x is T
    runtime-capable semidet conformance check

object.create(...)
    explicit prototype/object construction

protocol(...)
    structural and optional behavioral interface
```

Object/prototype semantics remain optional and are not implied merely by using types, protocols, or `new`.


## V2 Clarifications

### Callable categories

`rel`, `function`, and `void` are callable categories.

```text
rel
    Relational. May fail and/or produce multiple solutions.

function
    Non-relational/deterministic-style callable. Intended to behave as a single-result operation.

void
    Non-relational callable whose result is not logically consumed.
    Used primarily for host/internal/IO/side-effect operations.
```

Examples:

```cosmos
void read(...)
    ...

io.read=read
```

```cosmos
void halt()
    c::halt()
```

For mode checking, `void` is treated as effectively safe in a `function` body.

Thus:

```cosmos
function wait()
    print("> ")
    io.read(x)

    if(x="halt")
        os.halt()
```

is valid even though the underlying implementation of `io.read` or `os.halt` may terminate, throw, perform IO, or otherwise behave outside ordinary relational semantics.

`void` therefore means more than “returns no value.” It marks a callable as outside ordinary relational success/failure reasoning.

For current purposes:

```text
void ≈ det for function-mode analysis
```

although an implementation may technically be described as `semidet, void` or may terminate exceptionally.

The checker should not infer relational failure from such host/non-relational behavior.

---

## Modes

Modes remain properties of relation parameters:

```text
In
Out
InOut
```

They may be expressed using the existing type/declaration syntax rather than introducing a separate signature syntax.

For example:

```cosmos
rel move(In Number dx, In Number dy)
    true
```

describes both parameter types and modes.

Equivalent type/interface information may also be expressed separately:

```cosmos
Relation In In move
Relation Number Number move
```

The first declaration describes modes:

```text
move(In, In)
```

The second describes ordinary parameter types:

```text
move(Number, Number)
```

Together they describe:

```text
move(In Number, In Number)
```

This avoids requiring additional protocol-specific syntax.

---

## Determinism

Determinism is relevant primarily to relational callables:

```text
det
semidet
multi
nondet
```

Examples:

```text
concat(In, In, Out)   det
has(In, In)            semidet
has(In, Out)           multi
```

`function` and `void` participate differently in checking:

```text
rel
    ordinary relational determinism applies

function
    expected to behave as a non-failing/non-branching callable,
    except where failure is explicitly consumed

void
    treated as non-relational for function-flow checking
```

Thus a `void` operation is allowed directly inside a `function`:

```cosmos
function f()
    print("x")
    io.read(x)
```

without requiring those operations to be modeled as ordinary logical goals.

---

## Function failure checking

Potentially failing relational goals must still be handled deliberately.

Invalid or suspicious:

```cosmos
function wait()
    io.read(x)
    x="halt"
    print("halted")
```

because:

```text
x="halt"
```

is an ordinary relational/semidet constraint.

Valid:

```cosmos
function wait()
    io.read(x)

    if(x="halt")
        os.halt()
```

The `if` consumes the possible failure of the equality.

The `void` calls do not participate in this relational failure analysis.

---

## protocols

A protocol uses the existing declaration/type machinery.

Example:

```cosmos
protocol(Moving,{
    Number x

    Relation In In move
    Relation Number Number move
})
```

This requires:

```text
x : Number

move:
    mode  (In, In)
    type  (Number, Number)
```

No new protocol-only signature syntax is required.

The equivalent inline relation form is:

```cosmos
protocol(Moving,{
    Number x

    rel move(In Number dx, In Number dy)
        true
})
```

A relation declaration in a protocol may therefore combine:

- relation existence;
- parameter types;
- parameter modes;
- optional behavioral constraint.

---

## protocol relation bodies

Inside a protocol:

```cosmos
rel move(In Number dx, In Number dy)
    true
```

the body is a constraint/specification, not the implementation supplied to the object.

A body of:

```cosmos
true
```

means there is no additional behavioral restriction beyond the signature.

Example:

```cosmos
protocol(Moving,{
    Number x

    rel p(Number x)
        x>2
})
```

requires a compatible `p` and specifies that successful uses of `p(x)` must satisfy:

```text
x>2
```

In debug/runtime-contract mode, the implementation may be checked against that constraint.

---

## Interface-only declarations

The existing declaration form may be used without executable implementation:

```cosmos
protocol(Moving,{
    Number x
    Relation In In move
    Relation Number Number move
})
```

This is a normal structural interface.

Using:

```cosmos
rel move(In Number dx, In Number dy)
    true
```

is another way to express essentially the same structural requirement while using ordinary relation syntax.

A nontrivial body adds a behavioral constraint.

---

## `is`

```cosmos
ship is Moving
```

checks conformance with a nominal type or protocol.

Typical mode:

```text
is(In value, In type) : semidet
```

When statically known, the compiler may prove and eliminate the runtime check.

When not statically known, it may emit structural/runtime protocol checking.

---

## `new`

```cosmos
ship = new Ship(1,2)
```

means:

```text
1. require/find Ship.new
2. call Ship.new(ship,1,2)
3. type-check/bind ship as Ship
```

It does not invoke `object.create`.

It does not install prototype behavior.

`new` is therefore constructor + type information, not object creation.

---

## `object.create`

`object.create` is independent from the type system.

Its essential behavior is only to create an object with prototype information.

For example:

```cosmos
ship = object.create(Ship,{x=1,y=2})
```

may create an object conceptually containing:

```text
own fields:
    x=1
    y=2

prototype:
    Ship
```

But the prototype does not have to be a nominal type.

For example:

```cosmos
base={x=1}

obj=object.create(base,{y=2})
```

is valid even if both `base` and `obj` are typed only as `Table`.

Thus:

```text
object.create
    prototype mechanism

type/protocol
    static/runtime conformance mechanism
```

They may be used together, but neither depends on the other.

---

## Example combinations

Plain typed constructor:

```cosmos
ship = new Ship(1,2)
```

Prototype object with no special type:

```cosmos
base={x=1}
obj=object.create(base,{y=2})
```

Explicitly typed prototype object:

```cosmos
Ship ship = object.create(Ship,{x=1,y=2})
```

Later protocol check:

```cosmos
if(ship is Moving)
    ship.move(1,0)
```

These are separate mechanisms that can be composed as needed.

---

## `class` prototype declarations

```cosmos
class(Env,{
    rel new(this,result)
        result=this
})
```

`class(Name,Table)` declares `Name` as both a nominal type name and its
immutable prototype table. It does not create an instance and does not call
`object.create`; its value lowering is simply `Name = Table`. Lowercase
`class(...)` is accepted as a legacy spelling, while `class(...)` is canonical.

A method selected through the class value or a value statically typed with the
class receives the receiver as its first hidden argument:

```cosmos
Env.new(Env value,)      // call_cl(Env.new,[Env,value])
next=value.inc(1)        // call_cl(value.inc,[value,1,next])
```

For a declared class, `new Env(args...)` resolves `Env.new` and calls it with
`[Env,result,args...]`. A plain constructor table remains receiverless and is
called with `[result,args...]`. Prototype installation on an instance remains
explicit runtime behavior supplied by the constructor or `object.create`.
