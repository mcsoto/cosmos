:- style_check(-singleton).
'test1-1'(_) :- _x = 0, cosmos_test1_1__loop_1(_x, T1).
cosmos_test1_1__loop_1(C1, F1) :- true, ((true), (N1 = 2, C1 = 0, true), cosmos_test1_1__loop_1(N1, F1) ; (false), F1 = C1).
