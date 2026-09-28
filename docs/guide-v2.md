# V2+ features: intended behavior and current support

For the new compiler written in Cosmos, use the separate
[self-hosted compiler guide and support list](compiler-bootstrap.md) and
[implemented v2 behavior](compiler-v2.md).
The feature ratings below describe the self-hosted SWI-Prolog compiler.

This companion to the [full guide](guide.md) and [introductory guide](guide-simple.md) covers the newer features those guides do not explain. It describes the intended language behavior, including contracts that the compiler does not yet enforce completely.

Support notes refer to the active `compiler/` tree and the `compiler/swi.pl` runtime. Browser and packaged copies use the same generated SWI compiler. **Supported** means the described basic behavior is implemented; **partial** means important parts of the contract remain incomplete; **unsupported** means the described behavior is a design target. Accepting a declaration does not necessarily mean its full contract is checked.

## Support at a glance

| Feature | Current support |
| --- | --- |
| `In`, `Out`, `InOut` parameters and alternative mode signatures | **Partial:** syntax and conservative checks for named calls work; complete mode inference and checking through arbitrary callable values are not implemented. |
| Determinism per calling mode | **Unsupported as a general declaration/checking system.** The categories below describe the intended contract, not new accepted signature syntax. |
| Function failure checking | **Partial:** catches several unhandled relational goals and calls; does not prove exactly one successful result on every path. |
| `void` callable declarations | **Supported** as an effect-oriented category accepted in functions; not a proof that an operation returns normally. |
| Structural protocols | **Partial:** known table literals are checked for fields and callable signatures; dynamic checks only test member presence. |
| Behavioral protocol contracts | **Unsupported enforcement:** bodies are parsed, but their conditions are not installed as runtime checks or proved statically. |
| `value is Type` / `value is Protocol` | **Partial:** statically proven cases and a limited runtime check work; arbitrary nominal identity and full dynamic protocol validation are missing. |
| `new T(...)` and `class(T,{...})` | **Partial:** constructor calls, type tracking, and receiver insertion work; complete nominal/result validation is not enforced. |
| `!` state threading, `+=`, and branch joins | **Supported** for sequential state and branches; unsupported inside temporal loops. |
| `assert Goal`, `assert(Goal, Message)` | **Supported:** keep the first success or throw an error. |
| `next x += value` and `next object.field = value` | **Supported** additions to the existing temporal-loop syntax. |
| `unsafeNot` and `soft_if` | **Supported** explicit control forms. |
| `js::` host access | **Supported in SWI-WASM:** the JavaScript embedding supplies `cosmos_host_op/3`. |
| Cross-file type interfaces | **Unsupported** in the root compiler: intended interface headers, import-graph analysis, and cross-module contract checking remain design work. |

## Argument modes

A type describes what an argument can contain. A mode describes what information the caller supplies and what the call produces. Write the mode before the type:

```cosmos
rel double(In Number x, Out Number y)
    y=x*2

double(3,result)
export(result) // 6
```

| Mode | Intended use |
| --- | --- |
| `In` | Supply an argument sufficiently instantiated for the operation. |
| `Out` | Supply an output position; the operation produces its value on every successful return. |
| `InOut` | Supply an existing value or a value to be refined/produced, as permitted by the operation's contract. |

Modes do not turn logical variables into mutable cells. `InOut` can add information to a value; it does not overwrite a previous binding. Use `!` state threading when an operation needs distinct before/after values.

Types are optional: `In x` means `In Any x`. A parameter in an ordinary `rel` without a mode has no explicit mode restriction. For clear public interfaces, declare modes explicitly.

An operation can support several calling directions:

```cosmos
Relation In Out copy
Relation Out In copy
rel copy(a,b) a=b

copy(7,forward)
copy(backward,9)
export([forward,backward]) // [7,9]
```

