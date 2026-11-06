# Guide

For argument modes, protocols, constructors/classes, state threading, assertions, and their current support, see [V2+ features](guide-v2.md).

1. Syntax
2. Introduction
3. 2B. Relations
4. 2C. Operators
5. 2D. Data
6. Tutorial
7. Optimizations

### 1. Syntax

## Syntax

|  | Syntax | Output |
| --- | --- | --- |
|  | #str | size(str) |
|  | t.x | table.get(t,x) |  |
|  | t['x'] | table.get(t,x) |  |
|  | t.x:2 | table.set(t,x,2) |  |
|  | :f(2) | functor |  |

--

|  | Types | Data |
| --- | --- | --- |
|  | String | "str" |
|  | Number | 1, 2.5 |
|  | Relation | rel(x) true; |
|  | Functor | Tuple(x) |
|  | List | [1,'2'] |

|  | Operators |
| --- | --- |
|  | and,or |  |
|  | if,when,choose |  |
|  | not,once |  |

|  | Arithmetic Operators |
| --- | --- |
|  | + - * / |
|  | < > <= >= =!= |

|  | Conversion (casting) |
| --- | --- |
|  | str, int |
|  | num |

## Lexicon

Syntax: a language's grammar.

### 2. Using the Language

## Installation

Before doing anything, you may check that you've installed the language. By opening the language with the -v flag, you should see installation version number and confirm.

Open a command-line and type,

```
$ cosmos -v
Cosmos 0.16
```

If the language is installed, you'll see something akin to this.

## Interpreter

A good way to try out a new language is by opening the interpreter, if one is available, and making statements in it. This can be done with the -i flag.

We'll assume you have already downloaded the language.

```
$ cosmos -i
> x=1
| x = 1
> x=1 or 2=x
| x = 1
| x = 2
> str='hello'
| str = 'hello'
> l=[1,2,3]
| l=[1,2,3]
```

This way, you should get a better idea of how the language works. Whenever you see a new kind of statement in this guide, you may use the interpreter to try it on.

## Writing a file

Make a file `hello.co` with the content,

`print('hello world')`

A program that writes "hello world" on the screen is one of the simplest programs you can do. This can be done with a `print` command.

The file can be loaded with the `-l` flag.

```
$ cosmos -l hello
'hello world'`
```

### 2. From First Principles

## Statements

A simple way to make a statement in Cosmos is to use equality, aka the `=` operator.

```
x=1
y=z
2.5=z
```

These are three kinds of statements you can make.

```
x=1
print('hello world')
io.writeln('hello world')
```

The first uses the relation of equality.

Then, the built-in `print` relation is used to write 'hello world'.

Finally, a `writeln` relation is taken from a module `io` to write 'hello world'.

## Joining statements

x=1 y=2 and x=1

Statements can be joined together with *and*.

Statements from separate lines are implictly joined.

x=1 y=2

... is the same as...

x=1 and y=2

## Data types

Two basic types of data we've seen so far are *Number* and *String*.

Number includes 1, 2 and 2.5.

Unlike numbers, strings refer to a piece of text surrounded by double or single quotation in code.

String includes 'hello world' and "2".

Remember that 2 is a *Number* but '2' is a *String*.

## Comments

## Arithmetics

x = num(2+1*4/2)

The special *num* (or *real*) function computes the result of the mathematical operations, passing the result to x.

This is not necessary.

```
| x=1+2
print(x) //1+2
```

This *is* a technically correct program and saying that the value of x is 1+2 is an answer. Though, it may not be the one we want.

A logic program may sometimes,

1. Apply a bunch of numerical operations, and,
2. Evaluate the result of those operations with *num* or *real*, sometimes at the end of the program. This is the "solving" step.

x = 'hello'+' world'

Different data types, such as strings, may have their own interpretation of addition. We may use addition to "add" two strings together, for example.

```
print(str(x)) //'hello world'
```

This is akin to *casting* in procedural languages. A value like 1+2 has a different type than *Number*. It's stored as-is before being solved by the language's arithmetic system.

## Constraint Arithmetics

Cosmos is one of the few existing languages to have CLP as the default arithmetic system.

```
$ cosmos -i
> x=1+y
| x = 1+y
> x=num(1+y)
| x = _124
| y = _123
> x>5
| x > 5
```

*Why?*

As this is a rather unique decision, we should probably explain.

A regular language would have *x>5* or *y+1* simply fail. In those cases, it doesn't know the value of x or y. It wouldn't then be able to solve those equations.

As a logic language, they're simply taken as true until proven wrong. It's the same for equality, e.g. x=y would also give an error in a regular language. A logic language has *constraints* that are solved when needed.

This is commonly called Constraint Logic Programming (CLP). Cosmos has CLP for Reals[1] as its default arithmetic.[2] This also means that it uses floating-point numbers.

There are other known systems. However, they would not work well as the default arithmetics. CLP(FD) is limited to integers which would mean users couldn't use floating-point numbers at all.

As the default arithmetics, we wanted a system that would, (1) work under normal circumnstances, at the least, and (2) not be limited to that; if possible, explore and make use of logic programming. If it weren't possible to use numbers with decimals, it would clearly not work under the circumnstances in which procedural arithmetics do, as they do use them, thus breaking (1).

However, one can use other systems by calling the host language, and using a system from them. Furthermore, the current system may be changed by modifying *core.pl*.

[1] As far as we know, CLP for Reals goes back to Prolog III. See [http://prolog-heritage.org/en/ph30.html](http://prolog-heritage.org/en/ph30.html).

[2] It should be rather be asked why a logic language would *not* use CLP and instead present a classical, procedural system as the default one! Even though Prolog III has it, see [1]. It's practically asking users to make incorrect programs, logically speaking.

### 2B. Relations

## Custom Statements

Let's codify the intuition that "the double of x is y".

```
rel double(x,y)
    y=num(x*2)

