% File/platform adapter for the compiler whose implementation lives in .co.
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
    compiler_platform(PlatformDirectory),
    directory_file_path(PlatformDirectory, '../swi.pl', Runtime),
    directory_file_path(PlatformDirectory, 'runtime.pl', Operations),
    setup_call_cleanup(
        open(Output, append, Stream, [encoding(utf8), newline(posix)]),
        ( format(Stream, '~ncosmos_entry_load_runtime :-~n', []),
          format(Stream, '    ( current_predicate(cosmos_get/3) -> true~n', []),
          format(Stream, '    ; ensure_loaded(~q),~n', [Runtime]),
          format(Stream, '      ensure_loaded(~q)~n', [Operations]),
          format(Stream, '    ).~n', []),
          format(Stream, ':- initialization(cosmos_entry_load_runtime, now).~n', []),
          format(Stream, ':- initialization(cosmos_entry_main, main).~n', []),
          format(Stream, 'cosmos_entry_main :-~n', []),
          format(Stream, '    ( nb_current(cosmos_building_exe, true) -> true~n', []),
          format(Stream, '    ; nb_current(cosmos_entry_ran, true) -> true~n', []),
          format(Stream, '    ; nb_setval(cosmos_entry_ran, true),~n', []),
          % Preserve the conventional argv[0] slot. Cosmos lists use
          % zero-based indexing, so main(args) can use args[1] for the first
          % user-supplied argument, as command-line programs normally do.
          format(Stream, '      current_prolog_flag(executable, Executable), current_prolog_flag(argv, RawArguments),~n', []),
          format(Stream, '      Arguments = [Executable|RawArguments], ~q(Arguments)~n', [Predicate]),
          format(Stream, '    ).~n', [])
        ),
        close(Stream)).

compiler_executable_file(Output, Executable) :-
    file_name_extension(Base, _, Output),
    file_name_extension(Base, exe, Executable).

compiler_make_executable(Output, Executable) :-
    compiler_load_runtime,
    nb_setval(cosmos_building_exe, true),
    setup_call_cleanup(
        true,
        ( consult(Output),
          nb_delete(cosmos_building_exe),
          qsave_program(Executable, [goal(cosmos_entry_main), stand_alone(true), toplevel(halt)])
        ),
        ( nb_current(cosmos_building_exe, _) -> nb_delete(cosmos_building_exe) ; true )).

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
