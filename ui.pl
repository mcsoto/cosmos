:- use_module(library(pce)), initialization(start).

start :-
    new(P, picture('Moving rectangle')),
    send(P, size, size(640, 480)),
    send(P, open),

    new(Rect, box(80, 50)),
    send(Rect, fill_pattern, colour(blue)),
    send(P, display, Rect, point(100, 100))

    %new(Timer, timer(0.016, message(@prolog, move_rect, Rect))),
	%new(Timer, timer(0.016)),
    %send(Timer, start)
	.

move_rect(Rect) :-
    get(Rect, x, X),
    get(Rect, y, Y),
    X1 is X + 2,
    send(Rect, set, X1, Y).