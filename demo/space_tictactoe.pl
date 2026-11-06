:- style_check(-singleton).
'space_tictactoe::$impl_cell_at'(A,B,C):-if_(B=0.0,(cosmos_get(A,"a",D),C=D),if_(B=1.0,(cosmos_get(A,"b",E),C=E),if_(B=2.0,(cosmos_get(A,"c",F),C=F),if_(B=3.0,(cosmos_get(A,"d",G),C=G),if_(B=4.0,(cosmos_get(A,"e",H),C=H),if_(B=5.0,(cosmos_get(A,"f",I),C=I),if_(B=6.0,(cosmos_get(A,"g",J),C=J),if_(B=7.0,(cosmos_get(A,"h",K),C=K),(cosmos_get(A,"i",L),C=L))))))))).
'space_tictactoe::$impl_put_cell'(A,B,C,D):-if_(B=0.0,(new(E),set_(E,"a",C,F),cosmos_get(A,"b",G),set_(F,"b",G,H),cosmos_get(A,"c",I),set_(H,"c",I,J),cosmos_get(A,"d",K),set_(J,"d",K,L),cosmos_get(A,"e",M),set_(L,"e",M,N),cosmos_get(A,"f",O),set_(N,"f",O,P),cosmos_get(A,"g",Q),set_(P,"g",Q,R),cosmos_get(A,"h",S),set_(R,"h",S,T),cosmos_get(A,"i",U),set_(T,"i",U,V),cosmos_get(A,"turn",W),set_(V,"turn",W,X),D=X),if_(B=1.0,(new(Y),cosmos_get(A,"a",Z),set_(Y,"a",Z,A1),set_(A1,"b",C,B1),cosmos_get(A,"c",C1),set_(B1,"c",C1,D1),cosmos_get(A,"d",E1),set_(D1,"d",E1,F1),cosmos_get(A,"e",G1),set_(F1,"e",G1,H1),cosmos_get(A,"f",I1),set_(H1,"f",I1,J1),cosmos_get(A,"g",K1),set_(J1,"g",K1,L1),cosmos_get(A,"h",M1),set_(L1,"h",M1,N1),cosmos_get(A,"i",O1),set_(N1,"i",O1,P1),cosmos_get(A,"turn",Q1),set_(P1,"turn",Q1,R1),D=R1),if_(B=2.0,(new(S1),cosmos_get(A,"a",T1),set_(S1,"a",T1,U1),cosmos_get(A,"b",V1),set_(U1,"b",V1,W1),set_(W1,"c",C,X1),cosmos_get(A,"d",Y1),set_(X1,"d",Y1,Z1),cosmos_get(A,"e",A2),set_(Z1,"e",A2,B2),cosmos_get(A,"f",C2),set_(B2,"f",C2,D2),cosmos_get(A,"g",E2),set_(D2,"g",E2,F2),cosmos_get(A,"h",G2),set_(F2,"h",G2,H2),cosmos_get(A,"i",I2),set_(H2,"i",I2,J2),cosmos_get(A,"turn",K2),set_(J2,"turn",K2,L2),D=L2),if_(B=3.0,(new(M2),cosmos_get(A,"a",N2),set_(M2,"a",N2,O2),cosmos_get(A,"b",P2),set_(O2,"b",P2,Q2),cosmos_get(A,"c",R2),set_(Q2,"c",R2,S2),set_(S2,"d",C,T2),cosmos_get(A,"e",U2),set_(T2,"e",U2,V2),cosmos_get(A,"f",W2),set_(V2,"f",W2,X2),cosmos_get(A,"g",Y2),set_(X2,"g",Y2,Z2),cosmos_get(A,"h",A3),set_(Z2,"h",A3,B3),cosmos_get(A,"i",C3),set_(B3,"i",C3,D3),cosmos_get(A,"turn",E3),set_(D3,"turn",E3,F3),D=F3),if_(B=4.0,(new(G3),cosmos_get(A,"a",H3),set_(G3,"a",H3,I3),cosmos_get(A,"b",J3),set_(I3,"b",J3,K3),cosmos_get(A,"c",L3),set_(K3,"c",L3,M3),cosmos_get(A,"d",N3),set_(M3,"d",N3,O3),set_(O3,"e",C,P3),cosmos_get(A,"f",Q3),set_(P3,"f",Q3,R3),cosmos_get(A,"g",S3),set_(R3,"g",S3,T3),cosmos_get(A,"h",U3),set_(T3,"h",U3,V3),cosmos_get(A,"i",W3),set_(V3,"i",W3,X3),cosmos_get(A,"turn",Y3),set_(X3,"turn",Y3,Z3),D=Z3),if_(B=5.0,(new(A4),cosmos_get(A,"a",B4),set_(A4,"a",B4,C4),cosmos_get(A,"b",D4),set_(C4,"b",D4,E4),cosmos_get(A,"c",F4),set_(E4,"c",F4,G4),cosmos_get(A,"d",H4),set_(G4,"d",H4,I4),cosmos_get(A,"e",J4),set_(I4,"e",J4,K4),set_(K4,"f",C,L4),cosmos_get(A,"g",M4),set_(L4,"g",M4,N4),cosmos_get(A,"h",O4),set_(N4,"h",O4,P4),cosmos_get(A,"i",Q4),set_(P4,"i",Q4,R4),cosmos_get(A,"turn",S4),set_(R4,"turn",S4,T4),D=T4),if_(B=6.0,(new(U4),cosmos_get(A,"a",V4),set_(U4,"a",V4,W4),cosmos_get(A,"b",X4),set_(W4,"b",X4,Y4),cosmos_get(A,"c",Z4),set_(Y4,"c",Z4,A5),cosmos_get(A,"d",B5),set_(A5,"d",B5,C5),cosmos_get(A,"e",D5),set_(C5,"e",D5,E5),cosmos_get(A,"f",F5),set_(E5,"f",F5,G5),set_(G5,"g",C,H5),cosmos_get(A,"h",I5),set_(H5,"h",I5,J5),cosmos_get(A,"i",K5),set_(J5,"i",K5,L5),cosmos_get(A,"turn",M5),set_(L5,"turn",M5,N5),D=N5),if_(B=7.0,(new(O5),cosmos_get(A,"a",P5),set_(O5,"a",P5,Q5),cosmos_get(A,"b",R5),set_(Q5,"b",R5,S5),cosmos_get(A,"c",T5),set_(S5,"c",T5,U5),cosmos_get(A,"d",V5),set_(U5,"d",V5,W5),cosmos_get(A,"e",X5),set_(W5,"e",X5,Y5),cosmos_get(A,"f",Z5),set_(Y5,"f",Z5,A6),cosmos_get(A,"g",B6),set_(A6,"g",B6,C6),set_(C6,"h",C,D6),cosmos_get(A,"i",E6),set_(D6,"i",E6,F6),cosmos_get(A,"turn",G6),set_(F6,"turn",G6,H6),D=H6),(new(I6),cosmos_get(A,"a",J6),set_(I6,"a",J6,K6),cosmos_get(A,"b",L6),set_(K6,"b",L6,M6),cosmos_get(A,"c",N6),set_(M6,"c",N6,O6),cosmos_get(A,"d",P6),set_(O6,"d",P6,Q6),cosmos_get(A,"e",R6),set_(Q6,"e",R6,S6),cosmos_get(A,"f",T6),set_(S6,"f",T6,U6),cosmos_get(A,"g",V6),set_(U6,"g",V6,W6),cosmos_get(A,"h",X6),set_(W6,"h",X6,Y6),set_(Y6,"i",C,Z6),cosmos_get(A,"turn",A7),set_(Z6,"turn",A7,B7),D=B7))))))))).
'space_tictactoe::$impl_set_turn'(A,B,C):-new(D),cosmos_get(A,"a",E),set_(D,"a",E,F),cosmos_get(A,"b",G),set_(F,"b",G,H),cosmos_get(A,"c",I),set_(H,"c",I,J),cosmos_get(A,"d",K),set_(J,"d",K,L),cosmos_get(A,"e",M),set_(L,"e",M,N),cosmos_get(A,"f",O),set_(N,"f",O,P),cosmos_get(A,"g",Q),set_(P,"g",Q,R),cosmos_get(A,"h",S),set_(R,"h",S,T),cosmos_get(A,"i",U),set_(T,"i",U,V),set_(V,"turn",B,W),C=W.
'space_tictactoe::$impl_draw_mark'(A,B,C,D,E):-(r_mul(B,D,F),add_(F,24.0,G),H=G),(r_mul(C,D,I),add_(I,24.0,J),K=J),if_(A="x",((cosmos_get(E,"graphics",L),cosmos_method(L,"setColor",["#7cf4cb"])),add_(H,24.0,M),add_(K,8.0,N),cosmos_get(E,"graphics",O),cosmos_method(O,"print",["X",M,N])),if_(A="o",((cosmos_get(E,"graphics",P),cosmos_method(P,"setColor",["#f3c969"])),add_(H,24.0,Q),add_(K,8.0,R),cosmos_get(E,"graphics",S),cosmos_method(S,"print",["O",Q,R])),true)).
'space_tictactoe::$impl_draw_cell'(A,B,C,D,E):-(cosmos_get(E,"graphics",F),cosmos_method(F,"setColor",["#36516c"])),(cosmos_get(E,"graphics",G),cosmos_method(G,"setLineWidth",[4.0])),(r_mul(B,D,H),r_mul(C,D,I),cosmos_get(E,"graphics",J),cosmos_method(J,"rectangle",["line",H,I,D,D])),(r_mul(C,3.0,K),add_(B,K,L),'space_tictactoe::cell_at'(A,L,M)),'space_tictactoe::draw_mark'(M,B,C,D,E).
'space_tictactoe::$impl_draw'(A,B,C,D,E):-(cosmos_get(D,"graphics",F),cosmos_method(F,"setColor",["#07111f"])),(cosmos_get(D,"graphics",G),cosmos_method(G,"rectangle",["fill",0.0,0.0,E,C])),(H=0.0,cosmos_while(clos(upvals([]),'space_tictactoe::$closure_0.0'),clos(upvals([B,D,A]),'space_tictactoe::$closure_1.0'),[H],[I])),(cosmos_get(D,"graphics",J),cosmos_method(J,"setColor",["#dcebea"])),cosmos_get(D,"graphics",K),cosmos_method(K,"print",["Tic-tac-toe - click a square; R restarts",16.0,390.0]).
'space_tictactoe::$impl_play'(A,B,C,D,E):-(r_div(A,E,F),int(F,G),H=G),(r_div(B,E,I),int(I,J),K=J),((r_ge(H,0.0),r_lt(H,3.0),r_ge(K,0.0),r_lt(K,3.0)),(r_mul(K,3.0,L),add_(H,L,M),N=M),('space_tictactoe::cell_at'(C,N," "),(cosmos_get(C,"turn",O),'space_tictactoe::put_cell'(C,N,O,P)),cosmos_get(C,"turn",Q),if_(Q="o",'space_tictactoe::set_turn'(P,"x",D),'space_tictactoe::set_turn'(P,"o",D));\+'space_tictactoe::cell_at'(C,N," "),D=C);\+ (r_ge(H,0.0),r_lt(H,3.0),r_ge(K,0.0),r_lt(K,3.0)),D=C).
'space_tictactoe::$impl_mousereleased'(A,B,C,D,E,F):-if_(C=1.0,'space_tictactoe::play'(A,B,D,E,F),E=D).
'space_tictactoe::$impl_keypressed'(A,B,C,D):-if_(A="r",C=D,C=B).
'space_tictactoe::$impl_apply_events'(A,B,C,D,E):-if_(A=[],C=B,(A=[F|G],(cosmos_get(F,"type",H),I=H),if_(I="keydown",(cosmos_get(F,"key",J),'space_tictactoe::keypressed'(J,B,K,E)),if_(I="mouseup",(cosmos_get(F,"x",L),cosmos_get(F,"y",M),cosmos_get(F,"button",N),'space_tictactoe::mousereleased'(L,M,N,B,K,D)),K=B)),'space_tictactoe::apply_events'(G,K,C,D,E))).
'space_tictactoe::$impl_update'(A,B,C,D,E,F):-(cosmos_get(F,"event",G),cosmos_method(G,"get",[H])),'space_tictactoe::apply_events'(H,B,C,D,E).
space_tictactoe([]):-cosmos_require("space",A),B=600.0,C=450.0,D=120.0,(new(E),set_(E,"a"," ",F),set_(F,"b"," ",G),set_(G,"c"," ",H),set_(H,"d"," ",I),set_(I,"e"," ",J),set_(J,"f"," ",K),set_(K,"g"," ",L),set_(L,"h"," ",M),set_(M,"i"," ",N),set_(N,"turn","o",O),P=O),cosmos_method(A,"init",[B,C]),new(Q),set_(Q,"update",clos(upvals([D,P,A]),'space_tictactoe::$value_update'),R),set_(R,"draw",clos(upvals([D,C,A,B]),'space_tictactoe::$value_draw'),S),cosmos_method(A,"start",[16.0,S,P]).
'space_tictactoe::cell_at'(A,B,C):-'space_tictactoe::$impl_cell_at'(A,B,C).
'space_tictactoe::$value_cell_at'(A,B,C,upvals([])):-'space_tictactoe::cell_at'(A,B,C).
'space_tictactoe::put_cell'(A,B,C,D):-'space_tictactoe::$impl_put_cell'(A,B,C,D).
'space_tictactoe::$value_put_cell'(A,B,C,D,upvals([])):-'space_tictactoe::put_cell'(A,B,C,D).
'space_tictactoe::set_turn'(A,B,C):-'space_tictactoe::$impl_set_turn'(A,B,C).
'space_tictactoe::$value_set_turn'(A,B,C,upvals([])):-'space_tictactoe::set_turn'(A,B,C).
'space_tictactoe::draw_mark'(A,B,C,D,E):-'space_tictactoe::$impl_draw_mark'(A,B,C,D,E).
'space_tictactoe::$value_draw_mark'(A,B,C,upvals([D,E])):-'space_tictactoe::draw_mark'(A,B,C,D,E).
'space_tictactoe::draw_cell'(A,B,C,D,E):-'space_tictactoe::$impl_draw_cell'(A,B,C,D,E).
'space_tictactoe::$value_draw_cell'(A,B,C,upvals([D,E])):-'space_tictactoe::draw_cell'(A,B,C,D,E).
'space_tictactoe::$closure_0.0'([A],upvals([])):-r_lt(A,3.0).
'space_tictactoe::$closure_2.0'([A],upvals([])):-r_lt(A,3.0).
'space_tictactoe::$closure_3.0'([A],B,upvals([C,D,E,F])):-('space_tictactoe::draw_cell'(F,A,C,D,E),(add_(A,1.0,G),H=G),I=H),B=[H],I=H.
'space_tictactoe::$closure_1.0'([A],B,upvals([C,D,E])):-((F=0.0,cosmos_while(clos(upvals([]),'space_tictactoe::$closure_2.0'),clos(upvals([A,C,D,E]),'space_tictactoe::$closure_3.0'),[F],[G])),(add_(A,1.0,H),I=H),J=I),B=[I],J=I.
'space_tictactoe::draw'(A,B,C,D,E):-'space_tictactoe::$impl_draw'(A,B,C,D,E).
'space_tictactoe::$value_draw'(A,upvals([B,C,D,E])):-'space_tictactoe::draw'(A,B,C,D,E).
'space_tictactoe::play'(A,B,C,D,E):-'space_tictactoe::$impl_play'(A,B,C,D,E).
'space_tictactoe::$value_play'(A,B,C,D,upvals([E])):-'space_tictactoe::play'(A,B,C,D,E).
'space_tictactoe::mousereleased'(A,B,C,D,E,F):-'space_tictactoe::$impl_mousereleased'(A,B,C,D,E,F).
'space_tictactoe::$value_mousereleased'(A,B,C,D,E,upvals([F])):-'space_tictactoe::mousereleased'(A,B,C,D,E,F).
'space_tictactoe::keypressed'(A,B,C,D):-'space_tictactoe::$impl_keypressed'(A,B,C,D).
'space_tictactoe::$value_keypressed'(A,B,C,upvals([D])):-'space_tictactoe::keypressed'(A,B,C,D).
'space_tictactoe::apply_events'(A,B,C,D,E):-'space_tictactoe::$impl_apply_events'(A,B,C,D,E).
'space_tictactoe::$value_apply_events'(A,B,C,upvals([D,E])):-'space_tictactoe::apply_events'(A,B,C,D,E).
'space_tictactoe::update'(A,B,C,D,E,F):-'space_tictactoe::$impl_update'(A,B,C,D,E,F).
'space_tictactoe::$value_update'(A,B,C,upvals([D,E,F])):-'space_tictactoe::update'(A,B,C,D,E,F).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], space_tictactoe([])),cosmos_profile_finish)
    ).
