% File/platform adapter for the compiler whose implementation lives in .co.
:- use_module(library(filesex)).
:- dynamic compiler_platform_runtime_loaded/0.

compiler_platform(Here) :- source_file(compiler_platform(_),File),file_directory_name(File,Here).
compiler_file_module(Path,Module) :-
    absolute_file_name(Path,Absolute),file_base_name(Absolute,Base),file_name_extension(Module,_,Base).
compiler_load(Stage) :-
    compiler_load_runtime,
    compiler_platform(Here),
    directory_file_path(Stage,'?',Template),
    directory_file_path(Here,'../../libs/?',Libraries),
    directory_file_path(Here,'../../userlibs/?',UserLibraries),
    atomic_list_concat([Template,Libraries,UserLibraries],';',Path),nb_setval(path,Path),
    crequire("compiler",_,_).
compiler_load_runtime :- compiler_platform_runtime_loaded, !.
compiler_load_runtime :-
    compiler_platform(Here),
    directory_file_path(Here,'../swi.pl',Runtime),consult(Runtime),
    directory_file_path(Here,'terms.pl',Terms),consult(Terms),
    directory_file_path(Here,'runtime.pl',Operations),consult(Operations),
    directory_file_path(Here,'codec.pl',Codec),consult(Codec),
    assertz(compiler_platform_runtime_loaded).
compiler_compile(Source,Module,Code) :-
    compiler(Api),get_(Api,"compile",Compile),
    (once(call_cl(Compile,[Source,Module,Code])) -> true
    ; throw(error(compilation_failed,_))).
compiler_compile_file(Stage,Input,Output,Module) :-
    compiler_load(Stage),read_file_to_string(Input,Source,[]),
    system:atom_string(Module,Name),
    compiler(Api),
    (get_assoc("compile_unit",Api,CompileUnit)->
        get_assoc("imports",Api,Imports),once(call_cl(Imports,[Source,Names])),
        absolute_file_name(Input,Absolute),file_directory_name(Absolute,Directory),
        compiler_read_interfaces(Names,Directory,Pairs),list_to_assoc(Pairs,Interfaces),
        (once(call_cl(CompileUnit,[Source,Name,Interfaces,Unit]))->true;throw(error(compilation_failed,_))),
        get_assoc("prolog",Unit,Code),get_assoc("interface",Unit,Interface)
    ;compiler_compile(Source,Name,Code),Interface=none),
    setup_call_cleanup(open(Output,write,Stream,[encoding(utf8),newline(posix)]),
                       write(Stream,Code),close(Stream)),
    (Interface==none->true;
        file_name_extension(Base,_,Output),file_name_extension(Base,cif,InterfaceFile),
        setup_call_cleanup(open(InterfaceFile,write,Stream2,[encoding(utf8),newline(posix)]),
            write_term(Stream2,Interface,[quoted(true),fullstop(true),nl(true)]),close(Stream2))).