double(2,z)
```

We've seen statements that use built-in relations like *print* and *=* but this is the first time we *define* our own relation. Specifically,

1. We define a relation using the keyword `rel`.
2. We then "call" upon that same relation.

A fine rule to understand the second step is to substitute the statement for the definition.

A statement like `double(2,z)` is, by our definition, `z=2*2`, once we've substituted `x` by `2` and `y` by `z`.

In other words, the result is that z now equals 2*2.

Though *double* is not particularly useful, relations in general can single out pieces of code allowing for later use.

As we'll see later, relations can be kept in a *module*.

## What is a relation?

Cosmos™ is one of the few remaining *logic programming languages*. It's no surprise therefore that there's some connection.

Logic itself concerns with statements that may be *true* or *false*, such as,

```x equals 2 The double of 2 is 4. Socrates is a human. It's raining.

```

What these statements have in common is that they each have a _relation_. This is more evident when written in logic notation,

```x = 2
double(2, 4)
human('socrates')
rain().
```

The relationship in *double(2, 4)* is *double*, which we defined beforehand. Naturally, this statement is true.

Out of those, *=* is distinguishable enough that it doesn't need to be in logic notation. Generally, arithmetics stay in arithmetic notation.

## Logic and function notation

```
double(4,x)
x=double(4)
```

Consider these two statements. Although the meaning is the same, one of them uses *double* as a relation and the other uses it as a function.

## More about truth

## Whitespace

Any major "structure" such as rel and if are delimited by an increase in whitespace (generally, comprised of four spaces or a single tab character).

```
rel(true)
    false
```

The code that comprises the if- and else-parts are evident through this method.

An error is issued if there's any inconsistency. For example, if you chose the first indent to be four spaces but the second to be three.

As long as you make a consistent rule, i.e. four spaces or one tab-only, there should be no issues.

[1] As suggested by the programming language Python™, true statements can be used as placeholders.

### 2C. Operators

## and/or

In a logic language, these operators are more important than they may first seem. They are not only logical operators, they describe the flow of a logic language.

We've already seen them in use.

```
> x=1 and 2=y
| x = 1 and y = 2
> x=1 or 2=x
| x = 1
| x = 2
```

*Logic interpretation* A and B: Both A and B are true.

A or B: Either A, B or both are true.

## A more complicated example

This one is a bit more complicated.

`x=1 or x=2` essentially states that x may be 1 *or* 2. Which is to say, we don't know what the value is!

But what about `(x=1 or x=2) and x!=1`?

```
rel p(x)
    x=1 or x=2

rel main()
    p(x)
    x!=1
    io.writeln(x) //2
