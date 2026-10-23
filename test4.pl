:- style_check(-singleton).
'test4::$impl_update'(A,B,C,D):-(cosmos_get(D,"event",E),cosmos_method(E,"getType",["keydown",F])),(cosmos_get(B,"x",G),cosmos_get(B,"y",H),'test4::walk_keys'(F,G,H,I,J)),new(K),set_(K,"x",I,L),set_(L,"y",J,M),C=M.
'test4::$impl_walk_keys'([],A,B,C,D):-C=A,D=B.
'test4::$impl_walk_keys'([A|B],C,D,E,F):-(cosmos_get(A,"key",G),'test4::nudge'(G,C,D,H,I)),'test4::walk_keys'(B,H,I,E,F).
'test4::$impl_nudge'(A,B,C,D,E):-F=10.0,(A="left",(r_sub(B,F,G),'test4::clamp'(G,0.0,560.0,D)),E=C;dif(A,"left"),(A="right",(add_(B,F,H),'test4::clamp'(H,0.0,560.0,D)),E=C;dif(A,"right"),(A="up",D=B,r_sub(C,F,I),'test4::clamp'(I,0.0,430.0,E);dif(A,"up"),(A="down",D=B,add_(C,F,J),'test4::clamp'(J,0.0,430.0,E);dif(A,"down"),D=B,E=C)))).
'test4::$impl_clamp'(A,B,C,D):-r_lt(A,B),D=B;r_ge(A,B),(r_gt(A,C),D=C;r_le(A,C),D=A).
'test4::$impl_draw'(A,B):-(cosmos_get(B,"graphics",C),D=C),cosmos_method(D,"clear",["#12121c"]),cosmos_method(D,"setColor",["#2b2b45"]),cosmos_method(D,"rectangle",["line",0.0,0.0,640.0,480.0]),cosmos_method(D,"setColor",["#5ee7a0"]),(cosmos_get(A,"x",E),cosmos_get(A,"y",F),cosmos_method(D,"rectangle",["fill",E,F,80.0,50.0])),cosmos_method(D,"setColor",["#c8c8e0"]),(cosmos_method_value(D,"newFont",[16.0,"sans","normal"],G),cosmos_method(D,"setFont",[G])),cosmos_method(D,"print",["Arrow keys move the rectangle",16.0,16.0]).
test4([]):-cosmos_require("space",A),cosmos_method(A,"init",[640.0,480.0]),new(B),set_(B,"update",clos(upvals([A]),'test4::$value_update'),C),set_(C,"draw",clos(upvals([A]),'test4::$value_draw'),D),new(E),set_(E,"x",280.0,F),set_(F,"y",215.0,G),cosmos_method(A,"start",[16.0,D,G]).
'test4::update'(A,B,C,D):-'test4::$impl_update'(A,B,C,D).
'test4::$value_update'(A,B,C,upvals([D])):-'test4::update'(A,B,C,D).
'test4::walk_keys'(A,B,C,D,E):-'test4::$impl_walk_keys'(A,B,C,D,E).
'test4::$value_walk_keys'(A,B,C,D,E,upvals([])):-'test4::walk_keys'(A,B,C,D,E).
'test4::nudge'(A,B,C,D,E):-'test4::$impl_nudge'(A,B,C,D,E).
'test4::$value_nudge'(A,B,C,D,E,upvals([])):-'test4::nudge'(A,B,C,D,E).
'test4::clamp'(A,B,C,D):-'test4::$impl_clamp'(A,B,C,D).
'test4::$value_clamp'(A,B,C,D,upvals([])):-'test4::clamp'(A,B,C,D).
'test4::draw'(A,B):-'test4::$impl_draw'(A,B).
'test4::$value_draw'(A,upvals([B])):-'test4::draw'(A,B).
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
      directory_file_path(Root, 'libs/space_xpce_prolog.pl', Backend), ensure_loaded(Backend),
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
      setup_call_cleanup(true,(Arguments = [Executable|RawArguments], test4([])),cosmos_profile_finish)
    ).
