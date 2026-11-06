:- style_check(-singleton).
cosmos_ui__contains(_x, _y, _w, _h, _mx, _my, _inside) :- ({_mx >= _x}, add_(_x, _w, T1), {_mx =< T1}, {_my >= _y}, add_(_y, _h, T2), {_my =< T2} -> (_inside = 1.0) ; (_inside = 0.0)).
cosmos_ui__panel(_x, _y, _width, _height, _color, _command) :- new(T3), set_(T3, "kind", "panel", T4), set_(T4, "x", _x, T5), set_(T5, "y", _y, T6), set_(T6, "width", _width, T7), set_(T7, "height", _height, T8), set_(T8, "color", _color, T9), _command = T9.
cosmos_ui__rect(_x, _y, _width, _height, _color, _command) :- new(T10), set_(T10, "kind", "rect", T11), set_(T11, "x", _x, T12), set_(T12, "y", _y, T13), set_(T13, "width", _width, T14), set_(T14, "height", _height, T15), set_(T15, "color", _color, T16), _command = T16.
cosmos_ui__label(_text, _x, _y, _color, _command) :- new(T17), set_(T17, "kind", "label", T18), set_(T18, "text", _text, T19), set_(T19, "x", _x, T20), set_(T20, "y", _y, T21), set_(T21, "color", _color, T22), _command = T22.
cosmos_ui__button(_id, _text, _x, _y, _width, _height, _mx, _my, _command, _clicked) :- cosmos_ui__contains(_x, _y, _width, _height, _mx, _my, _clicked), new(T23), set_(T23, "kind", "button", T24), set_(T24, "id", _id, T25), set_(T25, "text", _text, T26), set_(T26, "x", _x, T27), set_(T27, "y", _y, T28), set_(T28, "width", _width, T29), set_(T29, "height", _height, T30), set_(T30, "hovered", _clicked, T31), _command = T31.
cosmos_ui__row(_left, _top, _gap, _width, _index, _x, _y) :- add_(_width, _gap, T32), r_mul(_index, T32, T33), add_(_left, T33, T34), _x = T34, _y = _top.
cosmos_ui__value_contains(V1, V2, V3, V4, V5, V6, V7, _upvals) :- cosmos_ui__contains(V1, V2, V3, V4, V5, V6, V7).
cosmos_ui__value_panel(V1, V2, V3, V4, V5, V6, _upvals) :- cosmos_ui__panel(V1, V2, V3, V4, V5, V6).
cosmos_ui__value_rect(V1, V2, V3, V4, V5, V6, _upvals) :- cosmos_ui__rect(V1, V2, V3, V4, V5, V6).
cosmos_ui__value_label(V1, V2, V3, V4, V5, _upvals) :- cosmos_ui__label(V1, V2, V3, V4, V5).
cosmos_ui__value_button(V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, _upvals) :- cosmos_ui__button(V1, V2, V3, V4, V5, V6, V7, V8, V9, V10).
cosmos_ui__value_row(V1, V2, V3, V4, V5, V6, V7, _upvals) :- cosmos_ui__row(V1, V2, V3, V4, V5, V6, V7).
ui(_t) :- new(T35), set_(T35, "contains", clos(upvals, cosmos_ui__value_contains), T36), set_(T36, "panel", clos(upvals, cosmos_ui__value_panel), T37), set_(T37, "rect", clos(upvals, cosmos_ui__value_rect), T38), set_(T38, "label", clos(upvals, cosmos_ui__value_label), T39), set_(T39, "button", clos(upvals, cosmos_ui__value_button), T40), set_(T40, "row", clos(upvals, cosmos_ui__value_row), T41), _t = T41.
