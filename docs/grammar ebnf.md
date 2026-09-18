# Cosmos EBNF Specification (Draft)

This specification defines the concrete syntax of Cosmos. The grammar is layout-sensitive: indentation determines block structure. The lexer produces ordinary tokens, while the layout phase inserts `INDENT`, `DEDENT`, and `NEWLINE`.

---

# Lexical Structure

```ebnf
program
    = { separator } ,
      { top_level , { separator } } ,
      EOF ;

separator
    = NEWLINE ;
```

---

# Top-Level

```ebnf
top_level
    = declaration
    | goal ;
```

---

# Declarations

```ebnf
declaration
    = relation_decl
    | functor_decl
    | export_decl ;
```

---

# Relation Declarations

```ebnf
relation_decl
    = relation_kind ,
      identifier ,
      "(" ,
      [ parameter_list ] ,
      ")" ,
      body ;

relation_kind
    = "rel"
    | "fun"
    | "bool" ;
```

Examples

```cosmos
rel append(x,y,z)
    ...

fun plus(x,y)
    ...

bool member(x,xs)
    ...
```

Anonymous relations:

```ebnf
relation_expression
    = relation_kind ,
      "(" ,
      [ parameter_list ] ,
      ")" ,
      body ;
```

---

# Parameters

```ebnf
parameter_list
    = parameter ,
      { "," , parameter } ;

parameter
    = [ type_expression ] ,
      term ;
```

Examples

```cosmos
rel p(x)

rel p(Integer x)

rel p([X|Xs])
```

Since unification is symmetric, parameters are simply terms.

---

# Bodies

A callable body may be written using indentation or inline with a semicolon.

```ebnf
body
    = layout_body
    | inline_body ;

layout_body
    = NEWLINE ,
      INDENT ,
      goal_block ,
      DEDENT ;

inline_body
    = goal ,
      ";" ;
```

Therefore

```cosmos
rel p(x)
    x = 1
```

and

```cosmos
rel p(x) x = 1;
```

are equivalent.

---

# Goal Blocks

```ebnf
goal_block
    = goal ,
      { NEWLINE , goal } ;
```

Consecutive goals form an implicit conjunction.

```cosmos
A
B
C
```

means

```cosmos
A and B and C
```

---

# Goals

```ebnf
goal
    = disjunction ;

disjunction
    = conjunction ,
      { "or" , conjunction } ;

conjunction
    = unary_goal ,
      { "and" , unary_goal } ;

unary_goal
    = "not" , unary_goal
    | "unsafeNot" , unary_goal
    | "once" , unary_goal
    | atomic_goal ;
```

Precedence:

```text
not
unsafeNot
once
atomic goals
and
or
```

---

# Atomic Goals

```ebnf
atomic_goal
    = unification
    | comparison
    | call_goal
    | if_goal
    | when_goal
    | choose_goal
    | case_goal
    | "(" , goal , ")"
    | "true"
    | "false" ;
```

`true` always succeeds.

`false` always fails.

---

# Unification

```ebnf
unification
    = expression ,
      "=" ,
      expression ;
```

Examples

```cosmos
x = 1

x = []

[x|xs] = list

Node(a,b,c) = tree
```

There is no separate grammar for pattern matching.

Patterns are ordinary terms participating in unification.

---

# Comparison

```ebnf
comparison
    = expression ,
      comparison_operator ,
      expression ;

comparison_operator
    = "<"
    | "<="
    | ">"
    | ">="
    | "!=" ;
```

---

# Calls

```ebnf
call_goal
    = expression ,
      "(" ,
      [ argument_list ] ,
      ")" ;

argument_list
    = expression ,
      { "," , expression } ;
```

Examples

```cosmos
append(x,y,z)

callback(x)

table.method(x)
```

---

# If

```ebnf
if_goal
    = "if" ,
      "(" ,
      goal ,
      ")" ,
      body ,
      { elseif_branch } ,
      [ else_branch ] ;

elseif_branch
    = "elseif" ,
      "(" ,
      goal ,
      ")" ,
      body ;

else_branch
    = "else" ,
      body ;
```

---

# When

```ebnf
when_goal
    = "when" ,
      "(" ,
      goal ,
      ")" ,
      body ,
      [ else_branch ] ;
```

