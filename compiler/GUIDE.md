# Using the current Cosmos compiler

This guide describes the self-hosted compiler in `compiler/src` as it works
today. It compiles Cosmos (`.co`) to SWI-Prolog, uses the checked-in Prolog seed
to rebuild itself, and has no Lua dependency.

The historical `cosmos-0.824` tree was checked while preparing this guide. Its
`docs/compiler-v2.md` remains useful design history, but this file is the guide
for the active compiler. Differences from 0.824 are called out where they affect
source compatibility.

## Requirements and commands

Install Node.js and SWI-Prolog. From the repository root, compile a file with
the full CLI:

```powershell
cosmos.bat -c hello.co
```

This creates `hello.pl` and `hello.cif`. The `.cif` file is the compile-time
interface used by other Cosmos modules; keep it beside the generated `.pl`.

Compile and immediately run:

```powershell
cosmos.bat -l hello.co
```

Run an already generated module:

```powershell
cosmos.bat -r hello.pl
```

The small `cs.cmd` launcher accepts the direct compiler form:

```powershell
cs.cmd input.co output.pl module_name
```

The equivalent platform command is:

```powershell
swipl -q -s compiler/platform/cli.pl -- input.co output.pl module_name
```

The module name is optional. If omitted, it is derived from the output name.

## First program

Cosmos is relational. `=` is unification: it constrains two values to be the
same, and may bind an unbound variable.

```cosmos
rel add(x,y,result)
    result=x+y

add(2,3,total)
export(total)
```

Running this program prints `5.0`. Indentation defines blocks. `//` starts a
line comment. Names beginning with a lowercase letter are ordinary Cosmos
variables and relation names; constructors and declared types conventionally
begin with an uppercase letter.

`export(value)` determines the generated module's result. Export a table when
you want to expose a module API:

```cosmos
rel double(x,result)
    result=x*2

export({double=double,title='Arithmetic'})
```

## Values and expressions

Current source forms include:

```cosmos
text='hello'
number=12.5
items=[1,2,3]
pair=['head'|'tail']
record={name='Ada',score=10}
name=record.name
first=items[0]
updated=record.score:11
```

List indexing is zero-based. `record.field:value` creates a functionally
updated value; it does not change `record`. Numeric operators include `+`, `-`,
`*`, `/`, and `%`. Comparisons include `=`, `!=`, `<`, `<=`, `>`, and `>=`.
String and list addition are supported where the runtime defines them.

Goals can have alternatives:

```cosmos
rel digit(x)
    x=1 or x=2 or x=3
```

`true` succeeds and `false` fails. `unsafeNot(goal)` succeeds when `goal`
cannot be proven, but bindings made inside it do not escape. It is negation as
failure, not general constructive negation.

## Relations, modes, and types

Parameters may declare a mode and type:

```cosmos
rel increment(In Number input,Out Number result)
    result=input+1

increment(4,next)
```

- `In` expects a ground value on entry.
- `Out` expects a fresh variable and a nonvariable result on success. The result
  need not be deeply ground.
- `InOut` describes a position that may be constrained in either direction.

The built-in annotation names are `Any`, `Number`, `Integer`, `Real`,
`String`, `Functor`, `Relation`, `List`, `Table`, and `Host`. The checker
propagates known straight-line types and modes and rejects known mismatches.
Dynamic values still receive runtime checks.

Multiple mode signatures can share one relation:

```cosmos
Relation In Out copy
Relation Out In copy
rel copy(a,b)
    a=b
```

Determinism suffixes describe the permitted number of successful answers:

| Suffix | Successful answers |
| --- | --- |
| `det` | Exactly one |
| `semidet` | Zero or one |
| `multi` | One or more |
| `nondet` | Any number |

For example, use `det` to request exactly one result:

```cosmos
rel exactlyOne(Out Number value) det
    value=1
```

Determinism checking is opt-in. Use `cosmos.bat -d ...` or set
`nb_setval(cosmos_debug_contracts,true)` in a Prolog embedding. A debug check
may request a second answer and therefore may repeat effects; use it as a
development contract, not as a static proof.

The callable categories are:

- `rel`: preserves logical failure and alternative answers.
- `bool`: selects the first answer and otherwise fails.
- `fun` / `function`: selects the first answer; failure raises a callable error.
  Its `if` commits to the successful condition.
- `void`: has the same success requirement as a function and denotes an
  effect-oriented callable.

These are operational rules. Acceptance does not prove that every function is
statically deterministic or successful.

They work as declarations and anonymous callable values:

```cosmos
positive=bool(x)
    x>0

choose=function(x,result)
    if(positive(x))
        result='positive'
    else
        result='other'
```

Relations are first-class and capture lexical values:

```cosmos
rel makeAdder(offset,callback)
    callback=rel(x,result)
        result=x+offset

makeAdder(3,addThree)
addThree(4,7)
```

## Functors and nominal types

Functors define nominal data constructors. The first item after the name is
the parent type; remaining items are field types.

```cosmos
functor(Expr,Functor)
functor(Var,Expr String)
functor(Binary,Expr String Expr Expr)

tree=Binary('+',Var('x'),Var('y'))
tree is Expr
```

