:- style_check(-singleton).
'xpce_events::$impl_on_keydown'(A):-cosmos_get(A,"key",B),cosmos_get(A,"char",C),cosmos_get(A,"mod",D),print(["CALLBACK keydown key=",B," char=",C," mod=",D]).
'xpce_events::$impl_on_mousedown'(A):-cosmos_get(A,"posx",B),cosmos_get(A,"posy",C),cosmos_get(A,"button",D),print(["CALLBACK mousedown x=",B," y=",C," button=",D]).
'xpce_events::$impl_show_one'(A,B,C):-(cosmos_get(B,"type",D),cosmos_get(B,"posx",E),cosmos_get(B,"posy",F),cosmos_get(B,"button",G),cosmos_get(B,"clicks",H),cosmos_get(B,"key",I),cosmos_get(B,"char",J),cosmos_get(B,"mod",K),print(["POLL #",A," ",D," x=",E," y=",F," button=",G," clicks=",H," key=",I," char=",J," mod=",K])),C=0.0.
'xpce_events::$impl_handle'(A,B):-(cosmos_receiver("list",B),cosmos_method(B,"each",[A,clos(upvals([]),'xpce_events::$value_show_one'),C])),(cosmos_receiver("list",B),cosmos_method(B,"size",[A,D])),(r_gt(D,0.0),print(["POLL drained ",D," event(s) this frame"]);r_le(D,0.0),true).
'xpce_events::$impl_draw'(A,B,C):-(cosmos_get(C,"graphics",D),cosmos_method(D,"clear",["#101820"])),(cosmos_get(C,"graphics",E),cosmos_method(E,"setColor",["#7ec8ff"])),(cosmos_get(C,"graphics",F),cosmos_method(F,"rectangle",["fill",20.0,20.0,340.0,28.0])),(cosmos_get(C,"graphics",G),cosmos_method(G,"setColor",["#ffffff"])),(cosmos_get(C,"graphics",H),cosmos_method(H,"print",["click in the window, or press a key",30.0,38.0])),(cosmos_get(C,"graphics",I),cosmos_method(I,"setColor",["#ffd166"])),(cosmos_get(C,"input",J),cosmos_method(J,"getPosition",[K])),(cosmos_get(K,"x",L),add_("mouse x=",L,M),add_(M," y=",N),cosmos_get(K,"y",O),add_(N,O,P),cosmos_get(C,"graphics",Q),cosmos_method(Q,"print",[P,20.0,58.0])),(cosmos_get(C,"event",R),cosmos_method(R,"get",[S])),(cosmos_receiver("list",B),cosmos_method(B,"size",[S,T])),(add_("queue holds ",T,U),add_(U," event(s) since the last get()",V),cosmos_get(C,"graphics",W),cosmos_method(W,"print",[V,20.0,74.0])),((cosmos_get(C,"input",X),cosmos_method(X,"buttonDown",[1.0])),cosmos_get(C,"graphics",Y),cosmos_method(Y,"print",["LEFT BUTTON HELD",20.0,86.0]);\+ (cosmos_get(C,"input",Z),cosmos_method(Z,"buttonDown",[1.0])),true).
'xpce_events::$impl_update'(A,B,C,D,E,F,G):-(cosmos_receiver("mutable",F),cosmos_method(F,"get",[D,"value",H])),(add_(H,1.0,I),cosmos_receiver("mutable",F),cosmos_method(F,"set",[D,"value",I])),(cosmos_get(G,"event",J),cosmos_method(J,"get",[K])),(cosmos_receiver("list",E),cosmos_method(E,"size",[K,L])),(r_gt(L,0.0),'xpce_events::handle'(K,E);r_le(L,0.0),true),((r_mod(H,30.0,M),M=0.0),print(["frame ",H," events ",L]);(r_mod(H,30.0,N),dif(N,0.0)),true),(r_gt(H,400.0),print(["STOPPING after ",H," frames"]),cosmos_method(G,"quit",[]);r_le(H,400.0),true),C=B.
xpce_events([]):-cosmos_require("space",A),cosmos_require("list",B),cosmos_require("mutable",C),((cosmos_receiver("mutable",C),cosmos_method_value(C,"new",[],D)),E=D),(cosmos_receiver("mutable",C),cosmos_method(C,"set",[E,"value",0.0])),cosmos_method(A,"init",[460.0,320.0]),(new(F),set_(F,"size",13.0,G),set_(G,"family","sans",H),set_(H,"style","normal",I),cosmos_get(A,"graphics",J),cosmos_method(J,"setFont",[I])),new(K),set_(K,"update",clos(upvals([E,B,C,A]),'xpce_events::$value_update'),L),set_(L,"draw",clos(upvals([B,A]),'xpce_events::$value_draw'),M),new(N),set_(N,"keydown",clos(upvals([]),'xpce_events::$value_on_keydown'),O),set_(O,"mousedown",clos(upvals([]),'xpce_events::$value_on_mousedown'),P),set_(M,"on",P,Q),cosmos_method(A,"start",[33.0,Q,R]).
'xpce_events::on_keydown'(A):-'xpce_events::$impl_on_keydown'(A).
'xpce_events::$value_on_keydown'(A,upvals([])):-'xpce_events::on_keydown'(A).
'xpce_events::on_mousedown'(A):-'xpce_events::$impl_on_mousedown'(A).
'xpce_events::$value_on_mousedown'(A,upvals([])):-'xpce_events::on_mousedown'(A).
'xpce_events::show_one'(A,B,C):-'xpce_events::$impl_show_one'(A,B,C).
'xpce_events::$value_show_one'(A,B,C,upvals([])):-'xpce_events::show_one'(A,B,C).
'xpce_events::handle'(A,B):-'xpce_events::$impl_handle'(A,B).
'xpce_events::$value_handle'(A,upvals([B])):-'xpce_events::handle'(A,B).
'xpce_events::draw'(A,B,C):-'xpce_events::$impl_draw'(A,B,C).
'xpce_events::$value_draw'(A,upvals([B,C])):-'xpce_events::draw'(A,B,C).
'xpce_events::update'(A,B,C,D,E,F,G):-'xpce_events::$impl_update'(A,B,C,D,E,F,G).
'xpce_events::$value_update'(A,B,C,upvals([D,E,F,G])):-'xpce_events::update'(A,B,C,D,E,F,G).
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
      directory_file_path(Root, ?, SourceTemplate),
      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),
      nb_setval(path,Path),
      Arguments = [Executable|RawArguments], xpce_events([])
    ).
