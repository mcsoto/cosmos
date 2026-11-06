:- style_check(-singleton).
'starfall::$impl_same'(A,B,C,D):-A=C,B=D.
'starfall::$impl_meteor'(A,B,C):-cosmos_get(C,"m1x",D),cosmos_get(C,"m1y",E),'starfall::same'(A,B,D,E);cosmos_get(C,"m2x",F),cosmos_get(C,"m2y",G),'starfall::same'(A,B,F,G);cosmos_get(C,"m3x",H),cosmos_get(C,"m3y",I),'starfall::same'(A,B,H,I);cosmos_get(C,"m4x",J),cosmos_get(C,"m4y",K),'starfall::same'(A,B,J,K).
'starfall::$impl_wrap_y'(A,B,C):-r_ge(A,C),B=1.0;r_lt(A,C),add_(A,1.0,D),B=D.
'starfall::$impl_wrap_x'(A,B,C,D):-(add_(A,B,E),F=E),(r_gt(F,D),r_sub(F,D,G),C=G;r_le(F,D),(r_lt(F,1.0),add_(F,D,H),C=H;r_ge(F,1.0),C=F)).
'starfall::$impl_next_core'(A,B,C):-cosmos_get(A,"cores",D),if_(D=0.0,(B=10.0,C=3.0),(cosmos_get(A,"cores",E),if_(E=1.0,(B=3.0,C=5.0),(cosmos_get(A,"cores",F),if_(F=2.0,(B=8.0,C=1.0),(cosmos_get(A,"cores",G),if_(G=3.0,(B=1.0,C=7.0),(cosmos_get(A,"cores",H),if_(H=4.0,(B=11.0,C=6.0),(cosmos_get(A,"cores",I),if_(I=5.0,(B=5.0,C=3.0),(cosmos_get(A,"cores",J),if_(J=6.0,(B=9.0,C=8.0),(B=2.0,C=2.0)))))))))))))).
'starfall::$impl_copy'(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R):-new(S),set_(S,"px",C,T),set_(T,"py",D,U),set_(U,"cores",E,V),set_(V,"lives",F,W),set_(W,"ended",G,X),set_(X,"won",H,Y),set_(Y,"m1x",I,Z),set_(Z,"m1y",J,A1),set_(A1,"m2x",K,B1),set_(B1,"m2y",L,C1),set_(C1,"m3x",M,D1),set_(D1,"m3y",N,E1),set_(E1,"m4x",O,F1),set_(F1,"m4y",P,G1),set_(G1,"corex",Q,H1),set_(H1,"corey",R,I1),B=I1.
'starfall::$impl_step'(A,B,C,D):-(cosmos_set_or_unify(A,"ended",1.0);cosmos_set_or_unify(A,"won",1.0)),B=A;\+ (cosmos_set_or_unify(A,"ended",1.0);cosmos_set_or_unify(A,"won",1.0)),(cosmos_get(A,"m1y",E),'starfall::wrap_y'(E,F,D)),(cosmos_get(A,"m2y",G),'starfall::wrap_y'(G,H,D)),(cosmos_get(A,"m3y",I),'starfall::wrap_y'(I,J,D)),(cosmos_get(A,"m4y",K),'starfall::wrap_y'(K,L,D)),(cosmos_get(A,"m1x",M),'starfall::wrap_x'(M,1.0,N,C)),(cosmos_get(A,"m2x",O),r_sub(0.0,1.0,P),'starfall::wrap_x'(O,P,Q,C)),(cosmos_get(A,"m3x",R),'starfall::wrap_x'(R,1.0,S,C)),(cosmos_get(A,"m4x",T),r_sub(0.0,1.0,U),'starfall::wrap_x'(T,U,V,C)),(((cosmos_get(A,"px",W),cosmos_get(A,"py",X),'starfall::same'(W,X,N,F);cosmos_get(A,"px",Y),cosmos_get(A,"py",Z),'starfall::same'(Y,Z,Q,H);cosmos_get(A,"px",A1),cosmos_get(A,"py",B1),'starfall::same'(A1,B1,S,J);cosmos_get(A,"px",C1),cosmos_get(A,"py",D1),'starfall::same'(C1,D1,V,L)),cosmos_get(A,"lives",E1),r_le(E1,1.0)),cosmos_get(A,"cores",F1),cosmos_get(A,"corex",G1),cosmos_get(A,"corey",H1),'starfall::copy'(A,B,6.0,9.0,F1,0.0,1.0,0.0,N,F,Q,H,S,J,V,L,G1,H1);\+ ((cosmos_get(A,"px",I1),cosmos_get(A,"py",J1),'starfall::same'(I1,J1,N,F);cosmos_get(A,"px",K1),cosmos_get(A,"py",L1),'starfall::same'(K1,L1,Q,H);cosmos_get(A,"px",M1),cosmos_get(A,"py",N1),'starfall::same'(M1,N1,S,J);cosmos_get(A,"px",O1),cosmos_get(A,"py",P1),'starfall::same'(O1,P1,V,L)),cosmos_get(A,"lives",Q1),r_le(Q1,1.0)),((cosmos_get(A,"px",R1),cosmos_get(A,"py",S1),'starfall::same'(R1,S1,N,F);cosmos_get(A,"px",T1),cosmos_get(A,"py",U1),'starfall::same'(T1,U1,Q,H);cosmos_get(A,"px",V1),cosmos_get(A,"py",W1),'starfall::same'(V1,W1,S,J);cosmos_get(A,"px",X1),cosmos_get(A,"py",Y1),'starfall::same'(X1,Y1,V,L)),cosmos_get(A,"cores",Z1),cosmos_get(A,"lives",A2),r_sub(A2,1.0,B2),cosmos_get(A,"corex",C2),cosmos_get(A,"corey",D2),'starfall::copy'(A,B,6.0,9.0,Z1,B2,0.0,0.0,N,F,Q,H,S,J,V,L,C2,D2);\+ (cosmos_get(A,"px",E2),cosmos_get(A,"py",F2),'starfall::same'(E2,F2,N,F);cosmos_get(A,"px",G2),cosmos_get(A,"py",H2),'starfall::same'(G2,H2,Q,H);cosmos_get(A,"px",I2),cosmos_get(A,"py",J2),'starfall::same'(I2,J2,S,J);cosmos_get(A,"px",K2),cosmos_get(A,"py",L2),'starfall::same'(K2,L2,V,L)),cosmos_get(A,"px",M2),cosmos_get(A,"py",N2),cosmos_get(A,"cores",O2),cosmos_get(A,"lives",P2),cosmos_get(A,"corex",Q2),cosmos_get(A,"corey",R2),'starfall::copy'(A,B,M2,N2,O2,P2,0.0,0.0,N,F,Q,H,S,J,V,L,Q2,R2))).
'starfall::$impl_move'(A,B,C,D,E,F):-(cosmos_set_or_unify(C,"ended",1.0);cosmos_set_or_unify(C,"won",1.0)),D=C;\+ (cosmos_set_or_unify(C,"ended",1.0);cosmos_set_or_unify(C,"won",1.0)),(cosmos_get(C,"px",G),add_(G,A,H),I=H),(cosmos_get(C,"py",J),add_(J,B,K),L=K),((r_lt(I,1.0);r_gt(I,E);r_lt(L,1.0);r_gt(L,F)),D=C;\+ (r_lt(I,1.0);r_gt(I,E);r_lt(L,1.0);r_gt(L,F)),('starfall::meteor'(I,L,C),((cosmos_get(C,"lives",M),r_le(M,1.0)),cosmos_get(C,"cores",N),cosmos_get(C,"m1x",O),cosmos_get(C,"m1y",P),cosmos_get(C,"m2x",Q),cosmos_get(C,"m2y",R),cosmos_get(C,"m3x",S),cosmos_get(C,"m3y",T),cosmos_get(C,"m4x",U),cosmos_get(C,"m4y",V),cosmos_get(C,"corex",W),cosmos_get(C,"corey",X),'starfall::copy'(C,D,6.0,9.0,N,0.0,1.0,0.0,O,P,Q,R,S,T,U,V,W,X);(cosmos_get(C,"lives",Y),r_gt(Y,1.0)),cosmos_get(C,"cores",Z),cosmos_get(C,"lives",A1),r_sub(A1,1.0,B1),cosmos_get(C,"m1x",C1),cosmos_get(C,"m1y",D1),cosmos_get(C,"m2x",E1),cosmos_get(C,"m2y",F1),cosmos_get(C,"m3x",G1),cosmos_get(C,"m3y",H1),cosmos_get(C,"m4x",I1),cosmos_get(C,"m4y",J1),cosmos_get(C,"corex",K1),cosmos_get(C,"corey",L1),'starfall::copy'(C,D,6.0,9.0,Z,B1,0.0,0.0,C1,D1,E1,F1,G1,H1,I1,J1,K1,L1));\+'starfall::meteor'(I,L,C),(((cosmos_get(C,"corex",M1),cosmos_get(C,"corey",N1),'starfall::same'(I,L,M1,N1)),cosmos_get(C,"cores",O1),r_ge(O1,7.0)),cosmos_get(C,"lives",P1),cosmos_get(C,"m1x",Q1),cosmos_get(C,"m1y",R1),cosmos_get(C,"m2x",S1),cosmos_get(C,"m2y",T1),cosmos_get(C,"m3x",U1),cosmos_get(C,"m3y",V1),cosmos_get(C,"m4x",W1),cosmos_get(C,"m4y",X1),cosmos_get(C,"corex",Y1),cosmos_get(C,"corey",Z1),'starfall::copy'(C,D,I,L,8.0,P1,0.0,1.0,Q1,R1,S1,T1,U1,V1,W1,X1,Y1,Z1);\+ ((cosmos_get(C,"corex",A2),cosmos_get(C,"corey",B2),'starfall::same'(I,L,A2,B2)),cosmos_get(C,"cores",C2),r_ge(C2,7.0)),((cosmos_get(C,"corex",D2),cosmos_get(C,"corey",E2),'starfall::same'(I,L,D2,E2)),'starfall::next_core'(C,F2,G2),cosmos_get(C,"cores",H2),add_(H2,1.0,I2),cosmos_get(C,"lives",J2),cosmos_get(C,"m1x",K2),cosmos_get(C,"m1y",L2),cosmos_get(C,"m2x",M2),cosmos_get(C,"m2y",N2),cosmos_get(C,"m3x",O2),cosmos_get(C,"m3y",P2),cosmos_get(C,"m4x",Q2),cosmos_get(C,"m4y",R2),'starfall::copy'(C,D,I,L,I2,J2,0.0,0.0,K2,L2,M2,N2,O2,P2,Q2,R2,F2,G2);\+ (cosmos_get(C,"corex",S2),cosmos_get(C,"corey",T2),'starfall::same'(I,L,S2,T2)),cosmos_get(C,"cores",U2),cosmos_get(C,"lives",V2),cosmos_get(C,"m1x",W2),cosmos_get(C,"m1y",X2),cosmos_get(C,"m2x",Y2),cosmos_get(C,"m2y",Z2),cosmos_get(C,"m3x",A3),cosmos_get(C,"m3y",B3),cosmos_get(C,"m4x",C3),cosmos_get(C,"m4y",D3),cosmos_get(C,"corex",E3),cosmos_get(C,"corey",F3),'starfall::copy'(C,D,I,L,U2,V2,0.0,0.0,W2,X2,Y2,Z2,A3,B3,C3,D3,E3,F3))))).
'starfall::$impl_keypressed'(A,B,C,D,E,F):-if_(A="r",C=E,if_(A="up",(r_sub(0.0,1.0,G),'starfall::move'(0.0,G,B,C,D,F)),if_(A="down",'starfall::move'(0.0,1.0,B,C,D,F),if_(A="left",(r_sub(0.0,1.0,H),'starfall::move'(H,0.0,B,C,D,F)),if_(A="right",'starfall::move'(1.0,0.0,B,C,D,F),C=B))))).
'starfall::$impl_update'(A,B,C,D,E,F):-(cosmos_get(F,"event",G),cosmos_method(G,"get",[H])),'starfall::apply_events'(H,A,I,C,D,E),'starfall::step'(I,B,C,E).
'starfall::$impl_apply_events'(A,B,C,D,E,F):-if_(A=[],C=B,(A=[G|H],(cosmos_get(G,"type",I),J=I),if_(J="keydown",(cosmos_get(G,"key",K),'starfall::keypressed'(K,B,L,D,E,F)),L=B),'starfall::apply_events'(H,L,C,D,E,F))).
'starfall::$impl_draw_star'(A,B,C,D,E,F):-(r_sub(A,1.0,G),r_mul(G,D,H),I=H),(r_sub(B,1.0,J),r_mul(J,D,K),add_(E,K,L),M=L),(cosmos_get(F,"graphics",N),cosmos_method(N,"setColor",[C])),(add_(I,17.0,O),add_(M,5.0,P),cosmos_get(F,"graphics",Q),cosmos_method(Q,"rectangle",["fill",O,P,6.0,30.0])),(add_(I,5.0,R),add_(M,17.0,S),cosmos_get(F,"graphics",T),cosmos_method(T,"rectangle",["fill",R,S,30.0,6.0])),add_(I,12.0,U),add_(M,12.0,V),cosmos_get(F,"graphics",W),cosmos_method(W,"rectangle",["fill",U,V,16.0,16.0]).
'starfall::$impl_draw_meteor'(A,B,C,D,E):-(r_sub(A,1.0,F),r_mul(F,C,G),H=G),(r_sub(B,1.0,I),r_mul(I,C,J),add_(D,J,K),L=K),(cosmos_get(E,"graphics",M),cosmos_method(M,"setColor",["#bb4e65"])),(add_(H,7.0,N),add_(L,7.0,O),cosmos_get(E,"graphics",P),cosmos_method(P,"rectangle",["fill",N,O,26.0,26.0])),(cosmos_get(E,"graphics",Q),cosmos_method(Q,"setColor",["#f08962"])),(add_(H,12.0,R),add_(L,12.0,S),cosmos_get(E,"graphics",T),cosmos_method(T,"rectangle",["fill",R,S,16.0,16.0])),(cosmos_get(E,"graphics",U),cosmos_method(U,"setColor",["#351633"])),add_(H,17.0,V),add_(L,17.0,W),cosmos_get(E,"graphics",X),cosmos_method(X,"rectangle",["fill",V,W,6.0,6.0]).
'starfall::$impl_draw_player'(A,B,C,D):-(cosmos_get(A,"px",E),r_sub(E,1.0,F),r_mul(F,B,G),H=G),(cosmos_get(A,"py",I),r_sub(I,1.0,J),r_mul(J,B,K),add_(C,K,L),M=L),(cosmos_get(D,"graphics",N),cosmos_method(N,"setColor",["#59d7e8"])),(add_(H,8.0,O),add_(M,9.0,P),cosmos_get(D,"graphics",Q),cosmos_method(Q,"rectangle",["fill",O,P,24.0,23.0])),(cosmos_get(D,"graphics",R),cosmos_method(R,"setColor",["#d6fbff"])),(add_(H,13.0,S),add_(M,4.0,T),cosmos_get(D,"graphics",U),cosmos_method(U,"rectangle",["fill",S,T,14.0,8.0])),(cosmos_get(D,"graphics",V),cosmos_method(V,"setColor",["#182346"])),(add_(H,13.0,W),add_(M,18.0,X),cosmos_get(D,"graphics",Y),cosmos_method(Y,"rectangle",["fill",W,X,5.0,5.0])),add_(H,22.0,Z),add_(M,18.0,A1),cosmos_get(D,"graphics",B1),cosmos_method(B1,"rectangle",["fill",Z,A1,5.0,5.0]).
'starfall::$impl_draw_hud'(A,B,C,D):-(cosmos_get(C,"graphics",E),cosmos_method(E,"setColor",["#10172c"])),(cosmos_get(C,"graphics",F),cosmos_method(F,"rectangle",["fill",0.0,0.0,D,B])),(cosmos_get(C,"graphics",G),cosmos_method(G,"setColor",["#7dffd1"])),(r_sub(B,3.0,H),cosmos_get(C,"graphics",I),cosmos_method(I,"rectangle",["fill",0.0,H,D,3.0])),(cosmos_get(C,"graphics",J),cosmos_method(J,"setColor",["#263759"])),(cosmos_get(C,"graphics",K),cosmos_method(K,"rectangle",["fill",10.0,10.0,120.0,18.0])),(cosmos_get(C,"graphics",L),cosmos_method(L,"rectangle",["fill",145.0,10.0,120.0,18.0])),(cosmos_get(C,"graphics",M),cosmos_method(M,"rectangle",["fill",280.0,10.0,190.0,18.0])),(N=1.0,cosmos_while(clos(upvals([]),'starfall::$closure_0.0'),clos(upvals([A,C]),'starfall::$closure_1.0'),[N],[O])),((cosmos_get(A,"lives",P),r_ge(P,1.0)),(cosmos_get(C,"graphics",Q),cosmos_method(Q,"setColor",["#ff6f7d"])),cosmos_get(C,"graphics",R),cosmos_method(R,"rectangle",["fill",294.0,14.0,12.0,10.0]);(cosmos_get(A,"lives",S),r_lt(S,1.0)),true),((cosmos_get(A,"lives",T),r_ge(T,2.0)),cosmos_get(C,"graphics",U),cosmos_method(U,"rectangle",["fill",312.0,14.0,12.0,10.0]);(cosmos_get(A,"lives",V),r_lt(V,2.0)),true),((cosmos_get(A,"lives",W),r_ge(W,3.0)),cosmos_get(C,"graphics",X),cosmos_method(X,"rectangle",["fill",330.0,14.0,12.0,10.0]);(cosmos_get(A,"lives",Y),r_lt(Y,3.0)),true).
'starfall::$impl_draw'(A,B,C,D,E,F,G,H):-(cosmos_get(G,"graphics",I),cosmos_method(I,"setColor",["#080d1c"])),(cosmos_get(G,"graphics",J),cosmos_method(J,"rectangle",["fill",0.0,0.0,H,D])),'starfall::draw_hud'(A,E,G,H),(K=1.0,cosmos_while(clos(upvals([F]),'starfall::$closure_2.0'),clos(upvals([B,C,E,G]),'starfall::$closure_3.0'),[K],[L])),(cosmos_get(A,"corex",M),cosmos_get(A,"corey",N),'starfall::draw_star'(M,N,"#f5d06f",B,E,G)),(cosmos_get(A,"m1x",O),cosmos_get(A,"m1y",P),'starfall::draw_meteor'(O,P,B,E,G)),(cosmos_get(A,"m2x",Q),cosmos_get(A,"m2y",R),'starfall::draw_meteor'(Q,R,B,E,G)),(cosmos_get(A,"m3x",S),cosmos_get(A,"m3y",T),'starfall::draw_meteor'(S,T,B,E,G)),(cosmos_get(A,"m4x",U),cosmos_get(A,"m4y",V),'starfall::draw_meteor'(U,V,B,E,G)),'starfall::draw_player'(A,B,E,G),cosmos_get(A,"ended",W),if_(W=1.0,((cosmos_get(G,"graphics",X),cosmos_method(X,"setColor",["#3b1e37"])),(cosmos_get(G,"graphics",Y),cosmos_method(Y,"rectangle",["fill",120.0,190.0,240.0,70.0])),(cosmos_get(G,"graphics",Z),cosmos_method(Z,"setColor",["#ff6f7d"])),(cosmos_get(G,"graphics",A1),cosmos_method(A1,"rectangle",["fill",138.0,207.0,204.0,7.0])),cosmos_get(G,"graphics",B1),cosmos_method(B1,"rectangle",["fill",168.0,228.0,144.0,7.0])),(cosmos_get(A,"won",C1),if_(C1=1.0,((cosmos_get(G,"graphics",D1),cosmos_method(D1,"setColor",["#173e3d"])),(cosmos_get(G,"graphics",E1),cosmos_method(E1,"rectangle",["fill",120.0,190.0,240.0,70.0])),(cosmos_get(G,"graphics",F1),cosmos_method(F1,"setColor",["#7dffd1"])),(cosmos_get(G,"graphics",G1),cosmos_method(G1,"rectangle",["fill",138.0,207.0,204.0,7.0])),(cosmos_get(G,"graphics",H1),cosmos_method(H1,"setColor",["#f5d06f"])),cosmos_get(G,"graphics",I1),cosmos_method(I1,"rectangle",["fill",168.0,228.0,144.0,7.0])),true))).
starfall([]):-cosmos_require("space",A),B=12.0,C=10.0,D=40.0,E=40.0,(r_mul(B,D,F),G=F),(r_mul(C,D,H),add_(H,E,I),J=I),K=130.0,(new(L),set_(L,"px",6.0,M),set_(M,"py",9.0,N),set_(N,"cores",0.0,O),set_(O,"lives",3.0,P),set_(P,"ended",0.0,Q),set_(Q,"won",0.0,R),set_(R,"m1x",2.0,S),set_(S,"m1y",1.0,T),set_(T,"m2x",6.0,U),set_(U,"m2y",4.0,V),set_(V,"m3x",10.0,W),set_(W,"m3y",7.0,X),set_(X,"m4x",12.0,Y),set_(Y,"m4y",2.0,Z),set_(Z,"corex",6.0,A1),set_(A1,"corey",2.0,B1),C1=B1),cosmos_method(A,"init",[G,J]),new(D1),set_(D1,"update",clos(upvals([B,C1,C,A]),'starfall::$value_update'),E1),set_(E1,"draw",clos(upvals([D,B,J,E,C,A,G]),'starfall::$value_draw'),F1),cosmos_method(A,"start",[K,F1,C1]).
'starfall::same'(A,B,C,D):-'starfall::$impl_same'(A,B,C,D).
'starfall::$value_same'(A,B,C,D,upvals([])):-'starfall::same'(A,B,C,D).
'starfall::meteor'(A,B,C):-'starfall::$impl_meteor'(A,B,C).
'starfall::$value_meteor'(A,B,C,upvals([])):-'starfall::meteor'(A,B,C).
'starfall::wrap_y'(A,B,C):-'starfall::$impl_wrap_y'(A,B,C).
'starfall::$value_wrap_y'(A,B,upvals([C])):-'starfall::wrap_y'(A,B,C).
'starfall::wrap_x'(A,B,C,D):-'starfall::$impl_wrap_x'(A,B,C,D).
'starfall::$value_wrap_x'(A,B,C,upvals([D])):-'starfall::wrap_x'(A,B,C,D).
'starfall::next_core'(A,B,C):-'starfall::$impl_next_core'(A,B,C).
'starfall::$value_next_core'(A,B,C,upvals([])):-'starfall::next_core'(A,B,C).
'starfall::copy'(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R):-'starfall::$impl_copy'(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R).
'starfall::$value_copy'(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,upvals([])):-'starfall::copy'(A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R).
'starfall::step'(A,B,C,D):-'starfall::$impl_step'(A,B,C,D).
'starfall::$value_step'(A,B,upvals([C,D])):-'starfall::step'(A,B,C,D).
'starfall::move'(A,B,C,D,E,F):-'starfall::$impl_move'(A,B,C,D,E,F).
'starfall::$value_move'(A,B,C,D,upvals([E,F])):-'starfall::move'(A,B,C,D,E,F).
'starfall::keypressed'(A,B,C,D,E,F):-'starfall::$impl_keypressed'(A,B,C,D,E,F).
'starfall::$value_keypressed'(A,B,C,upvals([D,E,F])):-'starfall::keypressed'(A,B,C,D,E,F).
'starfall::update'(A,B,C,D,E,F):-'starfall::$impl_update'(A,B,C,D,E,F).
'starfall::$value_update'(A,B,upvals([C,D,E,F])):-'starfall::update'(A,B,C,D,E,F).
'starfall::apply_events'(A,B,C,D,E,F):-'starfall::$impl_apply_events'(A,B,C,D,E,F).
'starfall::$value_apply_events'(A,B,C,upvals([D,E,F])):-'starfall::apply_events'(A,B,C,D,E,F).
'starfall::draw_star'(A,B,C,D,E,F):-'starfall::$impl_draw_star'(A,B,C,D,E,F).
'starfall::$value_draw_star'(A,B,C,upvals([D,E,F])):-'starfall::draw_star'(A,B,C,D,E,F).
'starfall::draw_meteor'(A,B,C,D,E):-'starfall::$impl_draw_meteor'(A,B,C,D,E).
'starfall::$value_draw_meteor'(A,B,upvals([C,D,E])):-'starfall::draw_meteor'(A,B,C,D,E).
'starfall::draw_player'(A,B,C,D):-'starfall::$impl_draw_player'(A,B,C,D).
'starfall::$value_draw_player'(A,upvals([B,C,D])):-'starfall::draw_player'(A,B,C,D).
'starfall::$closure_0.0'([A],upvals([])):-r_le(A,8.0).
'starfall::$closure_1.0'([A],B,upvals([C,D])):-(((cosmos_get(C,"cores",E),r_le(A,E)),(cosmos_get(D,"graphics",F),cosmos_method(F,"setColor",["#f5d06f"])),r_sub(A,1.0,G),r_mul(G,13.0,H),add_(156.0,H,I),cosmos_get(D,"graphics",J),cosmos_method(J,"rectangle",["fill",I,14.0,8.0,10.0]);(cosmos_get(C,"cores",K),r_gt(A,K)),true),(add_(A,1.0,L),M=L),N=M),B=[M],N=M.
'starfall::draw_hud'(A,B,C,D):-'starfall::$impl_draw_hud'(A,B,C,D).
'starfall::$value_draw_hud'(A,upvals([B,C,D])):-'starfall::draw_hud'(A,B,C,D).
'starfall::$closure_2.0'([A],upvals([B])):-r_le(A,B).
'starfall::$closure_4.0'([A],upvals([B])):-r_le(A,B).
'starfall::$closure_5.0'([A],B,upvals([C,D,E,F])):-(((r_sub(A,1.0,G),r_mul(G,D,H),I=H),(r_sub(C,1.0,J),r_mul(J,D,K),add_(E,K,L),M=L),(add_(A,C,N),r_mod(N,2.0,O),P=O),if_(P=0.0,((cosmos_get(F,"graphics",Q),cosmos_method(Q,"setColor",["#111a31"])),add_(I,1.0,R),add_(M,1.0,S),r_sub(D,2.0,T),r_sub(D,2.0,U),cosmos_get(F,"graphics",V),cosmos_method(V,"rectangle",["fill",R,S,T,U])),((cosmos_get(F,"graphics",W),cosmos_method(W,"setColor",["#0d1529"])),add_(I,1.0,X),add_(M,1.0,Y),r_sub(D,2.0,Z),r_sub(D,2.0,A1),cosmos_get(F,"graphics",B1),cosmos_method(B1,"rectangle",["fill",X,Y,Z,A1])))),(add_(A,1.0,C1),D1=C1),E1=D1),B=[D1],E1=D1.
'starfall::$closure_3.0'([A],B,upvals([C,D,E,F])):-((G=1.0,cosmos_while(clos(upvals([D]),'starfall::$closure_4.0'),clos(upvals([A,C,E,F]),'starfall::$closure_5.0'),[G],[H])),(add_(A,1.0,I),J=I),K=J),B=[J],K=J.
'starfall::draw'(A,B,C,D,E,F,G,H):-'starfall::$impl_draw'(A,B,C,D,E,F,G,H).
'starfall::$value_draw'(A,upvals([B,C,D,E,F,G,H])):-'starfall::draw'(A,B,C,D,E,F,G,H).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], starfall([])),cosmos_profile_finish)
    ).