```

## Logic and procedural interpretations

Naturally, we have said that x is 1 or 2. Since we then state that x *is not* 1, it's only possible for it to be 2. This is the logical interpretation of the program.

The program will then call io.writeln to write 2 on the screen.

## Logical Engine (I)

Cosmos is a language based on logic. Still, it runs on a computer. As such, there has to be a procedural (i.e. a machine-based) explanation on how the program runs.

We might say it's a logic program that's run by a procedural "logical engine".

We may call it the logic-procedural interpretation. This would be the *procedural* explanation on how our *logic* program is run.

*Procedural interpretation* A and B: A and B are both evaluated, in sequence.

A or B: A is evaluated. If that fails, B is evaluated.

1. As p(x) is called, first x=1 is evaluated.
2. However, we then evaluate x!=1. A contradiction is found.
3. *However,* we can still go back. Our program then backtracks to p(x), and evaluates x=2.
4. This time there are no contradictions.
5. It prints succesfully.

This is a proccess that, by the way, would not exist in a truly procedural language. A procedural program has no concept of backtracking. That is, it has no *or*. It's as if only *and* is used.

It's because this is a logic language that we must ensure our program works correctly.

## Limitations

This brings us to the well-known limitations of LP.

1. Infinite loops

Let's consider,

```
rel p(x)
    p(x)

p(x)
```

The program will call p(x), which will call p(x). This is an example of recursion. This is an example of an infinite loop, as the program will run forever.

The problem with this is that even correct logical problems may fall into an infinite loop.

1. Performance

## A Counterpoint

A possible counterpoint is that-- every language has the same problem, that is, they too can fall into infinite loops.

Couple that with the fact this occurs when you're doing recursion. Generally, if your program relies on a relation calling itself it's pretty obvious that it's doing so, and you have a hint that you should be looking out for such things.

The second point is a result of combining a query solver with a programming language. If you simply want the solver to answer a query, does it matter if it takes a few seconds (or less) longer? If you want to use it as a fast programming language, shouldn't

The programmer then wants to instead use it as a blazing fast programming language, while at the same time expecting it to be fast without doing any work on optimizing it- which is not how it works in any language.

Even if it's not ideal, knowing how the program works is often necessary to optimize it in any language.

### 2C. Operators

## Operators

Adding to our repertoire, we have *if* and *not*.

Logically speaking, this lets us represents all kinds of statements in the form,

`If X, then Y.` `not X.`

Which are common in logic and show up in practical programming.

```If it's raining, then someone will bring an umbrella. If someone is a human, they're mortal. (aka All humans are mortals) It's not raining.

```

_if_
--
```

if(true) print('condition is true') else print('condition is not true')

```

We may again open the interpreter to try if-statements.
```

$ cosmos -i

> if(x!=1) x=2; | x=2 if(x!=1) x=2 or x=1; | x=2 | x=1 if(x!=1) x=2; | x=2 ```

The body of the if-stm will be evaluated when the condition, e.g. x=1, is true.

```
> if(false) x=2 else x=1;
| x=1
> if(x=1) x=1 else x=0;
| x=1
| x=0
```

It's possible for an if-statement to have an else-clause. If the condition is true, the if-part holds, otherwise the else-part holds.

In the latter example, the interpreter tried out both possibilities and gave two answers.

## *elseif*

```
if(x=1)
    y=2
elseif(x=1)
    y=2
else
    true
