# Cosmos lowering table

This is the normative compact reference for canonical semantic lowering. One
row describes one construct. Detailed documents may add preconditions, scope
analysis, diagnostics, and search-semantics explanation, but must not contradict
this table. A conflicting detailed example is corrected or this table is
deliberately revised; complexity elsewhere does not silently redefine a row.

| Source construct | Core meaning | SWI-Prolog/runtime lowering |
| --- | --- | --- |
| `true` | success | `true` |
| `false` | failure | `false` |
| `cut` | commit | `!` |
| `A and B` | conjunction | `A, B` |
| `A or B` | disjunction | `(A ; B)` |
| `not A` | sound complement | derive complement or reject |
| `unsafeNot A` | negation as failure | `\+(A)` |
| `once A` | first solution | `once(A)` |
| `assert A` | require first success or raise | relation: `cosmos_assert(A, "assert error")`; function: `(once(A) -> true ; throw("assert error"))` |
| `assert(A, Message)` | require first success or raise `Message` | relation: `cosmos_assert(A, Message)`; function: `(once(A) -> true ; throw(Message))` |
| `A = B` | ordinary unification | `A = B` |
| `A != B` | disequality | `dif(A, B)` |
| `A < B` | numeric comparison | `{A < B}` |
| `A <= B` | numeric comparison | `{A =< B}` |
| `A > B` | numeric comparison | `{A > B}` |
| `A >= B` | numeric comparison | `{A >= B}` |
| `X = A + B` | generic addition | `add_(A, B, T), X = T` |
| `X = A - B` | numeric subtraction | `r_sub(A, B, T), X = T` |
| `X = A * B` | numeric multiplication | `r_mul(A, B, T), X = T` |
| `X = A / B` | numeric division | `r_div(A, B, T), X = T` |
| `X = A % B` | numeric modulo | `r_mod(A, B, T), X = T` |
| `X = #A` | generic size | `size_(A, T), X = T` |
| `X = str(E)` | string conversion expression | `lower(E, T1), str(T1, T), T = X` |
| `X = relation(A)` | resolved named expression call | `relation(A, T), X = T` |
| `X = F(A)` where `F` resolves to a value | closure expression call | `call_cl(F, [A, T]), X = T` |
| `item in collection` | membership | `has_(collection, item)` |
| `c::p(A)` / `pl::p(A)` | host call | `p(A)` |
| `X = js::name` | JavaScript host root | `cosmos_host_root("js", "name", X)` |
| `X = Host.key` / `Host[key]` | host property read | `cosmos_get(Host, Key, X)` |
| `X = Host.method(A)` | host method call | `cosmos_method_value(Host, "method", [A], X)` |
| `Host.key = V` | host property update | `cosmos_set_or_unify(Host, "key", V)` |
| `X = new T(A...)` | typed constructor call | plain table: `call_cl(T.new, [X,A...])`; class: `call_cl(T.new, [T,X,A...])` |
| `X is Type` | nominal/conformance goal | statically `true` or `type_is(X, "Type")` |
| `X is Protocol` | structural conformance goal | statically `true` or `protocol_is(X, Members)` |
| `require(M, X)` | module load | `crequire(M, X, _)` |
| `table = {k = V}` | persistent table construction | `new(T0), set_(T0, "k", V, T1), table = T1` |
| `class(T,{...})` | declare nominal prototype table | `T = {...}` plus class/type metadata |
| `X = table.k` | table read | `getnil(table, "k", X)` |
| `X = table[K]` | indexed read | `getnil(table, K, X)` |
| `New = table.k:V` | persistent table update | `set_(table, "k", V, New)` |
| `table.method(A)` | closure lookup and call | `getnil(table, "method", F), call_cl(F, [A])` |
| `T.method(A)` / `x.method(A)` for class `T` / typed `T x` | class method call | lookup method, then `call_cl(F, [Receiver,A])` |
| `when(A) B else C` | logical branch | `(A, B ; C)` |
| `choose(A) B else C` | committed choice | `(A -> B ; C)` |
| `soft_if(A) B else C` | soft committed choice | `(A *-> B ; C)` |
| `if(A) B else C` | relational conditional | `if_/3` or complemented branches |
| consecutive `case` branches | alternatives | disjunction of branch conjunctions |
| `while(C) B` | temporal loop | `Loop(true, C, B)` |
| `for(I; C; N) B` | initialized temporal loop | `I and Loop(true, C, B and N)` |
| `for(K, V in C) B` | universal provider iteration | provider initialization plus iterator `Loop` |
| `some(K, V in C) B` | existential provider iteration | generated provider search relation |
| `init X = V` | initial loop-state marker | associate `V` with the following loop's `XCurrent` |
| `next X = V` | next loop-state marker | assign `XNext`; complete untouched paths with `XNext = XCurrent` |
| `rel p(!X) B` | surface state-threading parameter | normalize to `rel p(In X0, Out XN) B'` |
| `p(!X)` | surface state-threading call | normalize to `p(XCurrent, XNext)`; later uses see `XNext` |
| `!X += E` | compound pseudo-update sugar | first `!X = X + E`, then fresh `XNext = XCurrent + E` |
| `rel(P...) Body` | closure with ordered captures | `clos(upvals(U...), Generated)` |
| `export(X)` | program result | source predicate output argument |

