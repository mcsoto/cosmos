
Cosmos
====

> 1. (noun) the world or universe regarded as an orderly, harmonious system.

Cosmos is a modern logic programming language.

_Cosmos 0.12 VM - Alpha version released._

Status
---

The language is in testing stage.

This was published only to release the current code.

Ideally, it'll go:

```
alpha -> beta (most bugs fixed, no missing features)
beta -> full (decent performance)
```

This answers any "when is it done?" questions.

The focus is on fixing issues and making it easy to try the language instead of performance, so as to make it usable for simple scripts, however.

See details.

Download
---

_Coming soon._

Documentation
---

_Wait for it._

See test samples.

Building
---

Use `make` or `make cosmos`

It should only require gcc (7.4.0)

Tested using cygwin.

See readme.txt for dev info.

Queries
----

You can try out the language by opening the interpreter and making _queries_ to the language.

```
$ cosmos -i
> x=1
| x = 1
> x=1 or 2=x
| x = 1
| x = 2
```

This will compile and run a file `test1.co`.

```
$ cosmos -l test1
```

Overview
====

```javascript
rel main()
    x = io.read()
    io.writeln("hello, "+x+'!')
```

The syntax is close to that of a typical scripting language (Python/JavaScript/Lua). The difference is that whereas traditional scripting languages tend to focus on imperative programming, Cosmos focuses on declarative (logic and functional) programming.


A Neutral Language
----

Although it is a logic programming language, code in this language can look and behave very conventionally: code might seem imperative or functional.

However, it's a declarative language. As such, variables are immutable. Instead of modifying a value we create a new one.

```javascript
list.push(l, 55, l2) //instead of modifying l, we create a new variable l2
io.writeln(l)  //[1, 2, 3]
io.writeln(l2) //[1, 2, 3, 55]
```

Cosmos adopts principles from (procedural) scripting languages, logic programming and functional programming. You may write using an almost imperative style, this will however compile to logic code.


Relations
----

Instead of functions, Cosmos has relations.

Whereas functions have one output, relations may have zero, one or more outputs. You can check this by making queries at the interpreter.

```$
cosmos -i
> x=1 or x=2 //this query has two answers (outputs)
| x = 1
| x = 2
```

If the system picks one answer and it turns out to be invalid, the system will backtrack and pick the other.

```javascript
rel p(x)
    x=1 or x=2
    
rel main()
	p(x)
	x!=1
	io.writeln(x) //2
```


When a relation is nested, the last parameter is hidden.

```javascript
//note that the there is no 'return' in the definition
//instead, the parameter y is explicit
//this is typically the 'output' parameter
rel double(x, y)
    y = x*2

double(4,x) //x is 8
```

Relations may adopt function syntax. When nesting, for example,

```javascript
print(double(3)) //this will print 6
```

Logic-wise, `double(4,x)` is read as a statement: "the double of 4 is x".

`double(4)` reads as a function; "the double of 4".

Functors
----

Functors are composite data.
```
functor(F, Functor) //declares an object for creating functors
x = F(1, 2) //x is assigned to a functor F with the values 1 and 2
x = F(1, a) //uses pattern matching to match F(1, 2) against F(1, a)
print(a) //2
```

Lists are syntax sugar for the functor Cons. Here are two ways to define a list:

```
l = [1, 2]
l = Cons(1, Cons(2, Cons))
```

Relations such as _first_, _map_ and _filter_ can be used to manipulate lists.

```
require('io', io)
require('math', math)
require('list', list)

rel main()
    l = [1,2,3]
    list.first(l, head) //head is 1
    list.rest(l, tail) //tail is [2, 3]
    list.map(l, math.inc, l2) //l2 is [2, 3, 4]
    list.filter(l, rel(x) x!=3;, l4) //l4 is [1, 2]
```

Cosmos adopts many principles and features that are common in functional programming languages (although the principles apply to *relations* rather than *functions*).

Tables
----

Tables (also known as maps, dictionaries, etc.) are structures that map keys to values.

```javascript
Table t = {x=1 and y=2}
table.set(t, 'a', 1, t2)

print(t) //{'x': 1, 'y': 2}
print(t2) //{'x': 1, 'y': 2, 'a': 1}
```

Booleans
----

There is no boolean type. Instead, relations themselves are "booleans".

Code such as

```
if(s = 'a')
	x = 0
elseif(s = 'b')
	x = 1
else
	x = 2
```

is simply sugar for

```
(s = 'a' and x = 0) or (s = 'b' and x = 1) or x = 2
```

For a less imperative-looking code,

```
case
	s = 'a'
	x = 0
case
	s = 'b'
	x = 1
case
	x = 2
```


Whitespace
----

The language is whitespace sensitive.
```
rel p(x)
    x!=1
    x<5
```
This could be a single line.
```
rel p(x) x!=1 and x<5;
```
It's possible to drop the whitespace semantics by writing the unnecessary characters, although this is not generally advisable.

Note that relations from different lines are separated by _ands_ (semicolons are only used to end the indendation).

Details
----

With the advent of the Cosmos 0.12 VM,
- It's still in alpha.
- It does not rely on other languages to build.
- C++ VM released. Parser is still built in Cosmos(!) itself.
- The VM is based on the WAM, as it provides a set of bytecode instructions for Prolog. Temporary variables are not used. See original WAM paper.
- The parser makes use of an intermediary language, "CWAM". `Put(Var(0), 1)` translates to `put_variable 0,1`.
- This has missing features, however, it's already more than (raw) Prolog. Again, this was uploaded only to give the language a basis.
- It has its own license.
- Does not rely on other Prolog implementations.
- For language samples, see test examples.
