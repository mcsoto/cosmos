% Line-oriented Cosmos REPL backed by the self-hosted compiler.
:- ensure_loaded(driver).
:- ensure_loaded(session).
:- initialization(main, main).

version :- 
	writeln("0.86").

main :-
    current_prolog_flag(argv, RawArguments),
    cosmos_runtime_options(RawArguments,Arguments),
    % halt/abort travel as unwind/1 balls; rethrow them instead of
    % reporting them as failures (otherwise every clean exit becomes 1).
    catch((cosmos_main(Arguments), halt), Error,
          ( ( Error = unwind(_) ; Error = '$abort' ) -> throw(Error)
          ; compiler_report(Error), halt(1)
          )).

cosmos_main([]) :- !, cosmos_repl.
cosmos_main(['-i']) :- !, cosmos_repl.
cosmos_main(['-t'|Arguments]) :- !,
    nb_setval(cosmos_trace_requested,true),
    nb_setval(cosmos_debug_contracts,true),
    cosmos_main(Arguments).
cosmos_main(['-d'|Arguments]) :- !,
    nb_setval(cosmos_debug_contracts,true),
    cosmos_main(Arguments).
cosmos_main(['-v']) :- !,
    %writeln('Cosmos self-hosted compiler').
	write('Cosmos self-hosted compiler'),
	write(' '),version.
cosmos_main(['-h']) :- !, cosmos_help.
cosmos_main(['--help']) :- !, cosmos_help.
cosmos_main(['-q', Source|Arguments]) :- !,
    cosmos_query_variables(Arguments, Variables),
    repl_execute(Source, Variables).
% Compile a source file and a one-shot fragment together.  This is not a
% filename-specific shortcut: the fragment shares the file's ordinary lexical
% scope, so relation captures (including require(...) values) are supplied by
% the generated top-level entry just as they are in a normal program.
cosmos_main(['-l', Source, '-q', Query|Arguments]) :- !,
    cosmos_query_variables(Arguments, Variables),
    cosmos_source_file(Source, Input),
    read_file_to_string(Input, Program, []),
    string_concat(Program, "\n", WithBreak),
    string_concat(WithBreak, Query, Combined),
    repl_execute(Combined, Variables).
cosmos_main(['-r', Program|Rest]) :- !,
    cosmos_module_argument(Rest, Program, Module),
    cosmos_run(Program, Module).
cosmos_main(['-b', Program|Rest]) :- !,
    cosmos_module_argument(Rest, Program, Module),
    cosmos_run(Program, Module).
cosmos_main(['-l', Source|Options]) :- !,
    cosmos_source_file(Source, Input),
    cosmos_output_file(Input, Output),
    cosmos_compile_options(Options, Output, Module, Entry, Executable),
    cosmos_compile(Input, Output, Module, Entry, Executable),
    ( Executable == true -> true ; cosmos_run(Output, Module) ).
cosmos_main(['-c', Source|Options]) :- !,
    cosmos_source_file(Source, Input),
    cosmos_output_file(Input, Output),
    cosmos_compile_options(Options, Output, Module, Entry, Executable),
    cosmos_compile(Input, Output, Module, Entry, Executable),
    format('Compiled ~w -> ~w~n', [Input, Output]).
cosmos_main(['-f', Input, '-o', Output|Rest]) :- !,
    cosmos_compile_options(Rest, Output, Module, Entry, Executable),
    cosmos_compile(Input, Output, Module, Entry, Executable).
cosmos_main(['-f', Input|Options]) :- !,
    cosmos_output_file(Input, Output),
    cosmos_compile_options(Options, Output, Module, Entry, Executable),
    cosmos_compile(Input, Output, Module, Entry, Executable).
cosmos_main([Input]) :- !,
    cosmos_source_file(Input, Source),
    cosmos_output_file(Source, Output),
    cosmos_compile(Source, Output, _).
cosmos_main(_) :-
    cosmos_help,
    halt(2).

cosmos_repl :-
    format('Cosmos self-hosted compiler loaded.~n', []),
    format('Enter a one-line Cosmos program; :help for help, :quit to exit.~n', []),
    repl,
    halt.