```

Naturally, this is just a way to write,

*Logical interpretation*

You may think of an if-statement as equivalent to,

if(A) B else C; <==> (A and B) or (not A and C)

An if-statement without else is,

if(A) B; <==> (not A) or B

Though this may not be its exact implementation.

## *not*

```
> not x=2
| x!=2
> not 5<1
| x=1
| x=0
> not x<=2
| x>2
```

As you may have noted, *not* simply negates a statement.

*Logical interpretation*

The negation of A is simply false when A holds, and true when A doesn't.

## Complex Conditionals

We recommend keeping the conditions for an *if* or *not* to simple arithmetics.

It's easy to see that *not x=1* is the same as *x=1*. Similarly, *not x>5* is just *x<=5*.

If a condition is too complex for our if-statement, an error will be given. You may try re-working your code or using an alternative conditional.

Finally, you may fall back from logic programming entirely and use *functions*.

Negation is actually more complicated to implement than it looks like, at least in a logic language. If you're interested in the details, see the implementation section - Logic-Procedural (II).

## Logic-Procedural (II)

We have not settled the mechanics for *if* (and *not*) completely. The only requirements are that,

- It's a logically sound conditional.
- If it can't do that, an error is given.

The reason for this is that we want to allow for different optimizations and ways to implement a logical conditional/negation to be tried.

For us, being able to use a sound conditional is already an improvement. Prolog famously implemented negation in an unsound way (that also gave no warnings whatsoever).This

This has highly limited experimentation with logic programming, as two operators were rendered mostly unusable.

For relations that require a specific implementation, we use the *when* operator. The *when* is simply syntax for and/or,

when(A) B else C <==> (A and B) or (C)

As you see, this is a rather barebones conditional. It evaluates to and/or, and is therefore pure code. However, the *else* is redundant, as the condition is not used. A further analysis will show that *when* will get caught in an infinite loop in many times where *if* doesn't, although it will work for the first answer.

You may use it to implement your own conditional, as long as you write out the negation,

when(x=2) true else x!=2

Furthermore, it can be easily switched with other conditionals as they share similar keywords.

## Functions

If it really is such a problem, a simple solution is to fall back into functions. A relation can be turned into a function by changing the `rel` to a `fun` keyword.

```
fun q(x,y)
    if(p(x))
        y=2
    else
        y=1
```

As functions have simple requirements when compared to full relations, an *if* or *when* will accept any conditions when inside a function[1].

Because a function is only meant to run once, there is no need to support backtracking or any other logical mechanisms.

This may mean we're abandoning relational programming (LP) for a moment, though this is restricted to *q*.

We'll explain this further in a later section.

[1] The semantics of *if* or *when* will be turned into that of a *commited-choice* conditional. This is also the *choose* operator in Cosmos.

## List of Conditionals (Summary)

if: guaranteed to be logically sound, gives error if the condition is too complex. when: simple conversion to and/or. Even if it fulfills the condition and goes to if-code, it may still backtrack to else-code. Works for any condition. choose: simply checks if the condition is true, then chooses if or else-code. It'll not backtrack, but then this may not be logically sound.

We recommend sticking to *if* when possible.

*if* works best with simple conditions, i.e. simple inequalities such as!= or >=.

## A Conditional in Formal Logic

This is just trivia, but it may be of interest to some that the actual conditional *A->B* in formal logic does not have an *else*.

It's simply something adopted from procedural programming where we often specify what to do if a condition is not true. This has often been adopted by LP aswell.[1]

`If it's raining, then I will fly.`

An odd thing about the formal conditional is that it holds true when the condition is false. As we said before, `if(A) B; <==> (not A) or B`.

This is actually rather arbitrary! The implication is that if we confirm that it did not rain, then this odd implication is true.

Perhaps we'd rather say: "you would not fly anyway!"

That would maybe render the implication false.

What about an implication that is always false when the condition is false? This would be arbitrary aswell.

Though this may be a moot point, we may conclude the formal implication is not the same as the implication we use in natural language.

There is no justification given for any of this.[2] It was simply deemed useful to take a conditional as true when we can't say otherwise.

It's useful in our programs to say,

`If the switch is set, our program will beep.`

And, if the condition doesn't hold, simply go on with our program. We're going by the assumption that our machinery is correct.

[1] See reif or `(->;)`. [2] One may consult the *Principia Mathematica* for a definition and explanation of the logical implication and see that, once again, it's an arbitrary definition.

## Whitespace

It's about time we explained our use of whitespace and indendation.

Any major "structure" such as rel and if are delimited by an increase in whitespace (generally, comprised of four spaces or a single tab character).

```
if(true)
    false
else
    false
```

The code that comprises the if- and else-parts are evident through this method.

An error is issued if there's any inconsistency. For example, if you chose the first indent to be four spaces but the second to be three.

As long as you make a consistent rule, i.e. four spaces or one tab-only, there should be no issues.

Syntax-wise, whitespace only adds *ands* to the end of lines (unless a keyword like *else* or *case* pops up) and ends any unindent with a *semicolon*.

As such, the semantics of whitespace are very easy to understand.

