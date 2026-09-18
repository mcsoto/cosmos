:- style_check(-singleton).
cosmos_test4__q(_x) :- _x = 2.0, print("q").
cosmos_test4__q3(_x, _f) :- print("q2"), writeln(_f), cosmos_test4__q(2.0), call_cl(_f, [2.0]).
cosmos_test4__value_q(V1, _upvals) :- cosmos_test4__q(V1).
cosmos_test4__value_q3(V1, V2, _upvals) :- cosmos_test4__q3(V1, V2).
test4(_) :- print(clos(upvals, cosmos_test4__value_q)), cosmos_test4__q(2.0), cosmos_test4__q3(_x, clos(upvals, cosmos_test4__value_q)).