cosmos_help :-
    format('Cosmos self-hosted compiler~n~n', []),
    format('  cosmos.bat -i                         Open the Cosmos interpreter.~n', []),
    format('  cosmos.bat -v                         Print the compiler version.~n', []),
    format('  cosmos.bat -f input.co -o output.pl [module]~n', []),
    format('                                        Compile a source file.~n', []),
    format('  cosmos.bat -c name                    Compile name.co to name.pl.~n', []),
    format('  cosmos.bat -c name [--main] [--exe]   Add argv-list main entry; --exe saves a standalone app.~n', []),
    format('  cosmos.bat -l name --xpce             Run a file\'s top-level goals, with no main.~n', []),
    format('                                        Lets `require(''space'', sp)'' sit at the top.~n', []),
    format('  cosmos.bat -l name                    Compile name.co and run it.~n', []),
    format('  cosmos.bat -l file.co -q "query" [--vars x,y]~n', []),
    format('                                        Run a query in that file\'s source scope.~n', []),
    format('  cosmos.bat -r program.pl [module]     Run generated Prolog (-b is an alias).~n', []),
    format('  cosmos.bat -q "Cosmos source" [--vars x,y]~n', []),
    format('                                        Compile a query with selected results.~n', []),
    format('  cosmos.bat -d [arguments]             Enable debug contract checks.~n', []),
    format('  cosmos.bat -l name -t                 Trace calls; also enables debug checks.~n', []).

% Preserve option operands (in particular query text), while allowing runtime
% switches before or after the command and its file argument.
cosmos_runtime_options([],[]).
cosmos_runtime_options([Flag,Value|Rest],[Flag,Value|Options]) :-
    memberchk(Flag,['-l','-c','-r','-b','-f','-o','-q','--module','--vars']),!,
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options(['-t'|Rest],Options) :- !,
    nb_setval(cosmos_trace_requested,true),nb_setval(cosmos_debug_contracts,true),
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options(['-d'|Rest],Options) :- !,
    nb_setval(cosmos_debug_contracts,true),cosmos_runtime_options(Rest,Options).
% The profiler switches are runtime switches like -t and -d: they are
% consumed here, so they never reach the compiler's option parser (which
% would read an unknown option as a module name).
cosmos_runtime_options(['--profile'|Rest],Options) :- !,
    nb_setval(cosmos_profile_requested,true),
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options(['--profile-out',File|Rest],Options) :- !,
    nb_setval(cosmos_profile_out,File),
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options(['--profile-frames',Frames|Rest],Options) :- !,
    cosmos_profile_number(Frames,Count),
    nb_setval(cosmos_profile_dump_frames,Count),
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options(['--profile-seconds',Seconds|Rest],Options) :- !,
    cosmos_profile_number(Seconds,Count),
    nb_setval(cosmos_profile_seconds,Count),
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options(['--profile-top',Top|Rest],Options) :- !,
    cosmos_profile_number(Top,Count),
    nb_setval(cosmos_profile_top,Count),
    cosmos_runtime_options(Rest,Options).
cosmos_runtime_options([Arg|Rest],[Arg|Options]) :- cosmos_runtime_options(Rest,Options).

% A count given on the command line is a number; a bad one is worth a
% complaint rather than a silent zero.
cosmos_profile_number(Text,Count) :-
    (   atom(Text)
    ->  atom_number(Text, Number)
    ;   number(Text)
    ->  Number = Text
    ;   Number = 0
    ),
    (   integer(Number), Number >= 0
    ->  Count = Number
    ;   format(user_error,'Cosmos: --profile-frames/--profile-top want a number, got ~w~n',[Text]),
        Count = 0
    ).

:- meta_predicate cosmos_execute(0).
cosmos_execute(Goal) :-
    (nb_current(cosmos_trace_requested,true)->
        b_setval(cosmos_trace_enabled,true),b_setval(cosmos_trace_depth,0),
        call(Goal),b_setval(cosmos_trace_enabled,false)
    ;call(Goal)).

