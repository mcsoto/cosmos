:- style_check(-singleton).
'sokoban::$impl_tileSize'(A):-A=32.0.
'sokoban::$impl_hudTop'(A):-A=224.0.
'sokoban::$impl_hudHeight'(A):-A=60.0.
'sokoban::$impl_level1'(A):-A=["#######","#     #","#@$$  #","#   ..#","#######"].
'sokoban::$impl_level2'(A):-A=["#########","#       #","#  $   .#","#  $  . #","#  $ .  #","# @     #","#########"].
'sokoban::$impl_level3'(A):-A=["#######","# .####","#  ####","#*@  ##","#  $ ##","#  ####","#######"].
'sokoban::$impl_level_rows'(A,B):-A=1.0->'sokoban::level1'(B);A=2.0->'sokoban::level2'(B);'sokoban::level3'(B).
'sokoban::$impl_level_dims'(A,B,C):-A=1.0->B=7.0,C=5.0;A=2.0->B=9.0,C=7.0;B=7.0,C=7.0.
'sokoban::$impl_lst_cons'(A,B,C):-C=[A|B].
'sokoban::$impl_lst_len'([],A):-A=0.0.
'sokoban::$impl_lst_len'([A|B],C):-'sokoban::lst_len'(B,D),add_(D,1.0,E),C=E.
'sokoban::$impl_reverse_list'([],A,B):-B=A.
'sokoban::$impl_reverse_list'([A|B],C,D):-'sokoban::reverse_list'(B,[A|C],D).
'sokoban::$impl_lst_get'(A,B,C):-A=[]->C=0.0;A=[D|E],(B=0.0->C=D;(r_sub(B,1.0,F),G=F),'sokoban::lst_get'(E,G,C)).
'sokoban::$impl_same_cell'(A,B,C,D,E):-A=C->(B=D->E=1.0;E=0.0);E=0.0.
'sokoban::$impl_list_has_cell'(A,B,C,D):-A=[]->D=0.0;A=[E|F],E=[G,H],'sokoban::same_cell'(G,H,B,C,I),(I=1.0->D=1.0;'sokoban::list_has_cell'(F,B,C,D)).
'sokoban::$impl_replace_box'(A,B,C,D,E,F):-A=[]->F=[];A=[G|H],G=[I,J],'sokoban::same_cell'(I,J,B,C,K),(K=1.0->'sokoban::lst_cons'([D,E],H,F);'sokoban::replace_box'(H,B,C,D,E,L),'sokoban::lst_cons'(G,L,F)).
'sokoban::$impl_all_on'(A,B,C):-A=[]->C=1.0;A=[D|E],D=[F,G],'sokoban::list_has_cell'(B,F,G,H),(H=1.0->'sokoban::all_on'(E,B,C);C=0.0).
'sokoban::$impl_parse_cell'(A,B,C,D,E,F,G,H,I,J,K):-A="."->'sokoban::lst_cons'([B,C],G,L),K=L,J=F,H=D,I=E;A="$"->'sokoban::lst_cons'([B,C],F,M),J=M,K=G,H=D,I=E;A="*"->'sokoban::lst_cons'([B,C],F,M),'sokoban::lst_cons'([B,C],G,L),J=M,K=L,H=D,I=E;A="@"->H=B,I=C,J=F,K=G;H=D,I=E,J=F,K=G.
'sokoban::$impl_parse_row'(A,B,C,D,E,F,G,H,I,J,K,L,M):-r_ge(C,D)->I=E,J=F,K=G,L=H;cosmos_method(M,"at",[A,C,N]),'sokoban::parse_cell'(N,C,B,E,F,G,H,O,P,Q,R),add_(C,1.0,S),'sokoban::parse_row'(A,B,S,D,O,P,Q,R,I,J,K,L,M).
'sokoban::$impl_parse_rows'(A,B,C,D,E,F,G,H,I,J,K,L,M):-r_ge(B,D)->I=E,J=F,K=G,L=H;'sokoban::lst_get'(A,B,N),'sokoban::parse_row'(N,B,0.0,C,E,F,G,H,O,P,Q,R,M),add_(B,1.0,S),'sokoban::parse_rows'(A,S,C,D,O,P,Q,R,I,J,K,L,M).
'sokoban::$impl_make_state'(A,B,C):-'sokoban::level_rows'(A,D),'sokoban::level_dims'(A,E,F),'sokoban::parse_rows'(D,0.0,E,F,0.0,0.0,[],[],G,H,I,J,C),'sokoban::reverse_list'(I,[],K),'sokoban::reverse_list'(J,[],L),('sokoban::lst_len'(K,M),N=M),(str(A,O),add_("Level ",O,P),add_(P," - push ",Q),str(N,R),add_(Q,R,S),add_(S," boxes onto the dots",T),U=T),new(V),set_(V,"lvl",A,W),set_(W,"w",E,X),set_(X,"h",F,Y),set_(Y,"rows",D,Z),set_(Z,"px",G,A1),set_(A1,"py",H,B1),set_(B1,"boxes",K,C1),set_(C1,"goals",L,D1),set_(D1,"moves",0.0,E1),set_(E1,"pushes",0.0,F1),set_(F1,"history",[],G1),set_(G1,"won",0.0,H1),set_(H1,"status",U,I1),B=I1.
'sokoban::$impl_wall_at'(A,B,C,D,E,F,G):-r_lt(D,0.0)->F=1.0;r_lt(E,0.0)->F=1.0;r_ge(D,B)->F=1.0;r_ge(E,C)->F=1.0;'sokoban::lst_get'(A,E,H),cosmos_method(G,"at",[H,D,I]),(I="#"->F=1.0;F=0.0).
'sokoban::$impl_blocked_at'(A,B,C,D,E,F,G,H):-'sokoban::wall_at'(A,B,C,E,F,I,H),'sokoban::list_has_cell'(D,E,F,J),(I=1.0->G=1.0;J=1.0->G=1.0;G=0.0).
'sokoban::$impl_write_step'(A,B,C,D,E,F):-(cosmos_get(A,"px",G),H=G),(cosmos_get(A,"py",I),J=I),(cosmos_get(A,"boxes",K),L=K),(new(M),set_(M,"px",H,N),set_(N,"py",J,O),set_(O,"boxes",L,P),set_(P,"pushes",E,Q),R=Q),(cosmos_get(A,"history",S),'sokoban::lst_cons'(R,S,T)),(cosmos_get(A,"moves",U),add_(U,1.0,V),W=V),(cosmos_update(A,"px",B,X),Y=X),(cosmos_update(Y,"py",C,Z),A1=Z),(cosmos_update(A1,"boxes",D,B1),C1=B1),(cosmos_update(C1,"history",T,D1),E1=D1),(cosmos_update(E1,"moves",W,F1),G1=F1),(cosmos_update(G1,"pushes",E,H1),I1=H1),'sokoban::finish'(I1,F).
'sokoban::$impl_do_step'(A,B,C,D):-(cosmos_get(A,"boxes",E),F=E),(cosmos_get(A,"pushes",G),H=G),'sokoban::write_step'(A,B,C,F,H,D).
'sokoban::$impl_do_push'(A,B,C,D,E,F):-(cosmos_get(A,"boxes",G),'sokoban::replace_box'(G,B,C,D,E,H)),(cosmos_get(A,"pushes",I),add_(I,1.0,J),K=J),'sokoban::write_step'(A,B,C,H,K,F).
'sokoban::$impl_try_move'(A,B,C,D,E):-(cosmos_get(A,"won",F),G=F),(G=1.0->D=A;(cosmos_get(A,"px",H),add_(H,B,I),J=I),(cosmos_get(A,"py",K),add_(K,C,L),M=L),(cosmos_get(A,"rows",N),cosmos_get(A,"w",O),cosmos_get(A,"h",P),'sokoban::wall_at'(N,O,P,J,M,Q,E)),(cosmos_get(A,"boxes",R),'sokoban::list_has_cell'(R,J,M,S)),(S=1.0->(add_(J,B,T),U=T),(add_(M,C,V),W=V),(cosmos_get(A,"rows",X),cosmos_get(A,"w",Y),cosmos_get(A,"h",Z),cosmos_get(A,"boxes",A1),'sokoban::blocked_at'(X,Y,Z,A1,U,W,B1,E)),(B1=1.0->D=A;'sokoban::do_push'(A,J,M,U,W,D));Q=1.0->D=A;'sokoban::do_step'(A,J,M,D))).
'sokoban::$impl_finish'(A,B):-(cosmos_get(A,"boxes",C),cosmos_get(A,"goals",D),'sokoban::all_on'(C,D,E)),(E=1.0->F="Solved! R for the next level",G="All levels cleared! R to start over",(cosmos_get(A,"lvl",H),I=H),(I=3.0->cosmos_update(A,"status",G,J),K=J;cosmos_update(A,"status",F,L),K=L),(cosmos_update(K,"won",1.0,M),N=M),B=N;B=A).
'sokoban::$impl_do_undo'(A,B):-(cosmos_get(A,"history",C),D=C),(D=[]->B=A;D=[E|F],(new(G),set_(G,"px",H,I),set_(I,"py",J,K),set_(K,"boxes",L,M),set_(M,"pushes",N,O),E=O),(cosmos_get(A,"moves",P),r_sub(P,1.0,Q),R=Q),(cosmos_update(A,"px",H,S),T=S),(cosmos_update(T,"py",J,U),V=U),(cosmos_update(V,"boxes",L,W),X=W),(cosmos_update(X,"pushes",N,Y),Z=Y),(cosmos_update(Z,"history",F,A1),B1=A1),(cosmos_update(B1,"moves",R,C1),D1=C1),B=D1).
'sokoban::$impl_do_restart'(A,B,C):-(cosmos_get(A,"lvl",D),E=D),(cosmos_get(A,"won",F),G=F),(G=1.0->(add_(E,1.0,H),I=H),(r_gt(I,3.0)->'sokoban::make_state'(1.0,B,C);'sokoban::make_state'(I,B,C));'sokoban::make_state'(E,B,C)).
'sokoban::$impl_move_key'(A,B,C,D):-A="left"->B=1.0,(r_sub(0.0,1.0,E),C=E),D=0.0;A="right"->B=1.0,C=1.0,D=0.0;A="up"->B=1.0,C=0.0,r_sub(0.0,1.0,F),D=F;A="down"->B=1.0,C=0.0,D=1.0;A="a"->B=1.0,(r_sub(0.0,1.0,G),C=G),D=0.0;A="d"->B=1.0,C=1.0,D=0.0;A="w"->B=1.0,C=0.0,r_sub(0.0,1.0,H),D=H;A="s"->B=1.0,C=0.0,D=1.0;B=0.0,C=0.0,D=0.0.
'sokoban::$impl_key_action'(A,B,C,D):-'sokoban::move_key'(A,E,F,G),(E=1.0->'sokoban::try_move'(B,F,G,C,D);A="u"->'sokoban::do_undo'(B,C);A="r"->'sokoban::do_restart'(B,C,D);C=B).
'sokoban::$impl_apply_events'(A,B,C,D,E):-A=[]->C=B;A=[F|G],(cosmos_get(F,"type",H),I=H),(cosmos_receiver("io",D),cosmos_method(D,"writeln",[I])),(I="keydown"->(cosmos_get(F,"key",J),K=J),(cosmos_receiver("io",D),cosmos_method(D,"writeln",[K])),'sokoban::key_action'(K,B,L,E);L=B),'sokoban::apply_events'(G,L,C,D,E).
'sokoban::$impl_update'(A,B,C,D,E):-(cosmos_get(D,"event",F),cosmos_method(F,"get",[G])),'sokoban::apply_events'(G,A,B,C,E).
'sokoban::$impl_draw_floor'(A,B,C,D):-(cosmos_get(D,"graphics",E),F=E),cosmos_method(F,"setColor",["#252e44"]),cosmos_method(F,"rectangle",["fill",A,B,C,C]).
'sokoban::$impl_draw_goal'(A,B,C,D):-'sokoban::draw_floor'(A,B,C,D),(r_div(C,2.0,E),add_(A,E,F),G=F),(r_div(C,2.0,H),add_(B,H,I),J=I),(cosmos_get(D,"graphics",K),cosmos_method(K,"setColor",["#d9a441"])),cosmos_get(D,"graphics",L),cosmos_method(L,"circle",["fill",G,J,5.0]).
'sokoban::$impl_draw_wall'(A,B,C,D):-(cosmos_get(D,"graphics",E),F=E),cosmos_method(F,"setColor",["#454f6e"]),cosmos_method(F,"rectangle",["fill",A,B,C,C]),cosmos_method(F,"setColor",["#5a6489"]),cosmos_method(F,"rectangle",["fill",A,B,C,3.0]).
'sokoban::$impl_draw_cell'(A,B,C,D,E):-A="#"->'sokoban::draw_wall'(B,C,D,E);A="."->'sokoban::draw_goal'(B,C,D,E);'sokoban::draw_floor'(B,C,D,E).
'sokoban::$impl_draw_row'(A,B,C,D,E,F,G):-r_ge(B,C)->true;cosmos_method(G,"at",[A,B,H]),(r_mul(B,D,I),J=I),'sokoban::draw_cell'(H,J,E,D,F),add_(B,1.0,K),'sokoban::draw_row'(A,K,C,D,E,F,G).
'sokoban::$impl_draw_rows'(A,B,C,D,E,F):-A=[]->true;A=[G|H],'sokoban::draw_row'(G,0.0,C,D,B,E,F),(add_(B,D,I),J=I),'sokoban::draw_rows'(H,J,C,D,E,F).
'sokoban::$impl_draw_boxes'(A,B,C,D):-A=[]->true;A=[E|F],E=[G,H],(r_mul(G,C,I),J=I),(r_mul(H,C,K),L=K),'sokoban::list_has_cell'(B,G,H,M),(M=1.0->cosmos_get(D,"graphics",N),cosmos_method(N,"setColor",["#8ce99a"]);cosmos_get(D,"graphics",O),cosmos_method(O,"setColor",["#e09f3e"])),(add_(J,3.0,P),add_(L,3.0,Q),r_sub(C,6.0,R),r_sub(C,6.0,S),cosmos_get(D,"graphics",T),cosmos_method(T,"rectangle",["fill",P,Q,R,S])),(cosmos_get(D,"graphics",U),cosmos_method(U,"setColor",["#0d1117"])),(add_(J,3.0,V),add_(L,3.0,W),r_sub(C,6.0,X),r_sub(C,6.0,Y),cosmos_get(D,"graphics",Z),cosmos_method(Z,"rectangle",["line",V,W,X,Y])),'sokoban::draw_boxes'(F,B,C,D).
'sokoban::$impl_draw_player'(A,B):-C=32.0,(cosmos_get(A,"px",D),r_mul(D,C,E),r_div(C,2.0,F),add_(E,F,G),H=G),(cosmos_get(A,"py",I),r_mul(I,C,J),r_div(C,2.0,K),add_(J,K,L),M=L),(cosmos_get(B,"graphics",N),cosmos_method(N,"setColor",["#5b9dff"])),(r_div(C,2.0,O),r_sub(O,4.0,P),cosmos_get(B,"graphics",Q),cosmos_method(Q,"circle",["fill",H,M,P])),(cosmos_get(B,"graphics",R),cosmos_method(R,"setColor",["#0d1117"])),r_div(C,2.0,S),r_sub(S,9.0,T),cosmos_get(B,"graphics",U),cosmos_method(U,"circle",["fill",H,M,T]).
'sokoban::$impl_draw_hud'(A,B,C):-(cosmos_get(B,"graphics",D),E=D),'sokoban::hudHeight'(F),'sokoban::hudTop'(G),cosmos_method(E,"setColor",["#111a2b"]),cosmos_method(E,"rectangle",["fill",0.0,G,320.0,F]),cosmos_method(E,"setColor",["#31405f"]),cosmos_method(E,"rectangle",["fill",0.0,G,320.0,2.0]),(cosmos_get(A,"moves",H),I=H),(cosmos_get(A,"pushes",J),K=J),(cosmos_get(A,"lvl",L),M=L),cosmos_method(E,"setColor",["#c9d1e1"]),(str(M,N),add_("Level ",N,O),add_(G,8.0,P),cosmos_method(E,"print",[O,10.0,P])),(str(I,Q),add_("Moves ",Q,R),add_(R,"   Pushes ",S),str(K,T),add_(S,T,U),add_(G,8.0,V),cosmos_method(E,"print",[U,120.0,V])),cosmos_method(E,"setColor",["#7a86a3"]),(add_(G,26.0,W),cosmos_method(E,"print",["arrows move   U undo   R restart / next",10.0,W])),cosmos_get(A,"status",X),add_(G,44.0,Y),cosmos_method(E,"print",[X,10.0,Y]).
'sokoban::$impl_draw'(A,B,C):-D=32.0,(cosmos_get(A,"w",E),F=E),(cosmos_get(B,"graphics",G),H=G),cosmos_method(H,"clear",["#0d1117"]),(cosmos_method_value(H,"newFont",[12.0,"sans","normal"],I),cosmos_method(H,"setFont",[I])),'sokoban::hudTop'(J),cosmos_method(H,"setColor",["#152039"]),(r_mul(F,D,K),cosmos_method(H,"rectangle",["fill",0.0,0.0,K,J])),(cosmos_get(A,"rows",L),'sokoban::draw_rows'(L,0.0,F,D,B,C)),(cosmos_get(A,"boxes",M),cosmos_get(A,"goals",N),'sokoban::draw_boxes'(M,N,D,B)),'sokoban::draw_player'(A,B),'sokoban::draw_hud'(A,B,C).
sokoban([]):-cosmos_require("space",A),cosmos_require("string",B),cosmos_require("io",C),'sokoban::make_state'(1.0,D,B),cosmos_method(A,"init",[288.0,284.0]),new(E),set_(E,"update",clos(upvals([C,A,B]),'sokoban::$value_update'),F),set_(F,"draw",clos(upvals([A,B]),'sokoban::$value_draw'),G),cosmos_method(A,"start",[16.0,G,D]).
'sokoban::tileSize'(A):-'sokoban::$impl_tileSize'(A).
'sokoban::$value_tileSize'(A,upvals([])):-'sokoban::tileSize'(A).
'sokoban::hudTop'(A):-'sokoban::$impl_hudTop'(A).
'sokoban::$value_hudTop'(A,upvals([])):-'sokoban::hudTop'(A).
'sokoban::hudHeight'(A):-'sokoban::$impl_hudHeight'(A).
'sokoban::$value_hudHeight'(A,upvals([])):-'sokoban::hudHeight'(A).
'sokoban::level1'(A):-'sokoban::$impl_level1'(A).
'sokoban::$value_level1'(A,upvals([])):-'sokoban::level1'(A).
'sokoban::level2'(A):-'sokoban::$impl_level2'(A).
'sokoban::$value_level2'(A,upvals([])):-'sokoban::level2'(A).
'sokoban::level3'(A):-'sokoban::$impl_level3'(A).
'sokoban::$value_level3'(A,upvals([])):-'sokoban::level3'(A).
'sokoban::level_rows'(A,B):-'sokoban::$impl_level_rows'(A,B).
'sokoban::$value_level_rows'(A,B,upvals([])):-'sokoban::level_rows'(A,B).
'sokoban::level_dims'(A,B,C):-'sokoban::$impl_level_dims'(A,B,C).
'sokoban::$value_level_dims'(A,B,C,upvals([])):-'sokoban::level_dims'(A,B,C).
'sokoban::lst_cons'(A,B,C):-'sokoban::$impl_lst_cons'(A,B,C).
'sokoban::$value_lst_cons'(A,B,C,upvals([])):-'sokoban::lst_cons'(A,B,C).
'sokoban::lst_len'(A,B):-'sokoban::$impl_lst_len'(A,B).
'sokoban::$value_lst_len'(A,B,upvals([])):-'sokoban::lst_len'(A,B).
'sokoban::reverse_list'(A,B,C):-'sokoban::$impl_reverse_list'(A,B,C).
'sokoban::$value_reverse_list'(A,B,C,upvals([])):-'sokoban::reverse_list'(A,B,C).
'sokoban::lst_get'(A,B,C):-'sokoban::$impl_lst_get'(A,B,C).
'sokoban::$value_lst_get'(A,B,C,upvals([])):-'sokoban::lst_get'(A,B,C).
'sokoban::same_cell'(A,B,C,D,E):-'sokoban::$impl_same_cell'(A,B,C,D,E).
'sokoban::$value_same_cell'(A,B,C,D,E,upvals([])):-'sokoban::same_cell'(A,B,C,D,E).
'sokoban::list_has_cell'(A,B,C,D):-'sokoban::$impl_list_has_cell'(A,B,C,D).
'sokoban::$value_list_has_cell'(A,B,C,D,upvals([])):-'sokoban::list_has_cell'(A,B,C,D).
'sokoban::replace_box'(A,B,C,D,E,F):-'sokoban::$impl_replace_box'(A,B,C,D,E,F).
'sokoban::$value_replace_box'(A,B,C,D,E,F,upvals([])):-'sokoban::replace_box'(A,B,C,D,E,F).
'sokoban::all_on'(A,B,C):-'sokoban::$impl_all_on'(A,B,C).
'sokoban::$value_all_on'(A,B,C,upvals([])):-'sokoban::all_on'(A,B,C).
'sokoban::parse_cell'(A,B,C,D,E,F,G,H,I,J,K):-'sokoban::$impl_parse_cell'(A,B,C,D,E,F,G,H,I,J,K).
'sokoban::$value_parse_cell'(A,B,C,D,E,F,G,H,I,J,K,upvals([])):-'sokoban::parse_cell'(A,B,C,D,E,F,G,H,I,J,K).
'sokoban::parse_row'(A,B,C,D,E,F,G,H,I,J,K,L,M):-'sokoban::$impl_parse_row'(A,B,C,D,E,F,G,H,I,J,K,L,M).
'sokoban::$value_parse_row'(A,B,C,D,E,F,G,H,I,J,K,L,upvals([M])):-'sokoban::parse_row'(A,B,C,D,E,F,G,H,I,J,K,L,M).
'sokoban::parse_rows'(A,B,C,D,E,F,G,H,I,J,K,L,M):-'sokoban::$impl_parse_rows'(A,B,C,D,E,F,G,H,I,J,K,L,M).
'sokoban::$value_parse_rows'(A,B,C,D,E,F,G,H,I,J,K,L,upvals([M])):-'sokoban::parse_rows'(A,B,C,D,E,F,G,H,I,J,K,L,M).
'sokoban::make_state'(A,B,C):-'sokoban::$impl_make_state'(A,B,C).
'sokoban::$value_make_state'(A,B,upvals([C])):-'sokoban::make_state'(A,B,C).
'sokoban::wall_at'(A,B,C,D,E,F,G):-'sokoban::$impl_wall_at'(A,B,C,D,E,F,G).
'sokoban::$value_wall_at'(A,B,C,D,E,F,upvals([G])):-'sokoban::wall_at'(A,B,C,D,E,F,G).
'sokoban::blocked_at'(A,B,C,D,E,F,G,H):-'sokoban::$impl_blocked_at'(A,B,C,D,E,F,G,H).
'sokoban::$value_blocked_at'(A,B,C,D,E,F,G,upvals([H])):-'sokoban::blocked_at'(A,B,C,D,E,F,G,H).
'sokoban::write_step'(A,B,C,D,E,F):-'sokoban::$impl_write_step'(A,B,C,D,E,F).
'sokoban::$value_write_step'(A,B,C,D,E,F,upvals([])):-'sokoban::write_step'(A,B,C,D,E,F).
'sokoban::do_step'(A,B,C,D):-'sokoban::$impl_do_step'(A,B,C,D).
'sokoban::$value_do_step'(A,B,C,D,upvals([])):-'sokoban::do_step'(A,B,C,D).
'sokoban::do_push'(A,B,C,D,E,F):-'sokoban::$impl_do_push'(A,B,C,D,E,F).
'sokoban::$value_do_push'(A,B,C,D,E,F,upvals([])):-'sokoban::do_push'(A,B,C,D,E,F).
'sokoban::try_move'(A,B,C,D,E):-'sokoban::$impl_try_move'(A,B,C,D,E).
'sokoban::$value_try_move'(A,B,C,D,upvals([E])):-'sokoban::try_move'(A,B,C,D,E).
'sokoban::finish'(A,B):-'sokoban::$impl_finish'(A,B).
'sokoban::$value_finish'(A,B,upvals([])):-'sokoban::finish'(A,B).
'sokoban::do_undo'(A,B):-'sokoban::$impl_do_undo'(A,B).
'sokoban::$value_do_undo'(A,B,upvals([])):-'sokoban::do_undo'(A,B).
'sokoban::do_restart'(A,B,C):-'sokoban::$impl_do_restart'(A,B,C).
'sokoban::$value_do_restart'(A,B,upvals([C])):-'sokoban::do_restart'(A,B,C).
'sokoban::move_key'(A,B,C,D):-'sokoban::$impl_move_key'(A,B,C,D).
'sokoban::$value_move_key'(A,B,C,D,upvals([])):-'sokoban::move_key'(A,B,C,D).
'sokoban::key_action'(A,B,C,D):-'sokoban::$impl_key_action'(A,B,C,D).
'sokoban::$value_key_action'(A,B,C,upvals([D])):-'sokoban::key_action'(A,B,C,D).
'sokoban::apply_events'(A,B,C,D,E):-'sokoban::$impl_apply_events'(A,B,C,D,E).
'sokoban::$value_apply_events'(A,B,C,upvals([D,E])):-'sokoban::apply_events'(A,B,C,D,E).
'sokoban::update'(A,B,C,D,E):-'sokoban::$impl_update'(A,B,C,D,E).
'sokoban::$value_update'(A,B,upvals([C,D,E])):-'sokoban::update'(A,B,C,D,E).
'sokoban::draw_floor'(A,B,C,D):-'sokoban::$impl_draw_floor'(A,B,C,D).
'sokoban::$value_draw_floor'(A,B,C,upvals([D])):-'sokoban::draw_floor'(A,B,C,D).
'sokoban::draw_goal'(A,B,C,D):-'sokoban::$impl_draw_goal'(A,B,C,D).
'sokoban::$value_draw_goal'(A,B,C,upvals([D])):-'sokoban::draw_goal'(A,B,C,D).
'sokoban::draw_wall'(A,B,C,D):-'sokoban::$impl_draw_wall'(A,B,C,D).
'sokoban::$value_draw_wall'(A,B,C,upvals([D])):-'sokoban::draw_wall'(A,B,C,D).
'sokoban::draw_cell'(A,B,C,D,E):-'sokoban::$impl_draw_cell'(A,B,C,D,E).
'sokoban::$value_draw_cell'(A,B,C,D,upvals([E])):-'sokoban::draw_cell'(A,B,C,D,E).
'sokoban::draw_row'(A,B,C,D,E,F,G):-'sokoban::$impl_draw_row'(A,B,C,D,E,F,G).
'sokoban::$value_draw_row'(A,B,C,D,E,upvals([F,G])):-'sokoban::draw_row'(A,B,C,D,E,F,G).
'sokoban::draw_rows'(A,B,C,D,E,F):-'sokoban::$impl_draw_rows'(A,B,C,D,E,F).
'sokoban::$value_draw_rows'(A,B,C,D,upvals([E,F])):-'sokoban::draw_rows'(A,B,C,D,E,F).
'sokoban::draw_boxes'(A,B,C,D):-'sokoban::$impl_draw_boxes'(A,B,C,D).
'sokoban::$value_draw_boxes'(A,B,C,upvals([D])):-'sokoban::draw_boxes'(A,B,C,D).
'sokoban::draw_player'(A,B):-'sokoban::$impl_draw_player'(A,B).
'sokoban::$value_draw_player'(A,upvals([B])):-'sokoban::draw_player'(A,B).
'sokoban::draw_hud'(A,B,C):-'sokoban::$impl_draw_hud'(A,B,C).
'sokoban::$value_draw_hud'(A,upvals([B,C])):-'sokoban::draw_hud'(A,B,C).
'sokoban::draw'(A,B,C):-'sokoban::$impl_draw'(A,B,C).
'sokoban::$value_draw'(A,upvals([B,C])):-'sokoban::draw'(A,B,C).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], sokoban([])),cosmos_profile_finish)
    ).
