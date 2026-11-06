:- style_check(-singleton).
'square::$impl_update'(A,B):-B=A.
'square::$impl_draw'(A,B):-(cosmos_get(A,"color",C),cosmos_get(B,"graphics",D),cosmos_method(D,"setColor",[C])),cosmos_get(A,"x",E),cosmos_get(A,"y",F),cosmos_get(A,"width",G),cosmos_get(A,"height",H),cosmos_get(B,"graphics",I),cosmos_method(I,"rectangle",["fill",E,F,G,H]).
square([]):-cosmos_require("space",A),cosmos_method(A,"init",[480.0,280.0]),(new(B),set_(B,"x",175.0,C),set_(C,"y",75.0,D),set_(D,"width",130.0,E),set_(E,"height",130.0,F),set_(F,"color","#64d7b0",G),set_(G,"step",0.0,H),I=H),(new(J),set_(J,"update",clos(upvals([]),'square::$value_update'),K),set_(K,"draw",clos(upvals([A]),'square::$value_draw'),L),M=L),cosmos_method(A,"start",[16.0,M,I]).
'square::update'(A,B):-'square::$impl_update'(A,B).
'square::$value_update'(A,B,upvals([])):-'square::update'(A,B).
'square::draw'(A,B):-'square::$impl_draw'(A,B).
'square::$value_draw'(A,upvals([B])):-'square::draw'(A,B).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], square([])),cosmos_profile_finish)
    ).
