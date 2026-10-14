
:- use_module(library(pce)).
:- initialization(pce_main_loop(start), main).

start(_Frame) :-
    new(P, picture('XPCE wheel probe')),
    send(P, size, size(640, 400)),
    send(P, recogniser,
         handler(wheel,
                 message(@prolog, wheel_event, @arg1))),
    send(P, open).

wheel_event(Ev) :-
    get(Ev, id, Id),
    get(Ev, rotation, Rotation),
    format('event=~w rotation=~w~n', [Id, Rotation]),
    flush_output.

:- initialization(pce_main_loop(start), main).