% Command-line launch support is deliberately appended after ordinary code
% generation.  It does not inspect application source: every program with a
% relation named main/1 receives the same argv-list adapter.
compiler_add_main_entry(Output, Module) :-
    atom_concat(Module, '::main', Predicate),
    compiler_platform(PlatformDirectory0),
    absolute_file_name(PlatformDirectory0, PlatformDirectory),
    absolute_file_name(Output, AbsoluteOutput),
    file_directory_name(AbsoluteOutput, SourceDir),
    directory_file_path(PlatformDirectory, '../../libs', AbsLibsDir0),
    absolute_file_name(AbsLibsDir0, AbsLibsDir),
    directory_file_path(PlatformDirectory, '../../userlibs', AbsUserLibsDir0),
    absolute_file_name(AbsUserLibsDir0, AbsUserLibsDir),
    % Space/XPCE programs need the raw backend .pl at runtime (loading PCE
    % at build time poisons the saved image, so it is never embedded).
    directory_file_path(PlatformDirectory, '../../libs/space_xpce_prolog.pl', AbsBackend0),
    absolute_file_name(AbsBackend0, AbsBackend),
    ( read_file_to_string(Output, OutputCode, []),
      sub_string(OutputCode, _, _, _, "cosmos_require(\"space") ->
        SpaceBackend = AbsBackend
    ; SpaceBackend = none
    ),
    % Record everything RELATIVE to the output file, not as absolute paths.
    % The build machine's directory layout has no business being baked into
    % a generated artifact: it makes the .pl machine-specific, and it goes
    % stale as soon as the tree is moved or checked out elsewhere.  The exe
    % always lands beside the .pl, so one set of relative paths serves both
    % `swipl -s prog.pl` and `prog.exe`; the entry resolves them against
    % cosmos_entry_root/1 at runtime.
    cosmos_relative_to(SourceDir, AbsLibsDir, RelLibsDir),
    cosmos_relative_to(SourceDir, AbsUserLibsDir, RelUserLibsDir),
    % swi.pl sits one level ABOVE platform/, runtime.pl inside it.
    directory_file_path(PlatformDirectory, '../swi.pl', AbsRuntime0),
    absolute_file_name(AbsRuntime0, AbsRuntime),
    directory_file_path(PlatformDirectory, 'runtime.pl', AbsOperations0),
    absolute_file_name(AbsOperations0, AbsOperations),
    cosmos_relative_to(SourceDir, AbsRuntime, RelRuntime),
    cosmos_relative_to(SourceDir, AbsOperations, RelOperations),
    directory_file_path(RelLibsDir, '?', RelLibsTemplate),
    directory_file_path(RelUserLibsDir, '?', RelUserLibsTemplate),
    ( SpaceBackend == none -> true
    ; cosmos_relative_to(SourceDir, SpaceBackend, RelBackend)
    ),
    setup_call_cleanup(
        open(Output, append, Stream, [encoding(utf8), newline(posix)]),
        ( format(Stream, ':- initialization(cosmos_entry_main, main).~n', []),
          format(Stream, 'cosmos_entry_root(Root) :-~n', []),
          format(Stream, '    % The .pl is the anchor while running as source; in a saved~n', []),
          format(Stream, '    % image there is no .pl to point at, and the exe sits where~n', []),
          format(Stream, '    % the .pl was, so the executable directory is the fallback.~n', []),
          format(Stream, '    (   source_file(cosmos_entry_main, File), file_directory_name(File, Root)~n', []),
          format(Stream, '    ->  true~n', []),
          format(Stream, '    ;   current_prolog_flag(executable, Executable),~n', []),
          format(Stream, '        file_directory_name(Executable, Root)~n', []),
          format(Stream, '    ).~n', []),
          format(Stream, 'cosmos_entry_main :-~n', []),
          format(Stream, '    ( nb_current(cosmos_building_exe, true) -> true~n', []),
          format(Stream, '    ; nb_current(cosmos_entry_ran, true) -> true~n', []),
          format(Stream, '    ; nb_setval(cosmos_entry_ran, true),~n', []),
          format(Stream, '      abolish_all_tables,~n', []),
          format(Stream, '      current_prolog_flag(executable, Executable), current_prolog_flag(argv, RawArguments),~n', []),
          format(Stream, '      % Preserve the conventional argv[0] slot. Cosmos lists use~n', []),
          format(Stream, '      % zero-based indexing, so main(args) can use args[1] for the first~n', []),
          format(Stream, '      % user-supplied argument, as command-line programs normally do.~n', []),
          format(Stream, '      cosmos_entry_root(Root),~n', []),
          format(Stream, '      directory_file_path(Root, ~q, LibsRel),~n', [RelLibsDir]),
          format(Stream, '      directory_file_path(Root, ~q, UserLibsRel),~n', [RelUserLibsDir]),
          format(Stream, '      directory_file_path(Root, ~q, Runtime),~n', [RelRuntime]),
          format(Stream, '      directory_file_path(Root, ~q, Operations),~n', [RelOperations]),
          format(Stream, '      directory_file_path(Root, ~q, LibsTemplate),~n', [RelLibsTemplate]),
          format(Stream, '      directory_file_path(Root, ~q, UserLibsTemplate),~n', [RelUserLibsTemplate]),
          format(Stream, '      assertz(file_search_path(libs, LibsRel)),~n', []),
          format(Stream, '      assertz(file_search_path(userlibs, UserLibsRel)),~n', []),
          format(Stream, '      % swi.pl defines cosmos_get/3.  A saved image already has~n', []),
          format(Stream, '      % it, so only a source run needs the runtime loaded.~n', []),
          format(Stream, '      ( current_predicate(cosmos_get/3) -> true~n', []),
          format(Stream, '      ; ensure_loaded(Runtime), ensure_loaded(Operations)~n', []),
          format(Stream, '      ),~n', []),
          ( SpaceBackend == none -> true
          ; format(Stream, '      directory_file_path(Root, ~q, Backend), ensure_loaded(Backend),~n', [RelBackend])
          ),
          format(Stream, '      directory_file_path(Root, ~q, SourceTemplate),~n', ['?']),
          format(Stream, '      atomic_list_concat([SourceTemplate,LibsTemplate,UserLibsTemplate,?],;,Path),~n', []),
          format(Stream, '      nb_setval(path,Path),~n', []),
          format(Stream, '      Arguments = [Executable|RawArguments], ~q(Arguments)~n', [Predicate]),
          format(Stream, '    ).~n', [])
        ),
        close(Stream)).

