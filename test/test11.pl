:- style_check(-singleton).
cosmos_test11__each2(_l, _p) :- (_l = [] ; _l = [_e|[_e2|_l2]], cosmos_test11__each2(_l2, _p)).
cosmos_test11__value_each2(V1, V2, _upvals) :- cosmos_test11__each2(V1, V2).
test11(_) :- true.
