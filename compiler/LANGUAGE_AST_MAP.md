# Cosmos language AST map

This reference describes the active AST built by `src/parser.co` and consumed
by `src/normalize.co`, `src/check.co`, `src/resolve.co`, and
`src/emit_prolog.co`. Nodes are Cosmos functors, shown below as
`Node(field1, field2, ...)`. Names such as `name`, `kind`, and `op` are strings;
`items`, `params`, and `args` are lists. `None` is an AST sentinel for an
omitted optional field.

## Root and positions

| Shape | Meaning |
| --- | --- |
| `Program(items)` | Parsed source file. `items` contains declarations and top-level goals in source order. |
| `Loc(line, column)` | One-based source location attached to token-originating nodes. Generated nodes can use `Loc(0,0)`. |
| `Token(type, value, line, column)` | Lexer output. Indentation becomes `INDENT`/`DEDENT`; physical line endings can become `NEWLINE`. |
| `ParseError(message, tokens)` | Parser diagnostic carrying the remaining token stream. |
| `CompileError(message, loc)` | Later-stage diagnostic at a source location. |

The parser's public API exports `lex`, `parseTokens`, and `parse`. Normal
compilation calls `parse(source, Program(items))`.

## Declarations

| Shape | Source role | Important fields |
| --- | --- | --- |
| `RelationDecl(annotation, name, params, body, loc)` | Top-level `rel`, `bool`, `fun`, `function`, or `void` declaration. | `annotation` is the category string or a table containing `category` and `determinism`. `body` is a goal node. |
| `FunctorDecl(name, types, loc)` | `functor(...)` declaration. | `types` is an ordered list of names: parent first, then field types. An empty list or just `Functor` denotes the open form in the checker. |
| `ExportDecl(value, loc)` | `export(value)`. | `value` is an expression. The emitter uses the final export as the entry result. |
| `TypedDecl(words, name, value, loc)` | Typed binding or standalone declaration. | `words` contains annotation names; `value` is an expression or `None`. Also used for protocol field and body-free method declarations. |
| `ProtocolDecl(name, members, loc)` | `Protocol(...)` or `protocol(...)`. | `members` contains `TypedDecl` fields and `ClosureExpr` methods. |
| `ClassDecl(name, value, loc)` | `class(Name, value)`. | `value` is normally a `DictExpr` of methods. |

`TypedParam(words, name, loc)` is a parameter with type and/or mode words.
An unannotated parameter is normally a `VarExpr`. A standalone
`Relation ... name` declaration is initially a `TypedDecl`; normalization
attaches its signature to the matching `RelationDecl.annotation`.

## Goal nodes

Goals can succeed, fail, bind variables, produce alternatives, or invoke a
callable. The parser makes a `CallGoal` when a call is used as a statement;
the same syntax in a value position is a `CallExpr`.

| Shape | Meaning |
| --- | --- |
| `TrueGoal(loc)`, `FalseGoal(loc)`, `CutGoal(loc)` | `true`, `false`/`fail`, and `cut`. |
| `UnifyGoal(left, right, loc)` | `left = right`. Also represents a parsed explicit state update before normalization. |
| `CompareGoal(op, left, right, loc)` | `!=`, `<`, `<=`, `>`, or `>=`. |
| `HasGoal(item, collection, loc)` | Membership goal `item in collection`. |
| `IsGoal(value, typeName, loc)` | Type or protocol test `value is Type`. |
| `CallGoal(fn, args, loc)` | Callable invocation used as a goal. |
| `AndGoal(goals)`, `OrGoal(goals)` | Conjunction and alternatives. These grouping nodes have no location field. |
| `UnaryGoal(op, body, loc)` | Goal operators such as `not`, `unsafeNot`, `once`, `init`, and `next`. |
| `AssertGoal(body, message, loc)` | `assert(...)`; `message` is an expression. |
| `ControlGoal(kind, condition, yes, no, loc)` | `if`, `when`, `choose`, `soft_if`, and parsed `while`. `no` is a goal or `None`; `elseif` nests another `ControlGoal`. |
| `ForGoal(initial, condition, advance, body, loc)` | Three-part `for` loop. |
| `ForInGoal(kind, key, value, collection, body, loc)` | `for`, `for-in`, or `some` over a collection. `key` is `None` when omitted. |
| `CaseGoal(body, loc)` | A `case` group. `body` is an `OrGoal` or a single branch goal. |

A multi-line indented body is folded into an `AndGoal`; a single-line body may
remain its single goal node. A nested named relation in a body is parsed as a
`ClosureExpr` bound by `UnifyGoal(VarExpr(name,...), closure, ...)`.

## Expression nodes

