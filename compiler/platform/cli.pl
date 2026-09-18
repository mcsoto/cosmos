:- ensure_loaded(driver).
:- initialization(main,main).
main :- catch(run,E,(compiler_report(E),halt(1))).
run :-
    current_prolog_flag(argv,Args),
    (Args=[Input,Output|Options] -> compiler_file_module(Output,DefaultModule),
        compiler_cli_options(Options,DefaultModule,Module,Main,Executable)
    ; format(user_error,'Usage: swipl -q -s compiler/platform/cli.pl -- input.co output.pl [--module module] [--main] [--exe]~n',[]),halt(2)),
    compiler_platform(Here),directory_file_path(Here,'../generated',Stage),
    compiler_compile_application(Stage,Input,Output,Module,Main,Executable).
