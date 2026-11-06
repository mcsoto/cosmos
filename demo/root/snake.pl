:- style_check(-singleton).
'snake::$impl_reset'(A,B):-A=B.
'snake::$impl_same'(A,B,C,D):-A=C,B=D.
'snake::$impl_occupied'(A,B,C):-cosmos_get(A,"head_x",D),cosmos_get(A,"head_y",E),'snake::same'(B,D,C,E);cosmos_get(A,"body1_x",F),cosmos_get(A,"body1_y",G),'snake::same'(B,F,C,G);cosmos_get(A,"body2_x",H),cosmos_get(A,"body2_y",I),'snake::same'(B,H,C,I).
'snake::$impl_place_food'(A,B,C,D):-(cosmos_receiver("math",D),cosmos_method(D,"random",[1.0,18.0,B])),(cosmos_receiver("math",D),cosmos_method(D,"random",[1.0,18.0,C])),('snake::occupied'(A,B,C),'snake::place_food'(A,B,C,D);true).
'snake::$impl_apply_key'(A,B,C,D):-(A="up",cosmos_get(B,"dir_y",E),dif(E,1.0)),new(F),cosmos_get(B,"head_x",G),set_(F,"head_x",G,H),cosmos_get(B,"head_y",I),set_(H,"head_y",I,J),cosmos_get(B,"body1_x",K),set_(J,"body1_x",K,L),cosmos_get(B,"body1_y",M),set_(L,"body1_y",M,N),cosmos_get(B,"body2_x",O),set_(N,"body2_x",O,P),cosmos_get(B,"body2_y",Q),set_(P,"body2_y",Q,R),cosmos_get(B,"food_x",S),set_(R,"food_x",S,T),cosmos_get(B,"food_y",U),set_(T,"food_y",U,V),set_(V,"dir_x",0.0,W),r_sub(0.0,1.0,X),set_(W,"dir_y",X,Y),set_(Y,"next_x",0.0,Z),r_sub(0.0,1.0,A1),set_(Z,"next_y",A1,B1),cosmos_get(B,"score",C1),set_(B1,"score",C1,D1),cosmos_get(B,"game_over",E1),set_(D1,"game_over",E1,F1),cosmos_get(B,"win",G1),set_(F1,"win",G1,H1),C=H1;\+ (A="up",cosmos_get(B,"dir_y",I1),dif(I1,1.0)),((A="down",cosmos_get(B,"dir_y",J1),r_sub(0.0,1.0,K1),dif(J1,K1)),new(L1),cosmos_get(B,"head_x",M1),set_(L1,"head_x",M1,N1),cosmos_get(B,"head_y",O1),set_(N1,"head_y",O1,P1),cosmos_get(B,"body1_x",Q1),set_(P1,"body1_x",Q1,R1),cosmos_get(B,"body1_y",S1),set_(R1,"body1_y",S1,T1),cosmos_get(B,"body2_x",U1),set_(T1,"body2_x",U1,V1),cosmos_get(B,"body2_y",W1),set_(V1,"body2_y",W1,X1),cosmos_get(B,"food_x",Y1),set_(X1,"food_x",Y1,Z1),cosmos_get(B,"food_y",A2),set_(Z1,"food_y",A2,B2),set_(B2,"dir_x",0.0,C2),set_(C2,"dir_y",1.0,D2),set_(D2,"next_x",0.0,E2),set_(E2,"next_y",1.0,F2),cosmos_get(B,"score",G2),set_(F2,"score",G2,H2),cosmos_get(B,"game_over",I2),set_(H2,"game_over",I2,J2),cosmos_get(B,"win",K2),set_(J2,"win",K2,L2),C=L2;\+ (A="down",cosmos_get(B,"dir_y",M2),r_sub(0.0,1.0,N2),dif(M2,N2)),((A="left",cosmos_get(B,"dir_x",O2),dif(O2,1.0)),new(P2),cosmos_get(B,"head_x",Q2),set_(P2,"head_x",Q2,R2),cosmos_get(B,"head_y",S2),set_(R2,"head_y",S2,T2),cosmos_get(B,"body1_x",U2),set_(T2,"body1_x",U2,V2),cosmos_get(B,"body1_y",W2),set_(V2,"body1_y",W2,X2),cosmos_get(B,"body2_x",Y2),set_(X2,"body2_x",Y2,Z2),cosmos_get(B,"body2_y",A3),set_(Z2,"body2_y",A3,B3),cosmos_get(B,"food_x",C3),set_(B3,"food_x",C3,D3),cosmos_get(B,"food_y",E3),set_(D3,"food_y",E3,F3),r_sub(0.0,1.0,G3),set_(F3,"dir_x",G3,H3),set_(H3,"dir_y",0.0,I3),r_sub(0.0,1.0,J3),set_(I3,"next_x",J3,K3),set_(K3,"next_y",0.0,L3),cosmos_get(B,"score",M3),set_(L3,"score",M3,N3),cosmos_get(B,"game_over",O3),set_(N3,"game_over",O3,P3),cosmos_get(B,"win",Q3),set_(P3,"win",Q3,R3),C=R3;\+ (A="left",cosmos_get(B,"dir_x",S3),dif(S3,1.0)),((A="right",cosmos_get(B,"dir_x",T3),r_sub(0.0,1.0,U3),dif(T3,U3)),new(V3),cosmos_get(B,"head_x",W3),set_(V3,"head_x",W3,X3),cosmos_get(B,"head_y",Y3),set_(X3,"head_y",Y3,Z3),cosmos_get(B,"body1_x",A4),set_(Z3,"body1_x",A4,B4),cosmos_get(B,"body1_y",C4),set_(B4,"body1_y",C4,D4),cosmos_get(B,"body2_x",E4),set_(D4,"body2_x",E4,F4),cosmos_get(B,"body2_y",G4),set_(F4,"body2_y",G4,H4),cosmos_get(B,"food_x",I4),set_(H4,"food_x",I4,J4),cosmos_get(B,"food_y",K4),set_(J4,"food_y",K4,L4),set_(L4,"dir_x",1.0,M4),set_(M4,"dir_y",0.0,N4),set_(N4,"next_x",1.0,O4),set_(O4,"next_y",0.0,P4),cosmos_get(B,"score",Q4),set_(P4,"score",Q4,R4),cosmos_get(B,"game_over",S4),set_(R4,"game_over",S4,T4),cosmos_get(B,"win",U4),set_(T4,"win",U4,V4),C=V4;\+ (A="right",cosmos_get(B,"dir_x",W4),r_sub(0.0,1.0,X4),dif(W4,X4)),((A="r",cosmos_set_or_unify(B,"game_over",fc_True)),C=D;\+ (A="r",cosmos_set_or_unify(B,"game_over",fc_True)),C=B)))).
'snake::$impl_tick'(A,B,C,D):-cosmos_get(A,"game_over",E),if_(E=fc_True,B=A,((cosmos_get(A,"head_x",F),cosmos_get(A,"next_x",G),add_(F,G,H),I=H),(cosmos_get(A,"head_y",J),cosmos_get(A,"next_y",K),add_(J,K,L),M=L),((r_lt(I,0.0);r_ge(I,C);r_lt(M,0.0);r_ge(M,C)),new(N),cosmos_get(A,"head_x",O),set_(N,"head_x",O,P),cosmos_get(A,"head_y",Q),set_(P,"head_y",Q,R),cosmos_get(A,"body1_x",S),set_(R,"body1_x",S,T),cosmos_get(A,"body1_y",U),set_(T,"body1_y",U,V),cosmos_get(A,"body2_x",W),set_(V,"body2_x",W,X),cosmos_get(A,"body2_y",Y),set_(X,"body2_y",Y,Z),cosmos_get(A,"food_x",A1),set_(Z,"food_x",A1,B1),cosmos_get(A,"food_y",C1),set_(B1,"food_y",C1,D1),cosmos_get(A,"next_x",E1),set_(D1,"dir_x",E1,F1),cosmos_get(A,"next_y",G1),set_(F1,"dir_y",G1,H1),cosmos_get(A,"next_x",I1),set_(H1,"next_x",I1,J1),cosmos_get(A,"next_y",K1),set_(J1,"next_y",K1,L1),cosmos_get(A,"score",M1),set_(L1,"score",M1,N1),set_(N1,"game_over",fc_True,O1),set_(O1,"win",fc_False,P1),B=P1;\+ (r_lt(I,0.0);r_ge(I,C);r_lt(M,0.0);r_ge(M,C)),((cosmos_get(A,"body1_x",Q1),cosmos_get(A,"body1_y",R1),'snake::same'(I,M,Q1,R1);cosmos_get(A,"body2_x",S1),cosmos_get(A,"body2_y",T1),'snake::same'(I,M,S1,T1)),new(U1),cosmos_get(A,"head_x",V1),set_(U1,"head_x",V1,W1),cosmos_get(A,"head_y",X1),set_(W1,"head_y",X1,Y1),cosmos_get(A,"body1_x",Z1),set_(Y1,"body1_x",Z1,A2),cosmos_get(A,"body1_y",B2),set_(A2,"body1_y",B2,C2),cosmos_get(A,"body2_x",D2),set_(C2,"body2_x",D2,E2),cosmos_get(A,"body2_y",F2),set_(E2,"body2_y",F2,G2),cosmos_get(A,"food_x",H2),set_(G2,"food_x",H2,I2),cosmos_get(A,"food_y",J2),set_(I2,"food_y",J2,K2),cosmos_get(A,"next_x",L2),set_(K2,"dir_x",L2,M2),cosmos_get(A,"next_y",N2),set_(M2,"dir_y",N2,O2),cosmos_get(A,"next_x",P2),set_(O2,"next_x",P2,Q2),cosmos_get(A,"next_y",R2),set_(Q2,"next_y",R2,S2),cosmos_get(A,"score",T2),set_(S2,"score",T2,U2),set_(U2,"game_over",fc_True,V2),set_(V2,"win",fc_False,W2),B=W2;\+ (cosmos_get(A,"body1_x",X2),cosmos_get(A,"body1_y",Y2),'snake::same'(I,M,X2,Y2);cosmos_get(A,"body2_x",Z2),cosmos_get(A,"body2_y",A3),'snake::same'(I,M,Z2,A3)),((cosmos_get(A,"food_x",B3),cosmos_get(A,"food_y",C3),'snake::same'(I,M,B3,C3)),'snake::place_food'(A,D3,E3,D),new(F3),set_(F3,"head_x",I,G3),set_(G3,"head_y",M,H3),cosmos_get(A,"head_x",I3),set_(H3,"body1_x",I3,J3),cosmos_get(A,"head_y",K3),set_(J3,"body1_y",K3,L3),cosmos_get(A,"body1_x",M3),set_(L3,"body2_x",M3,N3),cosmos_get(A,"body1_y",O3),set_(N3,"body2_y",O3,P3),set_(P3,"food_x",D3,Q3),set_(Q3,"food_y",E3,R3),cosmos_get(A,"next_x",S3),set_(R3,"dir_x",S3,T3),cosmos_get(A,"next_y",U3),set_(T3,"dir_y",U3,V3),cosmos_get(A,"next_x",W3),set_(V3,"next_x",W3,X3),cosmos_get(A,"next_y",Y3),set_(X3,"next_y",Y3,Z3),cosmos_get(A,"score",A4),add_(A4,1.0,B4),set_(Z3,"score",B4,C4),set_(C4,"game_over",fc_False,D4),set_(D4,"win",fc_False,E4),B=E4;\+ (cosmos_get(A,"food_x",F4),cosmos_get(A,"food_y",G4),'snake::same'(I,M,F4,G4)),new(H4),set_(H4,"head_x",I,I4),set_(I4,"head_y",M,J4),cosmos_get(A,"head_x",K4),set_(J4,"body1_x",K4,L4),cosmos_get(A,"head_y",M4),set_(L4,"body1_y",M4,N4),cosmos_get(A,"body1_x",O4),set_(N4,"body2_x",O4,P4),cosmos_get(A,"body1_y",Q4),set_(P4,"body2_y",Q4,R4),cosmos_get(A,"food_x",S4),set_(R4,"food_x",S4,T4),cosmos_get(A,"food_y",U4),set_(T4,"food_y",U4,V4),cosmos_get(A,"next_x",W4),set_(V4,"dir_x",W4,X4),cosmos_get(A,"next_y",Y4),set_(X4,"dir_y",Y4,Z4),cosmos_get(A,"next_x",A5),set_(Z4,"next_x",A5,B5),cosmos_get(A,"next_y",C5),set_(B5,"next_y",C5,D5),cosmos_get(A,"score",E5),set_(D5,"score",E5,F5),set_(F5,"game_over",fc_False,G5),set_(G5,"win",fc_False,H5),B=H5))))).
'snake::$impl_update'(A,B,C,D,E,F):-(cosmos_get(F,"event",G),cosmos_method(G,"get",[H])),'snake::apply_events'(H,A,I,D),'snake::tick'(I,B,C,E).
'snake::$impl_apply_events'(A,B,C,D):-if_(A=[],C=B,(A=[E|F],(cosmos_get(E,"type",G),H=G),if_(H="keydown",(cosmos_get(E,"key",I),'snake::apply_key'(I,B,J,D)),J=B),'snake::apply_events'(F,J,C,D))).
'snake::$impl_draw_cell'(A,B,C,D,E):-(cosmos_get(E,"graphics",F),cosmos_method(F,"setColor",[C])),r_mul(A,D,G),add_(G,1.0,H),r_mul(B,D,I),add_(I,1.0,J),r_sub(D,2.0,K),r_sub(D,2.0,L),cosmos_get(E,"graphics",M),cosmos_method(M,"rectangle",["fill",H,J,K,L]).
'snake::$impl_render'(A,B,C,D):-(cosmos_get(D,"graphics",E),cosmos_method(E,"setColor",["#0b1220"])),(cosmos_get(D,"graphics",F),cosmos_method(F,"rectangle",["fill",0.0,0.0,B,B])),(cosmos_get(A,"food_x",G),cosmos_get(A,"food_y",H),'snake::draw_cell'(G,H,"#ff6b6b",C,D)),(cosmos_get(A,"body2_x",I),cosmos_get(A,"body2_y",J),'snake::draw_cell'(I,J,"#2fbf87",C,D)),(cosmos_get(A,"body1_x",K),cosmos_get(A,"body1_y",L),'snake::draw_cell'(K,L,"#42d99a",C,D)),(cosmos_get(A,"head_x",M),cosmos_get(A,"head_y",N),'snake::draw_cell'(M,N,"#b4ffe2",C,D)),cosmos_get(A,"game_over",O),if_(O=fc_True,((cosmos_get(D,"graphics",P),cosmos_method(P,"setColor",["#182235"])),cosmos_get(D,"graphics",Q),cosmos_method(Q,"rectangle",["fill",120.0,216.0,240.0,48.0])),true).
snake([]):-cosmos_require("space",A),cosmos_require("math",B),C=20.0,D=24.0,E=480.0,F=140.0,(new(G),set_(G,"head_x",10.0,H),set_(H,"head_y",10.0,I),set_(I,"body1_x",9.0,J),set_(J,"body1_y",10.0,K),set_(K,"body2_x",8.0,L),set_(L,"body2_y",10.0,M),set_(M,"food_x",14.0,N),set_(N,"food_y",10.0,O),set_(O,"dir_x",1.0,P),set_(P,"dir_y",0.0,Q),set_(Q,"next_x",1.0,R),set_(R,"next_y",0.0,S),set_(S,"score",0.0,T),set_(T,"game_over",fc_False,U),set_(U,"win",fc_False,V),W=V),cosmos_method(A,"init",[E,E]),new(X),set_(X,"update",clos(upvals([C,W,B,A]),'snake::$value_update'),Y),set_(Y,"draw",clos(upvals([E,D,A]),'snake::$value_render'),Z),cosmos_method(A,"start",[F,Z,W]).
'snake::reset'(A,B):-'snake::$impl_reset'(A,B).
'snake::$value_reset'(A,upvals([B])):-'snake::reset'(A,B).
'snake::same'(A,B,C,D):-'snake::$impl_same'(A,B,C,D).
'snake::$value_same'(A,B,C,D,upvals([])):-'snake::same'(A,B,C,D).
'snake::occupied'(A,B,C):-'snake::$impl_occupied'(A,B,C).
'snake::$value_occupied'(A,B,C,upvals([])):-'snake::occupied'(A,B,C).
'snake::place_food'(A,B,C,D):-'snake::$impl_place_food'(A,B,C,D).
'snake::$value_place_food'(A,B,C,upvals([D])):-'snake::place_food'(A,B,C,D).
'snake::apply_key'(A,B,C,D):-'snake::$impl_apply_key'(A,B,C,D).
'snake::$value_apply_key'(A,B,C,upvals([D])):-'snake::apply_key'(A,B,C,D).
'snake::tick'(A,B,C,D):-'snake::$impl_tick'(A,B,C,D).
'snake::$value_tick'(A,B,upvals([C,D])):-'snake::tick'(A,B,C,D).
'snake::update'(A,B,C,D,E,F):-'snake::$impl_update'(A,B,C,D,E,F).
'snake::$value_update'(A,B,upvals([C,D,E,F])):-'snake::update'(A,B,C,D,E,F).
'snake::apply_events'(A,B,C,D):-'snake::$impl_apply_events'(A,B,C,D).
'snake::$value_apply_events'(A,B,C,upvals([D])):-'snake::apply_events'(A,B,C,D).
'snake::draw_cell'(A,B,C,D,E):-'snake::$impl_draw_cell'(A,B,C,D,E).
'snake::$value_draw_cell'(A,B,C,upvals([D,E])):-'snake::draw_cell'(A,B,C,D,E).
'snake::render'(A,B,C,D):-'snake::$impl_render'(A,B,C,D).
'snake::$value_render'(A,upvals([B,C,D])):-'snake::render'(A,B,C,D).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], snake([])),cosmos_profile_finish)
    ).