Constructor arity, declared subtype chains, and statically known field types
are checked. A subtype value may be used where its parent is expected, but a
parent value is not accepted where a child type is required.

`functor(Name,Functor)` is retained as an open-arity bootstrap-compatible
declaration. For checked data, declare a more specific parent and explicit field
types. If a checked constructor receives an unbound field, the compiler installs
a delayed runtime guard; binding that field later to the wrong type raises a
contract error.

Use a leading colon when the constructor is intentionally undeclared and should
be emitted as an arbitrary Prolog functor:

```cosmos
value=:F(1,2)
empty=:Empty
```

The result has the general static type `Functor`. Arguments are checked and
evaluated normally, but there is deliberately no declared parent, field-type, or
arity validation. Without the colon, `F(1,2)` remains an ordinary declared
constructor or callable expression.

## Protocols

Protocols describe structural fields and methods:

```cosmos
protocol(Counter,{
    Number value
    rel read(Out Number result) det
})

Counter counter={
    value=3
    rel read(Out Number result) det
        result=3
}

counter.read(value)
counter is Counter
```

The typed declaration validates visible fields and method signatures. Protocol
values are views: calls go through the checked interface. Values that cannot be
proven statically are checked at runtime.

A method body in a protocol is a behavioral postcondition, not its
implementation. It runs after a successful implementation call when debug
contracts are enabled. Known literal implementations are checked for conflicting
input/output modes and incompatible types; dynamic implementations retain
runtime validation. Merely testing a raw value with `is` does not retroactively
turn every other reference to it into a checked protocol view.

## Classes and constructors

Declare a class with a table of relations. A class constructor is named `new`
and receives `this`, then `result`, then the user arguments:

```cosmos
class(Point,{
    rel new(this,result,x,y)
        result=object.create(this,{x=x,y=y})

    rel moveX(this,amount,result)
        result=this.x+amount

    rel read(this,result)
        result=[this.x,this.y]
})

Point point=new Point(10,20)
point.read(position)
point.moveX(5,movedX)
export([position,movedX])
```

`object.create(this, fields)` constructs the instance with the class/prototype
identity carried by `this`. `new Point(10,20)` passes the two user arguments;
the compiler supplies `this` and the result slot. Calling `point.read(...)`
supplies the receiver automatically.

`new` does not install prototype lookup by itself: the constructor controls the
created value. Use `object.create(this,fields)` when separate instances should
inherit the class methods, or deliberately return `this` when the prototype
object itself is the intended singleton.

A plain table can also act as a constructor. Its `new` relation receives only
the result followed by user arguments:

```cosmos
Factory={
    rel new(result,name)
        result={name=name}
}

item=new Factory('sample')
```

Known constructors are checked for callability and arity. Imported and dynamic
constructor-member checking remains less complete than local class checking.

## Explicit state and loops

Ordinary `=` is logical unification, not assignment. Use `!` for sequential
state updates:

```cosmos
count=0
!count+=1
!count=count+1
```

The compiler implements `!` by threading fresh logical versions. A declaration
such as `rel advance(!x)` expands to before/after positions; call it as
`advance(!x)` to update the current version, or with its ordinary expanded
arguments when both versions are needed. Earlier bindings retain their values,
and backtracking may explore alternative logical states.

Sequential compound updates support `+=`, `-=`, `*=`, `/=`, and `%=`. State
transitions are rejected in conditions, negation, and other scopes where a new
version could escape ambiguously.

Field updates are also supported:

```cosmos
point={x=1,y=2}
!point.x+=3
```

Current iterative loops use `!` updates:

```cosmos
total=0
for(item in [2,3,4])
    !total+=item

i=0
while(i<3)
    !i+=1
```

The temporal spelling uses `init` and `next`. Updates in one iteration are
simultaneous, and `next value` reads the pending next value:

```cosmos
init x=1
init y=2
init i=0
while(i<1)
    next x=y
    next y=x
    next i+=1
```

`for(init i=0; i<3; next i+=1)` and `for(item in list)` are supported. Every
next assignment on a possible path must be unambiguous. A branch that omits an
update carries the current value forward. Duplicate assignments on the same
path are compile errors, including two different field updates of one owner;
construct one replacement table when several fields must change together.

Use `init` explicitly to provide a temporal loop's initial value. A plain
unification before a temporal loop constrains the final value instead. Within an
iteration, plain `x` is the current value and `next x` is the shared pending
value, even when read before its assignment. Temporal assignments currently use
`=` and `+=`; do not mix `!` state transitions into the same temporal loop body.

## Meta declarations

The active compiler deliberately does not support source-defined `meta`
declarations. They were present in the archived `compiler-0.8.43` experiment,
but its broad word-operator recognition increased compiler load and could
misparse ordinary program identifiers. A `meta ...` declaration is therefore a
parse error in the current compiler. This removal does not affect ordinary
relations, callable values, or explicit and temporal state syntax.

## Conditionals, iteration, assertions, and errors

