
:- use_module(library(pce)).
:- initialization(pce_main_loop(start), main).


start :-
    new(P, picture('XPCE pointer probe')),
    send(P, size, size(640, 400)),
    send(P, recogniser,
         handler(motion,
                 message(@prolog, pointer_event, @arg1))),
    send(P, open).

pointer_event(Ev) :-
    get(Ev, x, X),
    get(Ev, y, Y),
    format('x=~w y=~w~n', [X, Y]),
    flush_output.

:- initialization(pce_main_loop(start), main).

