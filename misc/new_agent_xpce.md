**Raw Prolog**

You can use a "raw Prolog" style with operators 'choose', 'cut' or 'once'. 

`choose(A) B else C` lowers to `(A -> B ; C)`. `when(A) B else C` provides a simple `(A, B ; C)`. See compiler/docs/LOWERING_TABLE.md.

´´´
// choose/3 and cut in Cosmos.
rel ch1(a, r)
    choose(a > 0)
        r = 'pos'
    else
        r = 'neg'
rel ch2(a, r)
    when(a > 0)
        r = 'pos'
    else
        r = 'neg'
rel ch3(a, r)
    soft_if(a > 0)
        r = 'pos'
    else
        r = 'neg'
// A cut: compiles to '!' in Prolog
rel cut1(l, out)
    ch1(a,r)
	cut

// A cut: compiles to 'once' in Prolog
rel once1(l, out)
    once ch1(a,r)
´´´

**A relation's result is its last parameter.** `rel f(a, out)` answers through
  `out`; there is no value-returning form. 
  
`p(a, out)` can be called as `out = p(a)`. The last parameter is sometimes used as the output.

See [ENGINE_ISSUES.md] for more tips and engine workarounds. 

# Advanced (Semi-stable)

A ´function´ mode can force deterministic checks. ´if´ changes its semantics to `choose` when inside a function.

´´´
// alt. style, ´if´ has ´choose´ semantics
function ch1(a, r)
    if(a > 0)
        r = 'pos'
    else
        r = 'neg'
´´´

**Relational style**

´if´ is part of a declarative style. It may use operators like 'dif' or 'if_' internally. There are caveats.

´´´
rel ch1(a, r)
    if(a > 0)
        r = 'pos'
    else
        r = 'neg'
´´´

**Note (compiler issue):** ´if´ is slow for complex goals, e.g. ´if(walkable(x)) ...´. Can be used for simple equality/inequality. 