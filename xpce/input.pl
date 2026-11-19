:- style_check(-singleton).
'input::$impl_update'(A,B,C,D):-((cosmos_get(D,"event",E),cosmos_method_value(E,"get",[],F)),G=F),cosmos_for(G,clos(upvals([]),'input::$closure_0.0'),[],[]),((cosmos_get(D,"event",H),cosmos_method_value(H,"size",[],I)),J=I),((cosmos_get(D,"event",K),cosmos_method_value(K,"has",["keydown"],L)),M=L),((cosmos_get(D,"graphics",N),cosmos_method_value(N,"getColor",[],O)),P=O),new(Q),cosmos_get(B,"ticks",R),add_(R,1.0,S),set_(Q,"ticks",S,T),set_(T,"pending",M,U),set_(U,"queue",J,V),set_(V,"color",P,W),C=W.
'input::$impl_draw'(A,B):-(cosmos_get(B,"graphics",C),D=C),(cosmos_type_constraint(fc_rgb(16.0,16.0,24.0),"rgb",t("rgb",t("open",0.0,<,t("fields",["Number","Number","Number"],>,t,t("location",fc_Loc(26.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),<,t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",[],-,t,t)),-,t,t),t)),cosmos_method(D,"clear",[fc_rgb(16.0,16.0,24.0)])),(cosmos_type_constraint(fc_rgb(255.0,0.0,0.0),"rgb",t("rgb",t("open",0.0,<,t("fields",["Number","Number","Number"],>,t,t("location",fc_Loc(26.0,1.0),-,t,t)),t("parent","Functor",-,t,t)),<,t("$imports",t("kind","metadata",-,t("fields",t,-,t,t),t("modules",[],-,t,t)),-,t,t),t)),cosmos_method(D,"setColor",[fc_rgb(255.0,0.0,0.0)])),cosmos_method(D,"rectangle",["fill",20.0,20.0,60.0,60.0]),cosmos_get(A,"ticks",E),cosmos_get(A,"queue",F),cosmos_get(A,"pending",G),cosmos_get(A,"color",H),print(["tick",E,"queue",F,"pending",G,"color",H]).
'input::$impl_keypressed'(A,B,C):-print(["keypressed",A]),new(D),cosmos_get(B,"pressed",E),add_(E,1.0,F),set_(D,"pressed",F,G),C=G.
'input::$impl_keyreleased'(A,B,C):-print(["keyreleased",A]),C=B.
'input::$impl_mousepressed'(A,B,C,D,E):-print(["mousepressed",A,B,C]),E=D.
'input::$impl_mousereleased'(A,B,C,D,E):-print(["mousereleased",A,B,C]),E=D.
'input::$impl_wheel'(A,B,C,D):-print(["wheel",A,B]),D=C.
input([]):-cosmos_require("space",A),cosmos_method(A,"init",[320.0,240.0]),new(B),set_(B,"update",clos(upvals([A]),'input::$value_update'),C),set_(C,"draw",clos(upvals([A]),'input::$value_draw'),D),set_(D,"keypressed",clos(upvals([]),'input::$value_keypressed'),E),set_(E,"keyreleased",clos(upvals([]),'input::$value_keyreleased'),F),set_(F,"mousepressed",clos(upvals([]),'input::$value_mousepressed'),G),set_(G,"mousereleased",clos(upvals([]),'input::$value_mousereleased'),H),set_(H,"wheel",clos(upvals([]),'input::$value_wheel'),I),new(J),set_(J,"ticks",0.0,K),set_(K,"pressed",0.0,L),cosmos_method(A,"start",[16.0,I,L]).
'input::$closure_0.0'(A,B,[],C,upvals([])):-(cosmos_get(B,"type",D),print(["EV",D])),C=[].
'input::update'(A,B,C,D):-'input::$impl_update'(A,B,C,D).
'input::$value_update'(A,B,C,upvals([D])):-'input::update'(A,B,C,D).
'input::draw'(A,B):-'input::$impl_draw'(A,B).
'input::$value_draw'(A,upvals([B])):-'input::draw'(A,B).
'input::keypressed'(A,B,C):-'input::$impl_keypressed'(A,B,C).
'input::$value_keypressed'(A,B,C,upvals([])):-'input::keypressed'(A,B,C).
'input::keyreleased'(A,B,C):-'input::$impl_keyreleased'(A,B,C).
'input::$value_keyreleased'(A,B,C,upvals([])):-'input::keyreleased'(A,B,C).
'input::mousepressed'(A,B,C,D,E):-'input::$impl_mousepressed'(A,B,C,D,E).
'input::$value_mousepressed'(A,B,C,D,E,upvals([])):-'input::mousepressed'(A,B,C,D,E).
'input::mousereleased'(A,B,C,D,E):-'input::$impl_mousereleased'(A,B,C,D,E).
'input::$value_mousereleased'(A,B,C,D,E,upvals([])):-'input::mousereleased'(A,B,C,D,E).
'input::wheel'(A,B,C,D):-'input::$impl_wheel'(A,B,C,D).
'input::$value_wheel'(A,B,C,D,upvals([])):-'input::wheel'(A,B,C,D).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], input([])),cosmos_profile_finish)
    ).
