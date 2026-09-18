:- style_check(-singleton).
cosmos_lexor__debug(_s) :- true.
cosmos_lexor__digit(_c) :- default_lib("string", _string), getnil(_string, "lessOrEqual", T1), call_cl(T1, [_c, "9"]), default_lib("string", _string), getnil(_string, "lessOrEqual", T2), call_cl(T2, ["0", _c]).
cosmos_lexor__letter(_c) :- (default_lib("string", _string), getnil(_string, "lessOrEqual", T3), call_cl(T3, [_c, "z"]), default_lib("string", _string), getnil(_string, "lessOrEqual", T4), call_cl(T4, ["a", _c]) ; default_lib("string", _string), getnil(_string, "lessOrEqual", T5), call_cl(T5, [_c, "Z"]), default_lib("string", _string), getnil(_string, "lessOrEqual", T6), call_cl(T6, ["A", _c])).
cosmos_lexor__letter2(_c) :- (default_lib("string", _string), getnil(_string, "lessOrEqual", T7), call_cl(T7, [_c, "z"]), default_lib("string", _string), getnil(_string, "lessOrEqual", T8), call_cl(T8, ["a", _c]) ; default_lib("string", _string), getnil(_string, "lessOrEqual", T9), call_cl(T9, [_c, "Z"]), default_lib("string", _string), getnil(_string, "lessOrEqual", T10), call_cl(T10, ["A", _c]) ; _c = "_").
cosmos_lexor__single_quote(_c) :- default_lib("string", _string), getnil(_string, "code", T11), call_cl(T11, [_c, 39.0]), default_lib("string", _string), getnil(_string, "code", T12), call_cl(T12, [_c, 39.0]).
cosmos_lexor__double_quote(_c) :- _c = "\"".
cosmos_lexor__quote(_c) :- (cosmos_lexor__single_quote(_c) ; cosmos_lexor__double_quote(_c)).
cosmos_lexor__endline(_c) :- _c = "\n".
cosmos_lexor__slash(_c) :- default_lib("string", _string), getnil(_string, "code", T13), call_cl(T13, [_c, 92.0]).
cosmos_lexor__newline(_c) :- default_lib("string", _string), getnil(_string, "code", T14), call_cl(T14, [_c, 10.0]).
cosmos_lexor__newline2(_c) :- default_lib("string", _string), getnil(_string, "code", T15), call_cl(T15, [_c, 13.0]).
cosmos_lexor__tab(_c) :- default_lib("string", _string), getnil(_string, "code", T16), call_cl(T16, [_c, 9.0]).
cosmos_lexor__whitespace(_c) :- (_c = " " ; _c = "\t" ; _c = "\n" ; _c = "\r").
cosmos_lexor__match_rel2(_s, _i, _i2, _f) :- (true, default_lib("string", _string), getnil(_string, "at", T17), call_cl(T17, [_s, _i, _c]), call_cl(_f, [_c]), add_(_i, 1.0, T18), cosmos_lexor__match_rel2(_s, T18, _i2, _f) ; _i = _i2).
cosmos_lexor__match_some(_s, _i, _i2, _f) :- default_lib("string", _string), getnil(_string, "at", T19), call_cl(T19, [_s, _i, _c]), call_cl(_f, [_c]), add_(_i, 1.0, T20), cosmos_lexor__match_rel2(_s, T20, _i2, _f).
cosmos_lexor__match_one(_s, _i, _i2, _f) :- add_(_i, 1.0, T21), _i2 = T21, default_lib("string", _string), getnil(_string, "at", T22), call_cl(T22, [_s, _i, _c]), call_cl(_f, [_c]).
cosmos_lexor__match_any(_s, _i, _i2, _f) :- (default_lib("string", _string), getnil(_string, "at", T23), call_cl(T23, [_s, _i, _c]), call_cl(_f, [_c]), add_(_i, 1.0, T24), cosmos_lexor__match_any(_s, T24, _i2, _f) ; _i = _i2).
cosmos_lexor__match_until(_s, _i, _i2, _f) :- (default_lib("string", _string), getnil(_string, "at", T25), call_cl(T25, [_s, _i, _c]), call_cl(_f, [_c]), _i = _i2 ; add_(_i, 1.0, T26), cosmos_lexor__match_until(_s, T26, _i2, _f)).
cosmos_lexor__match_string(_s, _i, _i2, _str) :- default_lib("string", _string), getnil(_string, "size", T27), call_cl(T27, [_str, _size1]), def(_i), add_(_i, _size1, T28), _i2 = T28, default_lib("string", _string), getnil(_string, "slice", T29), call_cl(T29, [_s, _i, _i2, _str2]), def(_i2), _str2 = _str.
cosmos_lexor__match_list(_l, _s, _z) :- _l = [_head|_tail], if_(_head = _s, (_z = _s), (cosmos_lexor__match_list(_tail, _s, _z))).
cosmos_lexor__match_whitespace(_s, _i, _i2) :- cosmos_lexor__match_some(_s, _i, _i2, clos(upvals, cosmos_lexor__value_whitespace)).
cosmos_lexor__parse_double_string(_s, _i, _i2) :- default_lib("string", _string), getnil(_string, "at", T30), call_cl(T30, [_s, _i, _c]), (cosmos_lexor__double_quote(_c), _i = _i2 ; (cosmos_lexor__slash(_c), add_(_i, 2.0, T31), cosmos_lexor__parse_double_string(_s, T31, _i2) ; add_(_i, 1.0, T32), cosmos_lexor__parse_double_string(_s, T32, _i2))).
cosmos_lexor__parse_string(_s, _i, _i2) :- add_(_i, 1.0, T33), _j = T33, default_lib("string", _string), getnil(_string, "at", T34), call_cl(T34, [_s, _i, _c]), cosmos_lexor__debug(_c), (cosmos_lexor__double_quote(_c), cosmos_lexor__parse_double_string(_s, _j, _j2), add_(_j2, 1.0, T35), _i2 = T35 ; cosmos_lexor__debug("-"), cosmos_lexor__single_quote(_c), cosmos_lexor__match_until(_s, _j, _j2, clos(upvals, cosmos_lexor__value_single_quote)), add_(_j2, 1.0, T36), _i2 = T36).
cosmos_lexor__navigate_ws2(_s, _i, _i2, _line, _col, _info2) :- (default_lib("string", _string), getnil(_string, "at", T37), call_cl(T37, [_s, _i, _c]), if_(_c = "\n", (add_(_i, 1.0, T43), add_(_line, 1.0, T44), cosmos_lexor__navigate_ws2(_s, T43, _i2, T44, 1.0, _info2)), (if_(_c = "\t", (add_(_i, 1.0, T41), add_(_col, 4.0, T42), cosmos_lexor__navigate_ws2(_s, T41, _i2, _line, T42, _info2)), (if_(_c = "\r", (add_(_i, 1.0, T40), cosmos_lexor__navigate_ws2(_s, T40, _i2, _line, _col, _info2)), (cosmos_lexor__whitespace(_c), add_(_i, 1.0, T38), add_(_col, 1.0, T39), cosmos_lexor__navigate_ws2(_s, T38, _i2, _line, T39, _info2))))))) ; _i2 = _i, _info2 = fc_Info(_line,_col)).
cosmos_lexor__navigate_whitespace(_s, _i, _i2, _info, _info2) :- default_lib("string", _string), getnil(_string, "at", T45), call_cl(T45, [_s, _i, _c]), cosmos_lexor__whitespace(_c), _info = fc_Info(_line,_col), if_(_c = "\n", (add_(_i, 1.0, T47), add_(_line, 1.0, T48), cosmos_lexor__navigate_ws2(_s, T47, _i2, T48, 0.0, _info2)), (add_(_i, 1.0, T46), cosmos_lexor__navigate_ws2(_s, T46, _i2, _line, _col, _info2))).
cosmos_lexor__navigate_until_asterisk(_s, _i, _i2, _info, _info2) :- _info = fc_Info(_line,_col), default_lib("string", _string), getnil(_string, "at", T49), call_cl(T49, [_s, _i, _c]), if_(_c = "*", (_i = _i2, _info2 = _info), (if_(_c = "\n", (add_(_line, 1.0, T52), _info1 = fc_Info(T52,1.0)), (if_(_c = "\t", (add_(_col, 4.0, T51), _info1 = fc_Info(_line,T51)), (add_(_col, 1.0, T50), _info1 = fc_Info(_line,T50))))), add_(_i, 1.0, T53), cosmos_lexor__navigate_until_asterisk(_s, T53, _i2, _info1, _info2))).
cosmos_lexor__navigate_comment(_s, _i, _i2, _info, _info2) :- (cosmos_lexor__match_string(_s, _i, _x, "//"), _info2 = _info, (default_lib("string", _string), getnil(_string, "findIndex", T54), call_cl(T54, [_s, "\n", _x, _z]), _i2 = _z ; default_lib("string", _string), getnil(_string, "size", T55), call_cl(T55, [_s, _i2])) ; (default_lib("string", _string), getnil(_string, "at", T56), call_cl(T56, [_s, _i, "%"]), _info2 = _info, (default_lib("string", _string), getnil(_string, "findIndex", T57), call_cl(T57, [_s, "\n", _i, _z]), _i2 = _z ; default_lib("string", _string), getnil(_string, "size", T58), call_cl(T58, [_s, _i2])) ; cosmos_lexor__match_string(_s, _i, _x, " "))).
cosmos_lexor__parse_number(_s, _i, _i2) :- cosmos_lexor__debug("num"), (cosmos_lexor__match_some(_s, _i, _x1, clos(upvals, cosmos_lexor__value_digit)), cosmos_lexor__match_string(_s, _x1, _x2, "."), cosmos_lexor__match_some(_s, _x2, _i2, clos(upvals, cosmos_lexor__value_digit)) ; cosmos_lexor__match_some(_s, _i, _i2, clos(upvals, cosmos_lexor__value_digit))).
cosmos_lexor__parse_id(_s, _i, _i2) :- cosmos_lexor__match_some(_s, _i, _x, clos(upvals, cosmos_lexor__value_letter2)), cosmos_lexor__match_any(_s, _x, _i2, clos(upvals, cosmos_lexor__value_digit)).
cosmos_lexor__run_tk(_tk, _type, _l0, _l) :- (dif(_type, "comment"), _l = [_tk|_l0] ; _l = _l0).
cosmos_lexor__keywords(_s, _z) :- default_lib("list", _list), getnil(_list, "has", T60), call_cl(T60, [["?-"|["choose"|[]]], _z]).
cosmos_lexor__step5(_s, _i, _j, _z, _c, _info) :- (_l = ["<="|[">="|["=<"|["=>"|["!="|["::"|["?-"|[":-"|[]]]]]]]]], add_(_i, 2.0, T61), default_lib("string", _string), getnil(_string, "slice", T63), call_cl(T63, [_s, _i, T61, T62]), cosmos_lexor__match_list(_l, T62, _z), add_(_i, 2.0, T64), _j = T64 ; _l = ["+"|["-"|["<"|[">"|["["|["]"|["="|["/"|["*"|["#"|["!"|[":"|[]]]]]]]]]]]]], cosmos_lexor__match_list(_l, _c, _z), add_(_i, 1.0, T65), _j = T65 ; cosmos_lexor__match_one(_s, _i, _j, clos(upvals, cosmos_lexor__value_single_quote)), _z = "single_quote").
cosmos_lexor__step4(_s, _i, _j, _z, _c, _info, _info2) :- (cosmos_lexor__parse_string(_s, _i, _j), _z = "string" ; cosmos_lexor__parse_number(_s, _i, _j), _z = "number" ; cosmos_lexor__step5(_s, _i, _j, _z, _c, _info)).
cosmos_lexor__step1(_s, _i, _j, _z, _info, _info2) :- cosmos_lexor__debug([_i|[]]), def(_i), (cosmos_lexor__navigate_whitespace(_s, _i, _j, _info, _info2) -> _z = "whitespace" ; (cosmos_lexor__navigate_comment(_s, _i, _j, _info, _info2) -> _z = "comment" ; default_lib("string", _string), getnil(_string, "at", T66), call_cl(T66, [_s, _i, _c]), add_(_i, 1.0, T67), _k = T67, cosmos_lexor__debug(["at"|[_c|[_k|[]]]]), _l = [";"|["("|[")"|["{"|["}"|["."|[";"|[","|["|"|["#"|[]]]]]]]]]]], (cosmos_lexor__match_list(_l, _c, _z), add_(_i, 1.0, T68), _j = T68 ; (cosmos_lexor__letter2(_c), (cosmos_lexor__parse_id(_s, _i, _j) -> print([_i|[_j|[]]]), default_lib("string", _string), getnil(_string, "slice", T69), call_cl(T69, [_s, _i, _j, _s2]), _z = "id", cosmos_lexor__debug(["id/"|[_s|[_s2|[]]]]) ; true) ; (cosmos_lexor__step4(_s, _i, _j, _z, _c, _info, _info2), true ; throw(1.0)))), _info = fc_Info(_line,_col), int(_line, T70), add_(_col, _j, T71), r_sub(T71, _i, T72), int(T72, T73), _info2 = fc_Info(T70,T73))), cosmos_lexor__debug(["type"|[_z|[_i|[_j|[]]]]]).
cosmos_lexor__run2(_s, _start, _l, _info, _info2) :- (cosmos_lexor__debug(["run"|[_s|[_start|[]]]]), int(_start, T74), cosmos_lexor__step1(_s, T74, _x, _type, _info, _info1), default_lib("string", _string), getnil(_string, "at", T75), call_cl(T75, [_s, _start, _c]), cosmos_lexor__run2(_s, _x, _l0, _info1, _info2), int(_start, T76), default_lib("string", _string), getnil(_string, "slice", T77), call_cl(T77, [_s, T76, _x, _lexeme]), cosmos_lexor__run_tk(fc_Token(_lexeme,_type,_info), _type, _l0, _l) ; cosmos_lexor__debug(["--"|[_start|[]]]), _l = [fc_Token("EOF","EOF",_)|fc_Cons], default_lib("string", _string), getnil(_string, "size", T78), call_cl(T78, [_s, _z]), cosmos_lexor__debug(["end"|[_z|[_start|[]]]]), int(_start, T79), _z = T79, _info2 = _info ; throw("error")).
cosmos_lexor__run_lx(_s, _l) :- cosmos_lexor__run2(_s, 0.0, _l, fc_Info(1.0,1.0), _info2).
cosmos_lexor__value_debug(V1, _upvals) :- cosmos_lexor__debug(V1).
cosmos_lexor__value_digit(V1, _upvals) :- cosmos_lexor__digit(V1).
cosmos_lexor__value_letter(V1, _upvals) :- cosmos_lexor__letter(V1).
cosmos_lexor__value_letter2(V1, _upvals) :- cosmos_lexor__letter2(V1).
cosmos_lexor__value_single_quote(V1, _upvals) :- cosmos_lexor__single_quote(V1).
cosmos_lexor__value_double_quote(V1, _upvals) :- cosmos_lexor__double_quote(V1).
cosmos_lexor__value_quote(V1, _upvals) :- cosmos_lexor__quote(V1).
cosmos_lexor__value_endline(V1, _upvals) :- cosmos_lexor__endline(V1).
cosmos_lexor__value_slash(V1, _upvals) :- cosmos_lexor__slash(V1).
cosmos_lexor__value_newline(V1, _upvals) :- cosmos_lexor__newline(V1).
cosmos_lexor__value_newline2(V1, _upvals) :- cosmos_lexor__newline2(V1).
cosmos_lexor__value_tab(V1, _upvals) :- cosmos_lexor__tab(V1).
cosmos_lexor__value_whitespace(V1, _upvals) :- cosmos_lexor__whitespace(V1).
cosmos_lexor__value_match_rel2(V1, V2, V3, V4, _upvals) :- cosmos_lexor__match_rel2(V1, V2, V3, V4).
cosmos_lexor__value_match_some(V1, V2, V3, V4, _upvals) :- cosmos_lexor__match_some(V1, V2, V3, V4).
cosmos_lexor__value_match_one(V1, V2, V3, V4, _upvals) :- cosmos_lexor__match_one(V1, V2, V3, V4).
cosmos_lexor__value_match_any(V1, V2, V3, V4, _upvals) :- cosmos_lexor__match_any(V1, V2, V3, V4).
cosmos_lexor__value_match_until(V1, V2, V3, V4, _upvals) :- cosmos_lexor__match_until(V1, V2, V3, V4).
cosmos_lexor__value_match_string(V1, V2, V3, V4, _upvals) :- cosmos_lexor__match_string(V1, V2, V3, V4).
cosmos_lexor__value_match_list(V1, V2, V3, _upvals) :- cosmos_lexor__match_list(V1, V2, V3).
cosmos_lexor__value_match_whitespace(V1, V2, V3, _upvals) :- cosmos_lexor__match_whitespace(V1, V2, V3).
cosmos_lexor__value_parse_double_string(V1, V2, V3, _upvals) :- cosmos_lexor__parse_double_string(V1, V2, V3).
cosmos_lexor__value_parse_string(V1, V2, V3, _upvals) :- cosmos_lexor__parse_string(V1, V2, V3).
cosmos_lexor__value_navigate_ws2(V1, V2, V3, V4, V5, V6, _upvals) :- cosmos_lexor__navigate_ws2(V1, V2, V3, V4, V5, V6).
cosmos_lexor__value_navigate_whitespace(V1, V2, V3, V4, V5, _upvals) :- cosmos_lexor__navigate_whitespace(V1, V2, V3, V4, V5).
cosmos_lexor__value_navigate_until_asterisk(V1, V2, V3, V4, V5, _upvals) :- cosmos_lexor__navigate_until_asterisk(V1, V2, V3, V4, V5).
cosmos_lexor__value_navigate_comment(V1, V2, V3, V4, V5, _upvals) :- cosmos_lexor__navigate_comment(V1, V2, V3, V4, V5).
cosmos_lexor__value_parse_number(V1, V2, V3, _upvals) :- cosmos_lexor__parse_number(V1, V2, V3).
cosmos_lexor__value_parse_id(V1, V2, V3, _upvals) :- cosmos_lexor__parse_id(V1, V2, V3).
cosmos_lexor__value_run_tk(V1, V2, V3, V4, _upvals) :- cosmos_lexor__run_tk(V1, V2, V3, V4).
cosmos_lexor__value_keywords(V1, V2, _upvals) :- cosmos_lexor__keywords(V1, V2).
cosmos_lexor__value_step5(V1, V2, V3, V4, V5, V6, _upvals) :- cosmos_lexor__step5(V1, V2, V3, V4, V5, V6).
cosmos_lexor__value_step4(V1, V2, V3, V4, V5, V6, V7, _upvals) :- cosmos_lexor__step4(V1, V2, V3, V4, V5, V6, V7).
cosmos_lexor__value_step1(V1, V2, V3, V4, V5, V6, _upvals) :- cosmos_lexor__step1(V1, V2, V3, V4, V5, V6).
cosmos_lexor__value_run2(V1, V2, V3, V4, V5, _upvals) :- cosmos_lexor__run2(V1, V2, V3, V4, V5).
cosmos_lexor__value_run_lx(V1, V2, _upvals) :- cosmos_lexor__run_lx(V1, V2).
lexor(_t) :- crequire("string", _string, _), crequire("list", _list, _), crequire("io", _io, _), crequire("ui", _ui, _), new(T80), set_(T80, "run_lexer", clos(upvals, cosmos_lexor__value_run_lx), T81), set_(T81, "run", clos(upvals, cosmos_lexor__value_run_lx), T82), _t = T82, _f = fc_Info(0.0,0.0), _i = 0.0, _s = "p(x,y) <- X=1.".
