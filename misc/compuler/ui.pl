:- style_check(-singleton).
cosmos_ui__makemenu(_list, _b) :- true.
cosmos_ui__value_makemenu(V1, V2, _upvals) :- cosmos_ui__makemenu(V1, V2).
ui(clos(upvals, cosmos_ui__value_makemenu)) :- new(T1), _ui = T1, new(T2), set_(T2, "title", "open", T3), set_(T3, "action", "open", T4), _item1 = T4, new(T5), set_(T5, "img", "panel.png", T6), set_(T6, "panels", [_menu1|[]], T7), _menu = T7.
