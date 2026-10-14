:- style_check(-singleton).
'xpce-example::$impl_tick'(A,B,C,D):-cosmos_require("xpce",D),cosmos_method(D,"get_data",["ticks",E]),(add_(E,1.0,F),cosmos_method(D,"set_data",["ticks",F])),cosmos_method(D,"get_data",["phase",G]),cosmos_method(D,"get_data",["gauge",B]),(G=0.0,cosmos_method(D,"get_data",["orange",H]),cosmos_method(D,"set_data",["phase",1.0]);dif(G,0.0),cosmos_method(D,"get_data",["blue",H]),cosmos_method(D,"set_data",["phase",0.0])),cosmos_method(D,"send",[B,"fill_pattern",[H]]),((r_mod(E,25.0,I),I=0.0),print(["tick ",E]);(r_mod(E,25.0,J),dif(J,0.0)),true).
'xpce-example::$impl_do_greet'(A,B,C):-cosmos_require("xpce",C),cosmos_method(C,"get_data",["namefield",D]),cosmos_method(C,"get",[D,"selection",E]),print(["hello, ",E]).
'xpce-example::$impl_do_quit'(A,B,C):-cosmos_require("xpce",C),print("quit clicked"),cosmos_method(C,"quit",[]).
'xpce-example::$impl_auto_quit'(A,B,C):-cosmos_require("xpce",C),print("auto-quit"),cosmos_method(C,"quit",[]).
'xpce-example'([]):-cosmos_require("xpce",A),cosmos_method(A,"create",["dialog",["Cosmos XPCE"],B]),cosmos_method(A,"create",["text",["Pure XPCE, driven from Cosmos"],C]),cosmos_method(A,"send",[B,"append",[C]]),cosmos_method(A,"create",["box",[120.0,50.0],D]),cosmos_method(A,"color",["#3050ff",E]),cosmos_method(A,"color",["#ff5533",F]),cosmos_method(A,"send",[D,"fill_pattern",[E]]),cosmos_method(A,"send",[B,"append",[D]]),cosmos_method(A,"set_data",["gauge",D]),cosmos_method(A,"set_data",["blue",E]),cosmos_method(A,"set_data",["orange",F]),cosmos_method(A,"set_data",["phase",0.0]),cosmos_method(A,"set_data",["ticks",0.0]),cosmos_method(A,"create",["text",["name:"],G]),cosmos_method(A,"send",[B,"append",[G]]),cosmos_method(A,"create",["text_item",["name","Ada"],H]),cosmos_method(A,"send",[B,"append",[H]]),cosmos_method(A,"set_data",["namefield",H]),cosmos_method(A,"create",["button",["Greet"],I]),cosmos_method(A,"on_click",[I,clos(upvals([J,A]),'xpce-example::$value_do_greet')]),cosmos_method(A,"send",[B,"append",[I]]),cosmos_method(A,"create",["button",["Quit"],K]),cosmos_method(A,"on_click",[K,clos(upvals([J,A]),'xpce-example::$value_do_quit')]),cosmos_method(A,"send",[B,"append",[K]]),cosmos_method(A,"send",[B,"open",[]]),cosmos_method(A,"timer",[0.2,clos(upvals([D,J,A]),'xpce-example::$value_tick'),L]),cosmos_method(A,"timer",[25.0,clos(upvals([J,A]),'xpce-example::$value_auto_quit'),M]),cosmos_method(A,"loop",[]).
'xpce-example::tick'(A,B,C,D):-'xpce-example::$impl_tick'(A,B,C,D).
'xpce-example::$value_tick'(A,upvals([B,C,D])):-'xpce-example::tick'(A,B,C,D).
'xpce-example::do_greet'(A,B,C):-'xpce-example::$impl_do_greet'(A,B,C).
'xpce-example::$value_do_greet'(A,upvals([B,C])):-'xpce-example::do_greet'(A,B,C).
'xpce-example::do_quit'(A,B,C):-'xpce-example::$impl_do_quit'(A,B,C).
'xpce-example::$value_do_quit'(A,upvals([B,C])):-'xpce-example::do_quit'(A,B,C).
'xpce-example::auto_quit'(A,B,C):-'xpce-example::$impl_auto_quit'(A,B,C).
'xpce-example::$value_auto_quit'(A,upvals([B,C])):-'xpce-example::auto_quit'(A,B,C).
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
      directory_file_path(Root, ?, SourceTemplate),
      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),
      nb_setval(path,Path),
      Arguments = [Executable|RawArguments], 'xpce-example'([])
    ).