compiler_executable_file(Output, Executable) :-
    file_name_extension(Base, _, Output),
    file_name_extension(Base, exe, Executable).

% Path of AbsFile relative to FromDir, both absolute.
% relative_file_name/3 does not do this: its relative_to option expects a
% character-code alias, and it raises type_error(character_code,...) when
% handed a directory.  So split on the separator, drop the common prefix,
% and the answer is (one ".." per leftover FromDir part) ++ (the leftover
% ToDir parts).  Paths stay inside the output's own directory tree, so no
% absolute path is ever written into a generated artifact.
cosmos_relative_to(FromDir, AbsFile, Relative) :-
    file_directory_name(AbsFile, ToDir),
    file_base_name(AbsFile, Base),
    split_string(FromDir, "/", "", From),
    split_string(ToDir, "/", "", To),
    cosmos_common_prefix(From, To, Common),
    length(From, FromLength),
    length(Common, CommonLength),
    % One ".." per component of FromDir past the common prefix, then the part
    % of ToDir past it, then the file name itself.  misc/ -> libs gives
    % [.., libs] -> "../libs"; the same directory gives just "libs".
    % Order matters: Base goes last, or libs/space_xpce_prolog.pl comes out
    % as ../space_xpce_prolog.pl/libs.
    Up is FromLength - CommonLength,
    findall('..', between(1, Up, _), Ups),
    cosmos_suffix(To, CommonLength, Tail),
    append(Ups, Tail, Steps),
    append(Steps, [Base], Parts),
    atomic_list_concat(Parts, '/', Relative).

% Clause order matters here.  The heads-match case has to come first: with a
% catch-all first, From=["misc"] against To=["compiler"] would match it and
% report a common prefix that still contains "misc", yielding zero ".." steps
% and a silently wrong path.
cosmos_common_prefix([H|T], [H|T2], [H|R]) :- cosmos_common_prefix(T, T2, R).
cosmos_common_prefix(_, _, []).

cosmos_suffix(List, 0, List) :- !.
cosmos_suffix([_|T], N, R) :-
    N > 0,
    N1 is N - 1,
    cosmos_suffix(T, N1, R).

compiler_make_executable(Output, Executable) :-
    compiler_load_runtime,
    absolute_file_name(Output, AbsOutput),
    absolute_file_name(Executable, AbsExecutable),
    nb_setval(cosmos_building_exe, true),
    setup_call_cleanup(
        true,
        ( consult(AbsOutput),
          nb_delete(cosmos_building_exe),
          qsave_program(AbsExecutable, [goal(cosmos_entry_main), stand_alone(true), toplevel(halt)])
        ),
        ( nb_current(cosmos_building_exe, _) -> nb_delete(cosmos_building_exe) ; true )).

