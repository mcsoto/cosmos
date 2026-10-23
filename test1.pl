:- style_check(-singleton).
'test1::$impl_p'(A,B):-((add_(A,1.0,C),D=C),E=22.0),B=E.
'test1::$impl_said'(A,B,C):-call_cl(C,[A,B,D]).
'test1::$impl_saidAt'(A,B,C,D):-call_cl(D,[A,B,C]).
'test1::$impl_say'(A,B,C,D,E,F,G):-B=[H,G],call_cl(C,[A,H,D]),(add_(D,1.0,I),size_(A,J),cosmos_receiver("string",F),cosmos_method(F,"slice",[A,I,J,G])),print(G);B=[H],call_cl(C,[A,H,K]).
test1([]):-('test1::p'(1.0,A),print(A)),cosmos_for([1.0,2.0,3.0],clos(upvals([B]),'test1::$closure_0.0'),[],[]),cosmos_for("[1,2,3]",clos(upvals([B]),'test1::$closure_1.0'),[],[]),(cosmos_receiver("string",C),cosmos_get(C,"find",D),E=D),F=1.0,cosmos_while(clos(upvals([]),'test1::$closure_2.0'),clos(upvals([E,G,H,B,I,C,J]),'test1::$closure_3.0'),[F],[K]),(true,(cosmos_receiver("string",C),cosmos_method(C,"find",["a-",I,G])),(add_(">",G,L),print(L)),I="-",(add_(">",G,M),print(M)),(size_(N,O),add_("",O,P),print(P)),cosmos_receiver("list",H),cosmos_method(H,"choice",[[1.0,2.0,3.0],J]);\+true,true).
'test1::p'(A,B):-'test1::$impl_p'(A,B).
'test1::$value_p'(A,B,upvals([])):-'test1::p'(A,B).
'test1::said'(A,B,C):-'test1::$impl_said'(A,B,C).
'test1::$value_said'(A,B,upvals([C])):-'test1::said'(A,B,C).
'test1::saidAt'(A,B,C,D):-'test1::$impl_saidAt'(A,B,C,D).
'test1::$value_saidAt'(A,B,C,upvals([D])):-'test1::saidAt'(A,B,C,D).
'test1::say'(A,B,C,D,E,F,G):-'test1::$impl_say'(A,B,C,D,E,F,G).
'test1::$value_say'(A,B,upvals([C,D,E,F,G])):-'test1::say'(A,B,C,D,E,F,G).
'test1::$closure_0.0'(A,B,[],C,upvals([D])):-print(B),C=[].
'test1::$closure_1.0'(A,B,[],C,upvals([D])):-print(B),C=[].
'test1::$closure_2.0'([A],upvals([])):-A=1.0.
'test1::$closure_4.0'(A,B,[],C,upvals([D,E])):-(add_(B,"=",F),(cosmos_receiver("math",D),cosmos_method_value(D,"random",[1.0,10.0],G)),add_(F,G,H),print(H)),C=[].
'test1::$closure_3.0'([A],B,upvals([C,D,E,F,G,H,I])):-((cosmos_receiver("io",J),cosmos_method(J,"write",["> "])),((cosmos_receiver("io",J),cosmos_method_value(J,"read",[],K)),L=K),(L="random",((cosmos_receiver("math",M),cosmos_method_value(M,"range",[1.0,20.0],N)),cosmos_for(N,clos(upvals([M,F]),'test1::$closure_4.0'),[],[])),O=A;dif(L,"random"),(((cosmos_receiver("string",H),cosmos_method(H,"find",[L,G,D])),has_(["+","-","="],G)),(print("maths"),((cosmos_receiver("string",H),cosmos_method_value(H,"slice",[L,0.0,D],P)),Q=P),(add_(D,1.0,R),size_(L,S),(cosmos_receiver("string",H),cosmos_method_value(H,"slice",[L,R,S],T)),U=T),print(Q),print(U)),V=A;\+ ((cosmos_receiver("string",H),cosmos_method(H,"find",[L,G,D])),has_(["+","-","="],G)),('test1::say'(L,["say ",I],C,D,F,H,I),true,W=A;\+'test1::say'(L,["say ",I],C,D,F,H,I),('test1::said'(L,"random",C),((cosmos_receiver("list",E),cosmos_method(E,"choice",[[1.0,2.0,3.0],I])),print(I)),X=A;\+'test1::said'(L,"random",C),(Y=0.0,Z=Y),X=Y),W=X),V=W),O=V)),B=[O],Z=O.
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
      directory_file_path(Root, libs, LibsRel),
      directory_file_path(Root, userlibs, UserLibsRel),
      directory_file_path(Root, 'compiler/swi.pl', Runtime),
      directory_file_path(Root, 'compiler/platform/runtime.pl', Operations),
      directory_file_path(Root, 'libs/?', LibsTemplate),
      directory_file_path(Root, 'userlibs/?', UserLibsTemplate),
      assertz(file_search_path(libs, LibsRel)),
      assertz(file_search_path(userlibs, UserLibsRel)),
      % swi.pl defines cosmos_get/3.  A saved image already has
      % it, so only a source run needs the runtime loaded.
      ( current_predicate(cosmos_get/3) -> true
      ; ensure_loaded(Runtime), ensure_loaded(Operations)
      ),
      directory_file_path(Root, ?, SourceTemplate),
      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),
      nb_setval(path,Path),
      Arguments = [Executable|RawArguments], test1([])
    ).