Coming from a procedural language, it may seem odd that a semicolon is used to end a structure.

Still, this is in line with the syntax of most LP language.

### 2D. Data

## Functors

We start with a declaration.

```
functor(F, Functor)
```

By using the special relation *functor*, we declare that *F* is a functor, or rather, it's what will be used to make functors. We can now make functors with the name/label *F*.

```
F(1, 2) = F(1, a)
print(a) //2
```

Functors are a kind of composite data. They are what some languages call a *tuple*.

If 1 or 'hello' is a single value, F(1,'hello') is a value made from combining both.

We made two functors. Since they are equal to each other, we can also conclude that its values are. Hence, `a=2`.

## A Practical Example

Let's say we want to represent a person in our program. We could just make a functor `Person`.

```
functor(Person, Functor)
```

We can now make our first person.

```
bob = Person('bob', 23)
```

We have made the convention that the first two fields of `Person` stand for name and age, though if needed we could have included more fields. This allows us to make programs about one or more persons!

This is not the only way we could represent a person, of course. Cosmos™ has *objects* aswell, which are very similar in that sense! We'll cover them later.

## Tuple

If we simply to group things together, any functor is enough. We may use a *F* or *Tuple* functor for this.

```
> Tuple(x,1) = Tuple('x', y)
| x='x' and y=1
```

## Lists

A list is another kind of composite data. Let's say we want a list of things. This can easily be done with the syntax,

```
l = [1, 2, 3]
```

We've made a list with the values 1, 2 and 3.

There are operations we can make on lists. We can add, subtract or search for elements within it. These can be found in module list.

```
l2 = list.push(l, 55)
io.writeln(l)  //[1, 2, 3]
io.writeln(l2) //[1, 2, 3, 55]
```

If we *push* value 55 into l, we'll get a new list l2 with elements.

```
l = [1,2,3]
list.first(l, head) //head is 1
list.rest(l, tail) //tail is [2, 3]
l=[head|tail]
```

A common operation is to get the *first* element in a list, or the *rest*- the remaining, which itself is a new list. These are sometimes called the head and tail of a list.

This is a common pattern in declarative programming, and as such there's even a special syntax for it.

l=[head|tail]

The term [x|y] is very different from [x,y]- the latter is a list with two elements. The former is any list.

## Lists as Functors

Lists are often implemented in terms of the functor Cons. These lists are identical:

```
l = [1, 2]
l = Cons(1, Cons(2, Cons))
```

### 2E. Modes

## Functions [Incomplete]

*"A function is a less general kind of relation." - The Cosmos Programming Language*

While a relation may give multiple answers-- or no answer at all (in which case the statement is taken to be *false*), a function is guaranteed to only give one.[1]

[1] A function here is meant to mimic a typical *programming function* that you often see in procedural or functional languages. It's not necessarily a mathematical function. For example, it may accept more than one input.

## A Factorial Function

There's no clear rule on what should or shouldn't be a function.

We'll take *factorial* as a good case.

- It's often a function in mathematics.
- It may run multiple times. As such, it often benefits from whatever optimizations we may give it.
- You don't usually need anything more than simply getting its result.

```
fun fact(x,y)
    if(x=0)
        y=1
    else
        y=x*fact(num(x-1))
```

## A Main Function

### 3. A "Prolog" tutorial

A common way to introduce logical languages is by emphasizing its relation to logic. Although it's not very practical, it's as good as any tutorial or introduction nonetheless.

Let's make it clear that,

- A program is a set of relations.
- These relations are then *queried*.

```
rel human(x)
    x='socrates'

rel mortal(x)
    human(x)
```

## Possible worlds

```
t={
    rel human(x)
        x='socrates'

    rel mortal(x)
        human(x)
}
```

### 3A. Paradigms

Typically, programming is divided into four main paradigms,

- Procedural (imperative)
- Functional
- Logic -- Logic-procedural (?!)
- Object-oriented

Although this classification is increasingly dated, it's still used (and somewhat useful) to this day.

## Logic

```
x=double(1)
y=x
print(y)
```

In the logic paradigm, or logic programming (LP), which we follow to the letter, as our language *is* in fact a logic programming language, this is simply a set of statements.

- The double of 1 is x.
- The variable of y equals x.
- The value of y is written on the screen.