---

# Choose

```ebnf
choose_goal
    = "choose" ,
      "(" ,
      goal ,
      ")" ,
      body ,
      [ else_branch ] ;
```

---

# Case

Each case alternative is one conjunction.

Multiple alternatives form a disjunction.

```ebnf
case_goal
    = "case" ,
      NEWLINE ,
      INDENT ,
      case_branch ,
      { NEWLINE , case_branch } ,
      DEDENT ;

case_branch
    = goal_block ;
```

Thus

```cosmos
case
    A
    B
case
    C
    D
```

# Added Note: the keyword 'case' appears in each of those cases.

means

```text
(A and B)
or
(C and D)
```

---

# Expressions

```ebnf
expression
    = additive ;

additive
    = multiplicative ,
      { ("+" | "-") , multiplicative } ;

multiplicative
    = unary_expression ,
      { ("*" | "/" | "%") , unary_expression } ;

unary_expression
    = ("+" | "-") , unary_expression
    | postfix ;
```

---

# Postfix Expressions

```ebnf
postfix
    = primary ,
      { postfix_operator } ;

postfix_operator
    = call_suffix
    | field_suffix
    | index_suffix ;

call_suffix
    = "(" ,
      [ argument_list ] ,
      ")" ;

field_suffix
    = "." ,
      identifier ;

index_suffix
    = "[" ,
      expression ,
      "]" ;
```

Examples

```cosmos
t.x

t["name"]

t[y]

f(x)
```

Indexing follows Lua-style semantics.

---

# Primary Expressions

```ebnf
primary
    = identifier
    | literal
    | list
    | dictionary
    | relation_expression
    | "(" , expression , ")" ;
```

---

# Lists

```ebnf
list
    = "[" ,
      [ list_items ] ,
      "]" ;

list_items
    = expression ,
      { "," , expression } ,
      [ "|" , expression ] ;
```

Examples

```cosmos
[]

[1,2,3]

[X|Xs]

[a,b|Tail]
```

---

# Dictionaries

```ebnf
dictionary
    = "{"
      [ dictionary_entries ]
      "}" ;

dictionary_entries
    = dictionary_entry ,
      { "," , dictionary_entry } ;

dictionary_entry
    = identifier ,
      "=" ,
      expression ;
```

---

# Types

```ebnf
type_expression
    = applied_type ;

applied_type
    = identifier ,
      { identifier } ;
```

Examples

```cosmos
Any

Integer

Relation Any

Tree Any Any Any
```

Type annotations may appear

```cosmos
Integer x

rel p(Integer x)

Relation Any f
```

The exact semantic interpretation is performed after parsing.

---

# Functor Declaration

```ebnf
functor_decl
    = "functor"
      "("
      identifier
      ","
      type_expression
      ")" ;
```

Example

```cosmos
functor(Node, Tree Any Any Any)
```

Zero-argument functors require no parentheses.

```cosmos
x = None

x = Red
```

---

# Export

```ebnf
export_decl
    = "export"
      "("
      expression
      ")" ;
```

---

# Literals

```ebnf
literal
    = integer
    | float
    | string ;

integer
    = digit ,
      { digit } ;

float
    = integer ,
      "." ,
      integer ;

string
    = "\""
      { string_character | escape }
      "\"" ;

escape
    = "\\\\"
    | "\\\""
    | "\\'"
    | "\\n"
    | "\\r"
    | "\\t" ;
```

The escape `\'` is accepted.

---

# Identifiers

```ebnf
identifier
    = letter ,
      { letter | digit | "_" } ;
```

No capitalization convention is imposed. Variables, types, and functors are distinguished during semantic analysis rather than lexically.

---

# Comments

```ebnf
line_comment
    = "//"
      { any_character_except_newline } ;

block_comment
    = "/*"
      { block_comment | any_character }
      "*/" ;
```

Block comments may nest.

---

# Semantic Notes

The parser performs only syntactic analysis.

Later semantic passes perform transformations such as:

```text
implicit conjunction

case
    ↓
disjunction

x = f(a,b)
    ↓
f(a,b,x)

closure capture

name resolution

type checking
```

The parser preserves the source structure wherever possible and leaves semantic lowering to subsequent compiler phases.
