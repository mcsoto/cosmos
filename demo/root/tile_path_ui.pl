:- style_check(-singleton).
'tile_path_ui::$impl_state'(A,B,C,D,E):-new(F),set_(F,"player_x",A,G),set_(G,"player_y",B,H),set_(H,"goal_x",C,I),set_(I,"goal_y",D,J),E=J.
'tile_path_ui::$impl_draw_tiles'(A,B,C,D,E,F):-r_gt(B,D),true;r_le(B,D),(r_gt(A,C),add_(B,1.0,G),'tile_path_ui::draw_tiles'(1.0,G,C,D,E,F);r_le(A,C),(r_sub(A,1.0,H),r_mul(H,F,I),J=I),(r_sub(B,1.0,K),r_mul(K,F,L),add_(58.0,L,M),N=M),(add_(A,B,O),r_mod(O,2.0,P),Q=P),if_(Q=0.0,((cosmos_get(E,"graphics",R),cosmos_method(R,"setColor",["#142534"])),r_sub(F,1.0,S),r_sub(F,1.0,T),cosmos_get(E,"graphics",U),cosmos_method(U,"rectangle",["fill",J,N,S,T])),((cosmos_get(E,"graphics",V),cosmos_method(V,"setColor",["#10202e"])),r_sub(F,1.0,W),r_sub(F,1.0,X),cosmos_get(E,"graphics",Y),cosmos_method(Y,"rectangle",["fill",J,N,W,X]))),add_(A,1.0,Z),'tile_path_ui::draw_tiles'(Z,B,C,D,E,F)).
'tile_path_ui::$impl_draw_path'(A,B,C):-if_(A=[],true,(A=[D|E],(cosmos_get(D,"x",F),r_sub(F,1.0,G),r_mul(G,C,H),add_(H,13.0,I),J=I),(cosmos_get(D,"y",K),r_sub(K,1.0,L),r_mul(L,C,M),add_(58.0,M,N),add_(N,13.0,O),P=O),(cosmos_get(B,"graphics",Q),cosmos_method(Q,"setColor",["#4a8a74"])),(cosmos_get(B,"graphics",R),cosmos_method(R,"rectangle",["fill",J,P,16.0,16.0])),'tile_path_ui::draw_path'(E,B,C))).
'tile_path_ui::$impl_draw'(A,B,C,D,E,F,G,H,I,J):-(cosmos_get(F,"graphics",K),cosmos_method(K,"setColor",["#09131f"])),(cosmos_get(F,"graphics",L),cosmos_method(L,"rectangle",["fill",0.0,0.0,J,C])),'tile_path_ui::draw_tiles'(1.0,1.0,B,E,F,G),(cosmos_get(A,"player_x",M),cosmos_get(A,"player_y",N),cosmos_get(A,"goal_x",O),cosmos_get(A,"goal_y",P),cosmos_method(D,"find",[M,N,O,P,Q,R])),'tile_path_ui::draw_path'(Q,F,G),(cosmos_get(F,"graphics",S),cosmos_method(S,"setColor",["#67ddb4"])),(cosmos_get(A,"player_x",T),r_sub(T,1.0,U),r_mul(U,G,V),add_(V,7.0,W),cosmos_get(A,"player_y",X),r_sub(X,1.0,Y),r_mul(Y,G,Z),add_(58.0,Z,A1),add_(A1,7.0,B1),cosmos_get(F,"graphics",C1),cosmos_method(C1,"rectangle",["fill",W,B1,28.0,28.0])),(cosmos_get(F,"graphics",D1),cosmos_method(D1,"setColor",["#ffbd6c"])),(cosmos_get(A,"goal_x",E1),r_sub(E1,1.0,F1),r_mul(F1,G,G1),add_(G1,7.0,H1),cosmos_get(A,"goal_y",I1),r_sub(I1,1.0,J1),r_mul(J1,G,K1),add_(58.0,K1,L1),add_(L1,7.0,M1),cosmos_get(F,"graphics",N1),cosmos_method(N1,"rectangle",["fill",H1,M1,28.0,28.0])),cosmos_method(H,"panel",[0.0,0.0,J,54.0,"#162b3a",O1]),cosmos_method(H,"label",["Tile Path UI",12.0,11.0,"#e7f5fa",P1]),cosmos_method(H,"label",["Click a tile to route there",12.0,31.0,"#9bb7c6",Q1]),(r_sub(J,82.0,R1),r_sub(0.0,1.0,S1),r_sub(0.0,1.0,T1),cosmos_method(H,"button",["reset","Reset",R1,11.0,70.0,32.0,S1,T1,U1,V1])),cosmos_method(I,"drawAll",[[O1,P1,Q1,U1]]).
'tile_path_ui::$impl_update'(A,B,C,D,E,F,G,H,I):-(cosmos_get(F,"event",J),cosmos_method(J,"get",[K])),'tile_path_ui::apply_clicks'(K,A,B,C,D,E,G,H,I).
'tile_path_ui::$impl_apply_clicks'(A,B,C,D,E,F,G,H,I):-if_(A=[],C=B,(A=[J|K],(cosmos_get(J,"type",L),if_(L="mouseup",(cosmos_get(J,"x",M),cosmos_get(J,"y",N),'tile_path_ui::mouseup'(M,N,B,O,D,E,F,G,H,I)),O=B)),'tile_path_ui::apply_clicks'(K,O,C,D,E,F,G,H,I))).
'tile_path_ui::$impl_inside_board'(A,B,C,D,E):-r_lt(A,1.0),C=0.0;r_ge(A,1.0),(r_gt(A,D),C=0.0;r_le(A,D),(r_lt(B,1.0),C=0.0;r_ge(B,1.0),(r_gt(B,E),C=0.0;r_le(B,E),C=1.0))).
'tile_path_ui::$impl_mouseup'(A,B,C,D,E,F,G,H,I,J):-(r_sub(J,82.0,K),cosmos_method(I,"button",["reset","Reset",K,11.0,70.0,32.0,A,B,L,M])),if_(M=1.0,D=F,(r_lt(B,58.0),D=C;r_ge(B,58.0),(r_div(A,H,N),int(N,O),add_(O,1.0,P),Q=P),(r_sub(B,58.0,R),r_div(R,H,S),int(S,T),add_(T,1.0,U),V=U),'tile_path_ui::inside_board'(Q,V,W,E,G),if_(W=0.0,D=C,(cosmos_get(C,"player_x",X),cosmos_get(C,"player_y",Y),'tile_path_ui::state'(X,Y,Q,V,D))))).
tile_path_ui([]):-cosmos_require("space",A),cosmos_require("pathfinder",B),cosmos_require("ui",C),cosmos_require("ui_canvas",D),E=12.0,F=8.0,G=42.0,(r_mul(E,G,H),I=H),(r_mul(F,G,J),add_(J,58.0,K),L=K),M=30.0,(new(N),set_(N,"player_x",2.0,O),set_(O,"player_y",4.0,P),set_(P,"goal_x",10.0,Q),set_(Q,"goal_y",4.0,R),S=R),cosmos_method(A,"init",[I,L]),new(T),set_(T,"update",clos(upvals([E,S,F,A,G,C,I]),'tile_path_ui::$value_update'),U),set_(U,"draw",clos(upvals([E,L,B,F,A,G,C,D,I]),'tile_path_ui::$value_draw'),V),cosmos_method(A,"startCanvas",[M,V,S]).
'tile_path_ui::state'(A,B,C,D,E):-'tile_path_ui::$impl_state'(A,B,C,D,E).
'tile_path_ui::$value_state'(A,B,C,D,E,upvals([])):-'tile_path_ui::state'(A,B,C,D,E).
'tile_path_ui::draw_tiles'(A,B,C,D,E,F):-'tile_path_ui::$impl_draw_tiles'(A,B,C,D,E,F).
'tile_path_ui::$value_draw_tiles'(A,B,upvals([C,D,E,F])):-'tile_path_ui::draw_tiles'(A,B,C,D,E,F).
'tile_path_ui::draw_path'(A,B,C):-'tile_path_ui::$impl_draw_path'(A,B,C).
'tile_path_ui::$value_draw_path'(A,upvals([B,C])):-'tile_path_ui::draw_path'(A,B,C).
'tile_path_ui::draw'(A,B,C,D,E,F,G,H,I,J):-'tile_path_ui::$impl_draw'(A,B,C,D,E,F,G,H,I,J).
'tile_path_ui::$value_draw'(A,upvals([B,C,D,E,F,G,H,I,J])):-'tile_path_ui::draw'(A,B,C,D,E,F,G,H,I,J).
'tile_path_ui::update'(A,B,C,D,E,F,G,H,I):-'tile_path_ui::$impl_update'(A,B,C,D,E,F,G,H,I).
'tile_path_ui::$value_update'(A,B,upvals([C,D,E,F,G,H,I])):-'tile_path_ui::update'(A,B,C,D,E,F,G,H,I).
'tile_path_ui::apply_clicks'(A,B,C,D,E,F,G,H,I):-'tile_path_ui::$impl_apply_clicks'(A,B,C,D,E,F,G,H,I).
'tile_path_ui::$value_apply_clicks'(A,B,C,upvals([D,E,F,G,H,I])):-'tile_path_ui::apply_clicks'(A,B,C,D,E,F,G,H,I).
'tile_path_ui::inside_board'(A,B,C,D,E):-'tile_path_ui::$impl_inside_board'(A,B,C,D,E).
'tile_path_ui::$value_inside_board'(A,B,C,upvals([D,E])):-'tile_path_ui::inside_board'(A,B,C,D,E).
'tile_path_ui::mouseup'(A,B,C,D,E,F,G,H,I,J):-'tile_path_ui::$impl_mouseup'(A,B,C,D,E,F,G,H,I,J).
'tile_path_ui::$value_mouseup'(A,B,C,D,upvals([E,F,G,H,I,J])):-'tile_path_ui::mouseup'(A,B,C,D,E,F,G,H,I,J).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], tile_path_ui([])),cosmos_profile_finish)
    ).
