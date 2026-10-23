:- style_check(-singleton).
'test6::$impl_p'(A):-A=1.0.
'test6::$impl_draw'(A):-true.
'test6::$impl_update'(A,B,C):-C=B.
test6([]):-(new(A),B=A),(cosmos_receiver("table",C),cosmos_method(C,"set",[B,0.0,D,E])),print(E),(cosmos_receiver("table",C),cosmos_method(C,"set",[E,0.0,D,F])),print(F),cosmos_require("space",G),(cosmos_receiver("table",C),cosmos_get(C,"set",H),I=H),(new(J),K=J),(L=0.0,cosmos_while(clos(upvals([]),'test6::$closure_0.0'),clos(upvals([M,I]),'test6::$closure_1.0'),[L,K],[N,O])),print(O),print(2.0),(cosmos_get(G,"graphics",P),Q=P),cosmos_method(G,"init",[640.0,480.0]),new(R),set_(R,"update",clos(upvals([]),'test6::$value_update'),S),set_(S,"draw",clos(upvals([]),'test6::$value_draw'),T),new(U),set_(U,"x",280.0,V),set_(V,"y",215.0,W),cosmos_method(G,"start",[16.0,T,W]).
'test6::p'(A):-'test6::$impl_p'(A).
'test6::$value_p'(A,upvals([])):-'test6::p'(A).
'test6::draw'(A):-cosmos_callable("void","draw",'test6::$impl_draw'(A)).
'test6::$value_draw'(A,upvals([])):-'test6::draw'(A).
'test6::update'(A,B,C):-cosmos_callable("void","update",'test6::$impl_update'(A,B,C)).
'test6::$value_update'(A,B,C,upvals([])):-'test6::update'(A,B,C).
'test6::$closure_0.0'([A,B],upvals([])):-r_lt(A,5.0).
'test6::$closure_1.0'([A,B],C,upvals([D,E])):-((print(B),(call_cl(E,[B,A,F,G]),H=G),I=H),(add_(A,1.0,J),K=J),L=K),C=[K,H],L=K,I=H.
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
      directory_file_path(Root, 'libs/space_xpce_prolog.pl', Backend), ensure_loaded(Backend),
      directory_file_path(Root, ?, SourceTemplate),
      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),
      nb_setval(path,Path),
      Arguments = [Executable|RawArguments], test6([])
    ).
