:- style_check(-singleton).
'space_welcome::$impl_mouseup'(A,B,C,D):-new(E),set_(E,"x",A,F),set_(F,"y",B,G),cosmos_get(C,"dx",H),set_(G,"dx",H,I),cosmos_get(C,"hue",J),set_(I,"hue",J,K),D=K.
'space_welcome::$impl_apply_events'(A,B,C):-if_(A=[],C=B,(A=[D|E],(cosmos_get(D,"type",F),G=F),if_(G="mouseup",(cosmos_get(D,"x",H),cosmos_get(D,"y",I),'space_welcome::mouseup'(H,I,B,J)),J=B),'space_welcome::apply_events'(E,J,C))).
'space_welcome::$impl_update'(A,B,C,D):-(new(E),cosmos_get(A,"x",F),cosmos_get(A,"dx",G),add_(F,G,H),r_mod(H,D,I),set_(E,"x",I,J),cosmos_get(A,"y",K),set_(J,"y",K,L),cosmos_get(A,"dx",M),set_(L,"dx",M,N),cosmos_get(A,"hue",O),add_(O,1.0,P),set_(N,"hue",P,Q),R=Q),(cosmos_get(C,"event",S),cosmos_method(S,"get",[T])),'space_welcome::apply_events'(T,R,B).
'space_welcome::$impl_draw'(A,B):-(cosmos_get(B,"graphics",C),cosmos_method(C,"clear",["#07111f"])),(cosmos_get(B,"graphics",D),cosmos_method(D,"setColor",["#7cf4cb"])),cosmos_get(A,"x",E),r_sub(E,28.0,F),cosmos_get(A,"y",G),r_sub(G,28.0,H),cosmos_get(B,"graphics",I),cosmos_method(I,"rectangle",["fill",F,H,56.0,56.0]).
space_welcome([]):-cosmos_require("space",A),B=640.0,C=360.0,D=16.0,(new(E),set_(E,"x",320.0,F),set_(F,"y",180.0,G),set_(G,"dx",2.0,H),set_(H,"hue",0.0,I),J=I),cosmos_method(A,"init",[B,C]),new(K),set_(K,"update",clos(upvals([A,B]),'space_welcome::$value_update'),L),set_(L,"draw",clos(upvals([A]),'space_welcome::$value_draw'),M),cosmos_method(A,"start",[16.0,M,J]).
'space_welcome::mouseup'(A,B,C,D):-'space_welcome::$impl_mouseup'(A,B,C,D).
'space_welcome::$value_mouseup'(A,B,C,D,upvals([])):-'space_welcome::mouseup'(A,B,C,D).
'space_welcome::apply_events'(A,B,C):-'space_welcome::$impl_apply_events'(A,B,C).
'space_welcome::$value_apply_events'(A,B,C,upvals([])):-'space_welcome::apply_events'(A,B,C).
'space_welcome::update'(A,B,C,D):-'space_welcome::$impl_update'(A,B,C,D).
'space_welcome::$value_update'(A,B,upvals([C,D])):-'space_welcome::update'(A,B,C,D).
'space_welcome::draw'(A,B):-'space_welcome::$impl_draw'(A,B).
'space_welcome::$value_draw'(A,upvals([B])):-'space_welcome::draw'(A,B).
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], space_welcome([])),cosmos_profile_finish)
    ).
