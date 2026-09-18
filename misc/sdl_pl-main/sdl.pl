:- use_foreign_library(foreign(sdl)).

setRGB(X,Y,Z) :- setRGBA(X,Y,Z,255).

sdl_right(1073741903).
sdl_left(1073741904).
sdl_down(1073741905).
sdl_up(1073741906).

:- check(1,1),check(1,2).