% The XPCE backend .pl is loaded at runtime (see entry template), never
% embedded: a saved image containing library(pce) does not start.

% DLL staging, opt-in only.
%
% A saved exe dynamically links libswipl.dll and nothing else, so it starts
% as long as the SWI installation is reachable: libswipl.dll carries PLHOME,
% and from there SWI resolves pl2xpce.dll and the SDL/cairo/pango stack
% itself.  Verified on this machine: an exe with zero DLLs beside it runs
% and opens its window with SWI's bin on PATH, and with only the five core
% DLLs beside it runs with PATH cleared.  Staging the rest (24 extra files,
% libstdc++-6.dll alone is 26 MB) therefore bought nothing, while dropping
% ~30 DLLs into the source tree on every --exe was exactly the mess
% complained about.
%
% So --exe no longer copies anything.  compiler_stage_exe/2 stays available
% for packaging an exe to ship to a machine with no SWI installed, and the
% installer targets can call it; it is just never on by default.

% SpaceProgram selects the core-only (false) or core+XPCE (true) set.
compiler_stage_exe(ExeFile, SpaceProgram) :-
    absolute_file_name(ExeFile, AbsExe),
    file_directory_name(AbsExe, ExeDir),
    compiler_stage_native_dlls(ExeDir, SpaceProgram).

compiler_stage_native_dlls(ExeDir0, SpaceProgram) :-
    absolute_file_name(ExeDir0, ExeDir),
    current_prolog_flag(executable, SwiExe),
    file_directory_name(SwiExe, SwiBin),
    forall(compiler_native_dll(SpaceProgram, Dll),
           ( directory_file_path(SwiBin, Dll, Source),
             directory_file_path(ExeDir, Dll, Target),
             ( exists_file(Target) -> true
             ; catch(copy_file(Source, Target), E,
                     print_message(warning, E))
             ))).

% Core closure of libswipl.dll (from its PE import table).
compiler_native_dll(_, 'libswipl.dll').
compiler_native_dll(_, 'libgcc_s_seh-1.dll').
compiler_native_dll(_, 'libwinpthread-1.dll').
compiler_native_dll(_, 'libgmp-10.dll').
compiler_native_dll(_, 'zlib1.dll').
% XPCE closure of pl2xpce.dll (from its PE import table + transitive deps).
compiler_native_dll(true, 'pl2xpce.dll').
compiler_native_dll(true, 'libswipl.dll').
compiler_native_dll(true, 'SDL3.dll').
compiler_native_dll(true, 'SDL3_image.dll').
compiler_native_dll(true, 'libcairo-2.dll').
compiler_native_dll(true, 'libglib-2.0-0.dll').
compiler_native_dll(true, 'libgobject-2.0-0.dll').
compiler_native_dll(true, 'libgmodule-2.0-0.dll').
compiler_native_dll(true, 'libpango-1.0-0.dll').
compiler_native_dll(true, 'libpangocairo-1.0-0.dll').
compiler_native_dll(true, 'libpangoft2-1.0-0.dll').
compiler_native_dll(true, 'libpangowin32-1.0-0.dll').
compiler_native_dll(true, 'libharfbuzz-0.dll').
compiler_native_dll(true, 'libfontconfig-1.dll').
compiler_native_dll(true, 'libfreetype-6.dll').
compiler_native_dll(true, 'libfribidi-0.dll').
compiler_native_dll(true, 'libpixman-1-0.dll').
compiler_native_dll(true, 'libpng16-16.dll').
compiler_native_dll(true, 'libgio-2.0-0.dll').
compiler_native_dll(true, 'libintl-8.dll').
compiler_native_dll(true, 'libffi-8.dll').
compiler_native_dll(true, 'libexpat-1.dll').
compiler_native_dll(true, 'libpcre2-8-0.dll').
compiler_native_dll(true, 'libbz2-1.dll').
compiler_native_dll(true, 'libgmp-10.dll').
compiler_native_dll(true, 'libwinpthread-1.dll').
compiler_native_dll(true, 'libgcc_s_seh-1.dll').
compiler_native_dll(true, 'libstdc++-6.dll').
compiler_native_dll(true, 'zlib1.dll').

