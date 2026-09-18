:- style_check(-singleton).
cosmos_test0_1__main() :- _dir = "right", cosmos_test0_1__loop_1(_dir, T2).
cosmos_test0_1__value_main(_upvals) :- cosmos_test0_1__main().
'test0-1'(_) :- cosmos_test0_1__main().
cosmos_test0_1__loop_2(C1, F1) :- true, (true -> (N1 = "right", print(C1), false), cosmos_test0_1__loop_2(N1, F1) ; F1 = C1).
cosmos_test0_1__loop_1(C1, F1) :- true, (true -> (print(C1), N1 = "left", print(N1), cosmos_test0_1__loop_2(T1, C1), false, true), cosmos_test0_1__loop_1(N1, F1) ; F1 = C1).
