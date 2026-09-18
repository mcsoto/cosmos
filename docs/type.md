#Type definitions

concat
string
list
table

Numbers have unique `-`, `*`, `/`, and `%` operations.

## Generic addition

`+` is generic concatenation/addition. It accepts operands of any type and
its static result type is `Any`. The compiler always lowers `A + B` to
`add_(A, B, Result)`; the runtime selects the operation after values are
available:

- numbers: numeric addition;
- strings: concatenation, with number-to-string conversion;
- lists: list concatenation;
- tables: the table `update` operation (from its metatable).

Unknown operands are valid and may resolve later through delayed runtime
evaluation. Type checking must not reject a `+` expression merely because an
operand is unbound, mixed, or a table.

Collections have:
#	size
+ concat
[] get (deprecated:at?)
And keywords:
x in l -> has(l,x)
In addition:
#
Tables can overload with setmeta(''). #todo #so far only iterator-based some/for

These may be decided by runtime, even with delay of arguments (freeze/2).

string.get(s, i, c)//string.at(s, i, c)
s[i]=c

list.has(l, x)
x in l

string
list
table? l.x contain [at:i]
- t.has(value), t.hasKey

| `X = #A` | generic size | `size_(A, T), X = T` |

# Modes

rel(InOut, InOut)
function(In, In..., Out) -- todo: last argument is Out in a conservative reading, consider conservative InOut only for last-parameter?

#

get(In,In,Out) det
t[x]=y
In, Out, Out
multi

nonfail
once(semidet)=>det

rel leftmost(x)
	x=0 or x=1 or x=2

rel _default(board,x,y)
	leftmost(x) and leftmost(y)
	//x>=0 and y>=0
	//x<=2 and y<=2
	empty(board,x,y)
