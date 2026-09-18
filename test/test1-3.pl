:- style_check(-singleton).
'test1-3'(_) :- _x = 0, cosmos_test1_3__loop_1(_x, T1), print(T1).
cosmos_test1_3__loop_1(C1, F1) :- true, ((C1 = 0), (N1 = 5, print(C1)), cosmos_test1_3__loop_1(N1, F1) ; (dif(C1, 0)), F1 = C1).
