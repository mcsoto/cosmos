:- style_check(-singleton).
'notepad::$impl_do_save'(A,B,C,D):-(cosmos_method(D,"get_data",["buffer",C]),cosmos_method(D,"get",[C,"contents",E])),(cosmos_receiver("io",B),cosmos_method(B,"writeToFile",["notepad.txt",E])),print("saved notepad.txt").
'notepad::$impl_do_load'(A,B,C,D):-(cosmos_receiver("io",B),cosmos_method(B,"readFile",["notepad.txt",E])),cosmos_method(D,"get_data",["buffer",C]),cosmos_method(D,"send",[C,"contents",[E]]),print("loaded notepad.txt").
'notepad::$impl_do_quit'(A,B):-print("quit selected"),cosmos_method(B,"quit",[]).
notepad([]):-cosmos_require("xpce",A),cosmos_require("io",B),cosmos_method(A,"create",["frame",["Cosmos Notepad"],C]),cosmos_method(A,"size",[660.0,480.0,D]),cosmos_method(A,"send",[C,"size",[D]]),cosmos_method(A,"create",["dialog",[],E]),cosmos_method(A,"send",[C,"append",[E]]),cosmos_method(A,"create",["menu_bar",[],F]),cosmos_method(A,"send",[E,"append",[F]]),cosmos_method(A,"create",["popup",["File"],G]),cosmos_method(A,"send",[F,"append",[G]]),cosmos_method(A,"create",["menu_item",["Save"],H]),cosmos_method(A,"on_select",[H,clos(upvals([B,I,A]),'notepad::$value_do_save')]),cosmos_method(A,"send",[G,"append",[H]]),cosmos_method(A,"create",["menu_item",["Load"],J]),cosmos_method(A,"on_select",[J,clos(upvals([B,I,A]),'notepad::$value_do_load')]),cosmos_method(A,"send",[G,"append",[J]]),cosmos_method(A,"create",["menu_item",["Quit"],K]),cosmos_method(A,"on_select",[K,clos(upvals([A]),'notepad::$value_do_quit')]),cosmos_method(A,"send",[G,"append",[K]]),cosmos_method(A,"create",["view",[],L]),cosmos_method(A,"send",[C,"append",[L]]),cosmos_method(A,"send",[L,"below",[E]]),cosmos_method(A,"send",[C,"open",[]]),cosmos_method(A,"get",[L,"editor",M]),cosmos_method(A,"get",[M,"text_buffer",I]),cosmos_method(A,"send",[I,"contents",["Welcome to Cosmos Notepad.\nType here, then File > Save.\n"]]),cosmos_method(A,"set_data",["buffer",I]),cosmos_method(A,"loop",[]).
'notepad::do_save'(A,B,C,D):-'notepad::$impl_do_save'(A,B,C,D).
'notepad::$value_do_save'(A,upvals([B,C,D])):-'notepad::do_save'(A,B,C,D).
'notepad::do_load'(A,B,C,D):-'notepad::$impl_do_load'(A,B,C,D).
'notepad::$value_do_load'(A,upvals([B,C,D])):-'notepad::do_load'(A,B,C,D).
'notepad::do_quit'(A,B):-'notepad::$impl_do_quit'(A,B).
'notepad::$value_do_quit'(A,upvals([B])):-'notepad::do_quit'(A,B).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], notepad([])),cosmos_profile_finish)
    ).