These declarations describe one relation with alternative contracts. The compiler selects a compatible signature using the information available at the call. An unbound argument to an `In`-only operation is a mode error; an already produced argument does not fit an `Out`-only position. Declare another mode when testing an existing result is a valid use.

**Current limits:** the checker tracks a conservative approximation of instantiation. It checks explicit outputs of ordinary relations, but does not establish complete contracts for every closure, library call, or imported value. `fun`/`function` currently infer `In` for unmarked parameters before the last parameter and `InOut` for the last, when there are at least two parameters; use explicit modes to avoid relying on this shorthand.

## Functions, determinism, and effects

The original guides introduce `function` (also spelled `fun`). V2 strengthens its intended contract: a function completes with one successful result rather than accidentally exposing logical failure or alternatives. Exceptions and operations that terminate the process are separate from logical failure.

Determinism is a property of a particular calling mode:

| Contract | Number of successful solutions |
| --- | --- |
| `det` | Exactly one |
| `semidet` | Zero or one |
| `multi` | One or more |
| `nondet` | Zero or more |

For example, finding an element may enumerate many results, while testing membership of a given element may return only success or failure. Neither its name nor its argument types alone establish determinism. These labels are explanatory notation here; a general source syntax for declaring them is not implemented.

Handle an expected failure in a conditional:

```cosmos
function classify(In Number x, Out String label)
    if(x=2)
        label="two"
    else
        label="other"

classify(3,label)
export(label) // "other"
```

Inside a function, `if` chooses the first successful condition result and executes that branch. An unguarded test such as `x=2` can make the function fail, so it should be handled by a branch or an assertion. A plain binding into a fresh output is different from testing two existing values.

`once Goal` limits alternatives but still fails if `Goal` has no solution. It therefore cannot, by itself, establish the intended exactly-one-result function contract. Similarly, a disjunction needs a successful fallback if the whole function must succeed.

Use `void` for an operation whose purpose is an effect:

```cosmos
void announce(In String message)
    print(message)

function start()
    announce("ready")

start()
```

`void` is a callable category, not an argument mode or a promise to return no explicit output arguments. It identifies host, I/O, or other effect-oriented operations that function analysis treats as safe to call. Such an operation may still throw or terminate execution.

**Current limits:** the compiler rejects several obvious unhandled failures in named functions, but its checks are not a complete determinism analysis. Acceptance of `once`, disjunctions, indirect calls, or a `void` declaration does not prove that the surrounding operation always succeeds exactly once.

## Protocols and conformance

A protocol describes the members a value must provide. A value can satisfy it without belonging to any particular class:

```cosmos
protocol(Moving,{
    Number x
    Relation In In move
    Relation Number Number move
})

Moving ship={
    x=3
    rel move(In Number dx, In Number dy)
        true
}

ship is Moving
export(ship.x) // 3
```

Here `move` is a plain table member taking two explicit arguments. The separate `Relation` declarations describe its modes and types. They do not provide its implementation. An implementation may support additional calling modes, but must support every mode promised by the protocol.

The intended check includes field types, callable arities, parameter types, supported modes, and any declared determinism promise. Extra fields are allowed. Use a typed binding such as `Moving ship=...` when conformance is required; use `ship is Moving` when conformance is a question that may succeed or fail.

### Behavioral contracts

A relation body inside a protocol describes a condition on successful calls to the member:

```cosmos
protocol(PositiveSource,{
    rel read(Out Number value)
        value>0
})
```

This says that the implementation supplies `read` and that each successful result must be positive. It does not supply a default implementation. A body of `true` adds no behavioral restriction beyond the signature.

The intended implementation checks what it can statically and can check behavioral contracts after successful calls in a runtime-contract/debug mode. A violation is a contract error, not an ordinary failed search result that silently removes the offending answer.

**Unsupported:** the current compiler accepts these bodies but does not enforce their behavior. There is no implemented runtime-contract mode to enable. For now, put an explicit assertion inside the implementation when the check is needed.

