:- style_check(-singleton).
'tictactoe::$impl_leftmost'(A):-A=0.0;A=1.0;A=2.0.
'tictactoe::$impl__default'(A,B,C):-(cosmos_trace_call("leftmost",[B],'tictactoe::leftmost'(B)),cosmos_trace_call("leftmost",[C],'tictactoe::leftmost'(C))),cosmos_trace_call("board.empty",[B,C],cosmos_method(A,"empty",[B,C])).
'tictactoe::$impl_floor'(A,B):-cosmos_trace_call("int",[A,C],int(A,C)),B=C.
'tictactoe::$impl_radius_of'(A,B,C,D):-((cosmos_get(A,"x",E),r_sub(B,D,F),r_ge(E,F)),cosmos_get(A,"x",G),add_(B,D,H),r_le(G,H)),(cosmos_get(A,"y",I),r_sub(C,D,J),r_ge(I,J)),cosmos_get(A,"y",K),add_(C,D,L),r_le(K,L).
'tictactoe::$impl_find_tile'(A,B,C):-r_div(A,C,D),cosmos_trace_call("floor",[D,E],'tictactoe::floor'(D,E)),B=E.
'tictactoe::$impl_clear'(A):-cosmos_trace_call("sp.setRGBA",[255.0,255.0,255.0,255.0],cosmos_method(A,"setRGBA",[255.0,255.0,255.0,255.0])),cosmos_trace_call("sp.clear",[],cosmos_method(A,"clear",[])).
'tictactoe::$impl_draw'(A,B,C,D,E,F):-cosmos_trace_call("sp.setRGB",[0.0,0.0,100.0],cosmos_method(D,"setRGB",[0.0,0.0,100.0])),G=0.0,cosmos_trace_call("pl::cosmos_while",[clos(upvals([]),'tictactoe::$closure_0.0'),clos(upvals([A,B,C,D,E,F]),'tictactoe::$closure_1.0'),[G],[H]],cosmos_while(clos(upvals([]),'tictactoe::$closure_0.0'),clos(upvals([A,B,C,D,E,F]),'tictactoe::$closure_1.0'),[G],[H])).
'tictactoe::$impl_checkwin'(A):-cosmos_trace_call("board.win",["x"],cosmos_method(A,"win",["x"]));cosmos_trace_call("board.win",["O"],cosmos_method(A,"win",["O"]));cosmos_trace_call("board.full",[],cosmos_method(A,"full",[])).
'tictactoe::$impl_move'(A,B,C,D,E,F):-cosmos_trace_call("checkwin",[C],'tictactoe::checkwin'(C))->cosmos_trace_call("print",["game ended"],print("game ended")),C=D;cosmos_trace_call("board.empty",[A,B],cosmos_method(C,"empty",[A,B]))->cosmos_trace_call("board.set",[A,B,"o",G],cosmos_method(C,"set",[A,B,"o",G])),(cosmos_trace_call("checkwin",[G],'tictactoe::checkwin'(G))->cosmos_trace_call("print",["game ended"],print("game ended")),G=D;cosmos_trace_call("board1.move",[E,D],cosmos_method(G,"move",[E,D])));C=D.
tictactoe([]):-cosmos_trace_call("::main",[],(cosmos_trace_call("require",["space",A],cosmos_require("space",A)),cosmos_trace_call("require",["table",B],cosmos_require("table",B)),cosmos_trace_call("require",["list",C],cosmos_require("list",C)),cosmos_trace_call("require",["logic",D],cosmos_require("logic",D)),cosmos_trace_call("require",["math",E],cosmos_require("math",E)),cosmos_trace_call("require",["board",F],cosmos_require("board",F)),cosmos_trace_call("require",["object",G],cosmos_require("object",G)),(cosmos_receiver("math",E),cosmos_get(E,"range",H),I=H),(cosmos_receiver("table",B),cosmos_get(B,"set",J),K=J),(L=50.0,M=50.0),(new(N),set_(N,"piece","x",O),set_(O,"ai",clos(upvals([]),'tictactoe::$value__default'),P),Q=P),(new(R),set_(R,"piece","o",S),set_(S,"ai",T,U),V=U),cosmos_trace_call("print",[F],print(F)),(cosmos_trace_call("object.create",[F,W],(cosmos_receiver("object",G),cosmos_method_value(G,"create",[F],W))),X=W),cosmos_trace_call("sp.init",[600.0,450.0],cosmos_method(A,"init",[600.0,450.0])),(cosmos_trace_call("sp.loadImage",["x.png",Y],cosmos_method_value(A,"loadImage",["x.png"],Y)),Z=Y),(cosmos_trace_call("sp.loadImage",["o.png",A1],cosmos_method_value(A,"loadImage",["o.png"],A1)),B1=A1),new(C1),set_(C1,"mouseup",clos(upvals([Q,D1,M]),'tictactoe::$closure_4.0'),E1),set_(E1,"keypressed",clos(upvals([]),'tictactoe::$closure_5.0'),F1),set_(F1,"update",clos(upvals([B1,Z,A,M,L]),'tictactoe::$closure_6.0'),G1),cosmos_trace_call("sp.start",[500.0,G1,X],cosmos_method(A,"start",[500.0,G1,X])))).
'tictactoe::leftmost'(A):-'tictactoe::$impl_leftmost'(A).
'tictactoe::$value_leftmost'(A,upvals([])):-'tictactoe::leftmost'(A).
'tictactoe::_default'(A,B,C):-'tictactoe::$impl__default'(A,B,C).
'tictactoe::$value__default'(A,B,C,upvals([])):-'tictactoe::_default'(A,B,C).
'tictactoe::floor'(A,B):-'tictactoe::$impl_floor'(A,B).
'tictactoe::$value_floor'(A,B,upvals([])):-'tictactoe::floor'(A,B).
'tictactoe::radius_of'(A,B,C,D):-cosmos_callable("function","radius_of",'tictactoe::$impl_radius_of'(A,B,C,D)).
'tictactoe::$value_radius_of'(A,B,C,D,upvals([])):-'tictactoe::radius_of'(A,B,C,D).
'tictactoe::find_tile'(A,B,C):-cosmos_callable("function","find_tile",'tictactoe::$impl_find_tile'(A,B,C)).
'tictactoe::$value_find_tile'(A,B,upvals([C])):-'tictactoe::find_tile'(A,B,C).
'tictactoe::clear'(A):-'tictactoe::$impl_clear'(A).
'tictactoe::$value_clear'(upvals([A])):-'tictactoe::clear'(A).
'tictactoe::$closure_0.0'([A],upvals([])):-r_lt(A,3.0).
'tictactoe::$closure_2.0'([A],upvals([])):-r_lt(A,3.0).
'tictactoe::$closure_3.0'([A],B,upvals([C,D,E,F,G,H,I])):-(((r_mul(C,I,J),r_mul(A,H,K),cosmos_trace_call("sp.rectBorder",[J,K,I,H],cosmos_method(G,"rectBorder",[J,K,I,H]))),cosmos_trace_call("board.get",[C,A,L],cosmos_method(D,"get",[C,A,L])),if_(L="x",(r_mul(C,I,M),add_(M,5.0,N),r_mul(A,H,O),add_(O,5.0,P),cosmos_trace_call("sp.drawImage",[F,N,P],cosmos_method(G,"drawImage",[F,N,P]))),if_(L="o",(r_mul(C,I,Q),add_(Q,5.0,R),r_mul(A,H,S),add_(S,5.0,T),cosmos_trace_call("sp.drawImage",[E,R,T],cosmos_method(G,"drawImage",[E,R,T]))),true))),(add_(A,1.0,U),V=U),W=V),B=[V],W=V.
'tictactoe::$closure_1.0'([A],B,upvals([C,D,E,F,G,H])):-((I=0.0,cosmos_trace_call("pl::cosmos_while",[clos(upvals([]),'tictactoe::$closure_2.0'),clos(upvals([A,C,D,E,F,G,H]),'tictactoe::$closure_3.0'),[I],[J]],cosmos_while(clos(upvals([]),'tictactoe::$closure_2.0'),clos(upvals([A,C,D,E,F,G,H]),'tictactoe::$closure_3.0'),[I],[J]))),(add_(A,1.0,K),L=K),M=L),B=[L],M=L.
'tictactoe::draw'(A,B,C,D,E,F):-cosmos_callable("function","draw",'tictactoe::$impl_draw'(A,B,C,D,E,F)).
'tictactoe::$value_draw'(A,upvals([B,C,D,E,F])):-'tictactoe::draw'(A,B,C,D,E,F).
'tictactoe::checkwin'(A):-'tictactoe::$impl_checkwin'(A).
'tictactoe::$value_checkwin'(A,upvals([])):-'tictactoe::checkwin'(A).
'tictactoe::move'(A,B,C,D,E,F):-cosmos_callable("function","move",'tictactoe::$impl_move'(A,B,C,D,E,F)).
'tictactoe::$value_move'(A,B,C,D,upvals([E,F])):-'tictactoe::move'(A,B,C,D,E,F).
'tictactoe::$closure_4.0'(A,B,C,D,upvals([E,F,G])):-cosmos_trace_call("find_tile",[A,H],'tictactoe::find_tile'(A,H,G)),cosmos_trace_call("find_tile",[B,I],'tictactoe::find_tile'(B,I,G)),cosmos_trace_call("print",[[H,I]],print([H,I])),cosmos_trace_call("move",[H,I,C,D],'tictactoe::move'(H,I,C,D,E,F)).
'tictactoe::$closure_5.0'(A,B,C,upvals([])):-if_(A="escape",cosmos_trace_call("pl::halt",[],system:halt),C=B).
'tictactoe::$closure_6.0'(A,A,upvals([B,C,D,E,F])):-cosmos_trace_call("clear",[],'tictactoe::clear'(D)),G=A,cosmos_trace_call("sp.setRGB",[0.0,0.0,0.0],cosmos_method(D,"setRGB",[0.0,0.0,0.0])),cosmos_trace_call("draw",[G],'tictactoe::draw'(G,B,C,D,E,F)),cosmos_trace_call("sp.refresh",[],cosmos_method(D,"refresh",[])).
:- initialization(cosmos_entry_main, main).
cosmos_entry_root(Root) :-
    % The .pl is the anchor while running as source; in a saved
    % image there is no .pl to point at, and the exe sits where
    % the .pl was, so the executable directory is the fallback.
    (   source_file(cosmos_entry_main, File), file_directory_name(File, Root)
    ->  true
    ;   current_prolog_flag(executable, Executable),
        file_directory_name(Executable, Root)
    ).
