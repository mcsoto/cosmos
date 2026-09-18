:- ensure_loaded(driver).
:- initialization(main,main).
main :- catch(run,E,(compiler_report(E),halt(1))).
run :-
    current_prolog_flag(argv,Args),
    (Args=[Input,Output,Module] -> true
    ; Args=[Input,Output] -> compiler_file_module(Output,Module)
    ; format(user_error,'Usage: swipl -q -s compiler/platform/cli.pl -- input.co output.pl [module]~n',[]),halt(2)),
    compiler_platform(Here),directory_file_path(Here,'../generated',Stage),
    compiler_compile_file(Stage,Input,Output,Module).