cosmos_query_variables([], none) :- !.
cosmos_query_variables(['--vars', Spec], Variables) :- !,
    cosmos_variable_list(Spec, Variables).
cosmos_query_variables([Spec], Variables) :- !,
    cosmos_variable_list(Spec, Variables).
cosmos_query_variables(_, _) :-
    throw(error(domain_error(cosmos_query_arguments, 'use --vars x,y'), _)).

cosmos_variable_list(Spec, Variables) :-
    ( string(Spec) -> Text = Spec ; atom_string(Spec, Text) ),
    split_string(Text, ', ', ', ', Names),
    maplist(atom_string, Variables, Names).

cosmos_source_file(Name, Input) :-
    ( file_name_extension(_, co, Name) -> Input = Name
    ; atom_concat(Name, '.co', Input)
    ).

cosmos_output_file(Input, Output) :-
    file_name_extension(Stem, _, Input),
    atom_concat(Stem, '.pl', Output).

cosmos_module_argument(['--main'], _, main) :- !.
cosmos_module_argument(['--module', Module], _, Module) :- !.
% The entry kind is not a module name: `cosmos -r program.pl --xpce'
% names the module `program', not `--xpce'.
cosmos_module_argument(['--xpce'|Rest], Path, Module) :- !,
    cosmos_module_argument(Rest, Path, Module).
cosmos_module_argument(['--main'|Rest], Path, Module) :- !,
    cosmos_module_argument(Rest, Path, Module).
cosmos_module_argument([Module], _, Module) :- !.
cosmos_module_argument([], Path, Module) :-
    file_base_name(Path, Base),
    file_name_extension(Module, _, Base).

cosmos_compile_options(Options, Output, Module, Entry, Executable) :-
    compiler_file_module(Output, DefaultModule),
    compiler_cli_options(Options, DefaultModule, Module, Entry, Executable).

cosmos_compile(Input, Output, Module) :-
    cosmos_compile(Input, Output, Module, none, false).
cosmos_compile(Input, Output, Module, Entry, Executable) :-
    compiler_platform(Here),
    directory_file_path(Here, '../generated', Stage),
    get_time(Start),
    compiler_compile_application(Stage, Input, Output, Module, Entry, Executable),
    get_time(End),
    Milliseconds is round((End - Start) * 1000),
    % Kept for the profiler report: the compile is part of the pipeline
    % a Space program travels, and it is worth seeing next to the run.
    nb_setval(cosmos_profile_compile_ms, Milliseconds),
    nb_setval(cosmos_profile_source, Input),
    nb_setval(cosmos_profile_target, Output).

% What the profiler report should call this program.
cosmos_profile_note(File, Module) :-
    % file_base_name/2 does not split on a backslash on Windows, so the
    % last path component is taken here instead.
    split_string(File, '/\\', '', Parts),
    last(Parts, Base),
    file_name_extension(Name, _, Base),
    nb_setval(cosmos_profile_program, Name),
    nb_setval(cosmos_profile_module, Module).

% Load the profiler when the run asked for one and start the sampler.
%
% The generated entry point loads the profiler as well, so a program run
% directly with `swipl -s program.pl' is covered too.  Doing it here as
% well means `cosmos -r program.pl --profile' works with a program that
% was generated before the profiler existed.
cosmos_profile_prepare :-
    (   nb_current(cosmos_profile_prepared, true)
    ->  true
    ;   nb_setval(cosmos_profile_prepared, true),
        compiler_platform(Here),
        directory_file_path(Here, 'profile.pl', Profiler),
        (   exists_file(Profiler)
        ->  ensure_loaded(Profiler),
            cosmos_profile:cosmos_profile_start()
        ;   format(user_error,'Cosmos: no profiler at ~w~n',[Profiler])
        )
    ).