### `is`: type identity versus structural conformance

`value is Number` asks about a built-in type; `value is Ship` asks about a nominal type; `value is Moving` asks about a protocol. `is` is a test, not a conversion or a constructor. A matching set of fields can establish protocol conformance without giving the value the nominal identity `Ship`.

When the compiler has already proved conformance, it can omit the test. Otherwise the intended behavior is to check it at runtime. Pass an available value to this test; it is not intended to enumerate or construct all values of a type.

**Current limits:** static checking covers known table literals and some tracked types. Dynamic protocol tests check that named members exist, but do not validate their types, callability, modes, or behavioral contracts. Runtime nominal checks for arbitrary user-defined types are not implemented; the built-in runtime cases are `Any`, `Number`, `String`, `List`, `Table`, and `Null`. Do not use a successful dynamic protocol test as proof that an arbitrary value satisfies the full interface yet.

## Constructors and classes

`new T(arguments...)` resolves `T.new`, calls the constructor, and gives the result the intended nominal type `T`. A plain constructor table receives the result first:

```cosmos
Ship={
    rel new(result,x,y)
        result={x=x,y=y}
}

ship=new Ship(1,2)
ship is Ship
export([ship.x,ship.y]) // [1,2]
```

The constructor controls what is created. `new` does not automatically install a prototype or invoke `object.create`. A missing constructor is an error; the intended checker also validates its arguments and result contract.

`class(Name, Table)` declares a nominal type name together with its prototype table. Selecting a method through that class or a value statically typed as the class supplies the receiver as the first argument:

```cosmos
class(Origin,{
    x=0
    rel new(this,result)
        result=this
    rel position(this,result)
        result=this.x
})

Origin origin=new Origin()
x=origin.position()
export(x) // 0
```

This small constructor deliberately returns the prototype itself. To create separate instances or attach inheritance, do that explicitly inside the constructor.

| Form | Constructor's explicit parameter order |
| --- | --- |
| Plain table `new T(a,b)` | `new(result,a,b)` |
| Declared class `new T(a,b)` | `new(this,result,a,b)`, with `T` supplied as `this` |

For an ordinary class method used as an expression, such as `x=origin.position()`, the receiver comes first and the expression result comes last. Plain table methods do not acquire a hidden receiver merely because their first parameter is named `this`.

**Current limits:** receiver insertion depends on the compiler knowing the class/type. The compiler tracks constructor result types but does not fully verify that a constructor establishes a valid nominal instance. Runtime nominal checks and class identity across module boundaries remain incomplete.

## State threading with `!`

Use `!` to express a sequence of new values while preserving logical single assignment:

```cosmos
rel bump(!x)
    !x += 1

x=1
bump(!x)
bump(!x)
export(x) // 3
```

`rel bump(!x)` has an input and an output for `x`. Calling `bump(!x)` supplies the current value and makes subsequent uses of `x` refer to the new value. `!x += 1` means `!x = x+1`; it creates a new logical value rather than changing the previous one.

The ordinary two-argument form remains available: the declaration above can be called as `bump(before,after)`. A relation with one expanded input/output pair can also be used as an expression, for example `after=bump(1)`.

An old binding retains its value:

```cosmos
x=1
before=x
!x += 2
export([before,x]) // [1,3]
```

Branches carry the appropriate resulting value onward. A branch without an update keeps the incoming value:

```cosmos
rel maybeBump(In flag,!x)
    choose(flag=1)
        !x += 2
    else
        true

x=1
maybeBump(0,!x)
export(x) // 1
```

State threading also supports a field of a table:

```cosmos
ship={x=1}
before=ship
!ship.x += 2
export([before.x,ship.x]) // [1,3]
```

This produces a new table and carries it forward as `ship`; the earlier table remains available through `before`. These forms implement logical state, so backtracking can explore alternative states. They do not undo external I/O or mutations performed by host operations.

