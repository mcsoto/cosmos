
:- use_module(library(pce)).
:- initialization(pce_main_loop(start), main).


start(_Frame) :-
    new(P, picture('XPCE keyboard probe')),
    send(P, size, size(640, 400)),
    send(P, recogniser,
         handler(keyboard,
                 message(@prolog, keyboard_event, @arg1))),
    send(P, open).

keyboard_event(Ev) :-
    get(Ev, id, Id),
    format('keyboard event id=~w~n', [Id]),
    flush_output.

:- initialization(pce_main_loop(start), main).
