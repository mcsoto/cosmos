:- style_check(-singleton).
cosmos_debug__write(_s, _io, _logic, _string) :- default_lib("logic", _logic), getnil(_logic, "type", T1), call_cl(T1, [_s, _x]), if_(_x = "String", (default_lib("string", _string), getnil(_string, "size", T3), call_cl(T3, [_s, _n]), ({_n > 10.0} -> default_lib("io", _io), getnil(_io, "write", T4), call_cl(T4, ["#str"]) ; default_lib("io", _io), getnil(_io, "writeFormat", T5), call_cl(T5, [_s]))), (default_lib("io", _io), getnil(_io, "write", T2), call_cl(T2, [_s]), !)).
cosmos_debug__str(_l, _i, _n, _io, _logic, _string) :- (_i = _n -> default_lib("io", _io), getnil(_io, "write", T6), call_cl(T6, [""]) ; (r_sub(_n, 1.0, T7), _i = T7 -> int(_i, _hostI), nth0(_hostI, _l, _e), cosmos_debug__write(_e, _io, _logic, _string) ; int(_i, _hostI), nth0(_hostI, _l, _e), cosmos_debug__write(_e, _io, _logic, _string), default_lib("io", _io), getnil(_io, "write", T8), call_cl(T8, [", "]), add_(_i, 1.0, T9), cosmos_debug__str(_l, T9, _n, _io, _logic, _string))).
cosmos_debug__ftrace(_l, _io, _logic, _string) :- closure(_e, _name, _n, _i), ((_name = "get" ; _name = "set") -> true ; default_lib("io", _io), getnil(_io, "write", T10), call_cl(T10, ["| "]), default_lib("io", _io), getnil(_io, "write", T11), call_cl(T11, [_name]), default_lib("io", _io), getnil(_io, "write", T12), call_cl(T12, ["("]), cosmos_debug__str(_l, 0.0, _n, _io, _logic, _string), default_lib("io", _io), getnil(_io, "write", T13), call_cl(T13, [")\n"])).
cosmos_debug__onhalt(_l, _mutable, _t) :- closure(_e, _name, _n, _i), ((_name = "get" ; _name = "set") -> true ; default_lib("mutable", _mutable), getnil(_mutable, "get", T14), call_cl(T14, [_t, "stack", _i]), print(["ret"|[_name|[_l|[_i|[]]]]]), print(_t), r_sub(_i, 1.0, T15), default_lib("mutable", _mutable), getnil(_mutable, "set", T16), call_cl(T16, [_t, "stack", T15])).
cosmos_debug__onhalt2(_l) :- closure(_e, _name, _n, _i), print(["-"|[_l|[_name|[_n|[_i|[]]]]]]).
cosmos_debug__sethooks(_s, _s1, _s2) :- sethook(_s1, "r"), sethook(_s, "c").
cosmos_debug__rep(_i, _stack, _io) :- (_i = _stack -> true ; default_lib("io", _io), getnil(_io, "write", T17), call_cl(T17, ["|"]), add_(_i, 1.0, T18), cosmos_debug__rep(T18, _stack, _io)).
cosmos_debug__trace(_l, _io, _logic, _string) :- closure(_e, _name, _n, _i), ((_name = "get" ; _name = "set") -> true ; getstack(_stack), cosmos_debug__rep(0.0, _stack, _io), default_lib("io", _io), getnil(_io, "write", T19), call_cl(T19, [_name]), default_lib("io", _io), getnil(_io, "write", T20), call_cl(T20, ["("]), cosmos_debug__str(_l, 0.0, _n, _io, _logic, _string), default_lib("io", _io), getnil(_io, "write", T21), call_cl(T21, [")\n"])).
cosmos_debug__p(_x) :- true.
cosmos_debug__value_write(V1, _upvals) :- cosmos_debug__write(V1, C1, C2, C3).
cosmos_debug__value_str(V1, V2, V3, _upvals) :- cosmos_debug__str(V1, V2, V3, C1, C2, C3).
cosmos_debug__value_ftrace(V1, _upvals) :- cosmos_debug__ftrace(V1, C1, C2, C3).
cosmos_debug__value_onhalt(V1, _upvals) :- cosmos_debug__onhalt(V1, C1, C2).
cosmos_debug__value_onhalt2(V1, _upvals) :- cosmos_debug__onhalt2(V1).
cosmos_debug__value_sethooks(V1, V2, V3, _upvals) :- cosmos_debug__sethooks(V1, V2, V3).
cosmos_debug__value_rep(V1, V2, _upvals) :- cosmos_debug__rep(V1, V2, C1).
cosmos_debug__value_trace(V1, _upvals) :- cosmos_debug__trace(V1, C1, C2, C3).
cosmos_debug__value_p(V1, _upvals) :- cosmos_debug__p(V1).
debug(_debug) :- crequire("mutable", _mutable, _), crequire("io", _io, _), crequire("logic", _logic, _), crequire("string", _string, _), _print2 = _print, default_lib("mutable", _mutable), getnil(_mutable, "new", T22), call_cl(T22, [_t]), default_lib("mutable", _mutable), getnil(_mutable, "set", T23), _set = T23, default_lib("mutable", _mutable), getnil(_mutable, "get", T24), _get = T24, default_lib("mutable", _mutable), getnil(_mutable, "set", T25), call_cl(T25, [_t, "stack", 0.0]), new(T26), set_(T26, "sethook", clos(upvals, cosmos_debug__closure_1), T27), set_(T27, "trace", clos(upvals, cosmos_debug__closure_2), T28), set_(T28, "sethooks", clos(upvals, cosmos_debug__value_sethooks), T29), set_(T29, "getlocal", clos(upvals, cosmos_debug__closure_3), T30), set_(T30, "switch", clos(upvals(_mutable, _t), cosmos_debug__closure_4), T32), set_(T32, "p", clos(upvals, cosmos_debug__closure_5), T33), _debug = T33.
cosmos_debug__closure_1(clos(upvals, cosmos_debug__value_p), _s, _upvals) :- _upvals = upvals, sethook(clos(upvals, cosmos_debug__value_p), _s).
cosmos_debug__closure_2(_l, _upvals) :- _upvals = upvals, sethook(clos(upvals, cosmos_debug__value_trace)).
cosmos_debug__closure_3(_i, _x, _upvals) :- _upvals = upvals, getlocal(_i, _x).
cosmos_debug__closure_4(_i, _upvals) :- _upvals = upvals(_mutable, _t), default_lib("mutable", _mutable), getnil(_mutable, "set", T31), call_cl(T31, [_t, "on", _i]).
cosmos_debug__closure_5(_i, _upvals) :- _upvals = upvals, true.