```cosmos
if(score>10)
    label='high'
else
    label='low'

some(item in [1,2,3])
    item>1

assert(score>=0,'score must not be negative')
```

`some` is relational iteration: it succeeds for matching elements and fails if
none match. `assert(goal,message)` throws when its goal fails. `choose(...)`
may be used to group alternatives.

## Modules and imports

Compile dependencies before consumers, into the same directory:

```cosmos
// arithmetic.co
rel add(In Number x,In Number y,Out Number result)
    result=x+y
export({add=add,pi=3.14159})
```

```powershell
cosmos.bat -c arithmetic.co
```

Then import its exported table:

```cosmos
require('arithmetic',math)
math.add(2,3,total)
export(total)
```

The compiler reads `arithmetic.cif` beside the importing source to check known
exported fields, callbacks, types, and modes. At runtime, `arithmetic.pl` must
be discoverable beside the generated consumer or on the Cosmos library path.
Dependency compilation is not recursive: build dependencies first.

This is stronger than 0.824: the earlier compiler performed runtime module
loading but did not provide the current exported-table and nested-member type
checks. Current interfaces still do not recursively build dependencies or fully
describe imported constructors and protocol members.

## REPL and one-shot queries

Open the interpreter:

```powershell
cosmos.bat -i
```

Select variables with `:vars x,y`, then enter a one-line goal. Use `:help` for
commands and `:quit` to exit.

Run a one-shot fragment:

```powershell
cosmos.bat -q "x=2`ny=x+1" --vars x,y
```

Run a query in a source file's lexical scope:

```powershell
cosmos.bat -l program.co -q "main(result)" --vars result
```

## Command-line applications

Define `main(args)` and compile with `--main`:

```cosmos
rel main(args)
    print(args[1])
```

```powershell
cosmos.bat -c app.co --main
swipl -q -s app.pl -- Ada
```

`args[0]` is the executable and `args[1]` is the first user argument. On
Windows, `--exe` asks SWI-Prolog to save a standalone executable and implies
`--main`:

```powershell
cosmos.bat -c app.co --exe
app.exe Ada
```

## Prolog and JavaScript hosts

`pl::name(...)` calls a Prolog predicate exposed by the runtime. This is an
advanced escape hatch and ties the program to the SWI host.

JavaScript roots use `js::`:

```cosmos
space=js::space
canvas=js::canvas
context=canvas.getContext('2d')
context.fillStyle='#64d7b0'
context.fillRect(10,10,80,40)
```

These expressions use the generic host bridge. They work only in an embedding,
such as Space, that provides the named roots and `cosmos_host_op/3`; standalone
SWI does not invent browser objects. Graphical programs use the same compiler,
Space lifecycle, bridge, and Canvas API regardless of their filename.

## Current limits

The current compiler is usable, but these areas remain incomplete:

- whole-program mode/type inference through every recursive and uncertain
  control-flow path;
- static success and determinism proofs beyond explicit/debug contracts;
- automatic recursive dependency compilation and complete imported constructor
  and protocol-member interfaces;
- general constructive negation and general `break`, `continue`, and `return`;
- asynchronous/reactive scheduling beyond the implemented iterative temporal
  loops;
- asynchronous host calls and a universal live-host value codec.

Use annotations at module boundaries, compile imported modules first, and keep
runtime contract checks enabled while developing code that crosses dynamic or
host boundaries.

## Rebuild and verify the compiler

```powershell
node compiler/build.mjs
node --test tests/compiler/compiler.test.mjs
```

The build compiles all six Cosmos compiler modules through successive Prolog
stages and verifies that the final two generations are byte-identical.

At the time of this update, the compiler suite passes 23 tests, the self-build
stabilizes, and all 10 broader events/Canvas/runtime checks pass, including the
complete shipped Space pipeline.

## Relationship to Cosmos 0.824

The active compiler preserves the 0.824 self-hosted core: relational calls,
callable categories, typed modes, explicit and temporal state, protocols,
classes, constructors, nominal functors, query compilation, and SWI execution.
The active tree additionally has:

- arbitrary undeclared functors through `:Name(...)` and `:Name`;
- `.cif` interfaces with exported and nested table-member checking;
- one-shot queries in a file's lexical scope;
- generic `--main` and `--exe` application entry points;
- generated SWI-WASM compiler assets and synchronous Canvas host dispatch.

Compared with the archived `compiler-0.8.43`, the active compiler source is
about 8.5 percent smaller and its generated Prolog is about 8.3 percent smaller
because MetaDecl parsing and expansion are absent. The independent checker,
interface, CLI, REPL, host, and arbitrary-functor improvements are retained.

Do not use the old `cosmos-0.824` compiler, runtime, or generated artifacts as
dependencies of new programs. Use it only as a historical behavior reference;
compile current source with the root `cosmos.bat` and active `compiler/` tree.
The archived directory is not a self-contained runnable distribution: its CLI
still resolves `compiler/platform/../../src/swi.pl`, but that `src` runtime is
not present beneath `cosmos-0.824`. A direct 0.824 CLI smoke test therefore
fails before compilation. This does not affect the active root compiler.