| Shape | Meaning |
| --- | --- |
| `VarExpr(name, loc)` | Identifier, including host-qualified spellings such as `pl::name` or `js::name`. |
| `LiteralExpr(value, loc)` | String, number, or generated literal key. |
| `RawFunctorExpr(name, args, loc)` | Explicit undeclared `:Name(...)` or `:Name`. |
| `CallExpr(fn, args, loc)` | Call used to produce a value. A known declared functor call is handled as construction by the checker/emitter. |
| `NewExpr(prototype, args, loc)` | `new Type(...)`; the parser requires `prototype` to be `VarExpr`. |
| `BinaryExpr(op, left, right, loc)` | Arithmetic or overloaded `+`, `-`, `*`, `/`, `%`. |
| `UnaryExpr(op, operand, loc)` | Unary arithmetic; the parser currently produces this for `-`. |
| `SizeExpr(operand, loc)` | `#operand`. |
| `FieldExpr(owner, key, loc)` | `owner.key`; `key` is a string. |
| `IndexExpr(owner, key, loc)` | `owner[key]`; `key` is an expression. |
| `SliceExpr(owner, from, to, loc)` | Range `owner[from:to]`, lowered to the host `slice_/4`. Both bounds are expressions. |
| `SetFieldExpr(field, value, loc)` | Functional update `owner.key:value`; `field` is a `FieldExpr`. |
| `ListExpr(items, tail, loc)` | List literal. `tail` is `None` for an ordinary closed list. |
| `DictExpr(entries, loc)` | Table literal. Each entry is `Entry(key, value)` with expression children. |
| `ClosureExpr(annotation, params, body, loc)` | Anonymous, nested, table, or protocol callable. |
| `StateExpr(child, loc)` | Explicit `!` syntax before normalization. |
| `NextExpr(child, loc)` | Read of `next value` before temporal normalization. |

For `DictExpr`, an identifier key such as `name=value` becomes
`Entry(LiteralExpr('name', ...), value)`. A positional table item receives a
numeric literal key. A method declared inside a table is an `Entry` whose
value is a `ClosureExpr`.

## Callable annotations

`RelationDecl.annotation` may be a category string, for example `'rel'`, or a
table such as `{category='rel', determinism='det'}`. A closure uses its name
as the simple annotation for a plain `rel`, or a table with `name`, `category`,
and `determinism`. Normalization may add a `contracts` field to a relation
annotation from standalone mode declarations.

These annotation tables are metadata, distinct from the structural AST
functors. Parameter mode and type names remain in `TypedParam.words` until
the checker and emitter turn them into compile-time facts and runtime
contracts.

## How the AST changes by stage

```text
Parser AST
  Program(items)
    │
    ├─ normalize: attaches standalone modes, expands ! arguments/assignments,
    │             lowers iterative and temporal loops to closures and calls
    ▼
Normalized item list
    │
    ├─ check: walks AST; builds schemas and inferred callable signatures
    ├─ resolve: partitions relations/top-level goals and computes captures
    ▼
Resolved program table + checked schemas
    │
    └─ emit: lowers nodes to Prolog terms and writes clauses
```

The normalized list is still mostly made of the same functors. Important
rewrites include:

- `StateExpr` call arguments and parameters expand to before/after variable
  positions. `!x = value` becomes a `UnifyGoal` against a fresh `VarExpr`.
- `ForGoal` becomes an initial goal followed by a `while` control node.
  Iterative `while` and `for`/`for-in` then become `CallGoal` nodes targeting
  `pl::cosmos_while` or `pl::cosmos_for`, with generated `ClosureExpr` steps.
- Temporal `init`/`next` assignments become versioned variables and shared
  future slots. Invalid updates in conditions or negation produce
  `CompileError`.
- `some` remains a `ForInGoal` for relational iteration in the emitter.

`check.co` derives tables for schemas, imports, exports, and callable facts;
it does not define a separate typed AST node family. `resolve.co` returns a
program table with `relations`, `top`, `globals`, `signatures`, and `functors`.
Each signature is `Signature(name, arity, captures, calls, kind)`. The emitter
adds `schemas` to that table and turns each node into a Prolog term.

## Example

For this source:

```cosmos
rel copy(x,y)
    y=x

copy(1,result)
export(result)
```

The parser's top-level structure is approximately:

```text
Program([
  RelationDecl('rel', 'copy', [VarExpr('x', ...), VarExpr('y', ...)],
    UnifyGoal(VarExpr('y', ...), VarExpr('x', ...), ...), ...),
  CallGoal(VarExpr('copy', ...), [LiteralExpr(1, ...), VarExpr('result', ...)], ...),
  ExportDecl(VarExpr('result', ...), ...)
])
```

The ellipses stand for `Loc` values. This is a shape sketch, not a serialized
AST dump.

## Source pointers

- Node declarations and lexer: `src/parser.co` at the top of the file.
- Parsing declarations: `parse_program_item`, `parse_relation_declaration`,
  `parse_typed_declaration`, `parse_protocol`, `parse_functor_declaration`.
- Parsing goals: `parse_goal`, `parse_unary_goal`, `parse_atomic_goal`,
  `parse_control`, `parse_for_control`, `parse_for_in_control`.
- Parsing expressions: `parse_term`, `parse_prefix_expression`,
  `parse_postfix_tail`, `parse_primary`, `parse_list`, `parse_dictionary`.
- Transformations: `normalize.rewrite`, `normalize.temporal_rewrite`,
  `check.expression_type`, `check.flow`, `resolve.analyze`,
  `emit_prolog.expression`, and `emit_prolog.goal`.
