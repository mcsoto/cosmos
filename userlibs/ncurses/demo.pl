:- style_check(-singleton).
'demo::$impl_main'(A):-cosmos_method(A,"init",[]),cosmos_method(A,"clear",[]),cosmos_method(A,"printAt",[0.0,0.0,"Cosmos ncurses"]),cosmos_method(A,"printAt",[2.0,0.0,"Press any key to return to the shell."]),cosmos_method(A,"refresh",[]),cosmos_method(A,"getch",[B]),cosmos_method(A,"close",[]).
demo([]):-cosmos_require("ncurses",A),'demo::main'(A).
'demo::main'(A):-'demo::$impl_main'(A).
'demo::$value_main'(upvals([A])):-'demo::main'(A).
