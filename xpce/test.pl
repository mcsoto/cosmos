:- style_check(-singleton).
'test::$impl_move'(A,B,C):-(A="left"->(cosmos_get(B,"x",D),add_(D,1.0,E),cosmos_update(B,"x",E,F),G=F),H=G;(A="up"->(cosmos_get(B,"y",I),r_sub(I,1.0,J),cosmos_update(B,"y",J,K),L=K),M=L;true,M=B),H=M),C=H.
'test::$impl_move2'(A,B,C):-((A="left";A="right";A="up";A="down"),cosmos_update(B,"dir",A,D),E=D),C=E.
'test::$impl_update'(A,B,C,D):-(new(E),cosmos_get(B,"x",F),add_(F,2.0,G),r_mod(G,520.0,H),set_(E,"x",H,I),set_(I,"y",0.0,J),C=J),K=B,(cosmos_get(K,"x",L),cosmos_get(K,"y",M),print([L,M])),((cosmos_get(D,"event",N),cosmos_method_value(N,"get",[],O)),P=O),cosmos_for(P,clos(upvals([K,Q]),'test::$closure_0.0'),[],[]).
'test::$impl_draw'(A,B):-(cosmos_get(B,"graphics",C),D=C),cosmos_method(D,"clear",["#1b1b2f"]),cosmos_method(D,"setColor",["#3050ff"]),cosmos_get(A,"x",E),cosmos_method(D,"rectangle",["fill",E,100.0,80.0,50.0]).
test([]):-cosmos_require("space",A),cosmos_method(A,"init",[640.0,480.0]),new(B),set_(B,"update",clos(upvals([A]),'test::$value_update'),C),set_(C,"draw",clos(upvals([A]),'test::$value_draw'),D),new(E),set_(E,"x",100.0,F),set_(F,"y",0.0,G),cosmos_method(A,"start",[16.0,D,G]).
'test::move'(A,B,C):-cosmos_callable("function","move",'test::$impl_move'(A,B,C)).
'test::$value_move'(A,B,C,upvals([])):-'test::move'(A,B,C).
'test::move2'(A,B,C):-cosmos_callable("function","move2",'test::$impl_move2'(A,B,C)).
'test::$value_move2'(A,B,C,upvals([])):-'test::move2'(A,B,C).
'test::$closure_0.0'(A,B,[],C,upvals([D,E])):-(((cosmos_get(B,"type",F),dif(F,"mousemotion")),print(B);\+ (cosmos_get(B,"type",G),dif(G,"mousemotion")),true),cosmos_get(B,"type",H),if_(H="keyup",((cosmos_get(B,"key",I),print([I,D,J])),cosmos_get(B,"key",K),'test::move'(K,D,J)),true)),C=[].
'test::update'(A,B,C,D):-cosmos_checked_call("function","update",[t("parameters",[t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","In",>,t,t("type","Any",-,t,t)),t("mode","Unspecified",>,t,t("type","Any",-,t,t))],<,t("determinism","nondet",-,t,t),t)],[A,B,C],t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",[],-,t,t)),-,t,t),'test::$impl_update'(A,B,C,D),E).
'test::$value_update'(A,B,C,upvals([D])):-'test::update'(A,B,C,D).
'test::draw'(A,B):-'test::$impl_draw'(A,B).
'test::$value_draw'(A,upvals([B])):-'test::draw'(A,B).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], test([])),cosmos_profile_finish)
    ).
