# Parser Design

## Pratt Parsing and Front-End Architecture

This document describes the parsing strategy used by the Cosmos compiler.

Rather than implementing a separate recursive-descent function for every operator precedence level, Cosmos uses **Pratt parsers** (Top-Down Operator Precedence parsers) for both expressions and logical goals.

This keeps the parser compact, extensible, and easy to modify as the language evolves.

---

# Overall Compiler Pipeline

```text
Source
    │
Lexer
    │
Layout Processor
    │
Parser
        ├── Declaration Parser
        ├── Goal Pratt Parser
        └── Expression Pratt Parser
    │
Abstract Syntax Tree
    │
Semantic Analysis
    │
Core IR
```

Each stage has a single responsibility.

---

# Lexer

The lexer converts characters into tokens.

It recognizes:

* identifiers
* keywords
* operators
* literals
* punctuation
* comments

The lexer does **not** interpret indentation.

Example:

```cosmos
rel append(x,y,z)
    x = []
```

becomes approximately

```text
REL
IDENTIFIER(append)
(
IDENTIFIER(x)
,
IDENTIFIER(y)
,
IDENTIFIER(z)
)
NEWLINE
IDENTIFIER(x)
=
[
]
EOF
```

---

# Layout Processor

The layout processor examines indentation.

It inserts virtual tokens:

```text
INDENT
DEDENT
NEWLINE
```

while rejecting invalid indentation.

Example

```cosmos
rel p(x)
    x = 1
    y = 2
```

becomes

```text
REL
IDENTIFIER(p)
(
IDENTIFIER(x)
)

NEWLINE
INDENT

IDENTIFIER(x)
=
1

NEWLINE

IDENTIFIER(y)
=
2

DEDENT
```

The parser never measures whitespace directly.

---

# Parser

The parser consumes the layout-aware token stream.

It consists of three cooperating parsers.

```text
Declaration Parser

Goal Pratt Parser

Expression Pratt Parser
```

---

# Declaration Parser

The declaration parser recognizes constructs beginning with reserved declaration keywords.

Examples:

```cosmos
rel p(x)
    ...

fun q(x)
    ...

bool member(x,xs)
    ...

functor(Node, Tree)

export(tree)
```

These produce declaration AST nodes.

Anything that is not a declaration is parsed as a goal.

---

# Goal Pratt Parser

The Goal Pratt Parser parses logical formulas.

Examples:

```cosmos
x = 1

member(x,xs)

not member(x,xs)

A and B

A or B

A and B or C
```

Its result is always a Goal AST node.

---

# Expression Pratt Parser

The Expression Pratt Parser parses value-producing expressions.

Examples:

```cosmos
1 + 2

x * y

t[i]

t.x

Node(a,b)

{
    x = 1
}
```

Its result is always a Term or Expression AST node.

---

# Cooperation Between Parsers

The Goal Parser delegates expression parsing whenever an expression is expected.

For example,

```cosmos
x = y + 1
```

is parsed as

```text
Goal Parser

    left
        Expression Parser

    "="

    right
        Expression Parser
```

Similarly,

```cosmos
x < y + z
```

uses the Expression Parser for both operands.

The Goal Parser never parses arithmetic itself.

---

# Prefix Constructs

Some language constructs are not operators.

Instead they introduce structured syntax.

These include

```text
if

when

choose

case
```

The Goal Parser recognizes these before invoking Pratt parsing.

For example,

```cosmos
if(x = 1)
    y = 2
else
    false
```

is parsed directly into an `IfGoal`.

No precedence rules are involved.

---

# Why Pratt Parsing?

Traditional recursive-descent parsers typically contain many functions.

```text
parse_expression()

parse_additive()

parse_multiplicative()

parse_unary()

parse_primary()
```

Each new precedence level requires another parser function.

Pratt parsing replaces this hierarchy with one generic algorithm driven by an operator table.

Conceptually:

```text
parse_expression(min_precedence)
```

This single routine handles every binary and unary operator.

Adding a new operator usually requires only adding one table entry.

---

# Expression Operators

The initial expression precedence is:

| Operator      | Associativity |
| ------------- | ------------- |
| `.` `[]` `()` | Left          |
| unary `+` `-` | Right         |
| `*` `/` `%`   | Left          |
| `+` `-`       | Left          |

Additional operators may be added later without changing the parser algorithm.

---

# Goal Operators

Logical goals use their own precedence table.

| Operator       | Associativity |
| -------------- | ------------- |
| `not`          | Right         |
| `unsafeNot`    | Right         |
| `once`         | Right         |
| `=`            | None          |
| `< <= > >= !=` | Left          |
| `and`          | Left          |
| `or`           | Left          |

This gives

```cosmos
not A and B or C
```

the interpretation

```text
((not A) and B) or C
```

---

# Postfix Operators

Postfix operations naturally fit the Pratt model.

Examples:

```cosmos
table.x

table[key]

f(x)

table.method(x)
```

These bind tighter than every infix operator.

For example,

```cosmos
table.x + 1
```

parses as

```text
(+)

    (.)

        table

        x

    1
```

---

# Future Operators

One advantage of Pratt parsing is extensibility.

Suppose Cosmos later introduces

```cosmos
a |> f

a ?? b

a ?: b
```

No parser restructuring is required.

Only the operator table changes.

---

# Operator Table

Conceptually, every operator is described by metadata.

```text
symbol

precedence

associativity

prefix parser

infix parser

postfix parser
```

The Pratt algorithm consults this table rather than relying on hard-coded parser functions.

---

# Error Recovery

Pratt parsers naturally know the precedence context.

This makes diagnostics such as

* missing operand,
* missing closing parenthesis,
* unexpected operator,
* invalid chaining,

simpler to report with accurate source locations.

---

# Advantages

Compared with a traditional recursive-descent precedence parser, Pratt parsing offers:

* substantially less parser code,
* easier addition of new operators,
* simpler maintenance,
* clearer precedence handling,
* naturally supports postfix syntax,
* naturally supports prefix operators,
* no explosion of parser functions.

These advantages make it particularly suitable for Cosmos, whose syntax is expected to evolve while retaining a relatively small and expressive core.

---

# Parser Responsibilities

The parser is responsible only for syntax.

It constructs the AST without performing semantic transformations.

Specifically, the parser does **not**:

* resolve names,
* infer types,
* perform closure capture analysis,
* lower relational expression sugar,
* expand `case` into disjunction,
* normalize anonymous relations,
* optimize expressions.

Those tasks belong to the semantic analysis phase.

The parser's sole responsibility is to convert a valid stream of layout-aware tokens into an accurate abstract syntax tree.
