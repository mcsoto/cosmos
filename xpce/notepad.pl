:- style_check(-singleton).
'notepad::$impl_do_save'(A,B,C,D,E):-cosmos_require("xpce",E),cosmos_require("io",B),cosmos_method(E,"get_data",["buffer",D]),cosmos_method(E,"get",[D,"contents",F]),(cosmos_receiver("io",B),cosmos_method(B,"writeToFile",["notepad.txt",F])),print("saved notepad.txt").
'notepad::$impl_do_load'(A,B,C,D,E):-cosmos_require("xpce",E),cosmos_require("io",B),(cosmos_receiver("io",B),cosmos_method(B,"readFile",["notepad.txt",F])),cosmos_method(E,"get_data",["buffer",D]),cosmos_method(E,"send",[D,"contents",[F]]),print("loaded notepad.txt").
'notepad::$impl_do_quit'(A,B,C):-cosmos_require("xpce",C),print("quit selected"),cosmos_method(C,"quit",[]).
notepad([]):-cosmos_require("xpce",A),cosmos_require("io",B),cosmos_method(A,"create",["frame",["Cosmos Notepad"],C]),cosmos_method(A,"size",[660.0,480.0,D]),cosmos_method(A,"send",[C,"size",[D]]),cosmos_method(A,"create",["dialog",[],E]),cosmos_method(A,"send",[C,"append",[E]]),cosmos_method(A,"create",["menu_bar",[],F]),cosmos_method(A,"send",[E,"append",[F]]),cosmos_method(A,"create",["popup",["File"],G]),cosmos_method(A,"send",[F,"append",[G]]),cosmos_method(A,"create",["menu_item",["Save"],H]),cosmos_method(A,"on_select",[H,clos(upvals([B,I,J,A]),'notepad::$value_do_save')]),cosmos_method(A,"send",[G,"append",[H]]),cosmos_method(A,"create",["menu_item",["Load"],K]),cosmos_method(A,"on_select",[K,clos(upvals([B,I,J,A]),'notepad::$value_do_load')]),cosmos_method(A,"send",[G,"append",[K]]),cosmos_method(A,"create",["menu_item",["Quit"],L]),cosmos_method(A,"on_select",[L,clos(upvals([I,A]),'notepad::$value_do_quit')]),cosmos_method(A,"send",[G,"append",[L]]),cosmos_method(A,"create",["view",[],M]),cosmos_method(A,"send",[C,"append",[M]]),cosmos_method(A,"send",[M,"below",[E]]),cosmos_method(A,"send",[C,"open",[]]),cosmos_method(A,"get",[M,"editor",N]),cosmos_method(A,"get",[N,"text_buffer",J]),cosmos_method(A,"send",[J,"contents",["Welcome to Cosmos Notepad.\nType here, then File > Save.\n"]]),cosmos_method(A,"set_data",["buffer",J]),cosmos_method(A,"loop",[]).
'notepad::do_save'(A,B,C,D,E):-'notepad::$impl_do_save'(A,B,C,D,E).
'notepad::$value_do_save'(A,upvals([B,C,D,E])):-'notepad::do_save'(A,B,C,D,E).
'notepad::do_load'(A,B,C,D,E):-'notepad::$impl_do_load'(A,B,C,D,E).
'notepad::$value_do_load'(A,upvals([B,C,D,E])):-'notepad::do_load'(A,B,C,D,E).
'notepad::do_quit'(A,B,C):-'notepad::$impl_do_quit'(A,B,C).
'notepad::$value_do_quit'(A,upvals([B,C])):-'notepad::do_quit'(A,B,C).
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
      directory_file_path(Root, ?, SourceTemplate),
      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),
      nb_setval(path,Path),
      Arguments = [Executable|RawArguments], notepad([])
    ).
