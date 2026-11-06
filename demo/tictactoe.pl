:- style_check(-singleton).
'tictactoe::$impl_pause'(A):-print("> "),ioread(B).
'tictactoe::$impl_set'(A,B,C,D,E,F):-(r_mul(D,3.0,G),add_(C,G,H),I=H),call_cl(F,[A,I,E,B]).
'tictactoe::$impl_get'(A,B,C,D):-(r_mul(C,3.0,E),add_(B,E,F),G=F),cosmos_get(A,G,H),D=H.
'tictactoe::$impl_empty'(A,B,C):-'tictactoe::get'(A,B,C," ").
'tictactoe::$impl_win_col'(A,B,C):-call_cl(C,[0.0,2.0,D]),cosmos_each(D,E,F),'tictactoe::get'(A,0.0,F,B).
'tictactoe::$impl_draw'(A,B):-C=0.0,cosmos_while(clos(upvals([]),'tictactoe::$closure_0.0'),clos(upvals([A,B]),'tictactoe::$closure_1.0'),[C],[D]).
'tictactoe::$impl_win'(A,B,C,D):-(call_cl(D,[0.0,2.0,E]),cosmos_each(E,F,G),(add_("col",G,H),call_cl(C,[H])),'tictactoe::get'(A,0.0,G,B),'tictactoe::get'(A,1.0,G,B),'tictactoe::get'(A,2.0,G,B),add_("piece",B,I),call_cl(C,[I]);call_cl(D,[0.0,2.0,J]),cosmos_each(J,K,L),(add_("line",L,M),call_cl(C,[M])),'tictactoe::get'(A,L,0.0,B),'tictactoe::get'(A,L,1.0,B),'tictactoe::get'(A,L,2.0,B),call_cl(C,[B]);call_cl(D,[0.0,2.0,N]),cosmos_for(N,clos(upvals([A,C,O,L,B]),'tictactoe::$closure_4.0'),[],[]);'tictactoe::get'(A,2.0,0.0,B),'tictactoe::get'(A,1.0,1.0,B),'tictactoe::get'(A,0.0,2.0,B)),dif(B," ").
'tictactoe::$impl_full'(A):-cosmos_for(A,clos(upvals([]),'tictactoe::$closure_5.0'),[],[]).
'tictactoe::$impl_move'(A,B,C,D):-cosmos_method(B,"ai",[A,E,F]),cosmos_get(B,"piece",G),'tictactoe::set'(A,C,E,F,G,D).
'tictactoe::$impl_wait'(A,B):-(print("> "),cosmos_receiver("io",A),cosmos_method(A,"read",[C])),(C="halt"->system:halt;true).
'tictactoe::$impl_game'(A,B,C,D,E,F,G,H,I):-'tictactoe::win'(A,"X",E,G)->cosmos_receiver("io",F),cosmos_method(F,"writeln",["X won!"]);'tictactoe::win'(A,"O",E,G)->cosmos_receiver("io",F),cosmos_method(F,"writeln",["O won!"]);'tictactoe::full'(A)->cosmos_receiver("io",F),cosmos_method(F,"writeln",["Draw!"]);(cosmos_receiver("io",F),cosmos_method(F,"writeln",[""])),(add_("turn ",D,J),str(J,K),cosmos_receiver("io",F),cosmos_method(F,"writeln",[K])),once('tictactoe::move'(A,B,L,H)),'tictactoe::draw'(L,I),add_(D,1.0,M),'tictactoe::game'(L,C,B,M,E,F,G,H,I).
'tictactoe::$impl_leftmost'(A):-A=0.0;A=1.0;A=2.0.
'tictactoe::$impl__player'(A,B,C,D,E,F):-print("> input line:"),((cosmos_receiver("io",D),cosmos_method_value(D,"read",[],G)),(cosmos_receiver("math",E),cosmos_method_value(E,"stringToNumber",[G],H)),r_sub(H,1.0,I),C=I),print("> input column:"),((cosmos_receiver("io",D),cosmos_method_value(D,"read",[],J)),(cosmos_receiver("math",E),cosmos_method_value(E,"stringToNumber",[J],K)),r_sub(K,1.0,L),B=L),(\+'tictactoe::empty'(A,B,C)->throw("invalid move");true).
'tictactoe::$impl__default'(A,B,C):-('tictactoe::leftmost'(B),'tictactoe::leftmost'(C)),'tictactoe::empty'(A,B,C).
'tictactoe::$impl__random'(A,B,C,D):-(cosmos_receiver("math",D),cosmos_method(D,"random",[0.0,2.0,B])),(cosmos_receiver("math",D),cosmos_method(D,"random",[0.0,2.0,C])),'tictactoe::empty'(A,B,C).
'tictactoe::$impl_main':-true.
tictactoe([]):-cosmos_require("io",A),cosmos_require("table",B),cosmos_require("list",C),cosmos_require("math",D),E=clos(upvals([]),'tictactoe::$closure_6.0'),(cosmos_receiver("math",D),cosmos_get(D,"range",F),G=F),(new(H),set_(H,0.0," ",I),set_(I,1.0," ",J),set_(J,2.0," ",K),set_(K,3.0," ",L),set_(L,4.0," ",M),set_(M,5.0," ",N),set_(N,6.0," ",O),set_(O,7.0," ",P),set_(P,8.0," ",Q),R=Q),(cosmos_receiver("table",B),cosmos_get(B,"set",S),T=S),(cosmos_receiver("io",A),cosmos_get(A,"write",U),V=U),(new(W),set_(W,"piece","X",X),set_(X,"ai",clos(upvals([]),'tictactoe::$value__default'),Y),Z=Y),(new(A1),set_(A1,"piece","O",B1),set_(B1,"ai",clos(upvals([]),'tictactoe::$value__default'),C1),D1=C1),E1=R,call_cl(E,[E1]),call_cl(E,["-draw"]),'tictactoe::game'(E1,Z,D1,1.0,E,A,G,T,V),cosmos_require("object",F1),G1=Z,(cosmos_method_value(F1,"create",[G1],H1),I1=H1),print(I1).
'tictactoe::pause'(A):-'tictactoe::$impl_pause'(A).
'tictactoe::$value_pause'(upvals([A])):-'tictactoe::pause'(A).
'tictactoe::set'(A,B,C,D,E,F):-'tictactoe::$impl_set'(A,B,C,D,E,F).
'tictactoe::$value_set'(A,B,C,D,E,upvals([F])):-'tictactoe::set'(A,B,C,D,E,F).
'tictactoe::get'(A,B,C,D):-'tictactoe::$impl_get'(A,B,C,D).
'tictactoe::$value_get'(A,B,C,D,upvals([])):-'tictactoe::get'(A,B,C,D).
'tictactoe::empty'(A,B,C):-'tictactoe::$impl_empty'(A,B,C).
'tictactoe::$value_empty'(A,B,C,upvals([])):-'tictactoe::empty'(A,B,C).
'tictactoe::win_col'(A,B,C):-'tictactoe::$impl_win_col'(A,B,C).
'tictactoe::$value_win_col'(A,B,upvals([C])):-'tictactoe::win_col'(A,B,C).
'tictactoe::$closure_0.0'([A],upvals([])):-r_lt(A,3.0).
'tictactoe::$closure_2.0'([A],upvals([])):-r_lt(A,3.0).
'tictactoe::$closure_3.0'([A],B,upvals([C,D,E])):-(('tictactoe::get'(D,A,C,F),G=F),write(G),write("|"),(add_(A,1.0,H),I=H),J=I),B=[I],J=I.
'tictactoe::$closure_1.0'([A],B,upvals([C,D])):-(E=0.0,write("|"),cosmos_while(clos(upvals([]),'tictactoe::$closure_2.0'),clos(upvals([A,C,D]),'tictactoe::$closure_3.0'),[E],[F]),write("\n"),(add_(A,1.0,G),H=G),I=H),B=[H],I=H.
'tictactoe::draw'(A,B):-cosmos_callable("function","draw",'tictactoe::$impl_draw'(A,B)).
'tictactoe::$value_draw'(A,upvals([B])):-'tictactoe::draw'(A,B).
'tictactoe::$closure_4.0'(A,B,[],C,upvals([D,E,F,G,H])):-((add_("line",G,I),call_cl(E,[I])),'tictactoe::get'(D,B,B,H),call_cl(E,[H])),C=[].
'tictactoe::win'(A,B,C,D):-cosmos_callable("bool","win",'tictactoe::$impl_win'(A,B,C,D)).
'tictactoe::$value_win'(A,B,upvals([C,D])):-'tictactoe::win'(A,B,C,D).
'tictactoe::$closure_5.0'(A,B,[],C,upvals([])):-dif(B," "),C=[].
'tictactoe::full'(A):-'tictactoe::$impl_full'(A).
'tictactoe::$value_full'(A,upvals([])):-'tictactoe::full'(A).
'tictactoe::move'(A,B,C,D):-'tictactoe::$impl_move'(A,B,C,D).
'tictactoe::$value_move'(A,B,C,upvals([D])):-'tictactoe::move'(A,B,C,D).
'tictactoe::wait'(A,B):-cosmos_callable("function","wait",'tictactoe::$impl_wait'(A,B)).
'tictactoe::$value_wait'(upvals([A,B])):-'tictactoe::wait'(A,B).
'tictactoe::game'(A,B,C,D,E,F,G,H,I):-cosmos_checked_call("function","game",[t("parameters",[t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","InOut",>,t,t("type","Any",-,t,t))],<,t("determinism","nondet",-,t,t),t)],[A,B,C,D],t("T",t("open",1.0,<,t("fields",[],>,t,t("location",fc_Loc(18.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),-,t("Pair",t("open",1.0,<,t("fields",[],>,t,t("location",fc_Loc(17.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),<,t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",[],-,t,t)),-,t,t),t),t("p1",t("kind","constructor",-,t("fields",[fc_Entry(fc_LiteralExpr("piece",fc_Loc(136.0,2.0)),fc_LiteralExpr("X",fc_Loc(136.0,8.0))),fc_Entry(fc_LiteralExpr("ai",fc_Loc(137.0,2.0)),fc_VarExpr("_default",fc_Loc(137.0,5.0)))],-,t,t),t("location",fc_Loc(135.0,1.0),-,t,t)),-,t("_board",t("kind","constructor",-,t("fields",[fc_Entry(fc_LiteralExpr(0.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,9.0))),fc_Entry(fc_LiteralExpr(1.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,13.0))),fc_Entry(fc_LiteralExpr(2.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,17.0))),fc_Entry(fc_LiteralExpr(3.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,21.0))),fc_Entry(fc_LiteralExpr(4.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,25.0))),fc_Entry(fc_LiteralExpr(5.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,29.0))),fc_Entry(fc_LiteralExpr(6.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,33.0))),fc_Entry(fc_LiteralExpr(7.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,37.0))),fc_Entry(fc_LiteralExpr(8.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,41.0)))],-,t,t),t("location",fc_Loc(22.0,1.0),-,t,t)),-,t,t),t("p2",t("kind","constructor",-,t("fields",[fc_Entry(fc_LiteralExpr("piece",fc_Loc(140.0,2.0)),fc_LiteralExpr("O",fc_Loc(140.0,8.0))),fc_Entry(fc_LiteralExpr("ai",fc_Loc(141.0,2.0)),fc_VarExpr("_default",fc_Loc(141.0,5.0)))],-,t,t),t("location",fc_Loc(139.0,1.0),-,t,t)),-,t,t))),'tictactoe::$impl_game'(A,B,C,D,E,F,G,H,I),J).
'tictactoe::$value_game'(A,B,C,D,upvals([E,F,G,H,I])):-'tictactoe::game'(A,B,C,D,E,F,G,H,I).
'tictactoe::leftmost'(A):-'tictactoe::$impl_leftmost'(A).
'tictactoe::$value_leftmost'(A,upvals([])):-'tictactoe::leftmost'(A).
'tictactoe::_player'(A,B,C,D,E,F):-cosmos_checked_call("function","_player",[t("parameters",[t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","Out",>,t,t("type","Any",-,t,t)),t("mode","Out",>,t,t("type","Any",-,t,t))],<,t("determinism","nondet",-,t,t),t)],[A,B,C],t("T",t("open",1.0,<,t("fields",[],>,t,t("location",fc_Loc(18.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),-,t("Pair",t("open",1.0,<,t("fields",[],>,t,t("location",fc_Loc(17.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),<,t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",[],-,t,t)),-,t,t),t),t("p1",t("kind","constructor",-,t("fields",[fc_Entry(fc_LiteralExpr("piece",fc_Loc(136.0,2.0)),fc_LiteralExpr("X",fc_Loc(136.0,8.0))),fc_Entry(fc_LiteralExpr("ai",fc_Loc(137.0,2.0)),fc_VarExpr("_default",fc_Loc(137.0,5.0)))],-,t,t),t("location",fc_Loc(135.0,1.0),-,t,t)),-,t("_board",t("kind","constructor",-,t("fields",[fc_Entry(fc_LiteralExpr(0.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,9.0))),fc_Entry(fc_LiteralExpr(1.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,13.0))),fc_Entry(fc_LiteralExpr(2.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,17.0))),fc_Entry(fc_LiteralExpr(3.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,21.0))),fc_Entry(fc_LiteralExpr(4.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,25.0))),fc_Entry(fc_LiteralExpr(5.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,29.0))),fc_Entry(fc_LiteralExpr(6.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,33.0))),fc_Entry(fc_LiteralExpr(7.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,37.0))),fc_Entry(fc_LiteralExpr(8.0,fc_Loc(0.0,0.0)),fc_LiteralExpr(" ",fc_Loc(22.0,41.0)))],-,t,t),t("location",fc_Loc(22.0,1.0),-,t,t)),-,t,t),t("p2",t("kind","constructor",-,t("fields",[fc_Entry(fc_LiteralExpr("piece",fc_Loc(140.0,2.0)),fc_LiteralExpr("O",fc_Loc(140.0,8.0))),fc_Entry(fc_LiteralExpr("ai",fc_Loc(141.0,2.0)),fc_VarExpr("_default",fc_Loc(141.0,5.0)))],-,t,t),t("location",fc_Loc(139.0,1.0),-,t,t)),-,t,t))),'tictactoe::$impl__player'(A,B,C,D,E,F),G).
'tictactoe::$value__player'(A,B,C,upvals([D,E,F])):-'tictactoe::_player'(A,B,C,D,E,F).
'tictactoe::_default'(A,B,C):-'tictactoe::$impl__default'(A,B,C).
'tictactoe::$value__default'(A,B,C,upvals([])):-'tictactoe::_default'(A,B,C).
'tictactoe::_random'(A,B,C,D):-'tictactoe::$impl__random'(A,B,C,D).
'tictactoe::$value__random'(A,B,C,upvals([D])):-'tictactoe::_random'(A,B,C,D).
'tictactoe::main':-cosmos_callable("function","main",'tictactoe::$impl_main').
'tictactoe::$value_main'(upvals([])):-'tictactoe::main'.
'tictactoe::$closure_6.0'(A,upvals([])):-true.
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
