:- style_check(-singleton).
cosmos_goto__succ(_x, _y) :- (add_(_x, 1, T1), _y = T1 ; add_(_x, 1, T2), cosmos_goto__succ(T2, T3), _y = T3).
cosmos_goto__nat(_x) :- cosmos_goto__succ(0, _x).
cosmos_goto__is_int(_x) :- {T4 = -1}, cosmos_goto__succ(T4, _x).
cosmos_goto__push(_e, _e2, _x) :- _x = fc_Block(_a,_b), default_lib("table", _table), getnil(_table, "set", T5), call_cl(T5, [_e, _a, _b, _e2]).
cosmos_goto__run_c(_c, _e, _e2) :- if_(_c = [_c1|_l2], (cosmos_goto__run_c(_c1, _e, _e1), cosmos_goto__run_c(_l2, _e1, _e2)), (if_(_c = [], (_e = _e2), (if_(_c = fc_Eq(_a,_b), (cosmos_goto__push(_e, _e2, fc_Block(_a,_b))), (((call_cl(_JMP_LE, [_a, _b, _c, T6] ), _c = T6), ({_b < _c}) ; (\+(call_cl(_JMP_LE, [_a, _b, _c, T7] ), _c = T7)), (print(_c), call_cl(_throw, ["incorrect command"]))))))))).
cosmos_goto__run(_c, _e, _e2) :- if_(_c = [_c1|_l2], (cosmos_goto__run(_c1, _e, _e1), cosmos_goto__run(_l2, _e1, _e2)), (if_(_c = [], (_e = _e2), (if_(_c = fc_Label(_a,_b), (cosmos_goto__run_c(_b, _e, _e2)), (if_(_c = fc_Eq(_a,_b), (true), (print(_c), call_cl(_throw, ["incorrect statement"]))))))))).
cosmos_goto__value_succ(V1, V2, _upvals) :- cosmos_goto__succ(V1, V2).
cosmos_goto__value_nat(V1, _upvals) :- cosmos_goto__nat(V1).
cosmos_goto__value_is_int(V1, _upvals) :- cosmos_goto__is_int(V1).
cosmos_goto__value_push(V1, V2, V3, _upvals) :- cosmos_goto__push(V1, V2, V3).
cosmos_goto__value_run_c(V1, V2, V3, _upvals) :- cosmos_goto__run_c(V1, V2, V3).
cosmos_goto__value_run(V1, V2, V3, _upvals) :- cosmos_goto__run(V1, V2, V3).
goto(_) :- crequire("table", _table, _), _list1 = [fc_Label(1,[fc_Eq(_y,2)|[fc_Eq(_y,1)|[]]])|[]], new(T8), _nil = T8, cosmos_goto__is_int(_y), dif(_y, 0), dif(_y, 1), cosmos_goto__run(_list1, _nil, _e), print(_e).
