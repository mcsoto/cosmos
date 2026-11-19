:- style_check(-singleton).
'dungeon_queue::$impl_mapWidth'(A):-A=28.0.
'dungeon_queue::$impl_mapHeight'(A):-A=19.0.
'dungeon_queue::$impl_tileSize'(A):-A=24.0.
'dungeon_queue::$impl_hudHeight'(A):-A=66.0.
'dungeon_queue::$impl_autoplayFlag'(A):-A=0.0.
'dungeon_queue::$impl_traceFlag'(A):-A=0.0.
'dungeon_queue::$impl_dungeonMap'(A):-A=["############################","#....#.........#..........E#","#.##..#....##..#...#####...#","#.#...#....##..#...#...*.#...#","#.#...#....##..#...#...#...#","#.#...#########...#...#...##","#.#....*..........#.b.#...##","#.#.#########.#...#...#...##","#.#.#...*...#.#...#...#...##","#*#.#a#####.#.#...#...#...##","#.#.#.#...#.#.#.a.#...#...##","#...#.#...#.#.#...#...#...##","#####.#...#.#.##########...#","#......b...#*..#*........b.#","#.####.#####...#...#######.#","#.#..#.......#...#.......#.#","#@#..#####...#...#####...#.#","#............#.............#","############################"].
'dungeon_queue::$impl_lst_cons'(A,B,C):-C=[A|B].
'dungeon_queue::$impl_lst_get'(A,B,C):-if_(A=[],C=0.0,(A=[D|E],if_(B=0.0,C=D,((r_sub(B,1.0,F),G=F),'dungeon_queue::lst_get'(E,G,C))))).
'dungeon_queue::$impl_elem_at'(A,B,C):-'dungeon_queue::lst_get'(A,B,C).
'dungeon_queue::$impl_lst_put'(A,B,C,D):-if_(A=[],D=[],(A=[E|F],if_(B=0.0,D=[C|F],((r_sub(B,1.0,G),H=G),'dungeon_queue::lst_put'(F,H,C,I),D=[E|I])))).
'dungeon_queue::$impl_lst_len'([],A):-A=0.0.
'dungeon_queue::$impl_lst_len'([A|B],C):-'dungeon_queue::lst_len'(B,D),add_(D,1.0,E),C=E.
'dungeon_queue::$impl_lst_concat'([],A,B):-B=A.
'dungeon_queue::$impl_lst_concat'([A|B],C,D):-'dungeon_queue::lst_concat'(B,C,E),D=[A|E].
'dungeon_queue::$impl_same_cell'(A,B,C,D,E):-if_(A=C,if_(B=D,E=1.0,E=0.0),E=0.0).
'dungeon_queue::$impl_cell_in'(A,B,C,D):-if_(A=[],D=0.0,(A=[E|F],E=[G,H],'dungeon_queue::same_cell'(G,H,B,C,I),if_(I=1.0,D=1.0,'dungeon_queue::cell_in'(F,B,C,D)))).
'dungeon_queue::$impl_num_text'(A,B,C):-str(A,D),B=D.
'dungeon_queue::$impl_in_grid'(A,B,C,D,E):-(r_lt(C,0.0);r_lt(D,0.0);r_ge(C,A);r_ge(D,B)),E=0.0;\+ (r_lt(C,0.0);r_lt(D,0.0);r_ge(C,A);r_ge(D,B)),E=1.0.
'dungeon_queue::$impl_tile_at'(A,B,C,D,E,F,G,H):-'dungeon_queue::in_grid'(B,C,D,E,I),if_(I=1.0,('dungeon_queue::lst_get'(A,E,J),cosmos_method(H,"at",[J,D,F]),G=1.0),(F="",G=0.0)).
'dungeon_queue::$impl_walkable'(A,B,C,D,E,F,G):-'dungeon_queue::tile_at'(A,B,C,D,E,H,I,G),if_(I=1.0,(dif(H,"#"),F=1.0;\+dif(H,"#"),F=0.0),F=0.0).
'dungeon_queue::$impl_scan_grid'(A,B,C,D,E,F,G,H,I):-r_ge(D,C),'dungeon_queue::reverse_list'(G,[],H);r_lt(D,C),(r_ge(E,B),add_(D,1.0,J),'dungeon_queue::scan_grid'(A,B,C,J,0.0,F,G,H,I);r_lt(E,B),'dungeon_queue::lst_get'(A,D,K),cosmos_method(I,"at",[K,E,L]),if_(L=F,'dungeon_queue::lst_cons'([E,D],G,M),M=G),add_(E,1.0,N),'dungeon_queue::scan_grid'(A,B,C,D,N,F,M,H,I)).
'dungeon_queue::$impl_reverse_list'([],A,B):-B=A.
'dungeon_queue::$impl_reverse_list'([A|B],C,D):-'dungeon_queue::reverse_list'(B,[A|C],D).
'dungeon_queue::$impl_scan_chars'(A,B,C,D,E,F):-'dungeon_queue::scan_grid'(A,B,C,0.0,0.0,D,[],E,F).
'dungeon_queue::$impl_enemy_of'(A,B,C,D,E):-if_(A="a",((new(F),set_(F,"x",B,G),set_(G,"y",C,H),set_(H,"kind","grunt",I),set_(I,"notice",7.0,J),D=J),E=1.0),if_(A="b",((new(K),set_(K,"x",B,L),set_(L,"y",C,M),set_(M,"kind","hunter",N),set_(N,"notice",14.0,O),D=O),E=1.0),E=0.0)).
'dungeon_queue::$impl_scan_enemies_row'(A,B,C,D,E,F,G):-r_ge(D,B),'dungeon_queue::reverse_list'(E,[],F);r_lt(D,B),'dungeon_queue::lst_get'(A,C,H),cosmos_method(G,"at",[H,D,I]),'dungeon_queue::enemy_of'(I,D,C,J,K),if_(K=1.0,'dungeon_queue::lst_cons'(J,E,L),L=E),add_(D,1.0,M),'dungeon_queue::scan_enemies_row'(A,B,C,M,L,F,G).
'dungeon_queue::$impl_scan_enemies'(A,B,C,D,E,F,G):-r_ge(D,C),'dungeon_queue::reverse_list'(E,[],F);r_lt(D,C),'dungeon_queue::scan_enemies_row'(A,B,D,0.0,[],H,G),'dungeon_queue::lst_concat'(H,E,I),add_(D,1.0,J),'dungeon_queue::scan_enemies'(A,B,C,J,I,F,G).
'dungeon_queue::$impl_spawn_enemies'(A,B,C,D,E):-'dungeon_queue::scan_enemies'(A,B,C,0.0,[],D,E).
'dungeon_queue::$impl_cell_index'(A,B,C,D):-r_mul(C,A,E),add_(E,B,F),D=F.
'dungeon_queue::$impl_dist_at'(A,B,C,D,E,F):-'dungeon_queue::in_grid'(B,C,D,E,G),if_(G=1.0,('dungeon_queue::cell_index'(B,D,E,H),'dungeon_queue::lst_get'(A,H,F)),(r_sub(0.0,1.0,I),F=I)).
'dungeon_queue::$impl_dist_put'(A,B,C,D,E,F):-'dungeon_queue::cell_index'(B,C,D,G),'dungeon_queue::lst_put'(A,G,E,F).
'dungeon_queue::$impl_neighbours'(A,B,C):-add_(A,1.0,D),r_sub(A,1.0,E),add_(B,1.0,F),r_sub(B,1.0,G),C=[[D,B],[E,B],[A,F],[A,G]].
'dungeon_queue::$impl_fill_field'(A,B,C):-if_(A=0.0,C=[],((r_sub(A,1.0,D),'dungeon_queue::fill_field'(D,B,E)),C=[B|E])).
'dungeon_queue::$impl_open_scan'(A,B,C,D,E,F,G,H,I,J,K):-if_(A=[],(H=G,J=I),(A=[L|M],L=[N,O],'dungeon_queue::walkable'(B,C,D,N,O,P,K),if_(P=1.0,('dungeon_queue::dist_at'(E,C,D,N,O,Q),(r_lt(Q,0.0),'dungeon_queue::dist_put'(E,C,N,O,F,R),'dungeon_queue::lst_cons'([N,O],G,S),'dungeon_queue::open_scan'(M,B,C,D,R,F,S,H,R,J,K);r_ge(Q,0.0),'dungeon_queue::open_scan'(M,B,C,D,E,F,G,H,E,J,K))),'dungeon_queue::open_scan'(M,B,C,D,E,F,G,H,E,J,K)))).
'dungeon_queue::$impl_expand'(A,B,C,D,E,F,G,H,I):-if_(D=[],(G=[],H=E),(D=[J|K],J=[L,M],'dungeon_queue::neighbours'(L,M,N),'dungeon_queue::open_scan'(N,A,B,C,E,F,[],O,E,P,I),'dungeon_queue::expand'(A,B,C,K,P,F,Q,H,I),'dungeon_queue::lst_concat'(O,Q,G))).
'dungeon_queue::$impl_drain'(A,B,C,D,E,F,G,H):-if_(D=[],G=E,('dungeon_queue::expand'(A,B,C,D,E,F,I,J,H),(add_(F,1.0,K),L=K),'dungeon_queue::drain'(A,B,C,I,J,L,G,H))).
'dungeon_queue::$impl_flow_field'(A,B,C,D,E,F,G):-(r_mul(B,C,H),r_sub(0.0,1.0,I),'dungeon_queue::fill_field'(H,I,J)),'dungeon_queue::dist_put'(J,B,D,E,0.0,K),'dungeon_queue::drain'(A,B,C,[[D,E]],K,1.0,F,G).
'dungeon_queue::$impl_cand_move'(A,B,C,D,E,F,G,H,I):-G=[J,K],'dungeon_queue::walkable'(A,B,C,E,F,L,I),if_(L=1.0,('dungeon_queue::dist_at'(D,B,C,E,F,M),(r_ge(M,0.0),(r_lt(M,J),H=[M,[E,F]];r_ge(M,J),H=G);r_lt(M,0.0),H=G)),H=G).
'dungeon_queue::$impl_pick2'(A,B,C):-A=[D,E],B=[F,G],(r_lt(F,D),C=B;r_ge(F,D),C=A).
'dungeon_queue::$impl_flow_step'(A,B,C,D,E,F,G,H):-'dungeon_queue::dist_at'(D,B,C,E,F,I),J=[I,[E,F]],(add_(E,1.0,K),'dungeon_queue::cand_move'(A,B,C,D,K,F,J,L,H)),(r_sub(E,1.0,M),'dungeon_queue::cand_move'(A,B,C,D,M,F,L,N,H)),(add_(F,1.0,O),'dungeon_queue::cand_move'(A,B,C,D,E,O,N,P,H)),(r_sub(F,1.0,Q),'dungeon_queue::cand_move'(A,B,C,D,E,Q,P,R,H)),'dungeon_queue::pick2'(L,N,S),'dungeon_queue::pick2'(S,P,T),'dungeon_queue::pick2'(T,R,U),U=[V,G].
'dungeon_queue::$impl_hunting'(A,B,C):-r_ge(A,0.0),(r_le(A,B),C=1.0;r_gt(A,B),C=0.0);r_lt(A,0.0),C=0.0.
'dungeon_queue::$impl_dir_from_index'(0.0,A):-A=[1.0,0.0].
'dungeon_queue::$impl_dir_from_index'(1.0,A):-r_sub(0.0,1.0,B),A=[B,0.0].
'dungeon_queue::$impl_dir_from_index'(2.0,A):-A=[0.0,1.0].
'dungeon_queue::$impl_dir_from_index'(3.0,A):-r_sub(0.0,1.0,B),A=[0.0,B].
'dungeon_queue::$impl_rand_dir'(A,B):-random(0.0,4.0,C),(r_mul(A,0.0137,D),add_(C,D,E),F=E),(r_mod(F,1.0,G),r_sub(F,G,H),I=H),(r_mod(I,4.0,J),K=J),'dungeon_queue::dir_from_index'(K,B).
'dungeon_queue::$impl_settle'(A,B,C,D,E,F,G,H,I,J,K,L):-'dungeon_queue::walkable'(A,B,C,F,G,M,L),if_(M=1.0,('dungeon_queue::cell_in'(H,F,G,N),if_(N=1.0,(new(O),set_(O,"x",D,P),set_(P,"y",E,Q),set_(Q,"kind",I,R),set_(R,"notice",J,S),K=S),(new(T),set_(T,"x",F,U),set_(U,"y",G,V),set_(V,"kind",I,W),set_(W,"notice",J,X),K=X))),(new(Y),set_(Y,"x",D,Z),set_(Z,"y",E,A1),set_(A1,"kind",I,B1),set_(B1,"notice",J,C1),K=C1)).
'dungeon_queue::$impl_add_occupied'(A,B,C):-(new(D),set_(D,"x",E,F),set_(F,"y",G,H),set_(H,"kind",I,J),set_(J,"notice",K,L),A=L),'dungeon_queue::lst_cons'([E,G],B,C).
'dungeon_queue::$impl_move_enemies'(A,B,C,D,E,F,G,H,I):-if_(A=[],H=[],(A=[J|K],'dungeon_queue::move_enemies_step'(A,B,C,D,E,F,G,[],H,I))).
'dungeon_queue::$impl_move_enemies_step'(A,B,C,D,E,F,G,H,I,J):-if_(A=[],I=H,(A=[K|L],(new(M),set_(M,"x",N,O),set_(O,"y",P,Q),set_(Q,"kind",R,S),set_(S,"notice",T,U),K=U),'dungeon_queue::dist_at'(E,C,D,N,P,V),'dungeon_queue::hunting'(V,T,W),if_(W=1.0,('dungeon_queue::flow_step'(B,C,D,E,N,P,X,J),X=[Y,Z],'dungeon_queue::settle'(B,C,D,N,P,Y,Z,G,R,T,A1,J)),((r_mul(N,7.0,B1),r_mul(P,13.0,C1),add_(B1,C1,D1),add_(D1,F,E1),'dungeon_queue::rand_dir'(E1,F1)),F1=[G1,H1],add_(N,G1,I1),add_(P,H1,J1),'dungeon_queue::settle'(B,C,D,N,P,I1,J1,G,R,T,A1,J))),'dungeon_queue::add_occupied'(A1,G,K1),'dungeon_queue::lst_cons'(A1,H,L1),'dungeon_queue::move_enemies_step'(L,B,C,D,E,F,K1,L1,I,J))).
'dungeon_queue::$impl_caught'(A,B,C,D):-if_(A=[],D=0.0,(A=[E|F],(new(G),set_(G,"x",H,I),set_(I,"y",J,K),set_(K,"kind",L,M),set_(M,"notice",N,O),E=O),'dungeon_queue::same_cell'(H,J,B,C,P),if_(P=1.0,D=1.0,'dungeon_queue::caught'(F,B,C,D)))).
'dungeon_queue::$impl_enemy_cells'([],A,B):-B=A.
'dungeon_queue::$impl_enemy_cells'([A|B],C,D):-(new(E),set_(E,"x",F,G),set_(G,"y",H,I),set_(I,"kind",J,K),set_(K,"notice",L,M),A=M),'dungeon_queue::lst_cons'([F,H],C,N),'dungeon_queue::enemy_cells'(B,N,D).
'dungeon_queue::$impl_collect_gem'(A,B,C,D,E):-if_(A=[],(D=A,E=0.0),(A=[F|G],F=[H,I],'dungeon_queue::same_cell'(H,I,B,C,J),if_(J=1.0,(D=G,E=1.0),('dungeon_queue::collect_gem'(G,B,C,K,L),'dungeon_queue::lst_cons'(F,K,D),E=L)))).
'dungeon_queue::$impl_nearest_gem'(A,B,C,D,E):-if_(A=[],(D=0.0,E=0.0),(A=[F|G],F=[H,I],if_(G=[],(D=H,E=I),('dungeon_queue::nearest_gem'(G,B,C,J,K),'dungeon_queue::manhattan'(H,I,B,C,L),'dungeon_queue::manhattan'(J,K,B,C,M),(r_le(L,M),D=H,E=I;r_gt(L,M),D=J,E=K))))).
'dungeon_queue::$impl_manhattan'(A,B,C,D,E):-(r_sub(A,C,F),abs(F,G)),(r_sub(B,D,H),abs(H,I)),add_(G,I,J),E=J.
'dungeon_queue::$impl_field_is'(A,B,C,D):-if_(B="demo",(cosmos_get(A,"demo",E),F=E),if_(B="over",(cosmos_get(A,"over",G),F=G),if_(B="dirty",(cosmos_get(A,"dirty",H),F=H),if_(B="scent",(cosmos_get(A,"scent",I),F=I),(cosmos_get(A,"gems",J),F=J))))),if_(F=C,D=1.0,D=0.0).
'dungeon_queue::$impl_newGame'(A,B):-'dungeon_queue::buildMap'(C),'dungeon_queue::mapWidth'(D),'dungeon_queue::mapHeight'(E),'dungeon_queue::scan_chars'(C,D,E,"@",F,B),'dungeon_queue::lst_get'(F,0.0,G),G=[H,I],'dungeon_queue::scan_chars'(C,D,E,"E",J,B),'dungeon_queue::lst_get'(J,0.0,K),K=[L,M],'dungeon_queue::scan_chars'(C,D,E,"*",N,B),'dungeon_queue::spawn_enemies'(C,D,E,O,B),'dungeon_queue::autoplayFlag'(P),('dungeon_queue::lst_len'(N,Q),'dungeon_queue::num_text'(Q,R,B)),(add_("Collect the ",R,S),add_(S," gems",T),U=T),'dungeon_queue::flow_field'(C,D,E,H,I,V,B),new(W),set_(W,"map",C,X),set_(X,"w",D,Y),set_(Y,"h",E,Z),set_(Z,"px",H,A1),set_(A1,"py",I,B1),set_(B1,"ex",L,C1),set_(C1,"ey",M,D1),set_(D1,"gems",N,E1),set_(E1,"enemies",O,F1),set_(F1,"field",V,G1),set_(G1,"turn",0.0,H1),set_(H1,"status",U,I1),set_(I1,"over",0.0,J1),set_(J1,"won",0.0,K1),set_(K1,"queue",[],L1),set_(L1,"scent",0.0,M1),set_(M1,"demo",P,N1),set_(N1,"tick",0.0,O1),set_(O1,"dirty",1.0,P1),A=P1.
'dungeon_queue::$impl_buildMap'(A):-'dungeon_queue::dungeonMap'(A).
'dungeon_queue::$impl_put'(A,B,C):-cosmos_update(A,"dirty",B,D),C=D.
'dungeon_queue::$impl_set_flag'(A,B,C,D):-if_(B="scent",(cosmos_update(A,"scent",C,E),D=E),(cosmos_update(A,"demo",C,F),D=F)).
'dungeon_queue::$impl_idle'(A,B):-'dungeon_queue::put'(A,1.0,B).
'dungeon_queue::$impl_no_gems'(A,B):-'dungeon_queue::field_is'(A,"gems",[],B).
'dungeon_queue::$impl_next_objective'(A,B,C):-'dungeon_queue::no_gems'(A,D),if_(D=1.0,((cosmos_get(A,"ex",E),B=E),cosmos_get(A,"ey",F),C=F),(cosmos_get(A,"gems",G),cosmos_get(A,"px",H),cosmos_get(A,"py",I),'dungeon_queue::nearest_gem'(G,H,I,B,C))).
'dungeon_queue::$impl_turn_status'(A,B,C,D,E,F,G,H,I):-('dungeon_queue::lst_len'(B,J),'dungeon_queue::num_text'(J,K,I)),(cosmos_get(A,"ex",L),cosmos_get(A,"ey",M),'dungeon_queue::same_cell'(L,M,C,D,N)),if_(B=[],if_(N=1.0,('dungeon_queue::num_text'(E,O,I),(add_("Escaped in ",O,P),add_(P," turns",Q),F=Q),G=1.0,H=1.0),(F="The exit is open - get there",G=0.0,H=0.0)),((add_("Gems left: ",K,R),F=R),G=0.0,H=0.0)).
'dungeon_queue::$impl_advance'(A,B,C,D,E,F,G,H):-(cosmos_get(A,"map",I),cosmos_get(A,"w",J),cosmos_get(A,"h",K),'dungeon_queue::flow_field'(I,J,K,B,C,L,H)),'dungeon_queue::enemy_cells'(F,[],M),'dungeon_queue::lst_cons'([B,C],M,N),(cosmos_get(A,"map",O),cosmos_get(A,"w",P),cosmos_get(A,"h",Q),'dungeon_queue::move_enemies'(F,O,P,Q,L,E,N,R,H)),'dungeon_queue::caught'(R,B,C,S),(cosmos_update(A,"px",B,T),U=T),(cosmos_update(U,"py",C,V),W=V),(cosmos_update(W,"gems",D,X),Y=X),(cosmos_update(Y,"enemies",R,Z),A1=Z),(cosmos_update(A1,"turn",E,B1),C1=B1),(cosmos_update(C1,"field",L,D1),E1=D1),if_(S=1.0,((cosmos_update(E1,"status","Caught. Press R to try again.",F1),G1=F1),(cosmos_update(G1,"over",1.0,H1),I1=H1),(cosmos_update(I1,"won",0.0,J1),K1=J1),'dungeon_queue::put'(K1,1.0,G)),('dungeon_queue::turn_status'(A,D,B,C,E,L1,M1,N1,H),(cosmos_update(E1,"status",L1,O1),G1=O1),(cosmos_update(G1,"over",N1,P1),I1=P1),(cosmos_update(I1,"won",M1,Q1),K1=Q1),'dungeon_queue::put'(K1,1.0,G))).
'dungeon_queue::$impl_do_turn'(A,B,C,D,E):-(cosmos_get(A,"px",F),add_(F,B,G),H=G),(cosmos_get(A,"py",I),add_(I,C,J),K=J),(cosmos_get(A,"turn",L),add_(L,1.0,M),N=M),(cosmos_get(A,"map",O),cosmos_get(A,"w",P),cosmos_get(A,"h",Q),'dungeon_queue::walkable'(O,P,Q,H,K,R,E)),if_(R=1.0,((cosmos_get(A,"gems",S),'dungeon_queue::collect_gem'(S,H,K,T,U)),cosmos_get(A,"enemies",V),'dungeon_queue::advance'(A,H,K,T,N,V,D,E)),((cosmos_update(A,"status","A wall. They still move.",W),X=W),(cosmos_update(X,"turn",N,Y),Z=Y),cosmos_get(A,"px",A1),cosmos_get(A,"py",B1),cosmos_get(A,"gems",C1),cosmos_get(A,"enemies",D1),'dungeon_queue::advance'(A,A1,B1,C1,N,D1,D,E))).
'dungeon_queue::$impl_wait_turn'(A,B,C):-cosmos_get(A,"px",D),cosmos_get(A,"py",E),cosmos_get(A,"gems",F),cosmos_get(A,"turn",G),add_(G,1.0,H),cosmos_get(A,"enemies",I),'dungeon_queue::advance'(A,D,E,F,H,I,B,C).
'dungeon_queue::$impl_near_enemy'(A,B,C,D):-if_(A=[],D=0.0,(A=[E|F],(new(G),set_(G,"x",H,I),set_(I,"y",J,K),set_(K,"kind",L,M),set_(M,"notice",N,O),E=O),(r_sub(H,B,P),abs(P,Q)),(r_sub(J,C,R),abs(R,S)),(add_(Q,S,T),U=T),(r_le(U,1.0),D=1.0;r_gt(U,1.0),'dungeon_queue::near_enemy'(F,B,C,D)))).
'dungeon_queue::$impl_autoplay_move'(A,B,C):-'dungeon_queue::next_objective'(A,D,E),(cosmos_get(A,"map",F),cosmos_get(A,"w",G),cosmos_get(A,"h",H),'dungeon_queue::flow_field'(F,G,H,D,E,I,C)),(cosmos_get(A,"map",J),cosmos_get(A,"w",K),cosmos_get(A,"h",L),cosmos_get(A,"px",M),cosmos_get(A,"py",N),'dungeon_queue::flow_step'(J,K,L,I,M,N,O,C)),O=[P,Q],(cosmos_get(A,"enemies",R),'dungeon_queue::near_enemy'(R,P,Q,S)),(cosmos_get(A,"enemies",T),cosmos_get(A,"px",U),cosmos_get(A,"py",V),'dungeon_queue::near_enemy'(T,U,V,W)),if_(S=1.0,if_(W=1.0,(cosmos_get(A,"px",X),r_sub(P,X,Y),cosmos_get(A,"py",Z),r_sub(Q,Z,A1),'dungeon_queue::do_turn'(A,Y,A1,B,C)),'dungeon_queue::wait_turn'(A,B,C)),(cosmos_get(A,"px",B1),r_sub(P,B1,C1),cosmos_get(A,"py",D1),r_sub(Q,D1,E1),'dungeon_queue::do_turn'(A,C1,E1,B,C))).
'dungeon_queue::$impl_move_key'(A,B,C,D):-if_(A="left",(B=1.0,(r_sub(0.0,1.0,E),C=E),D=0.0),if_(A="right",(B=1.0,C=1.0,D=0.0),if_(A="up",(B=1.0,C=0.0,r_sub(0.0,1.0,F),D=F),if_(A="down",(B=1.0,C=0.0,D=1.0),if_(A="a",(B=1.0,(r_sub(0.0,1.0,G),C=G),D=0.0),if_(A="d",(B=1.0,C=1.0,D=0.0),if_(A="w",(B=1.0,C=0.0,r_sub(0.0,1.0,H),D=H),if_(A="s",(B=1.0,C=0.0,D=1.0),(B=0.0,C=0.0,D=0.0))))))))).
'dungeon_queue::$impl_try_key'(A,B,C,D):-'dungeon_queue::move_key'(B,E,F,G),if_(E=1.0,'dungeon_queue::do_turn'(A,F,G,C,D),((B=".";B="space"),'dungeon_queue::wait_turn'(A,C,D);\+ (B=".";B="space"),'dungeon_queue::idle'(A,C))).
'dungeon_queue::$impl_handle_key'(A,B,C,D,E):-'dungeon_queue::field_is'(A,"over",1.0,F),if_(F=1.0,if_(B="r",'dungeon_queue::newGame'(C,E),'dungeon_queue::idle'(A,C)),if_(B="r",'dungeon_queue::newGame'(C,E),if_(B="q",(cosmos_method(D,"quit",[]),'dungeon_queue::idle'(A,C)),if_(B="g",((cosmos_get(A,"scent",G),r_sub(1.0,G,H),'dungeon_queue::set_flag'(A,"scent",H,I)),'dungeon_queue::put'(I,1.0,C)),if_(B="p",((cosmos_get(A,"demo",J),r_sub(1.0,J,K),'dungeon_queue::set_flag'(A,"demo",K,I)),'dungeon_queue::put'(I,1.0,C)),'dungeon_queue::try_key'(A,B,C,E)))))).
'dungeon_queue::$impl_enqueue'([],[],A):-A=[].
'dungeon_queue::$impl_enqueue'(A,[],B):-B=A.
'dungeon_queue::$impl_enqueue'(A,[B|C],D):-'dungeon_queue::lst_cons'(B,A,E),'dungeon_queue::enqueue'(E,C,D).
'dungeon_queue::$impl_diag_write'(A):-system:atom_string(B,A),system:atom_string(C,"dungeon_log"),system:atom_string(D,"append"),system:open(C,D,E,[]),system:write(E,B),system:nl(E),system:close(E).
'dungeon_queue::$impl_diag'(A,B):-'dungeon_queue::traceFlag'(C),if_(C=1.0,((cosmos_get(A,"turn",D),str(D,E),add_("turn=",E,F),add_(F," gems=",G),cosmos_get(A,"gems",H),'dungeon_queue::lst_len'(H,I),str(I,J),add_(G,J,K),add_(K," pos=",L),cosmos_get(A,"px",M),str(M,N),add_(L,N,O),add_(O,",",P),cosmos_get(A,"py",Q),str(Q,R),add_(P,R,S),add_(S," over=",T),cosmos_get(A,"over",U),str(U,V),add_(T,V,W),add_(W," won=",X),cosmos_get(A,"won",Y),str(Y,Z),add_(X,Z,A1),add_(A1," status=",B1),cosmos_get(A,"status",C1),add_(B1,C1,D1),E1=D1),'dungeon_queue::diag_write'(E1)),true).
'dungeon_queue::$impl_update'(A,B,C,D,E):-'dungeon_queue::diag'(B,E),(cosmos_get(D,"event",F),cosmos_method(F,"getType",["keydown",G])),print(G),(cosmos_get(B,"queue",H),cosmos_update(B,"queue",H,I),J=I),(cosmos_get(B,"tick",K),add_(K,1.0,L),cosmos_update(J,"tick",L,M),N=M),(cosmos_get(N,"queue",O),'dungeon_queue::enqueue'(O,G,P)),(cosmos_update(N,"queue",P,Q),R=Q),if_(P=[],('dungeon_queue::field_is'(B,"demo",1.0,S),if_(S=1.0,('dungeon_queue::field_is'(B,"over",0.0,T),if_(T=1.0,('dungeon_queue::autoplay_move'(R,U,E),(cosmos_update(U,"queue",P,V),W=V),(cosmos_get(N,"tick",X),cosmos_update(W,"tick",X,Y),Z=Y),'dungeon_queue::put'(Z,1.0,C)),'dungeon_queue::put'(R,0.0,C))),((cosmos_get(N,"tick",A1),r_mod(A1,45.0,B1),C1=B1),if_(C1=0.0,'dungeon_queue::put'(R,1.0,C),((cosmos_get(N,"tick",D1),E1=D1),if_(E1=1.0,'dungeon_queue::put'(R,1.0,C),'dungeon_queue::put'(R,0.0,C))))))),('dungeon_queue::lst_get'(P,0.0,F1),(cosmos_get(F1,"key",G1),H1=G1),'dungeon_queue::drop_head'(P,I1,J1),(cosmos_update(R,"queue",I1,K1),U=K1),'dungeon_queue::handle_key'(U,H1,W,D,E),(cosmos_update(W,"queue",I1,L1),Z=L1),(cosmos_get(N,"tick",M1),cosmos_update(Z,"tick",M1,N1),O1=N1),'dungeon_queue::put'(O1,1.0,C))).
'dungeon_queue::$impl_drop_head'(A,B,C):-if_(A=[],(B=[],C=0.0),(A=[D|E],B=E,C=1.0)).
'dungeon_queue::$impl_draw'(A,B,C):-'dungeon_queue::field_is'(A,"dirty",1.0,D),if_(D=1.0,((cosmos_get(B,"graphics",E),F=E),cosmos_method(F,"clear",["#0b0d14"]),'dungeon_queue::draw_map'(A,B,C),'dungeon_queue::draw_scent'(A,B),(cosmos_get(A,"gems",G),'dungeon_queue::draw_gems'(G,B)),'dungeon_queue::draw_exit'(A,B),(cosmos_get(A,"enemies",H),'dungeon_queue::draw_enemies'(H,B)),'dungeon_queue::draw_player'(A,B),'dungeon_queue::draw_hud'(A,B,C),cosmos_method_value(F,"newFont",[12.0,"sans","normal"],I),cosmos_method(F,"setFont",[I])),true).
'dungeon_queue::$impl_draw_map'(A,B,C):-'dungeon_queue::tileSize'(D),'dungeon_queue::mapWidth'(E),cosmos_get(A,"map",F),'dungeon_queue::draw_rows'(F,0.0,D,E,B,C).
'dungeon_queue::$impl_draw_rows'(A,B,C,D,E,F):-if_(A=[],true,(A=[G|H],'dungeon_queue::draw_row_cells'(G,0.0,B,C,D,E,F),add_(B,C,I),'dungeon_queue::draw_rows'(H,I,C,D,E,F))).
'dungeon_queue::$impl_draw_row_cells'(A,B,C,D,E,F,G):-r_ge(B,E),true;r_lt(B,E),cosmos_method(G,"at",[A,B,H]),(r_mul(B,D,I),'dungeon_queue::draw_cell'(H,I,C,D,F)),add_(B,1.0,J),'dungeon_queue::draw_row_cells'(A,J,C,D,E,F,G).
'dungeon_queue::$impl_draw_cell'("#",A,B,C,D):-(cosmos_get(D,"graphics",E),cosmos_method(E,"setColor",["#39405a"])),(cosmos_get(D,"graphics",F),cosmos_method(F,"rectangle",["fill",A,B,C,C])),(cosmos_get(D,"graphics",G),cosmos_method(G,"setColor",["#4b5474"])),cosmos_get(D,"graphics",H),cosmos_method(H,"rectangle",["fill",A,B,C,3.0]).
'dungeon_queue::$impl_draw_cell'(A,B,C,D,E):-if_(A=".",('dungeon_queue::checker_light'(B,C,F),if_(F=1.0,(cosmos_get(E,"graphics",G),cosmos_method(G,"setColor",["#1a2030"])),(cosmos_get(E,"graphics",H),cosmos_method(H,"setColor",["#161c2a"]))),cosmos_get(E,"graphics",I),cosmos_method(I,"rectangle",["fill",B,C,D,D])),true).
'dungeon_queue::$impl_checker_light'(A,B,C):-(add_(A,B,D),r_mod(D,48.0,E),F=E),if_(F=0.0,C=1.0,C=0.0).
'dungeon_queue::$impl_draw_scent'(A,B):-'dungeon_queue::field_is'(A,"scent",1.0,C),if_(C=1.0,('dungeon_queue::tileSize'(D),cosmos_get(A,"field",E),cosmos_get(A,"w",F),cosmos_get(A,"h",G),'dungeon_queue::scent_rows'(E,F,G,D,0.0,B)),true).
'dungeon_queue::$impl_scent_rows'(A,B,C,D,E,F):-r_lt(E,C),'dungeon_queue::scent_cells'(A,B,D,E,0.0,F),add_(E,1.0,G),'dungeon_queue::scent_rows'(A,B,C,D,G,F);r_ge(E,C),true.
'dungeon_queue::$impl_scent_cells'(A,B,C,D,E,F):-r_lt(E,B),'dungeon_queue::cell_index'(B,E,D,G),'dungeon_queue::lst_get'(A,G,H),(r_ge(H,0.0),(r_le(H,12.0),(cosmos_get(F,"graphics",I),cosmos_method(I,"setColor",["#212d40"])),r_mul(E,C,J),r_mul(D,C,K),cosmos_get(F,"graphics",L),cosmos_method(L,"rectangle",["fill",J,K,C,C]);r_gt(H,12.0),true);r_lt(H,0.0),true),add_(E,1.0,M),'dungeon_queue::scent_cells'(A,B,C,D,M,F);r_ge(E,B),true.
'dungeon_queue::$impl_draw_gems'(A,B):-if_(A=[],true,(A=[C|D],C=[E,F],'dungeon_queue::tileSize'(G),(r_mul(E,G,H),r_div(G,2.0,I),add_(H,I,J),K=J),(r_mul(F,G,L),r_div(G,2.0,M),add_(L,M,N),O=N),(cosmos_get(B,"graphics",P),cosmos_method(P,"setColor",["#ffd166"])),(r_sub(O,7.0,Q),add_(K,6.0,R),add_(O,7.0,S),r_sub(K,6.0,T),cosmos_get(B,"graphics",U),cosmos_method(U,"polygon",["fill",[K,Q,R,O,K,S,T,O]])),'dungeon_queue::draw_gems'(D,B))).
'dungeon_queue::$impl_draw_exit'(A,B):-'dungeon_queue::tileSize'(C),(cosmos_get(A,"ex",D),r_mul(D,C,E),r_div(C,2.0,F),add_(E,F,G),H=G),(cosmos_get(A,"ey",I),r_mul(I,C,J),r_div(C,2.0,K),add_(J,K,L),M=L),'dungeon_queue::no_gems'(A,N),if_(N=1.0,(cosmos_get(B,"graphics",O),cosmos_method(O,"setColor",["#4ade80"])),(cosmos_get(B,"graphics",P),cosmos_method(P,"setColor",["#3f4a5f"]))),r_sub(H,7.0,Q),r_sub(M,7.0,R),cosmos_get(B,"graphics",S),cosmos_method(S,"rectangle",["line",Q,R,14.0,14.0]).
'dungeon_queue::$impl_draw_enemies'([],A):-true.
'dungeon_queue::$impl_draw_enemies'([A|B],C):-(new(D),set_(D,"x",E,F),set_(F,"y",G,H),set_(H,"kind",I,J),set_(J,"notice",K,L),A=L),'dungeon_queue::tileSize'(M),(r_mul(E,M,N),r_div(M,2.0,O),add_(N,O,P),Q=P),(r_mul(G,M,R),r_div(M,2.0,S),add_(R,S,T),U=T),if_(I="hunter",(cosmos_get(C,"graphics",V),cosmos_method(V,"setColor",["#c084fc"])),(cosmos_get(C,"graphics",W),cosmos_method(W,"setColor",["#f87171"]))),(r_div(M,2.0,X),r_sub(X,6.0,Y),cosmos_get(C,"graphics",Z),cosmos_method(Z,"circle",["fill",Q,U,Y])),(cosmos_get(C,"graphics",A1),cosmos_method(A1,"setColor",["#0b0d14"])),(r_sub(Q,4.0,B1),r_sub(U,1.0,C1),cosmos_get(C,"graphics",D1),cosmos_method(D1,"rectangle",["fill",B1,C1,8.0,2.0])),'dungeon_queue::draw_enemies'(B,C).
'dungeon_queue::$impl_draw_player'(A,B):-'dungeon_queue::tileSize'(C),(cosmos_get(A,"px",D),r_mul(D,C,E),r_div(C,2.0,F),add_(E,F,G),H=G),(cosmos_get(A,"py",I),r_mul(I,C,J),r_div(C,2.0,K),add_(J,K,L),M=L),(cosmos_get(B,"graphics",N),cosmos_method(N,"setColor",["#60a5fa"])),(r_div(C,2.0,O),r_sub(O,4.0,P),cosmos_get(B,"graphics",Q),cosmos_method(Q,"circle",["fill",H,M,P])),(cosmos_get(B,"graphics",R),cosmos_method(R,"setColor",["#0b0d14"])),(r_sub(H,4.0,S),r_sub(M,2.0,T),cosmos_get(B,"graphics",U),cosmos_method(U,"circle",["fill",S,T,2.0])),add_(H,4.0,V),r_sub(M,2.0,W),cosmos_get(B,"graphics",X),cosmos_method(X,"circle",["fill",V,W,2.0]).
'dungeon_queue::$impl_draw_hud'(A,B,C):-'dungeon_queue::mapWidth'(D),'dungeon_queue::mapHeight'(E),'dungeon_queue::tileSize'(F),'dungeon_queue::hudHeight'(G),(r_mul(E,F,H),I=H),(cosmos_get(B,"graphics",J),cosmos_method(J,"setColor",["#141926"])),(r_mul(D,F,K),cosmos_get(B,"graphics",L),cosmos_method(L,"rectangle",["fill",0.0,I,K,G])),(cosmos_get(B,"graphics",M),cosmos_method(M,"setColor",["#60a5fa"])),(r_mul(D,F,N),cosmos_get(B,"graphics",O),cosmos_method(O,"rectangle",["fill",0.0,I,N,2.0])),(cosmos_get(B,"graphics",P),cosmos_method(P,"setColor",["#c9d1e1"])),(cosmos_get(A,"gems",Q),'dungeon_queue::lst_len'(Q,R),'dungeon_queue::num_text'(R,S,C)),(cosmos_get(A,"turn",T),'dungeon_queue::num_text'(T,U,C)),(add_("Gems ",S,V),add_(V,"    Turn ",W),add_(W,U,X),add_(I,10.0,Y),cosmos_get(B,"graphics",Z),cosmos_method(Z,"print",[X,12.0,Y])),(cosmos_get(A,"status",A1),add_(I,28.0,B1),cosmos_get(B,"graphics",C1),cosmos_method(C1,"print",[A1,12.0,B1])),(cosmos_get(B,"graphics",D1),cosmos_method(D1,"setColor",["#6b7793"])),add_(I,46.0,E1),cosmos_get(B,"graphics",F1),cosmos_method(F1,"print",["arrows/WASD move   . wait   G scent   P autoplay   R restart   Q quit",12.0,E1]).
dungeon_queue([]):-cosmos_require("space2",A),cosmos_require("string",B),'dungeon_queue::newGame'(C,B),cosmos_method(A,"init",[672.0,522.0]),new(D),set_(D,"update",clos(upvals([A,B]),'dungeon_queue::$value_update'),E),set_(E,"draw",clos(upvals([A,B]),'dungeon_queue::$value_draw'),F),cosmos_method(A,"start",[16.0,F,C]).
'dungeon_queue::mapWidth'(A):-'dungeon_queue::$impl_mapWidth'(A).
'dungeon_queue::$value_mapWidth'(A,upvals([])):-'dungeon_queue::mapWidth'(A).
'dungeon_queue::mapHeight'(A):-'dungeon_queue::$impl_mapHeight'(A).
'dungeon_queue::$value_mapHeight'(A,upvals([])):-'dungeon_queue::mapHeight'(A).
'dungeon_queue::tileSize'(A):-'dungeon_queue::$impl_tileSize'(A).
'dungeon_queue::$value_tileSize'(A,upvals([])):-'dungeon_queue::tileSize'(A).
'dungeon_queue::hudHeight'(A):-'dungeon_queue::$impl_hudHeight'(A).
'dungeon_queue::$value_hudHeight'(A,upvals([])):-'dungeon_queue::hudHeight'(A).
'dungeon_queue::autoplayFlag'(A):-'dungeon_queue::$impl_autoplayFlag'(A).
'dungeon_queue::$value_autoplayFlag'(A,upvals([])):-'dungeon_queue::autoplayFlag'(A).
'dungeon_queue::traceFlag'(A):-'dungeon_queue::$impl_traceFlag'(A).
'dungeon_queue::$value_traceFlag'(A,upvals([])):-'dungeon_queue::traceFlag'(A).
'dungeon_queue::dungeonMap'(A):-'dungeon_queue::$impl_dungeonMap'(A).
'dungeon_queue::$value_dungeonMap'(A,upvals([])):-'dungeon_queue::dungeonMap'(A).
'dungeon_queue::lst_cons'(A,B,C):-'dungeon_queue::$impl_lst_cons'(A,B,C).
'dungeon_queue::$value_lst_cons'(A,B,C,upvals([])):-'dungeon_queue::lst_cons'(A,B,C).
'dungeon_queue::lst_get'(A,B,C):-'dungeon_queue::$impl_lst_get'(A,B,C).
'dungeon_queue::$value_lst_get'(A,B,C,upvals([])):-'dungeon_queue::lst_get'(A,B,C).
'dungeon_queue::elem_at'(A,B,C):-'dungeon_queue::$impl_elem_at'(A,B,C).
'dungeon_queue::$value_elem_at'(A,B,C,upvals([])):-'dungeon_queue::elem_at'(A,B,C).
'dungeon_queue::lst_put'(A,B,C,D):-'dungeon_queue::$impl_lst_put'(A,B,C,D).
'dungeon_queue::$value_lst_put'(A,B,C,D,upvals([])):-'dungeon_queue::lst_put'(A,B,C,D).
'dungeon_queue::lst_len'(A,B):-'dungeon_queue::$impl_lst_len'(A,B).
'dungeon_queue::$value_lst_len'(A,B,upvals([])):-'dungeon_queue::lst_len'(A,B).
'dungeon_queue::lst_concat'(A,B,C):-'dungeon_queue::$impl_lst_concat'(A,B,C).
'dungeon_queue::$value_lst_concat'(A,B,C,upvals([])):-'dungeon_queue::lst_concat'(A,B,C).
'dungeon_queue::same_cell'(A,B,C,D,E):-'dungeon_queue::$impl_same_cell'(A,B,C,D,E).
'dungeon_queue::$value_same_cell'(A,B,C,D,E,upvals([])):-'dungeon_queue::same_cell'(A,B,C,D,E).
'dungeon_queue::cell_in'(A,B,C,D):-'dungeon_queue::$impl_cell_in'(A,B,C,D).
'dungeon_queue::$value_cell_in'(A,B,C,D,upvals([])):-'dungeon_queue::cell_in'(A,B,C,D).
'dungeon_queue::num_text'(A,B,C):-'dungeon_queue::$impl_num_text'(A,B,C).
'dungeon_queue::$value_num_text'(A,B,upvals([C])):-'dungeon_queue::num_text'(A,B,C).
'dungeon_queue::in_grid'(A,B,C,D,E):-'dungeon_queue::$impl_in_grid'(A,B,C,D,E).
'dungeon_queue::$value_in_grid'(A,B,C,D,E,upvals([])):-'dungeon_queue::in_grid'(A,B,C,D,E).
'dungeon_queue::tile_at'(A,B,C,D,E,F,G,H):-'dungeon_queue::$impl_tile_at'(A,B,C,D,E,F,G,H).
'dungeon_queue::$value_tile_at'(A,B,C,D,E,F,G,upvals([H])):-'dungeon_queue::tile_at'(A,B,C,D,E,F,G,H).
'dungeon_queue::walkable'(A,B,C,D,E,F,G):-'dungeon_queue::$impl_walkable'(A,B,C,D,E,F,G).
'dungeon_queue::$value_walkable'(A,B,C,D,E,F,upvals([G])):-'dungeon_queue::walkable'(A,B,C,D,E,F,G).
'dungeon_queue::scan_grid'(A,B,C,D,E,F,G,H,I):-'dungeon_queue::$impl_scan_grid'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::$value_scan_grid'(A,B,C,D,E,F,G,H,upvals([I])):-'dungeon_queue::scan_grid'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::reverse_list'(A,B,C):-'dungeon_queue::$impl_reverse_list'(A,B,C).
'dungeon_queue::$value_reverse_list'(A,B,C,upvals([])):-'dungeon_queue::reverse_list'(A,B,C).
'dungeon_queue::scan_chars'(A,B,C,D,E,F):-'dungeon_queue::$impl_scan_chars'(A,B,C,D,E,F).
'dungeon_queue::$value_scan_chars'(A,B,C,D,E,upvals([F])):-'dungeon_queue::scan_chars'(A,B,C,D,E,F).
'dungeon_queue::enemy_of'(A,B,C,D,E):-'dungeon_queue::$impl_enemy_of'(A,B,C,D,E).
'dungeon_queue::$value_enemy_of'(A,B,C,D,E,upvals([])):-'dungeon_queue::enemy_of'(A,B,C,D,E).
'dungeon_queue::scan_enemies_row'(A,B,C,D,E,F,G):-'dungeon_queue::$impl_scan_enemies_row'(A,B,C,D,E,F,G).
'dungeon_queue::$value_scan_enemies_row'(A,B,C,D,E,F,upvals([G])):-'dungeon_queue::scan_enemies_row'(A,B,C,D,E,F,G).
'dungeon_queue::scan_enemies'(A,B,C,D,E,F,G):-'dungeon_queue::$impl_scan_enemies'(A,B,C,D,E,F,G).
'dungeon_queue::$value_scan_enemies'(A,B,C,D,E,F,upvals([G])):-'dungeon_queue::scan_enemies'(A,B,C,D,E,F,G).
'dungeon_queue::spawn_enemies'(A,B,C,D,E):-'dungeon_queue::$impl_spawn_enemies'(A,B,C,D,E).
'dungeon_queue::$value_spawn_enemies'(A,B,C,D,upvals([E])):-'dungeon_queue::spawn_enemies'(A,B,C,D,E).
'dungeon_queue::cell_index'(A,B,C,D):-'dungeon_queue::$impl_cell_index'(A,B,C,D).
'dungeon_queue::$value_cell_index'(A,B,C,D,upvals([])):-'dungeon_queue::cell_index'(A,B,C,D).
'dungeon_queue::dist_at'(A,B,C,D,E,F):-'dungeon_queue::$impl_dist_at'(A,B,C,D,E,F).
'dungeon_queue::$value_dist_at'(A,B,C,D,E,F,upvals([])):-'dungeon_queue::dist_at'(A,B,C,D,E,F).
'dungeon_queue::dist_put'(A,B,C,D,E,F):-'dungeon_queue::$impl_dist_put'(A,B,C,D,E,F).
'dungeon_queue::$value_dist_put'(A,B,C,D,E,F,upvals([])):-'dungeon_queue::dist_put'(A,B,C,D,E,F).
'dungeon_queue::neighbours'(A,B,C):-'dungeon_queue::$impl_neighbours'(A,B,C).
'dungeon_queue::$value_neighbours'(A,B,C,upvals([])):-'dungeon_queue::neighbours'(A,B,C).
'dungeon_queue::fill_field'(A,B,C):-'dungeon_queue::$impl_fill_field'(A,B,C).
'dungeon_queue::$value_fill_field'(A,B,C,upvals([])):-'dungeon_queue::fill_field'(A,B,C).
'dungeon_queue::open_scan'(A,B,C,D,E,F,G,H,I,J,K):-'dungeon_queue::$impl_open_scan'(A,B,C,D,E,F,G,H,I,J,K).
'dungeon_queue::$value_open_scan'(A,B,C,D,E,F,G,H,I,J,upvals([K])):-'dungeon_queue::open_scan'(A,B,C,D,E,F,G,H,I,J,K).
'dungeon_queue::expand'(A,B,C,D,E,F,G,H,I):-'dungeon_queue::$impl_expand'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::$value_expand'(A,B,C,D,E,F,G,H,upvals([I])):-'dungeon_queue::expand'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::drain'(A,B,C,D,E,F,G,H):-'dungeon_queue::$impl_drain'(A,B,C,D,E,F,G,H).
'dungeon_queue::$value_drain'(A,B,C,D,E,F,G,upvals([H])):-'dungeon_queue::drain'(A,B,C,D,E,F,G,H).
'dungeon_queue::flow_field'(A,B,C,D,E,F,G):-'dungeon_queue::$impl_flow_field'(A,B,C,D,E,F,G).
'dungeon_queue::$value_flow_field'(A,B,C,D,E,F,upvals([G])):-'dungeon_queue::flow_field'(A,B,C,D,E,F,G).
'dungeon_queue::cand_move'(A,B,C,D,E,F,G,H,I):-'dungeon_queue::$impl_cand_move'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::$value_cand_move'(A,B,C,D,E,F,G,H,upvals([I])):-'dungeon_queue::cand_move'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::pick2'(A,B,C):-'dungeon_queue::$impl_pick2'(A,B,C).
'dungeon_queue::$value_pick2'(A,B,C,upvals([])):-'dungeon_queue::pick2'(A,B,C).
'dungeon_queue::flow_step'(A,B,C,D,E,F,G,H):-'dungeon_queue::$impl_flow_step'(A,B,C,D,E,F,G,H).
'dungeon_queue::$value_flow_step'(A,B,C,D,E,F,G,upvals([H])):-'dungeon_queue::flow_step'(A,B,C,D,E,F,G,H).
'dungeon_queue::hunting'(A,B,C):-'dungeon_queue::$impl_hunting'(A,B,C).
'dungeon_queue::$value_hunting'(A,B,C,upvals([])):-'dungeon_queue::hunting'(A,B,C).
'dungeon_queue::dir_from_index'(A,B):-'dungeon_queue::$impl_dir_from_index'(A,B).
'dungeon_queue::$value_dir_from_index'(A,B,upvals([])):-'dungeon_queue::dir_from_index'(A,B).
'dungeon_queue::rand_dir'(A,B):-'dungeon_queue::$impl_rand_dir'(A,B).
'dungeon_queue::$value_rand_dir'(A,B,upvals([])):-'dungeon_queue::rand_dir'(A,B).
'dungeon_queue::settle'(A,B,C,D,E,F,G,H,I,J,K,L):-'dungeon_queue::$impl_settle'(A,B,C,D,E,F,G,H,I,J,K,L).
'dungeon_queue::$value_settle'(A,B,C,D,E,F,G,H,I,J,K,upvals([L])):-'dungeon_queue::settle'(A,B,C,D,E,F,G,H,I,J,K,L).
'dungeon_queue::add_occupied'(A,B,C):-'dungeon_queue::$impl_add_occupied'(A,B,C).
'dungeon_queue::$value_add_occupied'(A,B,C,upvals([])):-'dungeon_queue::add_occupied'(A,B,C).
'dungeon_queue::move_enemies'(A,B,C,D,E,F,G,H,I):-'dungeon_queue::$impl_move_enemies'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::$value_move_enemies'(A,B,C,D,E,F,G,H,upvals([I])):-'dungeon_queue::move_enemies'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::move_enemies_step'(A,B,C,D,E,F,G,H,I,J):-'dungeon_queue::$impl_move_enemies_step'(A,B,C,D,E,F,G,H,I,J).
'dungeon_queue::$value_move_enemies_step'(A,B,C,D,E,F,G,H,I,upvals([J])):-'dungeon_queue::move_enemies_step'(A,B,C,D,E,F,G,H,I,J).
'dungeon_queue::caught'(A,B,C,D):-'dungeon_queue::$impl_caught'(A,B,C,D).
'dungeon_queue::$value_caught'(A,B,C,D,upvals([])):-'dungeon_queue::caught'(A,B,C,D).
'dungeon_queue::enemy_cells'(A,B,C):-'dungeon_queue::$impl_enemy_cells'(A,B,C).
'dungeon_queue::$value_enemy_cells'(A,B,C,upvals([])):-'dungeon_queue::enemy_cells'(A,B,C).
'dungeon_queue::collect_gem'(A,B,C,D,E):-'dungeon_queue::$impl_collect_gem'(A,B,C,D,E).
'dungeon_queue::$value_collect_gem'(A,B,C,D,E,upvals([])):-'dungeon_queue::collect_gem'(A,B,C,D,E).
'dungeon_queue::nearest_gem'(A,B,C,D,E):-'dungeon_queue::$impl_nearest_gem'(A,B,C,D,E).
'dungeon_queue::$value_nearest_gem'(A,B,C,D,E,upvals([])):-'dungeon_queue::nearest_gem'(A,B,C,D,E).
'dungeon_queue::manhattan'(A,B,C,D,E):-'dungeon_queue::$impl_manhattan'(A,B,C,D,E).
'dungeon_queue::$value_manhattan'(A,B,C,D,E,upvals([])):-'dungeon_queue::manhattan'(A,B,C,D,E).
'dungeon_queue::field_is'(A,B,C,D):-'dungeon_queue::$impl_field_is'(A,B,C,D).
'dungeon_queue::$value_field_is'(A,B,C,D,upvals([])):-'dungeon_queue::field_is'(A,B,C,D).
'dungeon_queue::newGame'(A,B):-'dungeon_queue::$impl_newGame'(A,B).
'dungeon_queue::$value_newGame'(A,upvals([B])):-'dungeon_queue::newGame'(A,B).
'dungeon_queue::buildMap'(A):-'dungeon_queue::$impl_buildMap'(A).
'dungeon_queue::$value_buildMap'(A,upvals([])):-'dungeon_queue::buildMap'(A).
'dungeon_queue::put'(A,B,C):-'dungeon_queue::$impl_put'(A,B,C).
'dungeon_queue::$value_put'(A,B,C,upvals([])):-'dungeon_queue::put'(A,B,C).
'dungeon_queue::set_flag'(A,B,C,D):-'dungeon_queue::$impl_set_flag'(A,B,C,D).
'dungeon_queue::$value_set_flag'(A,B,C,D,upvals([])):-'dungeon_queue::set_flag'(A,B,C,D).
'dungeon_queue::idle'(A,B):-'dungeon_queue::$impl_idle'(A,B).
'dungeon_queue::$value_idle'(A,B,upvals([])):-'dungeon_queue::idle'(A,B).
'dungeon_queue::no_gems'(A,B):-'dungeon_queue::$impl_no_gems'(A,B).
'dungeon_queue::$value_no_gems'(A,B,upvals([])):-'dungeon_queue::no_gems'(A,B).
'dungeon_queue::next_objective'(A,B,C):-'dungeon_queue::$impl_next_objective'(A,B,C).
'dungeon_queue::$value_next_objective'(A,B,C,upvals([])):-'dungeon_queue::next_objective'(A,B,C).
'dungeon_queue::turn_status'(A,B,C,D,E,F,G,H,I):-'dungeon_queue::$impl_turn_status'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::$value_turn_status'(A,B,C,D,E,F,G,H,upvals([I])):-'dungeon_queue::turn_status'(A,B,C,D,E,F,G,H,I).
'dungeon_queue::advance'(A,B,C,D,E,F,G,H):-'dungeon_queue::$impl_advance'(A,B,C,D,E,F,G,H).
'dungeon_queue::$value_advance'(A,B,C,D,E,F,G,upvals([H])):-'dungeon_queue::advance'(A,B,C,D,E,F,G,H).
'dungeon_queue::do_turn'(A,B,C,D,E):-'dungeon_queue::$impl_do_turn'(A,B,C,D,E).
'dungeon_queue::$value_do_turn'(A,B,C,D,upvals([E])):-'dungeon_queue::do_turn'(A,B,C,D,E).
'dungeon_queue::wait_turn'(A,B,C):-'dungeon_queue::$impl_wait_turn'(A,B,C).
'dungeon_queue::$value_wait_turn'(A,B,upvals([C])):-'dungeon_queue::wait_turn'(A,B,C).
'dungeon_queue::near_enemy'(A,B,C,D):-'dungeon_queue::$impl_near_enemy'(A,B,C,D).
'dungeon_queue::$value_near_enemy'(A,B,C,D,upvals([])):-'dungeon_queue::near_enemy'(A,B,C,D).
'dungeon_queue::autoplay_move'(A,B,C):-'dungeon_queue::$impl_autoplay_move'(A,B,C).
'dungeon_queue::$value_autoplay_move'(A,B,upvals([C])):-'dungeon_queue::autoplay_move'(A,B,C).
'dungeon_queue::move_key'(A,B,C,D):-'dungeon_queue::$impl_move_key'(A,B,C,D).
'dungeon_queue::$value_move_key'(A,B,C,D,upvals([])):-'dungeon_queue::move_key'(A,B,C,D).
'dungeon_queue::try_key'(A,B,C,D):-'dungeon_queue::$impl_try_key'(A,B,C,D).
'dungeon_queue::$value_try_key'(A,B,C,upvals([D])):-'dungeon_queue::try_key'(A,B,C,D).
'dungeon_queue::handle_key'(A,B,C,D,E):-'dungeon_queue::$impl_handle_key'(A,B,C,D,E).
'dungeon_queue::$value_handle_key'(A,B,C,upvals([D,E])):-'dungeon_queue::handle_key'(A,B,C,D,E).
'dungeon_queue::enqueue'(A,B,C):-'dungeon_queue::$impl_enqueue'(A,B,C).
'dungeon_queue::$value_enqueue'(A,B,C,upvals([])):-'dungeon_queue::enqueue'(A,B,C).
'dungeon_queue::diag_write'(A):-'dungeon_queue::$impl_diag_write'(A).
'dungeon_queue::$value_diag_write'(A,upvals([])):-'dungeon_queue::diag_write'(A).
'dungeon_queue::diag'(A,B):-'dungeon_queue::$impl_diag'(A,B).
'dungeon_queue::$value_diag'(A,upvals([B])):-'dungeon_queue::diag'(A,B).
'dungeon_queue::update'(A,B,C,D,E):-'dungeon_queue::$impl_update'(A,B,C,D,E).
'dungeon_queue::$value_update'(A,B,C,upvals([D,E])):-'dungeon_queue::update'(A,B,C,D,E).
'dungeon_queue::drop_head'(A,B,C):-'dungeon_queue::$impl_drop_head'(A,B,C).
'dungeon_queue::$value_drop_head'(A,B,C,upvals([])):-'dungeon_queue::drop_head'(A,B,C).
'dungeon_queue::draw'(A,B,C):-'dungeon_queue::$impl_draw'(A,B,C).
'dungeon_queue::$value_draw'(A,upvals([B,C])):-'dungeon_queue::draw'(A,B,C).
'dungeon_queue::draw_map'(A,B,C):-'dungeon_queue::$impl_draw_map'(A,B,C).
'dungeon_queue::$value_draw_map'(A,upvals([B,C])):-'dungeon_queue::draw_map'(A,B,C).
'dungeon_queue::draw_rows'(A,B,C,D,E,F):-'dungeon_queue::$impl_draw_rows'(A,B,C,D,E,F).
'dungeon_queue::$value_draw_rows'(A,B,C,D,upvals([E,F])):-'dungeon_queue::draw_rows'(A,B,C,D,E,F).
'dungeon_queue::draw_row_cells'(A,B,C,D,E,F,G):-'dungeon_queue::$impl_draw_row_cells'(A,B,C,D,E,F,G).
'dungeon_queue::$value_draw_row_cells'(A,B,C,D,E,upvals([F,G])):-'dungeon_queue::draw_row_cells'(A,B,C,D,E,F,G).
'dungeon_queue::draw_cell'(A,B,C,D,E):-'dungeon_queue::$impl_draw_cell'(A,B,C,D,E).
'dungeon_queue::$value_draw_cell'(A,B,C,D,upvals([E])):-'dungeon_queue::draw_cell'(A,B,C,D,E).
'dungeon_queue::checker_light'(A,B,C):-'dungeon_queue::$impl_checker_light'(A,B,C).
'dungeon_queue::$value_checker_light'(A,B,C,upvals([])):-'dungeon_queue::checker_light'(A,B,C).
'dungeon_queue::draw_scent'(A,B):-'dungeon_queue::$impl_draw_scent'(A,B).
'dungeon_queue::$value_draw_scent'(A,upvals([B])):-'dungeon_queue::draw_scent'(A,B).
'dungeon_queue::scent_rows'(A,B,C,D,E,F):-'dungeon_queue::$impl_scent_rows'(A,B,C,D,E,F).
'dungeon_queue::$value_scent_rows'(A,B,C,D,E,upvals([F])):-'dungeon_queue::scent_rows'(A,B,C,D,E,F).
'dungeon_queue::scent_cells'(A,B,C,D,E,F):-'dungeon_queue::$impl_scent_cells'(A,B,C,D,E,F).
'dungeon_queue::$value_scent_cells'(A,B,C,D,E,upvals([F])):-'dungeon_queue::scent_cells'(A,B,C,D,E,F).
'dungeon_queue::draw_gems'(A,B):-'dungeon_queue::$impl_draw_gems'(A,B).
'dungeon_queue::$value_draw_gems'(A,upvals([B])):-'dungeon_queue::draw_gems'(A,B).
'dungeon_queue::draw_exit'(A,B):-'dungeon_queue::$impl_draw_exit'(A,B).
'dungeon_queue::$value_draw_exit'(A,upvals([B])):-'dungeon_queue::draw_exit'(A,B).
'dungeon_queue::draw_enemies'(A,B):-'dungeon_queue::$impl_draw_enemies'(A,B).
'dungeon_queue::$value_draw_enemies'(A,upvals([B])):-'dungeon_queue::draw_enemies'(A,B).
'dungeon_queue::draw_player'(A,B):-'dungeon_queue::$impl_draw_player'(A,B).
'dungeon_queue::$value_draw_player'(A,upvals([B])):-'dungeon_queue::draw_player'(A,B).
'dungeon_queue::draw_hud'(A,B,C):-'dungeon_queue::$impl_draw_hud'(A,B,C).
'dungeon_queue::$value_draw_hud'(A,upvals([B,C])):-'dungeon_queue::draw_hud'(A,B,C).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], dungeon_queue([])),cosmos_profile_finish)
    ).
