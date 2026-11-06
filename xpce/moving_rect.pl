:- style_check(-singleton).
'moving_rect::$impl_update'(A,B,C,D):-(new(E),cosmos_get(B,"x",F),add_(F,2.0,G),r_mod(G,520.0,H),set_(E,"x",H,I),C=I),((cosmos_get(D,"event",J),cosmos_method_value(J,"get",[],K)),L=K),((cosmos_get(D,"keyboard",M),cosmos_method(M,"isDown",["left"])),print(N);\+ (cosmos_get(D,"keyboard",O),cosmos_method(O,"isDown",["left"])),print("-")).
'moving_rect::$impl_draw'(A,B):-(cosmos_get(B,"graphics",C),D=C),cosmos_method(D,"clear",["#1b1b2f"]),cosmos_method(D,"setColor",["#3050ff"]),cosmos_get(A,"x",E),cosmos_method(D,"rectangle",["fill",E,100.0,80.0,50.0]).
moving_rect([]):-cosmos_require("space",A),cosmos_method(A,"init",[640.0,480.0]),new(B),set_(B,"update",clos(upvals([A]),'moving_rect::$value_update'),C),set_(C,"draw",clos(upvals([A]),'moving_rect::$value_draw'),D),new(E),set_(E,"x",100.0,F),cosmos_method(A,"start",[16.0,D,F]).
'moving_rect::update'(A,B,C,D):-'moving_rect::$impl_update'(A,B,C,D).
'moving_rect::$value_update'(A,B,C,upvals([D])):-'moving_rect::update'(A,B,C,D).
'moving_rect::draw'(A,B):-'moving_rect::$impl_draw'(A,B).
'moving_rect::$value_draw'(A,upvals([B])):-'moving_rect::draw'(A,B).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], moving_rect([])),cosmos_profile_finish)
    ).
