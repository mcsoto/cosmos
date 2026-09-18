:- style_check(-singleton).
cosmos_tree__pause() :- read(_x).
cosmos_tree__balance(_f, _f2) :- (_f = fc_Tuple(fc_Black,fc_Tree(fc_Red,fc_Tree(fc_Red,_a,_x,_b),_y,_c),_z,_d), _f2 = fc_Tree(fc_Red,fc_Tree(fc_Black,_a,_x,_b),_y,fc_Tree(fc_Black,_c,_z,_d)) ; _f = fc_Tuple(_color,_a,_x,_b), _f2 = fc_Tree(_color,_a,_x,_b)).
cosmos_tree__lt(_x, _y, _s) :- _x = fc_Pair(_a,_v), _y = fc_Pair(_b,_v2), pure_comp(_a, _b, _s).
cosmos_tree__ins2(_f, _f2, _x) :- (_f = fc_E, _f2 = fc_Tree(fc_Red,fc_E,_x,fc_E) ; _f = fc_Tree(_color,_a,_y,_b), cosmos_tree__lt(_x, _y, _s), if_(_s = "<", (cosmos_tree__ins2(_a, _a2, _x), cosmos_tree__balance(fc_Tuple(_color,_a2,_y,_b), _f2)), (if_(_s = "=", (print([_y|[_x|[]]]), _f2 = fc_Tree(_color,_a,_x,_b)), (cosmos_tree__ins2(_b, _b2, _x), cosmos_tree__balance(fc_Tuple(_color,_a,_y,_b2), _f2)))))).
cosmos_tree__ins(_f, _f2, _x) :- (_f = fc_E, _f2 = fc_Tree(fc_Red,fc_E,_x,fc_E) ; _f = fc_Tree(_color,_a,_y,_b), cosmos_tree__lt(_x, _y, _s), if_(_s = "<", (cosmos_tree__ins(_a, _a2, _x), cosmos_tree__balance(fc_Tuple(_color,_a2,_y,_b), _f2)), (if_(_s = "=", (_f2 = fc_Tree(_color,_a,_x,_b)), (cosmos_tree__ins(_b, _b2, _x), cosmos_tree__balance(fc_Tuple(_color,_a,_y,_b2), _f2)))))).
cosmos_tree__set(_f, _f2, _x, _y1) :- cosmos_tree__ins(_f, _f1, fc_Pair(_x,_y1)), _f1 = fc_Tree(_,_a,_y,_b), _f2 = fc_Tree(fc_Black,_a,_y,_b).
cosmos_tree__member(_f, _x) :- _f = fc_Tree(_color,_a,_y,_b), cosmos_tree__lt(_x, _y, _s), print([_s|[_f|[]]]), (_s = "<", print([_s|[_a|[]]]), cosmos_tree__member(_a, _x) ; (_s = "=", print([_s|[_x|[_y|[]]]]), _x = _y, print([_s|[_x|[_y|[]]]]), true ; print([_s|[_b|[]]]), cosmos_tree__member(_b, _x))).
cosmos_tree__get(_f, _x, _y) :- cosmos_tree__member(_f, fc_Pair(_x,_y)).
cosmos_tree__length(_f, _i) :- if_(_f = fc_E, (_i = 0, true), (if_(_f = fc_Tree(_color,_a,_y,_b), (cosmos_tree__length(_a, _i1), cosmos_tree__length(_y, _i3), cosmos_tree__length(_b, _i2), add_(_i1, _i2, T1), add_(T1, _i3, T2), _i = T2), (_i = 1)))).
cosmos_tree__has1(_f, _x) :- cosmos_tree__get(_f, _x, _).
cosmos_tree__has(_f, _x) :- if_(_f = fc_Pair(_,_), (_x = _f), (if_(_f = fc_Tree(_color,_a,_y,_b), (cosmos_tree__has(_a, _i1), cosmos_tree__has(_y, _i3), cosmos_tree__has(_b, _i2), add_(_i1, _i2, T3), add_(T3, _i3, T4), _i = T4), (true)))).
cosmos_tree__write_(_f) :- (_f = fc_Tree(_color,_a,_y,_b) -> cosmos_tree__write_(_a), cosmos_tree__write_(_y), cosmos_tree__write_(_b) ; (_f = fc_E -> true ; _f = fc_Pair(_a,_b), write(_a), write("="), write(_b), write(", "))).
cosmos_tree__concat(_f, _f1, _f2) :- if_(_f = fc_E, (_f2 = _f1), (_f = fc_Tree(_color,_a,_y,_b), cosmos_tree__has(_a, _i1), cosmos_tree__has(_y, _i3), cosmos_tree__has(_b, _i2), add_(_i1, _i2, T5), add_(T5, _i3, T6), _i = T6)).
cosmos_tree__value_pause(_upvals) :- cosmos_tree__pause().
cosmos_tree__value_balance(V1, V2, _upvals) :- cosmos_tree__balance(V1, V2).
cosmos_tree__value_lt(V1, V2, V3, _upvals) :- cosmos_tree__lt(V1, V2, V3).
cosmos_tree__value_ins2(V1, V2, V3, _upvals) :- cosmos_tree__ins2(V1, V2, V3).
cosmos_tree__value_ins(V1, V2, V3, _upvals) :- cosmos_tree__ins(V1, V2, V3).
cosmos_tree__value_set(V1, V2, V3, V4, _upvals) :- cosmos_tree__set(V1, V2, V3, V4).
cosmos_tree__value_member(V1, V2, _upvals) :- cosmos_tree__member(V1, V2).
cosmos_tree__value_get(V1, V2, V3, _upvals) :- cosmos_tree__get(V1, V2, V3).
cosmos_tree__value_length(V1, V2, _upvals) :- cosmos_tree__length(V1, V2).
cosmos_tree__value_has1(V1, V2, _upvals) :- cosmos_tree__has1(V1, V2).
cosmos_tree__value_has(V1, V2, _upvals) :- cosmos_tree__has(V1, V2).
cosmos_tree__value_write_(V1, _upvals) :- cosmos_tree__write_(V1).
cosmos_tree__value_concat(V1, V2, V3, _upvals) :- cosmos_tree__concat(V1, V2, V3).
tree(_) :- crequire("io", _io, _), default_lib("io", _io), getnil(_io, "write", T7), _write = T7, new(T8), set_(T8, "_write", clos(upvals, cosmos_tree__closure_1), T9), set_(T9, "length", clos(upvals, cosmos_tree__value_length), T10), _t = T10, _f = fc_E, cosmos_tree__set(_f, _f2, 1, 3), print(_f), cosmos_tree__set(_f2, _f3, 3, "a"), print(_f3), cosmos_tree__set(_f3, _f4, 4, "b"), !, print(_f4), cosmos_tree__get(_f4, 3, _).
cosmos_tree__closure_1(_f, _upvals) :- _upvals = upvals, write("{"), cosmos_tree__write_(_f), write("}").
