:- style_check(-singleton).
'sdl_demo_game::$impl_game'(A,B,C):-cosmos_method(C,"create",["frame",["XPCE SDL demo"],D]),cosmos_method(C,"size",[640.0,480.0,E]),cosmos_method(C,"create",["sdl_window",["Field",E],F]),cosmos_method(C,"send",[D,"append",[F]]),cosmos_method(C,"color",["#1b1b2f",G]),cosmos_method(C,"send",[F,"background",[G]]),cosmos_method(C,"create",["circle",[20.0],H]),cosmos_method(C,"color",["#3050ff",I]),cosmos_method(C,"send",[H,"fill",[I]]),cosmos_method(C,"send",[H,"pen",[2.0]]),cosmos_method(C,"create",["sdl_texture",[H],J]),cosmos_method(C,"point",[10.0,10.0,K]),cosmos_method(C,"send",[J,"hot_spot",[K]]),cosmos_method(C,"create",["area",[100.0,220.0,0.0,0.0],L]),cosmos_method(C,"create",["sdl_layer",[J,L,"none"],M]),cosmos_method(C,"send",[F,"append",[M]]),cosmos_method(C,"create",["text",["An sdl_window with a sprite"],N]),cosmos_method(C,"point",[10.0,10.0,O]),cosmos_method(C,"send",[F,"display",[N,O]]),cosmos_method(C,"color",["white",P]),cosmos_method(C,"send",[N,"colour",[P]]),cosmos_method(C,"send",[D,"open",[]]),cosmos_method(C,"set_data",["layer",M]),cosmos_method(C,"set_data",["area",L]),cosmos_method(C,"timer",[0.016,clos(upvals([B,C]),'sdl_demo_game::$value_tick'),Q]).
'sdl_demo_game::$impl_tick'(A,B,C):-cosmos_require("xpce",C),cosmos_method(C,"get_data",["layer",D]),cosmos_method(C,"get_data",["area",E]),cosmos_method(C,"get",[E,"x",F]),cosmos_method(C,"get",[E,"y",G]),(add_(F,4.0,H),r_mod(H,620.0,I),cosmos_method(C,"send",[E,"set",[I,G,0.0,0.0]])),cosmos_method(C,"send",[D,"area",[E]]),cosmos_method(C,"get",[D,"angle",J]),add_(J,3.0,K),r_mod(K,360.0,L),cosmos_method(C,"send",[D,"angle",[L]]).
sdl_demo_game([]):-cosmos_require("xpce",A),cosmos_method(A,"main_loop",[clos(upvals([B,A]),'sdl_demo_game::$value_game')]).
'sdl_demo_game::game'(A,B,C):-'sdl_demo_game::$impl_game'(A,B,C).
'sdl_demo_game::$value_game'(A,upvals([B,C])):-'sdl_demo_game::game'(A,B,C).
'sdl_demo_game::tick'(A,B,C):-'sdl_demo_game::$impl_tick'(A,B,C).
'sdl_demo_game::$value_tick'(A,upvals([B,C])):-'sdl_demo_game::tick'(A,B,C).
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
      (   (   nb_current(cosmos_profile_requested,true),
              directory_file_path(Root, 'compiler/platform/profile.pl', Profiler),
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], sdl_demo_game([])),cosmos_profile_finish)
    ).