In the closure row, a capture is the compiler's resolved reference to an outer
binding, an upvalue is the runtime value stored for that capture, and
`upvals(...)` is the runtime environment representation. Generated predicates
receive that environment as their final argument and destructure it using the
same slot order. A closure with no captures uses the sentinel atom `upvals`.

`Cons`, `T`, `Tuple`, `Pair`, `Some`, and `None` are standard functors and do
not require source declarations. `T` and `Tuple` accept any arity; `Pair`,
`Some`, and `None` have arities two, one, and zero respectively.

V2 parameter modes are stored independently from parameter types. At a call,
`In` requires an instantiated argument, `Out` requires a production position,
and `InOut` permits and may refine either state. Multiple `Relation In/Out ...`
declarations form alternative mode signatures. Modes do not imply types or
determinism.

`!` forms exist only in the surface AST. Normalization assigns a fresh logical
version for every pseudo-update and state-threading call. At a branch join, all
paths explicitly unify their current version with one fresh merge version;
an untouched path therefore carries its input forward. Temporal loops continue
to use the more explicit `init`/`next` protocol, and reject nested `!` forms.

`rel`, `function`/`fun`, and `void` are separate callable categories. A
potentially failing relational goal in a function must occur in a
failure-consuming context such as `if`, `not`, `once`, or `or`; calls declared
`void` are outside that relational failure analysis.

`protocol(Name,{...})` contributes interface/contract metadata and emits no
implementation. Typed bindings are checked structurally when their table shape
is known. Nontrivial protocol relation bodies are retained as behavioral
contracts for optional debug instrumentation.

## Stage invariants

Every value-expression lowering returns a pair:

```text
(PrerequisiteGoals, ResultTerm)
```

For example, `A + B` returns the lowered operand goals followed by
`add_(AResult, BResult, T)`, with `T` as its result term. Emitters serialize
these already-lowered goals; they do not decide whether a call is named,
closure-valued, field-based, or host-qualified.

`str(E)` is a reserved conversion expression, not a relation-valued call. Its
operand undergoes ordinary recursive expression lowering first. In particular,
`X = str("turn " + Turn)` emits
`add_("turn ", Turn, T1), str(T1, T), T = X`. The cast consumes `T1` and its
own result term is `T`.

Name and scope resolution precede closure conversion. A closure capture refers
to a specific enclosing binding and environment slot. Merely using a
non-parameter name does not make it a capture: unresolved names become an error
or a closure-local binding according to the language's binding rules.
Dictionary keys do not introduce lexical bindings. In particular,
`{it = Provider, rel range() use(it)}` does not make the field `it` available
as a bare lexical variable inside `range`; the source must bind `it` explicitly
or access it through a captured/self table value.

## Sound complement rules

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

If a goal is absent from this table, `not Goal` is rejected. Use
`unsafeNot Goal` only when negation as failure is intentionally required.
