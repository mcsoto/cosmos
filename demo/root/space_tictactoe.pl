:- style_check(-singleton).
'space_tictactoe::$impl_list_nth'(A,B,C):-if_(A=[],C=" ",(A=[D|E],if_(B=0.0,C=D,((r_sub(B,1.0,F),G=F),'space_tictactoe::list_nth'(E,G,C))))).
'space_tictactoe::$impl_list_put'(A,B,C,D):-if_(A=[],D=A,(A=[E|F],if_(B=0.0,D=[C|F],((r_sub(B,1.0,G),H=G),'space_tictactoe::list_put'(F,H,C,I),D=[E|I])))).
'space_tictactoe::$impl_cell_index'(A,B,C):-r_mul(B,3.0,D),add_(A,D,E),C=E.
'space_tictactoe::$impl_mark_pos'(A,B,C):-(r_mod(A,3.0,D),B=D),r_div(A,3.0,E),int(E,F),C=F.
'space_tictactoe::$impl_set_cell'(A,B,C,D,E):-'space_tictactoe::cell_index'(B,C,F),'space_tictactoe::list_put'(A,F,D,E).
'space_tictactoe::$impl_copy_state'(A,B,C,D,E,F,G):-new(H),set_(H,"cells",C,I),set_(I,"turn",D,J),set_(J,"over",E,K),set_(K,"winner",F,L),set_(L,"message",G,M),B=M.
'space_tictactoe::$impl_three'(A,B,C,D,E,F):-'space_tictactoe::list_nth'(A,B,G),'space_tictactoe::list_nth'(A,C,H),'space_tictactoe::list_nth'(A,D,I),((G=E,H=E,I=E),F=1.0;\+ (G=E,H=E,I=E),F=0.0).
'space_tictactoe::$impl_check_win'(A,B,C):-'space_tictactoe::three'(A,0.0,1.0,2.0,B,D),'space_tictactoe::three'(A,3.0,4.0,5.0,B,E),'space_tictactoe::three'(A,6.0,7.0,8.0,B,F),'space_tictactoe::three'(A,0.0,3.0,6.0,B,G),'space_tictactoe::three'(A,1.0,4.0,7.0,B,H),'space_tictactoe::three'(A,2.0,5.0,8.0,B,I),'space_tictactoe::three'(A,0.0,4.0,8.0,B,J),'space_tictactoe::three'(A,2.0,4.0,6.0,B,K),((D=1.0;E=1.0;F=1.0;G=1.0;H=1.0;I=1.0;J=1.0;K=1.0),C=1.0;\+ (D=1.0;E=1.0;F=1.0;G=1.0;H=1.0;I=1.0;J=1.0;K=1.0),C=0.0).
'space_tictactoe::$impl_has_empty'(A,B):-if_(A=[],B=0.0,(A=[C|D],if_(C=" ",B=1.0,'space_tictactoe::has_empty'(D,B)))).
'space_tictactoe::$impl_find_empty'(A,B,C,D,E):-r_ge(B,9.0),C=0.0,D=0.0,E=0.0;r_lt(B,9.0),'space_tictactoe::list_nth'(A,B,F),if_(F=" ",('space_tictactoe::mark_pos'(B,C,D),E=1.0),((add_(B,1.0,G),H=G),'space_tictactoe::find_empty'(A,H,C,D,E))).
'space_tictactoe::$impl_cpu_move'(A,B,C):-'space_tictactoe::find_empty'(B,0.0,D,E,F),if_(F=0.0,C=A,('space_tictactoe::set_cell'(B,D,E,"x",G),'space_tictactoe::check_win'(G,"x",H),if_(H=1.0,'space_tictactoe::copy_state'(A,C,G,"x",1.0,"x","The CPU wins - press R to play again"),'space_tictactoe::copy_state'(A,C,G,"x",0.0," ","Your turn - click a square")))).
'space_tictactoe::$impl_player_move'(A,B,C,D):-'space_tictactoe::cell_index'(B,C,E),(cosmos_get(A,"cells",F),'space_tictactoe::list_nth'(F,E,G)),cosmos_get(A,"over",H),if_(H=1.0,D=A,(dif(G," "),D=A;\+dif(G," "),(cosmos_get(A,"cells",I),'space_tictactoe::set_cell'(I,B,C,"o",J)),'space_tictactoe::check_win'(J,"o",K),if_(K=1.0,'space_tictactoe::copy_state'(A,D,J,"o",1.0,"o","You win - press R to play again"),('space_tictactoe::has_empty'(J,L),if_(L=1.0,'space_tictactoe::copy_state'(A,D,J,"o",1.0," ","A draw - press R to play again"),'space_tictactoe::cpu_move'(A,J,D)))))).
'space_tictactoe::$impl_tile_of'(A,B,C,D,E,F,G,H,I):-(r_sub(A,F,J),K=J),(r_sub(B,G,L),M=L),((r_lt(K,0.0);r_lt(M,0.0);r_ge(K,H);r_ge(M,H)),C=0.0,D=0.0,E=0.0;\+ (r_lt(K,0.0);r_lt(M,0.0);r_ge(K,H);r_ge(M,H)),(r_div(K,I,N),int(N,O),C=O),(r_div(M,I,P),int(P,Q),D=Q),E=1.0).
'space_tictactoe::$impl_apply_events'(A,B,C,D,E,F,G,H,I):-if_(A=[],C=B,(A=[J|K],'space_tictactoe::apply_event'(J,B,L,D,E,F,G,H,I),'space_tictactoe::apply_events'(K,L,C,D,E,F,G,H,I))).
'space_tictactoe::$impl_apply_event'(A,B,C,D,E,F,G,H,I):-(cosmos_get(A,"type",J),K=J),if_(K="keydown",'space_tictactoe::apply_key'(A,B,C,F,G),if_(K="mouseup",'space_tictactoe::apply_click'(A,B,C,D,E,H,I),C=B)).
'space_tictactoe::$impl_apply_key'(A,B,C,D,E):-(cosmos_get(A,"key",F),G=F),if_(G="escape",(cosmos_method(E,"quit",[]),C=B),if_(G="r",C=D,C=B)).
'space_tictactoe::$impl_apply_click'(A,B,C,D,E,F,G):-(cosmos_get(A,"x",H),I=H),(cosmos_get(A,"y",J),K=J),'space_tictactoe::tile_of'(I,K,L,M,N,D,E,F,G),if_(N=1.0,'space_tictactoe::player_move'(B,L,M,C),C=B).
'space_tictactoe::$impl_draw_mark'(A,B,C,D,E,F):-'space_tictactoe::list_nth'(A,B,G),if_(G="x",('space_tictactoe::mark_pos'(B,H,I),(cosmos_get(E,"graphics",J),cosmos_method(J,"setColor",["#7cf4cb"])),r_mul(H,F,K),add_(C,K,L),add_(L,18.0,M),r_mul(I,F,N),add_(D,N,O),add_(O,14.0,P),cosmos_get(E,"graphics",Q),cosmos_method(Q,"print",["X",M,P])),if_(G="o",('space_tictactoe::mark_pos'(B,H,I),(cosmos_get(E,"graphics",R),cosmos_method(R,"setColor",["#f3c969"])),r_mul(H,F,S),add_(C,S,T),add_(T,18.0,U),r_mul(I,F,V),add_(D,V,W),add_(W,14.0,X),cosmos_get(E,"graphics",Y),cosmos_method(Y,"print",["O",U,X])),true)).
'space_tictactoe::$impl_draw_marks'(A,B,C,D,E,F):-r_ge(B,9.0),true;r_lt(B,9.0),'space_tictactoe::draw_mark'(A,B,C,D,E,F),(add_(B,1.0,G),H=G),'space_tictactoe::draw_marks'(A,H,C,D,E,F).
'space_tictactoe::$impl_draw_grid'(A,B,C,D,E):-r_ge(A,3.0),true;r_lt(A,3.0),'space_tictactoe::draw_grid_row'(A,0.0,B,C,D,E),(add_(A,1.0,F),G=F),'space_tictactoe::draw_grid'(G,B,C,D,E).
'space_tictactoe::$impl_draw_grid_row'(A,B,C,D,E,F):-r_ge(B,3.0),true;r_lt(B,3.0),(r_mul(B,F,G),add_(C,G,H),r_mul(A,F,I),add_(D,I,J),cosmos_get(E,"graphics",K),cosmos_method(K,"rectangle",["line",H,J,F,F])),(add_(B,1.0,L),M=L),'space_tictactoe::draw_grid_row'(A,M,C,D,E,F).
'space_tictactoe::$impl_draw'(A,B,C,D,E,F):-(cosmos_get(D,"graphics",G),cosmos_method(G,"clear",["#0d1720"])),(cosmos_get(D,"graphics",H),cosmos_method(H,"setColor",["#36516c"])),'space_tictactoe::draw_grid'(0.0,B,C,D,E),(cosmos_get(A,"cells",I),'space_tictactoe::draw_marks'(I,0.0,B,C,D,E)),(cosmos_get(D,"graphics",J),cosmos_method(J,"setColor",["#dcebea"])),(cosmos_get(A,"message",K),cosmos_get(D,"graphics",L),cosmos_method(L,"print",[K,20.0,30.0])),(cosmos_get(D,"graphics",M),cosmos_method(M,"setColor",["#9bb7c6"])),r_sub(F,30.0,N),cosmos_get(D,"graphics",O),cosmos_method(O,"print",["R restarts - ESC quits",20.0,N]).
space_tictactoe([]):-cosmos_require("space",A),B=50.0,C=150.0,D=600.0,E=450.0,F=225.0,G=150.0,(new(H),set_(H,"cells",[" "," "," "," "," "," "," "," "," "],I),set_(I,"turn","o",J),set_(J,"over",0.0,K),set_(K,"winner"," ",L),set_(L,"message","Your turn - click a square",M),N=M),cosmos_method(A,"init",[D,E]),new(O),set_(O,"update",clos(upvals([F,G,N,A,C,B]),'space_tictactoe::$closure_0.0'),P),set_(P,"draw",clos(upvals([F,G,A,B,E]),'space_tictactoe::$closure_1.0'),Q),cosmos_method(A,"start",[33.0,Q,N]).
'space_tictactoe::list_nth'(A,B,C):-'space_tictactoe::$impl_list_nth'(A,B,C).
'space_tictactoe::$value_list_nth'(A,B,C,upvals([])):-'space_tictactoe::list_nth'(A,B,C).
'space_tictactoe::list_put'(A,B,C,D):-'space_tictactoe::$impl_list_put'(A,B,C,D).
'space_tictactoe::$value_list_put'(A,B,C,D,upvals([])):-'space_tictactoe::list_put'(A,B,C,D).
'space_tictactoe::cell_index'(A,B,C):-'space_tictactoe::$impl_cell_index'(A,B,C).
'space_tictactoe::$value_cell_index'(A,B,C,upvals([])):-'space_tictactoe::cell_index'(A,B,C).
'space_tictactoe::mark_pos'(A,B,C):-'space_tictactoe::$impl_mark_pos'(A,B,C).
'space_tictactoe::$value_mark_pos'(A,B,C,upvals([])):-'space_tictactoe::mark_pos'(A,B,C).
'space_tictactoe::set_cell'(A,B,C,D,E):-'space_tictactoe::$impl_set_cell'(A,B,C,D,E).
'space_tictactoe::$value_set_cell'(A,B,C,D,E,upvals([])):-'space_tictactoe::set_cell'(A,B,C,D,E).
'space_tictactoe::copy_state'(A,B,C,D,E,F,G):-'space_tictactoe::$impl_copy_state'(A,B,C,D,E,F,G).
'space_tictactoe::$value_copy_state'(A,B,C,D,E,F,G,upvals([])):-'space_tictactoe::copy_state'(A,B,C,D,E,F,G).
'space_tictactoe::three'(A,B,C,D,E,F):-'space_tictactoe::$impl_three'(A,B,C,D,E,F).
'space_tictactoe::$value_three'(A,B,C,D,E,F,upvals([])):-'space_tictactoe::three'(A,B,C,D,E,F).
'space_tictactoe::check_win'(A,B,C):-'space_tictactoe::$impl_check_win'(A,B,C).
'space_tictactoe::$value_check_win'(A,B,C,upvals([])):-'space_tictactoe::check_win'(A,B,C).
'space_tictactoe::has_empty'(A,B):-'space_tictactoe::$impl_has_empty'(A,B).
'space_tictactoe::$value_has_empty'(A,B,upvals([])):-'space_tictactoe::has_empty'(A,B).
'space_tictactoe::find_empty'(A,B,C,D,E):-'space_tictactoe::$impl_find_empty'(A,B,C,D,E).
'space_tictactoe::$value_find_empty'(A,B,C,D,E,upvals([])):-'space_tictactoe::find_empty'(A,B,C,D,E).
'space_tictactoe::cpu_move'(A,B,C):-'space_tictactoe::$impl_cpu_move'(A,B,C).
'space_tictactoe::$value_cpu_move'(A,B,C,upvals([])):-'space_tictactoe::cpu_move'(A,B,C).
'space_tictactoe::player_move'(A,B,C,D):-'space_tictactoe::$impl_player_move'(A,B,C,D).
'space_tictactoe::$value_player_move'(A,B,C,D,upvals([])):-'space_tictactoe::player_move'(A,B,C,D).
'space_tictactoe::tile_of'(A,B,C,D,E,F,G,H,I):-'space_tictactoe::$impl_tile_of'(A,B,C,D,E,F,G,H,I).
'space_tictactoe::$value_tile_of'(A,B,C,D,E,upvals([F,G,H,I])):-'space_tictactoe::tile_of'(A,B,C,D,E,F,G,H,I).
'space_tictactoe::apply_events'(A,B,C,D,E,F,G,H,I):-'space_tictactoe::$impl_apply_events'(A,B,C,D,E,F,G,H,I).
'space_tictactoe::$value_apply_events'(A,B,C,upvals([D,E,F,G,H,I])):-'space_tictactoe::apply_events'(A,B,C,D,E,F,G,H,I).
'space_tictactoe::apply_event'(A,B,C,D,E,F,G,H,I):-'space_tictactoe::$impl_apply_event'(A,B,C,D,E,F,G,H,I).
'space_tictactoe::$value_apply_event'(A,B,C,upvals([D,E,F,G,H,I])):-'space_tictactoe::apply_event'(A,B,C,D,E,F,G,H,I).
'space_tictactoe::apply_key'(A,B,C,D,E):-'space_tictactoe::$impl_apply_key'(A,B,C,D,E).
'space_tictactoe::$value_apply_key'(A,B,C,upvals([D,E])):-'space_tictactoe::apply_key'(A,B,C,D,E).
'space_tictactoe::apply_click'(A,B,C,D,E,F,G):-'space_tictactoe::$impl_apply_click'(A,B,C,D,E,F,G).
'space_tictactoe::$value_apply_click'(A,B,C,upvals([D,E,F,G])):-'space_tictactoe::apply_click'(A,B,C,D,E,F,G).
'space_tictactoe::draw_mark'(A,B,C,D,E,F):-'space_tictactoe::$impl_draw_mark'(A,B,C,D,E,F).
'space_tictactoe::$value_draw_mark'(A,B,upvals([C,D,E,F])):-'space_tictactoe::draw_mark'(A,B,C,D,E,F).
'space_tictactoe::draw_marks'(A,B,C,D,E,F):-'space_tictactoe::$impl_draw_marks'(A,B,C,D,E,F).
'space_tictactoe::$value_draw_marks'(A,B,upvals([C,D,E,F])):-'space_tictactoe::draw_marks'(A,B,C,D,E,F).
'space_tictactoe::draw_grid'(A,B,C,D,E):-'space_tictactoe::$impl_draw_grid'(A,B,C,D,E).
'space_tictactoe::$value_draw_grid'(A,upvals([B,C,D,E])):-'space_tictactoe::draw_grid'(A,B,C,D,E).
'space_tictactoe::draw_grid_row'(A,B,C,D,E,F):-'space_tictactoe::$impl_draw_grid_row'(A,B,C,D,E,F).
'space_tictactoe::$value_draw_grid_row'(A,B,upvals([C,D,E,F])):-'space_tictactoe::draw_grid_row'(A,B,C,D,E,F).
'space_tictactoe::draw'(A,B,C,D,E,F):-'space_tictactoe::$impl_draw'(A,B,C,D,E,F).
'space_tictactoe::$value_draw'(A,upvals([B,C,D,E,F])):-'space_tictactoe::draw'(A,B,C,D,E,F).
'space_tictactoe::$closure_0.0'(A,B,C,upvals([D,E,F,G,H,I])):-(cosmos_get(G,"event",J),cosmos_method(J,"get",[K])),'space_tictactoe::apply_events'(K,B,C,D,E,F,G,H,I).
'space_tictactoe::$closure_1.0'(A,upvals([B,C,D,E,F])):-'space_tictactoe::draw'(A,B,C,D,E,F).
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
      directory_file_path(Root, '../../libs', LibsRel),
      directory_file_path(Root, '../../userlibs', UserLibsRel),
      directory_file_path(Root, '../../compiler/swi.pl', Runtime),
      directory_file_path(Root, '../../compiler/platform/runtime.pl', Operations),
      directory_file_path(Root, '../../libs/?', LibsTemplate),
      directory_file_path(Root, '../../userlibs/?', UserLibsTemplate),
      assertz(file_search_path(libs, LibsRel)),
      assertz(file_search_path(userlibs, UserLibsRel)),
      % swi.pl defines cosmos_get/3.  A saved image already has
      % it, so only a source run needs the runtime loaded.
      ( current_predicate(cosmos_get/3) -> true
      ; ensure_loaded(Runtime), ensure_loaded(Operations)
      ),
      directory_file_path(Root, '../../libs/space_xpce_prolog.pl', Backend), ensure_loaded(Backend),
      (   (   nb_current(cosmos_profile_requested,true),
              directory_file_path(Root, '../../compiler/platform/profile.pl', Profiler),
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], space_tictactoe([])),cosmos_profile_finish)
    ).
