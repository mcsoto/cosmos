:- use_module(library(pce)).
:- use_module(library(pce_main)).

build :-
    qsave_program('ui2.exe',
        [ emulator(swi('bin/xpce-stub.exe')),
          stand_alone(true),
          goal(main)
        ]).