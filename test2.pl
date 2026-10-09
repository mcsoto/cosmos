:- style_check(-singleton).
'test2::$impl_increment'(A,B):-add_(A,1.0,C),B=C.
test2([]):-cosmos_for([1.0,2.0,3.0],clos(upvals([A]),'test2::$closure_0.0'),[],[]),cosmos_for("[1,2,3]",clos(upvals([A]),'test2::$closure_1.0'),[],[]),(size_(B,C),add_("",C,D),print(D)),(add_(1.0,E,F),G=F),(add_("",2.0,H),I=H),J="asdf",print(K),L=fc_fc,print(L),M=1.0,print("-"),cosmos_require("test3",N).
'test2::increment'(A,B):-cosmos_checked_call("rel","increment",[t("parameters",[t("mode","In",>,t,t("type","Number",-,t,t)),t("mode","Out",>,t,t("type","Number",-,t,t))],<,t("determinism","nondet",-,t,t),t)],[A,B],t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",["_"],-,t,t)),-,t,t),'test2::$impl_increment'(A,B),C).
'test2::$value_increment'(A,B,upvals([])):-'test2::increment'(A,B).
'test2::$closure_0.0'(A,B,[],C,upvals([D])):-print(B),C=[].
'test2::$closure_1.0'(A,B,[],C,upvals([D])):-print(B),C=[].
