:- use_module(library(pce)).

%:- initialization(start).

start :-	
    new(P, picture('Moving rectangle')),
    send(P, size, size(640, 480)),

    new(Rect, box(80, 50)),
    send(Rect, fill_pattern, colour(blue)),
    send(P, display, Rect, point(100, 100)),

    new(Timer, timer(0.016,
                     message(@prolog, tick, P, Rect))),

    send(P, done_message,
         message(@prolog, stop_app, P, Timer)),

    send(P, open),
    send(Timer, start).

tick(P, Rect) :-
    object(P),
    object(Rect),
    get(Rect, x, X),
    get(Rect, y, Y),
    X1 is X + 2,
    send(Rect, set, X1, Y).

stop_app(P, Timer) :-
    send(Timer, stop),
    send(P, destroy).
	
run(_Argv) :- start.
