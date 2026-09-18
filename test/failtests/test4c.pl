:- style_check(-singleton).
cosmos_test4c__q(_x, _q) :- print(_x), print(clos(upvals, cosmos_test4c__value_q)), {_x < 2}, r_sub(_x, 1, T1), cosmos_test4c__q(T1, _q).
cosmos_test4c__q3(_x, _f) :- print("q2"), writeln(_f), cosmos_test4c__q(2, _q), call_cl(_f, [2]).
cosmos_test4c__value_q(V1, _upvals) :- cosmos_test4c__q(V1, C1).
cosmos_test4c__value_q3(V1, V2, _upvals) :- cosmos_test4c__q3(V1, V2).
test4c(_) :- print(clos(upvals, cosmos_test4c__value_q)), cosmos_test4c__q(3, _q), cosmos_test4c__q3(_x, clos(upvals, cosmos_test4c__value_q)).
