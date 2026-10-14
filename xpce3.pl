
:- use_module(library(pce)).
:- initialization(pce_main_loop(start), main).


start :-
    new(P, picture('XPCE click probe')),
    send(P, size, size(640, 400)),
    send(P, recogniser,
         click_gesture(left, single,
                       message(@prolog, report_click, single))),
    send(P, recogniser,
         click_gesture(left, double,
                       message(@prolog, report_click, double))),
    send(P, open).

report_click(Kind) :-
    format('click=~w~n', [Kind]),
    flush_output.

:- initialization(pce_main_loop(start), main).