**Current restrictions:** updates accept `=` and `+=`; do not assume a full family of compound operators such as `-=`. Conditional guards cannot perform a `!` transition, and an update's right-hand expression cannot contain another `!` transition. Inside temporal loops, use the existing `init`/`next` notation instead of `!`.

### Shorter temporal updates

The guides already explain `init`, `next`, `while`, and `for`. Two additional update forms are available:

```cosmos
init ship={x=0}
while(ship.x<3)
    next ship.x += 1
export(ship.x) // 3
```

`next x += n` means `next x=x+n`. `next ship.x=value` carries a new table forward as the next `ship`. These are next-iteration values; plain uses in the current iteration still refer to the current state.

## Assertions

An assertion requires one successful result. It retains bindings from the first success and throws if the goal has no solution:

```cosmos
function positive(In Number x, Out Number result)
    assert(x>0,"expected a positive number")
    result=x

positive(2,result)
export(result) // 2
```

`assert Goal` and `assert(Goal)` use the default message `"assert error"`. `assert(Goal,Message)` supplies the error value. Calling the example with `-1` raises `"expected a positive number"`; it does not quietly fail or return a Boolean.

Use assertions for required conditions and `if` for expected alternatives. Assertions can wrap relation calls in a function when taking the first success or raising an error is the intended behavior. If the asserted goal itself throws, the exception propagates.

## Additional explicit control forms

`unsafeNot Goal` is negation as failure: it succeeds if the attempted goal has no solution. It does not construct the complement of a relation. For instance, given `rel one(x) x=1`, `unsafeNot one(2)` succeeds, but `unsafeNot one(x)` fails because an answer exists; it does not mean `x!=1`. Use it for an intentional existence test with appropriately known inputs.

`soft_if(Condition) Body else Fallback` uses the fallback only when the condition has no solutions. If the condition succeeds, its alternatives remain available on backtracking. Even if the body later fails for every alternative, the fallback is not tried. This differs from `choose`, which commits to the first condition solution:

```cosmos
soft_if(x=1 or x=2)
    y=x
else
    y=0
export(y)
```

The relation has answers `1` and `2` on backtracking. A runner that requests only the first answer displays only `1`.

## Host values and module interfaces

### JavaScript embedding

`js::name` refers to a value supplied by the JavaScript embedding. Host values are opaque: property access and calls go through the host bridge, rather than Cosmos table/closure operations.

Example for a browser embedding that exposes `canvas`:

```cosmos
canvas=js::canvas
ctx=canvas.getContext('2d')
ctx.fillRect(10,10,80,40)
```

The compiler emits generic host operations. Native SWI requires an embedding to
provide `cosmos_host_op/3`; the shipped SWI-WASM browser bridge provides it for
JavaScript objects.

### Cross-file checking

The intended interface system carries exported types, table member signatures, and functor identities across literal imports such as `require("module",value)`. It also applies to implicit standard-library receivers. A dynamic module name yields `Any` when its interface cannot be established statically.

Generated `.pl` files are intended to start with a three-line comment header: exported type, relevant functor declarations, then reserved mode/determinism metadata. The compiler can use that interface when source is unavailable. Cyclic imports should be analyzed together so the final types do not depend on which file is visited first. Importing an interface does not automatically bring its functor constructor names into scope.

**Unsupported:** the root compiler currently neither writes these interface headers nor performs this module-graph analysis. Runtime module loading works, but it does not establish cross-file type safety. The header/interface design is described in [type-2.md](../type-2.md).

## Design references

The intended contracts come from [V2 Mode Rules](../V2%20Mode%20Rules.md), including its later clarifications, [V2-2](../v2-2.md), and [type-2](../type-2.md). Where the earlier notes and later clarifications differ, this guide follows the later clarification, particularly for `void`, protocol declarations, and class constructor receivers. The [lowering reference](../LOWERING_TABLE.md) describes the compiler/runtime forms.
