:- ensure_loaded(driver).
:- initialization(main,main).
main :- catch((current_prolog_flag(argv,[Stage,Input,Output,Module]),
               compiler_compile_file(Stage,Input,Output,Module)),E,
              (compiler_report(E),halt(1))).
