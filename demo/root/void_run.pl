:- style_check(-singleton).
'void_run::$impl_same'(A,B,C,D):-A=C,B=D.
'void_run::$impl_wall'(A,B):-A=4.0,r_ge(B,1.0),r_le(B,6.0);A=8.0,r_ge(B,4.0),r_le(B,10.0);A=12.0,r_ge(B,1.0),r_le(B,6.0);B=8.0,r_ge(A,2.0),r_le(A,5.0);B=3.0,r_ge(A,9.0),r_le(A,11.0).
'void_run::$impl_sentry'(A,B):-A=6.0,B=2.0;A=10.0,B=7.0;A=14.0,B=4.0;A=3.0,B=9.0.
'void_run::$impl_copy_state'(A,B,C,D,E,F,G,H,I,J,K,L,M):-new(N),set_(N,"x",C,O),set_(O,"y",D,P),set_(P,"c1",E,Q),set_(Q,"c2",F,R),set_(R,"c3",G,S),set_(S,"c4",H,T),set_(T,"score",I,U),set_(U,"lives",J,V),set_(V,"moves",K,W),set_(W,"game_over",L,X),set_(X,"win",M,Y),B=Y.
'void_run::$impl_collect'(A,B,C,D,E,F,G,H):-('void_run::same'(A,B,2.0,6.0),cosmos_set_or_unify(C,"c1",0.0)),D=1.0,(cosmos_get(C,"c2",I),E=I),(cosmos_get(C,"c3",J),F=J),(cosmos_get(C,"c4",K),G=K),cosmos_get(C,"score",L),add_(L,1.0,M),H=M;\+ ('void_run::same'(A,B,2.0,6.0),cosmos_set_or_unify(C,"c1",0.0)),(('void_run::same'(A,B,6.0,9.0),cosmos_set_or_unify(C,"c2",0.0)),(cosmos_get(C,"c1",N),D=N),E=1.0,(cosmos_get(C,"c3",O),F=O),(cosmos_get(C,"c4",P),G=P),cosmos_get(C,"score",Q),add_(Q,1.0,R),H=R;\+ ('void_run::same'(A,B,6.0,9.0),cosmos_set_or_unify(C,"c2",0.0)),(('void_run::same'(A,B,10.0,2.0),cosmos_set_or_unify(C,"c3",0.0)),(cosmos_get(C,"c1",S),D=S),(cosmos_get(C,"c2",T),E=T),F=1.0,(cosmos_get(C,"c4",U),G=U),cosmos_get(C,"score",V),add_(V,1.0,W),H=W;\+ ('void_run::same'(A,B,10.0,2.0),cosmos_set_or_unify(C,"c3",0.0)),(('void_run::same'(A,B,15.0,8.0),cosmos_set_or_unify(C,"c4",0.0)),(cosmos_get(C,"c1",X),D=X),(cosmos_get(C,"c2",Y),E=Y),(cosmos_get(C,"c3",Z),F=Z),G=1.0,cosmos_get(C,"score",A1),add_(A1,1.0,B1),H=B1;\+ ('void_run::same'(A,B,15.0,8.0),cosmos_set_or_unify(C,"c4",0.0)),(cosmos_get(C,"c1",C1),D=C1),(cosmos_get(C,"c2",D1),E=D1),(cosmos_get(C,"c3",E1),F=E1),(cosmos_get(C,"c4",F1),G=F1),cosmos_get(C,"score",G1),H=G1))).
'void_run::$impl_move'(A,B,C,D,E,F):-cosmos_get(C,"game_over",G),if_(G=1.0,D=C,(cosmos_get(C,"win",H),if_(H=1.0,D=C,((cosmos_get(C,"x",I),add_(I,A,J),K=J),(cosmos_get(C,"y",L),add_(L,B,M),N=M),((r_lt(K,1.0);r_gt(K,E);r_lt(N,1.0);r_gt(N,F)),D=C;\+ (r_lt(K,1.0);r_gt(K,E);r_lt(N,1.0);r_gt(N,F)),('void_run::wall'(K,N),D=C;\+'void_run::wall'(K,N),('void_run::sentry'(K,N),((cosmos_get(C,"lives",O),r_le(O,1.0)),cosmos_get(C,"c1",P),cosmos_get(C,"c2",Q),cosmos_get(C,"c3",R),cosmos_get(C,"c4",S),cosmos_get(C,"score",T),cosmos_get(C,"moves",U),add_(U,1.0,V),'void_run::copy_state'(C,D,1.0,1.0,P,Q,R,S,T,0.0,V,1.0,0.0);(cosmos_get(C,"lives",W),r_gt(W,1.0)),cosmos_get(C,"c1",X),cosmos_get(C,"c2",Y),cosmos_get(C,"c3",Z),cosmos_get(C,"c4",A1),cosmos_get(C,"score",B1),cosmos_get(C,"lives",C1),r_sub(C1,1.0,D1),cosmos_get(C,"moves",E1),add_(E1,1.0,F1),'void_run::copy_state'(C,D,1.0,1.0,X,Y,Z,A1,B1,D1,F1,0.0,0.0));\+'void_run::sentry'(K,N),'void_run::collect'(K,N,C,G1,H1,I1,J1,K1),((G1=1.0,H1=1.0,I1=1.0,J1=1.0),cosmos_get(C,"lives",L1),cosmos_get(C,"moves",M1),add_(M1,1.0,N1),'void_run::copy_state'(C,D,K,N,G1,H1,I1,J1,K1,L1,N1,0.0,1.0);\+ (G1=1.0,H1=1.0,I1=1.0,J1=1.0),cosmos_get(C,"lives",O1),cosmos_get(C,"moves",P1),add_(P1,1.0,Q1),'void_run::copy_state'(C,D,K,N,G1,H1,I1,J1,K1,O1,Q1,0.0,0.0))))))))).
'void_run::$impl_handle_key'(A,B,C,D,E,F):-if_(B="up",(r_sub(0.0,1.0,G),'void_run::move'(0.0,G,A,C,D,F)),if_(B="down",'void_run::move'(0.0,1.0,A,C,D,F),if_(B="left",(r_sub(0.0,1.0,H),'void_run::move'(H,0.0,A,C,D,F)),if_(B="right",'void_run::move'(1.0,0.0,A,C,D,F),if_(B="r",C=E,C=A))))).
'void_run::$impl_update'(A,B,C,D,E,F):-(cosmos_get(F,"event",G),cosmos_method(G,"get",[H])),'void_run::apply_events'(H,A,B,C,D,E).
'void_run::$impl_apply_events'(A,B,C,D,E,F):-if_(A=[],C=B,(A=[G|H],(cosmos_get(G,"type",I),J=I),if_(J="keydown",(cosmos_get(G,"key",K),'void_run::handle_key'(B,K,L,D,E,F)),L=B),'void_run::apply_events'(H,L,C,D,E,F))).
'void_run::$impl_draw_tile'(A,B,C,D,E,F,G):-(r_sub(A,1.0,H),r_mul(H,D,I),J=I),(r_sub(B,1.0,K),r_mul(K,D,L),add_(G,L,M),N=M),((add_(A,B,O),cosmos_receiver("math",E),cosmos_method(E,"mod",[O,2.0,0.0])),(cosmos_get(F,"graphics",P),cosmos_method(P,"setColor",["#101b2b"])),add_(J,1.0,Q),add_(N,1.0,R),r_sub(D,2.0,S),r_sub(D,2.0,T),cosmos_get(F,"graphics",U),cosmos_method(U,"rectangle",["fill",Q,R,S,T]);\+ (add_(A,B,V),cosmos_receiver("math",E),cosmos_method(E,"mod",[V,2.0,0.0])),(cosmos_get(F,"graphics",W),cosmos_method(W,"setColor",["#0d1726"])),add_(J,1.0,X),add_(N,1.0,Y),r_sub(D,2.0,Z),r_sub(D,2.0,A1),cosmos_get(F,"graphics",B1),cosmos_method(B1,"rectangle",["fill",X,Y,Z,A1])),('void_run::wall'(A,B),(cosmos_get(F,"graphics",C1),cosmos_method(C1,"setColor",["#253d56"])),(add_(J,3.0,D1),add_(N,3.0,E1),r_sub(D,6.0,F1),r_sub(D,6.0,G1),cosmos_get(F,"graphics",H1),cosmos_method(H1,"rectangle",["fill",D1,E1,F1,G1])),(cosmos_get(F,"graphics",I1),cosmos_method(I1,"setColor",["#31506a"])),add_(J,8.0,J1),add_(N,8.0,K1),r_sub(D,16.0,L1),r_sub(D,16.0,M1),cosmos_get(F,"graphics",N1),cosmos_method(N1,"rectangle",["fill",J1,K1,L1,M1]);\+'void_run::wall'(A,B),true),('void_run::sentry'(A,B),(cosmos_get(F,"graphics",O1),cosmos_method(O1,"setColor",["#d9515e"])),(add_(J,6.0,P1),add_(N,6.0,Q1),r_sub(D,12.0,R1),r_sub(D,12.0,S1),cosmos_get(F,"graphics",T1),cosmos_method(T1,"rectangle",["fill",P1,Q1,R1,S1])),(cosmos_get(F,"graphics",U1),cosmos_method(U1,"setColor",["#ffb35c"])),add_(J,12.0,V1),add_(N,12.0,W1),r_sub(D,24.0,X1),r_sub(D,24.0,Y1),cosmos_get(F,"graphics",Z1),cosmos_method(Z1,"rectangle",["fill",V1,W1,X1,Y1]);\+'void_run::sentry'(A,B),true).
'void_run::$impl_draw_shard'(A,B,C,D,E,F):-if_(C=0.0,((r_sub(A,1.0,G),r_mul(G,D,H),I=H),(r_sub(B,1.0,J),r_mul(J,D,K),add_(F,K,L),M=L),(cosmos_get(E,"graphics",N),cosmos_method(N,"setColor",["#f5d06f"])),(add_(I,11.0,O),add_(M,5.0,P),cosmos_get(E,"graphics",Q),cosmos_method(Q,"rectangle",["fill",O,P,10.0,22.0])),(cosmos_get(E,"graphics",R),cosmos_method(R,"setColor",["#ffe7a3"])),add_(I,6.0,S),add_(M,11.0,T),cosmos_get(E,"graphics",U),cosmos_method(U,"rectangle",["fill",S,T,20.0,10.0])),true).
'void_run::$impl_draw_player'(A,B,C,D):-(cosmos_get(A,"x",E),r_sub(E,1.0,F),r_mul(F,B,G),H=G),(cosmos_get(A,"y",I),r_sub(I,1.0,J),r_mul(J,B,K),add_(D,K,L),M=L),(cosmos_get(C,"graphics",N),cosmos_method(N,"setColor",["#59d7e8"])),(add_(H,5.0,O),add_(M,5.0,P),r_sub(B,10.0,Q),r_sub(B,10.0,R),cosmos_get(C,"graphics",S),cosmos_method(S,"rectangle",["fill",O,P,Q,R])),(cosmos_get(C,"graphics",T),cosmos_method(T,"setColor",["#d8fbff"])),(add_(H,10.0,U),add_(M,10.0,V),r_sub(B,20.0,W),r_sub(B,20.0,X),cosmos_get(C,"graphics",Y),cosmos_method(Y,"rectangle",["fill",U,V,W,X])),(cosmos_get(C,"graphics",Z),cosmos_method(Z,"setColor",["#17263c"])),add_(H,13.0,A1),add_(M,13.0,B1),cosmos_get(C,"graphics",C1),cosmos_method(C1,"rectangle",["fill",A1,B1,6.0,6.0]).
'void_run::$impl_draw_panel'(A,B,C,D):-(cosmos_get(B,"graphics",E),cosmos_method(E,"setColor",["#08111e"])),(cosmos_get(B,"graphics",F),cosmos_method(F,"rectangle",["fill",0.0,0.0,D,C])),(cosmos_get(B,"graphics",G),cosmos_method(G,"setColor",["#59d7e8"])),(r_sub(C,3.0,H),cosmos_get(B,"graphics",I),cosmos_method(I,"rectangle",["fill",0.0,H,D,3.0])),(cosmos_get(B,"graphics",J),cosmos_method(J,"setColor",["#12283a"])),(cosmos_get(B,"graphics",K),cosmos_method(K,"rectangle",["fill",10.0,10.0,122.0,20.0])),(cosmos_get(B,"graphics",L),cosmos_method(L,"rectangle",["fill",138.0,10.0,90.0,20.0])),(cosmos_get(B,"graphics",M),cosmos_method(M,"rectangle",["fill",236.0,10.0,110.0,20.0])),(cosmos_get(B,"graphics",N),cosmos_method(N,"rectangle",["fill",354.0,10.0,90.0,20.0])),(cosmos_get(B,"graphics",O),cosmos_method(O,"rectangle",["fill",452.0,10.0,50.0,20.0])),((cosmos_get(A,"lives",P),r_ge(P,1.0)),(cosmos_get(B,"graphics",Q),cosmos_method(Q,"setColor",["#ff7b70"])),cosmos_get(B,"graphics",R),cosmos_method(R,"rectangle",["fill",460.0,15.0,8.0,10.0]);(cosmos_get(A,"lives",S),r_lt(S,1.0)),true),((cosmos_get(A,"lives",T),r_ge(T,2.0)),cosmos_get(B,"graphics",U),cosmos_method(U,"rectangle",["fill",472.0,15.0,8.0,10.0]);(cosmos_get(A,"lives",V),r_lt(V,2.0)),true),((cosmos_get(A,"lives",W),r_ge(W,3.0)),cosmos_get(B,"graphics",X),cosmos_method(X,"rectangle",["fill",484.0,15.0,8.0,10.0]);(cosmos_get(A,"lives",Y),r_lt(Y,3.0)),true).
'void_run::$impl_draw'(A,B,C,D,E,F,G,H,I):-(cosmos_get(G,"graphics",J),cosmos_method(J,"setColor",["#08111e"])),(cosmos_get(G,"graphics",K),cosmos_method(K,"rectangle",["fill",0.0,0.0,I,D])),'void_run::draw_panel'(A,G,H,I),(L=1.0,cosmos_while(clos(upvals([F]),'void_run::$closure_0.0'),clos(upvals([B,C,E,A,G,H]),'void_run::$closure_1.0'),[L],[M])),(cosmos_get(A,"c1",N),'void_run::draw_shard'(2.0,6.0,N,B,G,H)),(cosmos_get(A,"c2",O),'void_run::draw_shard'(6.0,9.0,O,B,G,H)),(cosmos_get(A,"c3",P),'void_run::draw_shard'(10.0,2.0,P,B,G,H)),(cosmos_get(A,"c4",Q),'void_run::draw_shard'(15.0,8.0,Q,B,G,H)),'void_run::draw_player'(A,B,G,H),cosmos_get(A,"game_over",R),if_(R=1.0,((cosmos_get(G,"graphics",S),cosmos_method(S,"setColor",["#3d1a2a"])),(cosmos_get(G,"graphics",T),cosmos_method(T,"rectangle",["fill",176.0,190.0,160.0,74.0])),(cosmos_get(G,"graphics",U),cosmos_method(U,"setColor",["#ff7b70"])),(cosmos_get(G,"graphics",V),cosmos_method(V,"rectangle",["fill",188.0,202.0,136.0,4.0])),cosmos_get(G,"graphics",W),cosmos_method(W,"rectangle",["fill",204.0,222.0,104.0,5.0])),(cosmos_get(A,"win",X),if_(X=1.0,((cosmos_get(G,"graphics",Y),cosmos_method(Y,"setColor",["#193c3c"])),(cosmos_get(G,"graphics",Z),cosmos_method(Z,"rectangle",["fill",160.0,190.0,192.0,74.0])),(cosmos_get(G,"graphics",A1),cosmos_method(A1,"setColor",["#7dffd1"])),(cosmos_get(G,"graphics",B1),cosmos_method(B1,"rectangle",["fill",176.0,202.0,160.0,4.0])),cosmos_get(G,"graphics",C1),cosmos_method(C1,"rectangle",["fill",192.0,222.0,128.0,5.0])),true))).
void_run([]):-cosmos_require("space",A),cosmos_require("math",B),C=16.0,D=10.0,E=32.0,F=42.0,(r_mul(C,E,G),H=G),(r_mul(D,E,I),add_(I,F,J),K=J),L=80.0,(new(M),set_(M,"x",1.0,N),set_(N,"y",1.0,O),set_(O,"c1",0.0,P),set_(P,"c2",0.0,Q),set_(Q,"c3",0.0,R),set_(R,"c4",0.0,S),set_(S,"score",0.0,T),set_(T,"lives",3.0,U),set_(U,"moves",0.0,V),set_(V,"game_over",0.0,W),set_(W,"win",0.0,X),Y=X),cosmos_method(A,"init",[H,K]),new(Z),set_(Z,"update",clos(upvals([C,Y,D,A]),'void_run::$value_update'),A1),set_(A1,"draw",clos(upvals([E,C,K,B,D,A,F,H]),'void_run::$value_draw'),B1),cosmos_method(A,"start",[L,B1,Y]).
'void_run::same'(A,B,C,D):-'void_run::$impl_same'(A,B,C,D).
'void_run::$value_same'(A,B,C,D,upvals([])):-'void_run::same'(A,B,C,D).
'void_run::wall'(A,B):-'void_run::$impl_wall'(A,B).
'void_run::$value_wall'(A,B,upvals([])):-'void_run::wall'(A,B).
'void_run::sentry'(A,B):-'void_run::$impl_sentry'(A,B).
'void_run::$value_sentry'(A,B,upvals([])):-'void_run::sentry'(A,B).
'void_run::copy_state'(A,B,C,D,E,F,G,H,I,J,K,L,M):-'void_run::$impl_copy_state'(A,B,C,D,E,F,G,H,I,J,K,L,M).
'void_run::$value_copy_state'(A,B,C,D,E,F,G,H,I,J,K,L,M,upvals([])):-'void_run::copy_state'(A,B,C,D,E,F,G,H,I,J,K,L,M).
'void_run::collect'(A,B,C,D,E,F,G,H):-'void_run::$impl_collect'(A,B,C,D,E,F,G,H).
'void_run::$value_collect'(A,B,C,D,E,F,G,H,upvals([])):-'void_run::collect'(A,B,C,D,E,F,G,H).
'void_run::move'(A,B,C,D,E,F):-'void_run::$impl_move'(A,B,C,D,E,F).
'void_run::$value_move'(A,B,C,D,upvals([E,F])):-'void_run::move'(A,B,C,D,E,F).
'void_run::handle_key'(A,B,C,D,E,F):-'void_run::$impl_handle_key'(A,B,C,D,E,F).
'void_run::$value_handle_key'(A,B,C,upvals([D,E,F])):-'void_run::handle_key'(A,B,C,D,E,F).
'void_run::update'(A,B,C,D,E,F):-'void_run::$impl_update'(A,B,C,D,E,F).
'void_run::$value_update'(A,B,upvals([C,D,E,F])):-'void_run::update'(A,B,C,D,E,F).
'void_run::apply_events'(A,B,C,D,E,F):-'void_run::$impl_apply_events'(A,B,C,D,E,F).
'void_run::$value_apply_events'(A,B,C,upvals([D,E,F])):-'void_run::apply_events'(A,B,C,D,E,F).
'void_run::draw_tile'(A,B,C,D,E,F,G):-'void_run::$impl_draw_tile'(A,B,C,D,E,F,G).
'void_run::$value_draw_tile'(A,B,C,upvals([D,E,F,G])):-'void_run::draw_tile'(A,B,C,D,E,F,G).
'void_run::draw_shard'(A,B,C,D,E,F):-'void_run::$impl_draw_shard'(A,B,C,D,E,F).
'void_run::$value_draw_shard'(A,B,C,upvals([D,E,F])):-'void_run::draw_shard'(A,B,C,D,E,F).
'void_run::draw_player'(A,B,C,D):-'void_run::$impl_draw_player'(A,B,C,D).
'void_run::$value_draw_player'(A,upvals([B,C,D])):-'void_run::draw_player'(A,B,C,D).
'void_run::draw_panel'(A,B,C,D):-'void_run::$impl_draw_panel'(A,B,C,D).
'void_run::$value_draw_panel'(A,upvals([B,C,D])):-'void_run::draw_panel'(A,B,C,D).
'void_run::$closure_0.0'([A],upvals([B])):-r_le(A,B).
'void_run::$closure_2.0'([A],upvals([B])):-r_le(A,B).
'void_run::$closure_3.0'([A],B,upvals([C,D,E,F,G,H])):-('void_run::draw_tile'(A,C,F,D,E,G,H),(add_(A,1.0,I),J=I),K=J),B=[J],K=J.
'void_run::$closure_1.0'([A],B,upvals([C,D,E,F,G,H])):-((I=1.0,cosmos_while(clos(upvals([D]),'void_run::$closure_2.0'),clos(upvals([A,C,E,F,G,H]),'void_run::$closure_3.0'),[I],[J])),(add_(A,1.0,K),L=K),M=L),B=[L],M=L.
'void_run::draw'(A,B,C,D,E,F,G,H,I):-'void_run::$impl_draw'(A,B,C,D,E,F,G,H,I).
'void_run::$value_draw'(A,upvals([B,C,D,E,F,G,H,I])):-'void_run::draw'(A,B,C,D,E,F,G,H,I).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], void_run([])),cosmos_profile_finish)
    ).
