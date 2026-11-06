:- style_check(-singleton).
'minesweeper::$impl_mine'(A,B):-A=2.0,B=2.0;A=5.0,B=1.0;A=8.0,B=1.0;A=4.0,B=3.0;A=7.0,B=3.0;A=1.0,B=5.0;A=6.0,B=5.0;A=9.0,B=6.0;A=3.0,B=7.0;A=8.0,B=8.0.
'minesweeper::$impl_cell_id'(A,B,C):-r_mul(B,100.0,D),add_(A,D,E),C=E.
'minesweeper::$impl_mine_value'(A,B,C):-'minesweeper::mine'(A,B),C=1.0;\+'minesweeper::mine'(A,B),C=0.0.
'minesweeper::$impl_adjacent_mines'(A,B,C):-(r_sub(A,1.0,D),r_sub(B,1.0,E),'minesweeper::mine_value'(D,E,F)),(r_sub(B,1.0,G),'minesweeper::mine_value'(A,G,H)),(add_(A,1.0,I),r_sub(B,1.0,J),'minesweeper::mine_value'(I,J,K)),(r_sub(A,1.0,L),'minesweeper::mine_value'(L,B,M)),(add_(A,1.0,N),'minesweeper::mine_value'(N,B,O)),(r_sub(A,1.0,P),add_(B,1.0,Q),'minesweeper::mine_value'(P,Q,R)),(add_(B,1.0,S),'minesweeper::mine_value'(A,S,T)),(add_(A,1.0,U),add_(B,1.0,V),'minesweeper::mine_value'(U,V,W)),add_(F,H,X),add_(X,K,Y),add_(Y,M,Z),add_(Z,O,A1),add_(A1,R,B1),add_(B1,T,C1),add_(C1,W,D1),C=D1.
'minesweeper::$impl_copy_state'(A,B,C,D,E,F):-new(G),set_(G,"revealed",C,H),set_(H,"moves",D,I),set_(I,"game_over",E,J),set_(J,"win",F,K),B=K.
'minesweeper::$impl_reset'(A,B,C):-B=C.
'minesweeper::$impl_reveal'(A,B,C,D,E):-'minesweeper::cell_id'(A,B,F),((cosmos_get(C,"revealed",G),cosmos_receiver("list",E),cosmos_method(E,"has",[G,F])),D=C;\+ (cosmos_get(C,"revealed",H),cosmos_receiver("list",E),cosmos_method(E,"has",[H,F])),('minesweeper::mine'(A,B),cosmos_get(C,"revealed",I),cosmos_get(C,"moves",J),add_(J,1.0,K),cosmos_get(C,"win",L),'minesweeper::copy_state'(C,D,I,K,1.0,L);\+'minesweeper::mine'(A,B),(cosmos_get(C,"revealed",M),cosmos_receiver("list",E),cosmos_method(E,"concat",[M,[F],N])),((cosmos_get(C,"moves",O),r_ge(O,69.0)),cosmos_get(C,"moves",P),add_(P,1.0,Q),cosmos_get(C,"game_over",R),'minesweeper::copy_state'(C,D,N,Q,R,fc_Won);(cosmos_get(C,"moves",S),r_lt(S,69.0)),cosmos_get(C,"moves",T),add_(T,1.0,U),cosmos_get(C,"game_over",V),cosmos_get(C,"win",W),'minesweeper::copy_state'(C,D,N,U,V,W)))).
'minesweeper::$impl_mouseup'(A,B,C,D,E,F,G,H):-(r_div(A,E,I),int(I,J),add_(J,1.0,K),L=K),(r_sub(B,40.0,M),r_div(M,E,N),int(N,O),add_(O,1.0,P),Q=P),((cosmos_set_or_unify(C,"game_over",1.0);cosmos_set_or_unify(C,"win",fc_Won)),D=C;\+ (cosmos_set_or_unify(C,"game_over",1.0);cosmos_set_or_unify(C,"win",fc_Won)),((r_lt(L,1.0);r_gt(L,F);r_lt(Q,1.0);r_gt(Q,H)),D=C;\+ (r_lt(L,1.0);r_gt(L,F);r_lt(Q,1.0);r_gt(Q,H)),'minesweeper::reveal'(L,Q,C,D,G))).
'minesweeper::$impl_keypressed'(A,B,C,D):-if_(A="r",'minesweeper::reset'(B,C,D),C=B).
'minesweeper::$impl_draw_cell'(A,B,C,D,E,F,G):-'minesweeper::cell_id'(A,B,H),(r_sub(A,1.0,I),r_mul(I,D,J),K=J),(r_sub(B,1.0,L),r_mul(L,D,M),add_(40.0,M,N),O=N),((cosmos_get(C,"revealed",P),cosmos_receiver("list",E),cosmos_method(E,"has",[P,H])),(cosmos_get(F,"graphics",Q),cosmos_method(Q,"setColor",["#8ca58c"])),(add_(K,2.0,R),add_(O,2.0,S),r_sub(D,4.0,T),r_sub(D,4.0,U),cosmos_get(F,"graphics",V),cosmos_method(V,"rectangle",["fill",R,S,T,U])),'minesweeper::adjacent_mines'(A,B,W),(r_gt(W,0.0),int(W,X),(cosmos_get(F,"graphics",Y),cosmos_method(Y,"setColor",["#11283a"])),str(X,Z),add_(K,18.0,A1),add_(O,10.0,B1),cosmos_get(F,"graphics",C1),cosmos_method(C1,"print",[Z,A1,B1]);r_le(W,0.0),true);\+ (cosmos_get(C,"revealed",D1),cosmos_receiver("list",E),cosmos_method(E,"has",[D1,H])),((cosmos_set_or_unify(C,"game_over",1.0),'minesweeper::mine'(A,B)),(cosmos_get(F,"graphics",E1),cosmos_method(E1,"setColor",["#d65b50"])),add_(K,2.0,F1),add_(O,2.0,G1),r_sub(D,4.0,H1),r_sub(D,4.0,I1),cosmos_get(F,"graphics",J1),cosmos_method(J1,"rectangle",["fill",F1,G1,H1,I1]);\+ (cosmos_set_or_unify(C,"game_over",1.0),'minesweeper::mine'(A,B)),(cosmos_get(F,"graphics",K1),cosmos_method(K1,"setColor",["#38556a"])),add_(K,2.0,L1),add_(O,2.0,M1),r_sub(D,4.0,N1),r_sub(D,4.0,O1),cosmos_get(F,"graphics",P1),cosmos_method(P1,"rectangle",["fill",L1,M1,N1,O1]))).
'minesweeper::$impl_draw'(A,B,C,D,E,F,G,H,I):-(cosmos_get(G,"graphics",J),cosmos_method(J,"setColor",["#0d1720"])),(cosmos_get(G,"graphics",K),cosmos_method(K,"rectangle",["fill",0.0,0.0,I,D])),(cosmos_get(G,"graphics",L),cosmos_method(L,"setColor",["#182c38"])),(cosmos_get(G,"graphics",M),cosmos_method(M,"rectangle",["fill",0.0,0.0,I,36.0])),(cosmos_get(G,"graphics",N),cosmos_method(N,"setColor",["#2a4654"])),(cosmos_get(G,"graphics",O),cosmos_method(O,"rectangle",["fill",8.0,8.0,112.0,20.0])),(cosmos_get(G,"graphics",P),cosmos_method(P,"rectangle",["fill",132.0,8.0,112.0,20.0])),(cosmos_get(G,"graphics",Q),cosmos_method(Q,"rectangle",["fill",256.0,8.0,112.0,20.0])),(R=1.0,cosmos_while(clos(upvals([F]),'minesweeper::$closure_0.0'),clos(upvals([B,C,E,A,G,H]),'minesweeper::$closure_1.0'),[R],[S])),cosmos_get(A,"game_over",T),if_(T=1.0,((cosmos_get(G,"graphics",U),cosmos_method(U,"setColor",["#4a211f"])),cosmos_get(G,"graphics",V),cosmos_method(V,"rectangle",["fill",120.0,190.0,240.0,52.0])),(cosmos_get(A,"win",W),if_(W=fc_Won,((cosmos_get(G,"graphics",X),cosmos_method(X,"setColor",["#315137"])),cosmos_get(G,"graphics",Y),cosmos_method(Y,"rectangle",["fill",120.0,190.0,240.0,52.0])),true))).
'minesweeper::$impl_apply_events'(A,B,C,D,E,F,G,H):-if_(A=[],C=B,(A=[I|J],(cosmos_get(I,"type",K),L=K),if_(L="keydown",(cosmos_get(I,"key",M),'minesweeper::keypressed'(M,B,N,F)),if_(L="mouseup",(cosmos_get(I,"x",O),cosmos_get(I,"y",P),'minesweeper::mouseup'(O,P,B,N,D,E,G,H)),N=B)),'minesweeper::apply_events'(J,N,C,D,E,F,G,H))).
'minesweeper::$impl_update'(A,B,C,D,E,F,G,H):-(cosmos_get(H,"event",I),cosmos_method(I,"get",[J])),'minesweeper::apply_events'(J,A,B,C,D,E,F,G).
minesweeper([]):-cosmos_require("space",A),cosmos_require("list",B),cosmos_require("string",C),D=10.0,E=8.0,F=48.0,(r_mul(D,F,G),H=G),(r_mul(E,F,I),add_(I,40.0,J),K=J),L=80.0,(new(M),set_(M,"revealed",[],N),set_(N,"moves",0.0,O),set_(O,"game_over",0.0,P),set_(P,"win",fc_Playing,Q),R=Q),cosmos_method(A,"init",[H,K]),new(S),set_(S,"update",clos(upvals([F,D,R,B,E,A]),'minesweeper::$value_update'),T),set_(T,"draw",clos(upvals([F,D,K,B,E,A,C,H]),'minesweeper::$value_draw'),U),cosmos_method(A,"start",[L,U,R]).
'minesweeper::mine'(A,B):-'minesweeper::$impl_mine'(A,B).
'minesweeper::$value_mine'(A,B,upvals([])):-'minesweeper::mine'(A,B).
'minesweeper::cell_id'(A,B,C):-'minesweeper::$impl_cell_id'(A,B,C).
'minesweeper::$value_cell_id'(A,B,C,upvals([])):-'minesweeper::cell_id'(A,B,C).
'minesweeper::mine_value'(A,B,C):-'minesweeper::$impl_mine_value'(A,B,C).
'minesweeper::$value_mine_value'(A,B,C,upvals([])):-'minesweeper::mine_value'(A,B,C).
'minesweeper::adjacent_mines'(A,B,C):-'minesweeper::$impl_adjacent_mines'(A,B,C).
'minesweeper::$value_adjacent_mines'(A,B,C,upvals([])):-'minesweeper::adjacent_mines'(A,B,C).
'minesweeper::copy_state'(A,B,C,D,E,F):-'minesweeper::$impl_copy_state'(A,B,C,D,E,F).
'minesweeper::$value_copy_state'(A,B,C,D,E,F,upvals([])):-'minesweeper::copy_state'(A,B,C,D,E,F).
'minesweeper::reset'(A,B,C):-'minesweeper::$impl_reset'(A,B,C).
'minesweeper::$value_reset'(A,B,upvals([C])):-'minesweeper::reset'(A,B,C).
'minesweeper::reveal'(A,B,C,D,E):-'minesweeper::$impl_reveal'(A,B,C,D,E).
'minesweeper::$value_reveal'(A,B,C,D,upvals([E])):-'minesweeper::reveal'(A,B,C,D,E).
'minesweeper::mouseup'(A,B,C,D,E,F,G,H):-'minesweeper::$impl_mouseup'(A,B,C,D,E,F,G,H).
'minesweeper::$value_mouseup'(A,B,C,D,upvals([E,F,G,H])):-'minesweeper::mouseup'(A,B,C,D,E,F,G,H).
'minesweeper::keypressed'(A,B,C,D):-'minesweeper::$impl_keypressed'(A,B,C,D).
'minesweeper::$value_keypressed'(A,B,C,upvals([D])):-'minesweeper::keypressed'(A,B,C,D).
'minesweeper::draw_cell'(A,B,C,D,E,F,G):-'minesweeper::$impl_draw_cell'(A,B,C,D,E,F,G).
'minesweeper::$value_draw_cell'(A,B,C,upvals([D,E,F,G])):-'minesweeper::draw_cell'(A,B,C,D,E,F,G).
'minesweeper::$closure_0.0'([A],upvals([B])):-r_le(A,B).
'minesweeper::$closure_2.0'([A],upvals([B])):-r_le(A,B).
'minesweeper::$closure_3.0'([A],B,upvals([C,D,E,F,G,H])):-('minesweeper::draw_cell'(A,C,F,D,E,G,H),(add_(A,1.0,I),J=I),K=J),B=[J],K=J.
'minesweeper::$closure_1.0'([A],B,upvals([C,D,E,F,G,H])):-((I=1.0,cosmos_while(clos(upvals([D]),'minesweeper::$closure_2.0'),clos(upvals([A,C,E,F,G,H]),'minesweeper::$closure_3.0'),[I],[J])),(add_(A,1.0,K),L=K),M=L),B=[L],M=L.
'minesweeper::draw'(A,B,C,D,E,F,G,H,I):-'minesweeper::$impl_draw'(A,B,C,D,E,F,G,H,I).
'minesweeper::$value_draw'(A,upvals([B,C,D,E,F,G,H,I])):-'minesweeper::draw'(A,B,C,D,E,F,G,H,I).
'minesweeper::apply_events'(A,B,C,D,E,F,G,H):-'minesweeper::$impl_apply_events'(A,B,C,D,E,F,G,H).
'minesweeper::$value_apply_events'(A,B,C,upvals([D,E,F,G,H])):-'minesweeper::apply_events'(A,B,C,D,E,F,G,H).
'minesweeper::update'(A,B,C,D,E,F,G,H):-'minesweeper::$impl_update'(A,B,C,D,E,F,G,H).
'minesweeper::$value_update'(A,B,upvals([C,D,E,F,G,H])):-'minesweeper::update'(A,B,C,D,E,F,G,H).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], minesweeper([])),cosmos_profile_finish)
    ).
