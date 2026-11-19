:- style_check(-singleton).
'snake::$impl_reset'(A,B):-A=B.
'snake::$impl_same'(A,B,C,D):-A=C,B=D.
'snake::$impl_make_state'(A,B,C,D,E,F,G,H,I,J,K):-new(L),set_(L,"body",A,M),set_(M,"food_x",B,N),set_(N,"food_y",C,O),set_(O,"dir_x",D,P),set_(P,"dir_y",E,Q),set_(Q,"next_x",F,R),set_(R,"next_y",G,S),set_(S,"score",H,T),set_(T,"game_over",I,U),set_(U,"win",J,V),K=V.
'snake::$impl_hits'(A,B,C):-A=[[D,E]|F],((D=B,E=C),true;\+ (D=B,E=C),'snake::hits'(F,B,C)).
'snake::$impl_drop_last'(A,B):-if_(A=[],B=[],(A=[C|D],if_(D=[],B=[],(B=[C|E],'snake::drop_last'(D,E))))).
'snake::$impl_place_food'(A,B,C,D):-(cosmos_receiver("math",D),cosmos_method(D,"random",[1.0,18.0,B])),(cosmos_receiver("math",D),cosmos_method(D,"random",[1.0,18.0,C])),('snake::hits'(A,B,C),'snake::place_food'(A,B,C,D);true).
'snake::$impl_apply_key'(A,B,C,D):-(A="up",cosmos_get(B,"dir_y",E),dif(E,1.0)),cosmos_get(B,"body",F),cosmos_get(B,"food_x",G),cosmos_get(B,"food_y",H),r_sub(0.0,1.0,I),r_sub(0.0,1.0,J),cosmos_get(B,"score",K),cosmos_get(B,"game_over",L),cosmos_get(B,"win",M),'snake::make_state'(F,G,H,0.0,I,0.0,J,K,L,M,C);\+ (A="up",cosmos_get(B,"dir_y",N),dif(N,1.0)),((A="down",cosmos_get(B,"dir_y",O),r_sub(0.0,1.0,P),dif(O,P)),cosmos_get(B,"body",Q),cosmos_get(B,"food_x",R),cosmos_get(B,"food_y",S),cosmos_get(B,"score",T),cosmos_get(B,"game_over",U),cosmos_get(B,"win",V),'snake::make_state'(Q,R,S,0.0,1.0,0.0,1.0,T,U,V,C);\+ (A="down",cosmos_get(B,"dir_y",W),r_sub(0.0,1.0,X),dif(W,X)),((A="left",cosmos_get(B,"dir_x",Y),dif(Y,1.0)),cosmos_get(B,"body",Z),cosmos_get(B,"food_x",A1),cosmos_get(B,"food_y",B1),r_sub(0.0,1.0,C1),r_sub(0.0,1.0,D1),cosmos_get(B,"score",E1),cosmos_get(B,"game_over",F1),cosmos_get(B,"win",G1),'snake::make_state'(Z,A1,B1,C1,0.0,D1,0.0,E1,F1,G1,C);\+ (A="left",cosmos_get(B,"dir_x",H1),dif(H1,1.0)),((A="right",cosmos_get(B,"dir_x",I1),r_sub(0.0,1.0,J1),dif(I1,J1)),cosmos_get(B,"body",K1),cosmos_get(B,"food_x",L1),cosmos_get(B,"food_y",M1),cosmos_get(B,"score",N1),cosmos_get(B,"game_over",O1),cosmos_get(B,"win",P1),'snake::make_state'(K1,L1,M1,1.0,0.0,1.0,0.0,N1,O1,P1,C);\+ (A="right",cosmos_get(B,"dir_x",Q1),r_sub(0.0,1.0,R1),dif(Q1,R1)),((A="r",cosmos_set_or_unify(B,"game_over",fc_True)),C=D;\+ (A="r",cosmos_set_or_unify(B,"game_over",fc_True)),C=B)))).
'snake::$impl_tick'(A,B,C,D):-cosmos_get(A,"game_over",E),if_(E=fc_True,B=A,((cosmos_get(A,"body",F),G=F),G=[H|I],H=[J,K],(cosmos_get(A,"next_x",L),add_(J,L,M),N=M),(cosmos_get(A,"next_y",O),add_(K,O,P),Q=P),((r_lt(N,0.0);r_ge(N,C);r_lt(Q,0.0);r_ge(Q,C)),cosmos_get(A,"body",R),cosmos_get(A,"food_x",S),cosmos_get(A,"food_y",T),cosmos_get(A,"next_x",U),cosmos_get(A,"next_y",V),cosmos_get(A,"next_x",W),cosmos_get(A,"next_y",X),cosmos_get(A,"score",Y),'snake::make_state'(R,S,T,U,V,W,X,Y,fc_True,fc_False,B);\+ (r_lt(N,0.0);r_ge(N,C);r_lt(Q,0.0);r_ge(Q,C)),((cosmos_get(A,"body",Z),'snake::hits'(Z,N,Q)),cosmos_get(A,"body",A1),cosmos_get(A,"food_x",B1),cosmos_get(A,"food_y",C1),cosmos_get(A,"next_x",D1),cosmos_get(A,"next_y",E1),cosmos_get(A,"next_x",F1),cosmos_get(A,"next_y",G1),cosmos_get(A,"score",H1),'snake::make_state'(A1,B1,C1,D1,E1,F1,G1,H1,fc_True,fc_False,B);\+ (cosmos_get(A,"body",I1),'snake::hits'(I1,N,Q)),((cosmos_get(A,"food_x",J1),cosmos_get(A,"food_y",K1),'snake::same'(N,Q,J1,K1)),(cosmos_get(A,"body",L1),M1=[[N,Q]|L1]),'snake::place_food'(M1,N1,O1,D),cosmos_get(A,"next_x",P1),cosmos_get(A,"next_y",Q1),cosmos_get(A,"next_x",R1),cosmos_get(A,"next_y",S1),cosmos_get(A,"score",T1),add_(T1,1.0,U1),'snake::make_state'(M1,N1,O1,P1,Q1,R1,S1,U1,fc_False,fc_False,B);\+ (cosmos_get(A,"food_x",V1),cosmos_get(A,"food_y",W1),'snake::same'(N,Q,V1,W1)),(cosmos_get(A,"body",X1),M1=[[N,Q]|X1]),'snake::drop_last'(M1,Y1),cosmos_get(A,"food_x",Z1),cosmos_get(A,"food_y",A2),cosmos_get(A,"next_x",B2),cosmos_get(A,"next_y",C2),cosmos_get(A,"next_x",D2),cosmos_get(A,"next_y",E2),cosmos_get(A,"score",F2),'snake::make_state'(Y1,Z1,A2,B2,C2,D2,E2,F2,fc_False,fc_False,B)))))).
'snake::$impl_update'(A,B,C,D,E,F):-(cosmos_get(F,"event",G),cosmos_method(G,"get",[H])),'snake::apply_events'(H,A,I,D),'snake::tick'(I,B,C,E).
'snake::$impl_apply_events'(A,B,C,D):-if_(A=[],C=B,(A=[E|F],(cosmos_get(E,"type",G),H=G),if_(H="keydown",(cosmos_get(E,"key",I),'snake::apply_key'(I,B,J,D)),J=B),'snake::apply_events'(F,J,C,D))).
'snake::$impl_draw_cell'(A,B,C,D,E):-(cosmos_get(E,"graphics",F),cosmos_method(F,"setColor",[C])),r_mul(A,D,G),add_(G,1.0,H),r_mul(B,D,I),add_(I,1.0,J),r_sub(D,2.0,K),r_sub(D,2.0,L),cosmos_get(E,"graphics",M),cosmos_method(M,"rectangle",["fill",H,J,K,L]).
'snake::$impl_draw_body'(A,B,C):-if_(A=[],true,(A=[D|E],D=[F,G],'snake::draw_cell'(F,G,"#42d99a",B,C),'snake::draw_body'(E,B,C))).
'snake::$impl_render'(A,B,C,D):-(cosmos_get(D,"graphics",E),cosmos_method(E,"setColor",["#0b1220"])),(cosmos_get(D,"graphics",F),cosmos_method(F,"rectangle",["fill",0.0,0.0,B,B])),(cosmos_get(A,"food_x",G),cosmos_get(A,"food_y",H),'snake::draw_cell'(G,H,"#ff6b6b",C,D)),(cosmos_get(A,"body",I),'snake::draw_body'(I,C,D)),(cosmos_get(A,"body",J),K=J),K=[L|M],L=[N,O],'snake::draw_cell'(N,O,"#b4ffe2",C,D),cosmos_get(A,"game_over",P),if_(P=fc_True,((cosmos_get(D,"graphics",Q),cosmos_method(Q,"setColor",["#182235"])),(cosmos_get(D,"graphics",R),cosmos_method(R,"rectangle",["fill",90.0,200.0,300.0,80.0])),(cosmos_get(D,"graphics",S),cosmos_method(S,"setColor",["#f3c969"])),(cosmos_get(D,"graphics",T),cosmos_method(T,"printf",["GAME OVER",90.0,214.0,300.0,"center"])),(cosmos_get(D,"graphics",U),cosmos_method(U,"setColor",["#9bb7c6"])),cosmos_get(D,"graphics",V),cosmos_method(V,"printf",["press R to restart",90.0,246.0,300.0,"center"])),true).
snake([]):-cosmos_require("space",A),cosmos_require("math",B),C=20.0,D=24.0,E=480.0,F=140.0,(new(G),set_(G,"body",[[10.0,10.0],[9.0,10.0],[8.0,10.0]],H),set_(H,"food_x",14.0,I),set_(I,"food_y",10.0,J),set_(J,"dir_x",1.0,K),set_(K,"dir_y",0.0,L),set_(L,"next_x",1.0,M),set_(M,"next_y",0.0,N),set_(N,"score",0.0,O),set_(O,"game_over",fc_False,P),set_(P,"win",fc_False,Q),R=Q),cosmos_method(A,"init",[E,E]),(new(S),set_(S,"update",clos(upvals([C,R,B,A]),'snake::$value_update'),T),set_(T,"draw",clos(upvals([E,D,A]),'snake::$value_render'),U),cosmos_method(A,"start",[F,U,R])),cosmos_require("xpce",V),cosmos_method(V,"main_loop",[W]).
'snake::reset'(A,B):-'snake::$impl_reset'(A,B).
'snake::$value_reset'(A,upvals([B])):-'snake::reset'(A,B).
'snake::same'(A,B,C,D):-'snake::$impl_same'(A,B,C,D).
'snake::$value_same'(A,B,C,D,upvals([])):-'snake::same'(A,B,C,D).
'snake::make_state'(A,B,C,D,E,F,G,H,I,J,K):-'snake::$impl_make_state'(A,B,C,D,E,F,G,H,I,J,K).
'snake::$value_make_state'(A,B,C,D,E,F,G,H,I,J,K,upvals([])):-'snake::make_state'(A,B,C,D,E,F,G,H,I,J,K).
'snake::hits'(A,B,C):-'snake::$impl_hits'(A,B,C).
'snake::$value_hits'(A,B,C,upvals([])):-'snake::hits'(A,B,C).
'snake::drop_last'(A,B):-'snake::$impl_drop_last'(A,B).
'snake::$value_drop_last'(A,B,upvals([])):-'snake::drop_last'(A,B).
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
'snake::draw_body'(A,B,C):-'snake::$impl_draw_body'(A,B,C).
'snake::$value_draw_body'(A,upvals([B,C])):-'snake::draw_body'(A,B,C).
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
