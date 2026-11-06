:- use_module(library(pce)).
:- use_module(library(pce_main)).
:- style_check(-singleton).

main(_) :-
    get_time(Now),
    get(P, time, T0),
    get(P, max_dt, MaxDt).
	
:- pce_begin_class(animation_demo, frame,
                   "Play an animated image").

variable(timer, timer*, get, "Keeps the controls up to date").

initialise(F) :->
    send_super(F, initialise, 'Animation'),
    send(F, append, new(S, picture('Stage', size(320, 240)))),
    send(S, name, stage),
    send(S, scrollbars, none),
    send(S, background, colour(grey90)),
    send(S, display, new(_, bitmap)),
    send(new(D, dialog), below, S),
    send(D, name, controls),
    send(F, fill_dialog, D),
    send(new(Strip, picture('Frames', size(320, 76))), below, D),
    send(Strip, name, strip),
    send(Strip, scrollbars, horizontal),
    send(F, slot, timer, new(T, timer(0.05, message(F, update)))),
    send(T, start).
	