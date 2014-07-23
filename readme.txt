
Cosmos
====

1. (noun) the world or universe regarded as an orderly, harmonious system.

Cosmos is a modern logic programming language.

**Note:** the language is in alpha.

Download
---

_Coming soon._

Documentation
---

_Coming soon._

Building
---

Building from the source requires SWI-Prolog (7.1.16+). Look into the _make_ script and move the executable to swipl/bin.

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

Overview
====

Philosophy
----

The design of the language aims for simplicity and minimalism. This is done by adopting few but powerful core features: relations, functors and types. As a result, the language is concise and easy-to-learn without sacrificing expresiveness.

```javascript
rel main()
    x = io.read()
    io.writeln("hello, "+x+'!')
```

The syntax is close to that of a typical scripting language (Python/JavaScript/Lua). The difference is that whereas traditional scripting languages tend to focus on imperative programming, Cosmos focuses on declarative (logic and functional) programming.

Relations
----

Instead of functions, Cosmos has relations.

Relations allow input and output parameters to be used interchangeably.

```javascript
//note that the there is no 'return' in the definition
//instead, the parameter y is explicit
rel double(x, y)
    y = x*2
    
rel main()
    double(3, y) //y is 6
    double(x, 6) //x is 3
    io.writeln('the double of '+math.integerToString(x)+' is '+math.integerToString(y)) //the double of 3 is 6
```

When a relation is nested, the last parameter is hidden.

```javascript
rel main()
    io.writeln(double(3)) //this will print 6
    x = double(4) //x is 8
```

Note how conventional the code looks now. Despite being a declarative language, Cosmos can look and behave very similarly to a typical language at times. How similar is up to the programmer.

Whereas functions have one output, relations may have zero, one or more outputs. You can check this by making queries at the interpreter.

```javascript
Cosmos v0.10
> x=1 or x=2 //this query has two answers (outputs)
| x = 1
| x = 2
```

If the system picks one answer and it turns out to be invalid, the system will backtrack and pick the other.

```
rel p(x)
    x=1 or x=2
    
rel main()
	p(x)
	x!=1
	io.writeln(x) //2
```
Relations are first-class values. It's possible to define a relation within another.
```
rel p(x)
    rel temp(x)
        x = 2
    temp(x)
    
rel main(x)
    p(x) //x is 2
```
Alternatively:
```
rel p(x)
    temp = rel(x)
        x = 2
    temp(x)
```

Functors
----

Functors are composite data.
```
FunctorObject F //declares an object for creating functors
x = F(1, 2) //x is assigned to a functor F composed by the values 1 and 2
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
rel main()
    l = [1,2,3]
    list.first(l, head) //head is 1
    list.rest(l, tail) //tail is [2, 3]
    list.map(l, math.inc, l2) //l2 is [2, 3, 4]
    list.map(l3, math.inc, l) //l3 is [0, 1, 2]
    list.filter(l, rel(x) x!=3;, l4) //l4 is [1, 2]
```

Immutability
----

Variables are immutable. Instead of modifying a value we create a new one.

```
    l2 = list.push(l, 55) //instead of modifying l, we create a new variable l2
    io.writeln(l)  //[1, 2, 3]
    io.writeln(l2) //[1, 2, 3, 55]
```

Cosmos adopts many principles and features that are common in functional programming languages (although the principles apply to *relations* rather than *functions*).

Types
----

Cosmos manages a balance between strictness and non-strictness. Writing the type of a variable is (almost always) optional.

```javascript
    Integer n = 7
    Real x = 5.2
    String s = 'abc'
    z = 5 //z is implied to be an Integer
    Functor l = [1, 2, 3]
    FunctorObject F
    Functor f = F('apple', 5)
```

The type system supports *composite types*.
```
    Functor String Number f2 = F('apple', 2)
```
*Functor String Number* is a composite type that accepts any functor whose first element is a string and second is a number.
```
    Relation Any Any p = double
```
Relations can also receive composite types. *Relation Any Any* is a type that accepts any relation with exactly two arguments.

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
    s = 'a' or (s = 'b' and x = 1) or x = 2
```

Whitespace
----

The language is whitespace sensitive. This has two purposes:

* Remove the need to write and read unnecessary characters.
* Hide some of the logic semantics of the languages.

Take the following definition.
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

Host
----

Cosmos is currently compiled into Prolog. As such, it's possible to call predicates of Prolog from Cosmos.

```
rel write(x)
    pl::write(x) //calls Prolog predicate 'write'
```

> Written with [StackEdit](https://stackedit.io/).