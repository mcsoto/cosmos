:- style_check(-singleton).
cosmos_tictactoe__pause() :- print("> "), ioread(_x).
cosmos_tictactoe__set(_o, _o2, _x, _y, _e, _set_) :- r_mul(_y, 3.0, T1), add_(_x, T1, T2), _i = T2, call_cl(_set_, [_o, _i, _e, _o2]).
cosmos_tictactoe__get(_o, _x, _y, _e) :- r_mul(_y, 3.0, T3), add_(_x, T3, T4), _i = T4, getnil(_o, _i, T5), _e = T5.
cosmos_tictactoe__empty(_board, _x, _y) :- cosmos_tictactoe__get(_board, _x, _y, " ").
cosmos_tictactoe__win_col(_board, _piece, _range) :- call_cl(_range, [0.0, 2.0, T6]), cosmos_iter_start(T6, T7), cosmos_tictactoe__some_1(T7, _board, _piece).
cosmos_tictactoe__draw(_board) :- _i = 0.0, cosmos_tictactoe__loop_1(_i, T12, _board, _tile).
cosmos_tictactoe__win(_board, _piece, _debug, _range) :- (call_cl(_range, [0.0, 2.0, T15]), cosmos_iter_start(T15, T16), cosmos_tictactoe__some_2(T16, _board, _debug, _piece) ; call_cl(_range, [0.0, 2.0, T18]), cosmos_iter_start(T18, T19), cosmos_tictactoe__some_3(T19, _board, _debug, _piece) ; call_cl(_range, [0.0, 2.0, T20]), Collection1 = T20, cosmos_iter_start(Collection1, Iterator2), cosmos_tictactoe__loop_3(Iterator2, _, _board, _debug, _line, _piece) ; cosmos_tictactoe__get(_board, 2.0, 0.0, _piece), cosmos_tictactoe__get(_board, 1.0, 1.0, _piece), cosmos_tictactoe__get(_board, 0.0, 2.0, _piece)), dif(_piece, " ").
cosmos_tictactoe__full(_board) :- Collection7 = _board, cosmos_iter_start(Collection7, Iterator8), cosmos_tictactoe__loop_4(Iterator8, _).
cosmos_tictactoe__move(_board, _p, _board2, _set_) :- getnil(_p, "ai", T22), call_cl(T22, [_board, _x, _y]), getnil(_p, "piece", T23), cosmos_tictactoe__set(_board, _board2, _x, _y, T23, _set_).
cosmos_tictactoe__wait() :- print("> "), default_lib("io", _io), getnil(_io, "read", T24), call_cl(T24, [_x]), (_x = "halt" -> halt() ; true).
cosmos_tictactoe__game(_board, _p1, _p2, _turn, _debug, _range, _set_) :- (cosmos_tictactoe__win(_board, "X", _debug, _range) -> default_lib("io", _io), getnil(_io, "writeln", T32), call_cl(T32, ["X won!"]) ; (cosmos_tictactoe__win(_board, "O", _debug, _range) -> default_lib("io", _io), getnil(_io, "writeln", T31), call_cl(T31, ["O won!"]) ; (cosmos_tictactoe__full(_board) -> default_lib("io", _io), getnil(_io, "writeln", T30), call_cl(T30, ["Draw!"]) ; default_lib("io", _io), getnil(_io, "writeln", T25), call_cl(T25, [""]), add_("turn ", _turn, T26), str(T26, T27), default_lib("io", _io), getnil(_io, "writeln", T28), call_cl(T28, [T27]), once((cosmos_tictactoe__move(_board, _p1, _board2, _set_))), cosmos_tictactoe__draw(_board2), add_(_turn, 1.0, T29), cosmos_tictactoe__game(_board2, _p2, _p1, T29, _debug, _range, _set_)))).
cosmos_tictactoe__leftmost(_x) :- (_x = 0.0 ; _x = 1.0 ; _x = 2.0).
cosmos_tictactoe___player(_board, _x, _y) :- print("> input line:"), default_lib("io", _io), getnil(_io, "read", T34), call_cl(T34, [T33]), default_lib("math", _math), getnil(_math, "stringToNumber", T36), call_cl(T36, [T33, T35]), r_sub(T35, 1.0, T37), _y = T37, print("> input column:"), default_lib("io", _io), getnil(_io, "read", T39), call_cl(T39, [T38]), default_lib("math", _math), getnil(_math, "stringToNumber", T41), call_cl(T41, [T38, T40]), r_sub(T40, 1.0, T42), _x = T42, (\+(cosmos_tictactoe__empty(_board, _x, _y)) -> throw("invalid move") ; true).
cosmos_tictactoe___default(_board, _x, _y) :- cosmos_tictactoe__leftmost(_x), cosmos_tictactoe__leftmost(_y), cosmos_tictactoe__empty(_board, _x, _y).
cosmos_tictactoe___random(_board, _x, _y) :- default_lib("math", _math), getnil(_math, "random", T43), call_cl(T43, [0.0, 2.0, _x]), default_lib("math", _math), getnil(_math, "random", T44), call_cl(T44, [0.0, 2.0, _y]), cosmos_tictactoe__empty(_board, _x, _y).
cosmos_tictactoe__main() :- true.
cosmos_tictactoe__value_pause(_upvals) :- cosmos_tictactoe__pause().
cosmos_tictactoe__value_set(V1, V2, V3, V4, V5, _upvals) :- cosmos_tictactoe__set(V1, V2, V3, V4, V5, C1).
cosmos_tictactoe__value_get(V1, V2, V3, V4, _upvals) :- cosmos_tictactoe__get(V1, V2, V3, V4).
cosmos_tictactoe__value_empty(V1, V2, V3, _upvals) :- cosmos_tictactoe__empty(V1, V2, V3).
cosmos_tictactoe__value_win_col(V1, V2, _upvals) :- cosmos_tictactoe__win_col(V1, V2, C1).
cosmos_tictactoe__value_draw(V1, _upvals) :- cosmos_tictactoe__draw(V1).
cosmos_tictactoe__value_win(V1, V2, _upvals) :- cosmos_tictactoe__win(V1, V2, C1, C2).
cosmos_tictactoe__value_full(V1, _upvals) :- cosmos_tictactoe__full(V1).
cosmos_tictactoe__value_move(V1, V2, V3, _upvals) :- cosmos_tictactoe__move(V1, V2, V3, C1).
cosmos_tictactoe__value_wait(_upvals) :- cosmos_tictactoe__wait().
cosmos_tictactoe__value_game(V1, V2, V3, V4, _upvals) :- cosmos_tictactoe__game(V1, V2, V3, V4, C1, C2, C3).
cosmos_tictactoe__value_leftmost(V1, _upvals) :- cosmos_tictactoe__leftmost(V1).
cosmos_tictactoe__value__player(V1, V2, V3, _upvals) :- cosmos_tictactoe___player(V1, V2, V3).
cosmos_tictactoe__value__default(V1, V2, V3, _upvals) :- cosmos_tictactoe___default(V1, V2, V3).
cosmos_tictactoe__value__random(V1, V2, V3, _upvals) :- cosmos_tictactoe___random(V1, V2, V3).
cosmos_tictactoe__value_main(_upvals) :- cosmos_tictactoe__main().
tictactoe(_) :- crequire("io", _io, _), crequire("table", _table, _), crequire("list", _list, _), crequire("math", _math, _), _debug = clos(upvals, cosmos_tictactoe__closure_1), default_lib("math", _math), getnil(_math, "range", T45), _range = T45, new(T46), set_(T46, 0.0, " ", T47), set_(T47, 1.0, " ", T48), set_(T48, 2.0, " ", T49), set_(T49, 3.0, " ", T50), set_(T50, 4.0, " ", T51), set_(T51, 5.0, " ", T52), set_(T52, 6.0, " ", T53), set_(T53, 7.0, " ", T54), set_(T54, 8.0, " ", T55), __board = T55, default_lib("table", _table), getnil(_table, "set", T56), _set_ = T56, default_lib("io", _io), getnil(_io, "write", T57), _write = T57, new(T58), set_(T58, "piece", "X", T59), set_(T59, "ai", clos(upvals, cosmos_tictactoe__value__default), T60), _p1 = T60, new(T61), set_(T61, "piece", "O", T62), set_(T62, "ai", clos(upvals, cosmos_tictactoe__value__default), T63), _p2 = T63, _board = __board, call_cl(_debug, [_board]), call_cl(_debug, ["-draw"]), cosmos_tictactoe__game(_board, _p1, _p2, 1.0, _debug, _range, _set_), crequire("object", _Object, _), _p = _p1, getnil(_Object, "create", T65), call_cl(T65, [_p, T64]), _o = T64, print(_o).
cosmos_tictactoe__some_1(I, K1, K2) :- cosmos_iter_next(I, I2, K, V, S), S = 1.0, ((cosmos_tictactoe__get(K1, 0.0, V, K2)) ; cosmos_tictactoe__some_1(I2, K1, K2)).
cosmos_tictactoe__loop_2(C1, F1, K1, K2) :- true, ({C1 < 3.0} -> (cosmos_tictactoe__get(K1, C1, K2, T8), _tile = T8, write(_tile), write("|"), add_(C1, 1.0, T9), N1 = T9), cosmos_tictactoe__loop_2(N1, F1, K1, K2) ; F1 = C1).
cosmos_tictactoe__loop_1(C1, F1, K1, K2) :- true, ({C1 < 3.0} -> (_j = 0.0, write("|"), cosmos_tictactoe__loop_2(_j, T10, K1, C1), write("\n"), add_(C1, 1.0, T11), N1 = T11), cosmos_tictactoe__loop_1(N1, F1, K1, K2) ; F1 = C1).
cosmos_tictactoe__some_2(I, K1, K2, K3) :- cosmos_iter_next(I, I2, K, V, S), S = 1.0, ((add_("col", V, T13), call_cl(K2, [T13]), cosmos_tictactoe__get(K1, 0.0, V, K3), cosmos_tictactoe__get(K1, 1.0, V, K3), cosmos_tictactoe__get(K1, 2.0, V, K3), add_("piece", K3, T14), call_cl(K2, [T14])) ; cosmos_tictactoe__some_2(I2, K1, K2, K3)).
cosmos_tictactoe__some_3(I, K1, K2, K3) :- cosmos_iter_next(I, I2, K, V, S), S = 1.0, ((add_("line", V, T17), call_cl(K2, [T17]), cosmos_tictactoe__get(K1, V, 0.0, K3), cosmos_tictactoe__get(K1, V, 1.0, K3), cosmos_tictactoe__get(K1, V, 2.0, K3), call_cl(K2, [K3])) ; cosmos_tictactoe__some_3(I2, K1, K2, K3)).
cosmos_tictactoe__loop_3(C1, F1, K1, K2, K3, K4) :- cosmos_iter_next(C1, IterNext3, _, IterValue5, IterStatus6), ((IterStatus6 = 1.0), (add_("line", K3, T21), call_cl(K2, [T21]), cosmos_tictactoe__get(K1, IterValue5, IterValue5, K4), call_cl(K2, [K4]), N1 = IterNext3), cosmos_tictactoe__loop_3(N1, F1, K1, K2, K3, K4) ; (dif(IterStatus6, 1.0)), F1 = C1).
cosmos_tictactoe__loop_4(C1, F1) :- cosmos_iter_next(C1, IterNext9, _, IterValue11, IterStatus12), ((IterStatus12 = 1.0), (dif(IterValue11, " "), N1 = IterNext9), cosmos_tictactoe__loop_4(N1, F1) ; (dif(IterStatus12, 1.0)), F1 = C1).
cosmos_tictactoe__closure_1(_x, _upvals) :- _upvals = upvals, true.