It's easy to see by looking at the program that this applies. We may simply look at the program and see that x equals the result of a function *double*, y is x, and the value is written (which we know the statement *print* does).

We only have to take a moment to conclude that 2 will be written if we run the program, and it is.

```
2
```

## Procedural

If a paradigm is a way to look at a given program, the procedural paradigm looks at it *imperatively.* A program is a recipe, or list of instructions to be executed by the computer.

This paradigm follows the computer program closely. It's the closest to how the computer actually acts.

The following instructions would be executed.

1. A procedure or command *double* computes the double of 1.
2. This value is given to x. A variable in the procedural paradigm is like a slot. In fact, it's a slot of *computer memory* and occupies a space in the computer.
3. The value in x is then assigned to the slot y.
4. The command to write the statement on the screen, *print*, is given.

The difference so far is subtle, and you could take it as a procedural program as-is. In fact, our language highly resembles procedural languages in syntax.

This is on purpose, the language is made so that it can be reasoned or written in this style to some extent.

## Logic-Procedural

Though you may often simply see the program as a series of statements in the logic paradigm, it's sometimes needed to know how the computer executes them.

After all, the program runs in a computer.

We'll call this the "Logic-Procedural" paradigm (though it's a made-up term we invented). The Logic-Procedural interpretation of a program is given by how our procedural logic engine executes the logic program.

Often, the only reason we need to know this is so our program has good performance. An efficient program will run as quickly as it can and not consume many *memory slots*.

## Limitations

## Styles

A lot of this may be better off understood as styles.

### 3B. Pure Logic Programming

Most important for our language is the notion of a pure logic program.

Logic programs allow us to effectively write logical statements and have the language work them out correctly.

## Writing pure relations

- Any relation made of pure relations and operators is pure.
- =, and, or, if and regular arithmetic are pure.

Knowing you have written a pure relation is quite simple.

All you have to do is use pure relations! Then, your relation is also pure.

### 4B. Optimizations

## *if*

Because it's the language's main conditional, any number of optimizations may be applied to it as long as it keeps its properties as a conditional (while the operator *when* is kept for fine-tuning; if you want a minimal conditional to which you can apply your own optimizations).

Currently,

- Any condition is negated.

## *when* and *choose*

*when* is a sound but more barebones conditional. Implementing a pure factorial relation in *when* makes for a good case study.

*when* is a pure conditional. Still, since it requires you to manually negate the condition (which is redundant otherwise) and may not provide future optimizations, unless you implement them yourself, it's less preferred and not the default go-to for conditionals.

Remember that relations may *backtrack* or yield more than one solution. Even if a factorial relation succeeds the first time, an ill-defined program may cause on the second solution.

Let's compare this to,

rel fact(x,y) when(x=0) y=1 else y=x*fact(num(x-1))

... or...

```
(x=0 and y=1) or (y=x*fact(num(x-1)))
```

While fact(1,x) would still work, it would for the first solution alone. Remember that relations may *backtrack* or yield more than one solution.

This would suffice were it a regular imperative or functional definition of factorial, since those are meant to run only once and never backtrack.

However, this is not so for a logical language and different reasoning is needed. If it ever tries to find a second solution, it will procceed to the second clause. The reader is invited to keep this in mind and accompany the execution of fact(1,x).

rel fact2(x,y) when(x=0) y=1 else x>0 y=x*fact2(num(x-1))

As you see, we have,

- Manually negated x=0, by typing x>0.

The program now works soundly, even if it's not perfect! It still creates places to backtrack or *choice points*. This consumes memory, moreso if we call *when* a lot of times. But at least these are eliminated upon hitting x>0.

==

What then if we simply removed backtracking?

*choose* is a non-logical conditional that doesn't backtrack.

As such, it's fit for code with side-effects. A simple prompt, for example.

rel prompt() print('type a number') io.write('> ') io.read(x) choose(x='5') print('You typed 5!') else print('You didn't type 5!?') prompt()

Such code is non-logical in the first place- and has no need for backtracking.

The safest option is still to rely on *if*. It should never be unsafe to use *if*. For cases it can't be used, you'll invariably be given a warning or error at least. However, *choose* and *when* are available if you're aware of the limitations.

## *TCO* (Tail-Call Optimization)