compiler_compile_application(Stage, Input, Output, Module, Main, Executable) :-
    compiler_compile_file(Stage, Input, Output, Module),
    ( Main == true -> compiler_add_main_entry(Output, Module) ; true ),
    ( Executable == true -> compiler_executable_file(Output, Exe), compiler_make_executable(Output, Exe) ; true ).

% Options accepted by both command-line front ends.  --exe always creates a
% main wrapper because a standalone image must have a predictable entry.
compiler_cli_options(Options, DefaultModule, Module, Main, Executable) :-
    compiler_cli_options(Options, DefaultModule, DefaultModule, false, false, Module, Main, Executable).
compiler_cli_options([], _, Module, Main, Executable, Module, Main, Executable).
compiler_cli_options(['--main'|Rest], Default, Current, _, Executable, Module, Main, FinalExecutable) :- !,
    compiler_cli_options(Rest, Default, Current, true, Executable, Module, Main, FinalExecutable).
compiler_cli_options(['--exe'|Rest], Default, Current, _, _, Module, Main, FinalExecutable) :- !,
    compiler_cli_options(Rest, Default, Current, true, true, Module, Main, FinalExecutable).
compiler_cli_options(['--module', Name|Rest], Default, _, Main, Executable, Module, FinalMain, FinalExecutable) :- !,
    compiler_cli_options(Rest, Default, Name, Main, Executable, Module, FinalMain, FinalExecutable).
compiler_cli_options([Name|Rest], Default, _, Main, Executable, Module, FinalMain, FinalExecutable) :-
    compiler_cli_options(Rest, Default, Name, Main, Executable, Module, FinalMain, FinalExecutable).

% Data-only sidecars. No consult/1, directives, or imported application execution.
compiler_read_interfaces(Names,Directory,Pairs) :-
    sort(Names,Unique),compiler_read_interfaces_sorted(Unique,Directory,Pairs).
compiler_read_interfaces_sorted([],_,[]).
compiler_read_interfaces_sorted([Name|Names],Directory,Pairs) :-
    string_concat(Name,".cif",Relative),directory_file_path(Directory,Relative,File),
    (exists_file(File)->
        setup_call_cleanup(open(File,read,Stream,[encoding(utf8)]),
            (read_term(Stream,Unit,[]),read_term(Stream,End,[])),close(Stream)),
        (End==end_of_file,ground(Unit),is_assoc(Unit),get_assoc("format",Unit,Format),number(Format),Format=:=1,
         get_assoc("schemas",Unit,Schemas),is_assoc(Schemas),get_assoc("exports",Unit,Exports),is_assoc(Exports)
        ->Pairs=[Name-Unit|Tail]
        ;throw(error(domain_error(cosmos_interface,File),_)))
    ;Pairs=Tail),
    compiler_read_interfaces_sorted(Names,Directory,Tail).
compiler_report(fc_ParseError(Message,[fc_Token(_,_,Line,Column)|_])) :- !,
    format(user_error,'Parse error at ~g:~g: ~s~n',[Line,Column,Message]).
compiler_report(fc_ParseError(Message,Expected,[fc_Token(_,_,Line,Column)|_])) :- !,
    format(user_error,'Parse error at ~g:~g: ~s (expected ~s)~n',[Line,Column,Message,Expected]).
compiler_report(fc_CompileError(Message,fc_Loc(Line,Column))) :- !,
    format(user_error,'Compile error at ~g:~g: ~s~n',[Line,Column,Message]).
compiler_report(Message) :- string(Message),!,format(user_error,'Compile error: ~s~n',[Message]).
compiler_report(Error) :- print_message(error,Error).
