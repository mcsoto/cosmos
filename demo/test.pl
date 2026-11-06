:- style_check(-singleton).
'test::$impl_draw'(A,B,C,D):-(cosmos_get(C,"graphics",E),cosmos_method(E,"setColor",["#07111f"])),(cosmos_get(C,"graphics",F),cosmos_method(F,"rectangle",["fill",0.0,0.0,D,B])),(cosmos_get(C,"graphics",G),cosmos_method(G,"setColor",["#7cf4cb"])),cosmos_get(A,"x",H),r_sub(H,28.0,I),cosmos_get(A,"y",J),r_sub(J,28.0,K),cosmos_get(C,"graphics",L),cosmos_method(L,"rectangle",["fill",I,K,56.0,56.0]).
'test::$impl_mouseup'(A,B,C,D):-new(E),set_(E,"x",A,F),set_(F,"y",B,G),cosmos_get(C,"dx",H),set_(G,"dx",H,I),cosmos_get(C,"hue",J),set_(I,"hue",J,K),D=K.
'test::$impl_apply_events'(A,B,C):-if_(A=[],C=B,(A=[D|E],(cosmos_get(D,"type",F),G=F),if_(G="mouseup",(cosmos_get(D,"x",H),cosmos_get(D,"y",I),'test::mouseup'(H,I,B,J)),J=B),'test::apply_events'(E,J,C))).
'test::$impl_update'(A,B,C):-(cosmos_get(C,"event",D),cosmos_method(D,"get",[E])),'test::apply_events'(E,A,B).
test([]):-cosmos_require("space",A),(B=800.0,C=600.0),D=16.0,(new(E),set_(E,"x",320.0,F),set_(F,"y",180.0,G),set_(G,"dx",2.0,H),set_(H,"hue",0.0,I),J=I),cosmos_method(A,"init",[B,C]),new(K),set_(K,"update",clos(upvals([A]),'test::$value_update'),L),set_(L,"draw",clos(upvals([C,A,B]),'test::$value_draw'),M),cosmos_method(A,"start",[D,M,J]).
'test::draw'(A,B,C,D):-'test::$impl_draw'(A,B,C,D).
'test::$value_draw'(A,upvals([B,C,D])):-'test::draw'(A,B,C,D).
'test::mouseup'(A,B,C,D):-'test::$impl_mouseup'(A,B,C,D).
'test::$value_mouseup'(A,B,C,D,upvals([])):-'test::mouseup'(A,B,C,D).
'test::apply_events'(A,B,C):-'test::$impl_apply_events'(A,B,C).
'test::$value_apply_events'(A,B,C,upvals([])):-'test::apply_events'(A,B,C).
'test::update'(A,B,C):-'test::$impl_update'(A,B,C).
'test::$value_update'(A,B,upvals([C])):-'test::update'(A,B,C).
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
