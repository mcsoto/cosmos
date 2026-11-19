:- style_check(-singleton).
protoship([]):-cosmos_require("table",A),cosmos_require("object",B),(cosmos_receiver("table",A),cosmos_get(A,"update",C),D=C),(new(E),set_(E,"x",1.0,F),set_(F,"y",1.0,G),set_(G,"move",clos(upvals([]),'protoship::$closure_0.0'),H),I=H),J=I,(cosmos_receiver("math",K),cosmos_method_value(K,"range",[1.0,4.0],L)),cosmos_for(L,clos(upvals([I]),'protoship::$closure_1.0'),[J],[M]).
'protoship::$closure_0.0'(A,B,C,D,upvals([])):-new(E),set_(E,"x",B,F),set_(F,"y",C,G),add_(A,G,H),D=H.
'protoship::$closure_1.0'(A,B,[C],D,upvals([E])):-((cosmos_get(C,"x",F),print(F)),((cosmos_get(C,"x",G),add_(G,1.0,H),cosmos_method_value(E,"move",[C,H,1.0],I),J=I),K=J),print(C)),D=[J],K=J.
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], protoship([])),cosmos_profile_finish)
    ).
