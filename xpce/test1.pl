:- style_check(-singleton).
'test1::$impl_move'(A,B,C):-(A="left"->(cosmos_get(B,"x",D),add_(D,1.0,E),cosmos_update(B,"x",E,F),G=F),H=G;(A="up"->(cosmos_get(B,"y",I),r_sub(I,1.0,J),cosmos_update(B,"y",J,K),L=K),M=L;true,M=B),H=M),C=H.
'test1::$impl_move2'(A,B,C):-((A="left";A="right";A="up";A="down"),cosmos_update(B,"dir",A,D),E=D),C=E.
'test1::$impl_update'(A,B,C):-cosmos_set_or_unify(B,"dir","right")->new(D),cosmos_get(B,"x",E),add_(E,2.0,F),r_mod(F,520.0,G),set_(D,"x",G,H),set_(H,"y",0.0,I),set_(I,"dir","right",J),C=J;new(K),cosmos_get(B,"x",L),r_sub(L,2.0,M),r_mod(M,520.0,N),set_(K,"x",N,O),set_(O,"y",0.0,P),C=P.
'test1::$impl_mouseup'(A,B,C,D):-print(["-mouse"]).
'test1::$impl_keypressed'(A,B,C):-print("-key"),print(A),if_(A="left",(new(D),set_(D,"dir","left",E),cosmos_get(B,"x",F),set_(E,"x",F,G),'test1::update'(B,G,C)),(new(H),set_(H,"dir","right",I),cosmos_get(B,"x",J),set_(I,"x",J,K),'test1::update'(B,K,C))).
'test1::$impl_mousepressed'(A,B,C):-print("-").
'test1::$impl_draw'(A,B):-(cosmos_get(B,"graphics",C),D=C),cosmos_method(D,"clear",["#1b1b2f"]),cosmos_method(D,"setColor",["#3050ff"]),cosmos_get(A,"x",E),cosmos_method(D,"rectangle",["fill",E,100.0,80.0,50.0]).
test1([]):-cosmos_require("space2",A),cosmos_require("logic",B),cosmos_method(A,"init",[640.0,480.0]),new(C),set_(C,"update",clos(upvals([]),'test1::$value_update'),D),set_(D,"draw",clos(upvals([A]),'test1::$value_draw'),E),set_(E,"keypressed",clos(upvals([]),'test1::$value_keypressed'),F),set_(F,"mouseup",clos(upvals([]),'test1::$value_mouseup'),G),new(H),set_(H,"x",100.0,I),set_(I,"y",0.0,J),set_(J,"dir","right",K),cosmos_method(A,"start",[16.0,G,K]).
'test1::move'(A,B,C):-cosmos_callable("function","move",'test1::$impl_move'(A,B,C)).
'test1::$value_move'(A,B,C,upvals([])):-'test1::move'(A,B,C).
'test1::move2'(A,B,C):-cosmos_callable("function","move2",'test1::$impl_move2'(A,B,C)).
'test1::$value_move2'(A,B,C,upvals([])):-'test1::move2'(A,B,C).
'test1::update'(A,B,C):-cosmos_checked_call("function","update",[t("parameters",[t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","In",>,t,t("type","Any",-,t,t)),t("mode","Unspecified",>,t,t("type","Any",-,t,t))],<,t("determinism","nondet",-,t,t),t)],[A,B,C],t("rgb",t("open",0.0,<,t("fields",["Number","Number","Number"],>,t,t("location",fc_Loc(15.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),<,t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",[],-,t,t)),-,t,t),t),'test1::$impl_update'(A,B,C),D).
'test1::$value_update'(A,B,C,upvals([])):-'test1::update'(A,B,C).
'test1::mouseup'(A,B,C,D):-'test1::$impl_mouseup'(A,B,C,D).
'test1::$value_mouseup'(A,B,C,D,upvals([])):-'test1::mouseup'(A,B,C,D).
'test1::keypressed'(A,B,C):-'test1::$impl_keypressed'(A,B,C).
'test1::$value_keypressed'(A,B,C,upvals([])):-'test1::keypressed'(A,B,C).
'test1::mousepressed'(A,B,C):-'test1::$impl_mousepressed'(A,B,C).
'test1::$value_mousepressed'(A,B,C,upvals([])):-'test1::mousepressed'(A,B,C).
'test1::draw'(A,B):-'test1::$impl_draw'(A,B).
'test1::$value_draw'(A,upvals([B])):-'test1::draw'(A,B).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], test1([])),cosmos_profile_finish)
    ).