cosmos_entry_main :-
    ( nb_current(cosmos_building_exe, true) -> true
    ; nb_current(cosmos_entry_ran, true) -> true
    ; nb_setval(cosmos_entry_ran, true),
      abolish_all_tables,
      current_prolog_flag(executable, Executable), current_prolog_flag(argv, RawArguments),
      % Preserve the conventional argv[0] slot. Cosmos lists use
      % zero-based indexing, so main(args) can use args[1] for the first
      % user-supplied argument, as command-line programs normally do.
      cosmos_entry_root(Root),
      directory_file_path(Root, '../libs', LibsRel),
      directory_file_path(Root, '../userlibs', UserLibsRel),
      directory_file_path(Root, '../compiler/swi.pl', Runtime),
      directory_file_path(Root, '../compiler/platform/runtime.pl', Operations),
      directory_file_path(Root, '../libs/?', LibsTemplate),
      directory_file_path(Root, '../userlibs/?', UserLibsTemplate),
      assertz(file_search_path(libs, LibsRel)),
      assertz(file_search_path(userlibs, UserLibsRel)),
      % swi.pl defines cosmos_get/3.  A saved image already has
      % it, so only a source run needs the runtime loaded.
      ( current_predicate(cosmos_get/3) -> true
      ; ensure_loaded(Runtime), ensure_loaded(Operations)
      ),
      directory_file_path(Root, '../libs/space_xpce_prolog.pl', Backend), ensure_loaded(Backend),
      (   (   nb_current(cosmos_profile_requested,true),
              directory_file_path(Root, '../compiler/platform/profile.pl', Profiler),
              exists_file(Profiler),
              ensure_loaded(Profiler),
              cosmos_profile:cosmos_profile_start()
          )
      ->  true
      ;   true
      ),
      directory_file_path(Root, ?, SourceTemplate),
      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),
      nb_setval(path,Path),
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], tictactoe([])),cosmos_profile_finish)
    ).
