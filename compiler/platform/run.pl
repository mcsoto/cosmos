% Execute a generated module's exported entry without Lua.
:- ensure_loaded(driver).
:- initialization(main,main).
main :- catch(run,E,(compiler_report(E),halt(1))).
run :-
    current_prolog_flag(argv,Args),
    (Args=[File,Module] -> true
    ; Args=[File] -> compiler_file_module(File,Module)
    ; format(user_error,'Usage: swipl -q -s compiler/platform/run.pl -- program.pl [module]~n',[]),halt(2)),
    compiler_platform(Here),directory_file_path(Here,'../../src/swi.pl',Runtime),consult(Runtime),
    directory_file_path(Here,'runtime.pl',Operations),consult(Operations),
    absolute_file_name(File,Absolute),file_directory_name(Absolute,Directory),
    directory_file_path(Directory,'?',Local),nb_getval(path,Previous),
    atomic_list_concat([Local,Previous],';',Path),nb_setval(path,Path),
    consult(Absolute),Goal=..[Module,Output],
    (once(call(Goal))->(var(Output)->true;write_term(Output,[quoted(true)]),nl)
    ; format(user_error,'Program failed.~n',[]),halt(1)).