cosmos_run(File, Module) :-
    compiler_platform(Here),
    directory_file_path(Here, '../generated', Stage),
    compiler_load(Stage),
    absolute_file_name(File, Absolute),
    file_directory_name(Absolute, Directory),
    directory_file_path(Directory, '?', Local),
    nb_getval(path, Previous),
    atomic_list_concat([Local, Previous], ';', Path),
    nb_setval(path, Path),
    consult(Absolute),
    % A --main build carries its own entry point, which the compiler appends
    % as `:- initialization(cosmos_entry_main, main).`  That directive only
    % fires when the file is loaded as the main program, and consult/1 does
    % not count as that -- so calling the module goal here would run the
    % generated stub (moving_rect([]) :- true) and print [] instead of
    % starting the program.  Prefer the entry when the file defines one.
    ( current_predicate(cosmos_entry_main/0) -> Goal = cosmos_entry_main ; Goal =.. [Module, Output] ),
    cosmos_profile_note(File, Module),
    (   nb_current(cosmos_profile_requested, true)
    ->  cosmos_profile_prepare
    ;   true
    ),
    % An entry-driven run binds nothing here (the entry called main/the module
    % goal itself), so only report a result when the module goal produced one.
    % The cleanup closes a profiling run: a program without an entry point
    % (a plain -l compile) has no entry of its own to do it.
    (   setup_call_cleanup(true, once(cosmos_execute(Goal)), cosmos_profile_finish),
        nonvar(Output)
    ->  repl_print_result(Output)
    ;   throw(error(cosmos_program_failed, cosmos_run/2))
    ).

repl :- repl(none).

repl(Selected) :-
    write('> '),
    flush_output,
    read_line_to_string(user_input, Line),
    repl_line(Line, Selected, Next, Continue),
    ( Continue == true -> repl(Next) ; true ).

repl_line(end_of_file, Selected, Selected, false) :- !, nl.
repl_line("", Selected, Selected, true) :- !.
repl_line(":quit", Selected, Selected, false) :- !.
repl_line(":vars", _, none, true) :- !,
    writeln('variable selection cleared').
repl_line(Line, _, Variables, true) :-
    sub_string(Line, 0, 5, _, ":vars"), !,
    sub_string(Line, 5, _, 0, Spec),
    cosmos_variable_list(Spec, Variables),
    format('returning: ~w~n', [Variables]).
repl_line(":help", Selected, Selected, true) :- !,
    format('Enter Cosmos source on one line.  export(Value) prints Value; a program~n', []),
    format('without an export prints [] on success.  :vars x,y selects results.~n', []).
repl_line(Source, Selected, Selected, true) :-
    catch(repl_execute(Source, Selected), Error, compiler_report(Error)).

repl_execute(Source) :- repl_execute(Source, none).

repl_execute(Source, Selected) :-
    gensym(cosmos_repl_, Prefix),
    compiler_platform(Here),
    directory_file_path(Here, '../generated', Stage),
    repl_compile(Stage, Source, Selected, Prefix, Code),
    tmp_file(cosmos_repl, File),
    setup_call_cleanup(
        true,
        setup_call_cleanup(
            open(File, write, Stream, [encoding(utf8), newline(posix)]),
            ( write(Stream, Code),
              close(Stream),
              consult(File),
              cosmos_execute(repl_run(Prefix))
            ),
            ( catch(close(Stream), _, true),
              catch(delete_file(File), _, true)
            )
        ),
        compiler_session_dispose(Prefix)
    ).

repl_compile(Stage, Source, none, Prefix, Code) :- !,
    compiler_session_compile(Stage, Source, Prefix, Code).
repl_compile(Stage, Source, Variables, Prefix, Code) :-
    compiler_session_compile_query(Stage, Source, Variables, Prefix, Query),
    getnil(Query, "prolog", Code).

repl_run(Prefix) :-
    % Do not capture the program's output.  Capturing postpones every log
    % line until the query returns, which makes a running application appear
    % silent forever.  The prompt marker is written first; program writes then
    % flow straight to the terminal as they happen.
    format('| ', []),
    flush_output,
    ( compiler_session_entry(Prefix, Output)
    -> repl_print_result(Output)
    ;  writeln(false)
    ).

repl_print_result(Output) :-
    ( var(Output) ; Output == none ) -> writeln(true)
    ; write_term(Output, [quoted(true)]), nl.
