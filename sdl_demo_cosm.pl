:- use_module(library(pce)).
:- use_module(library(pce_main)).

% A minimal XPCE program with an SDL window.
%
%   swipl -q -s xpce/sdl_demo.pl
%
% Close the window to exit.  No classes are defined: the built-in
% sdl_window, sdl_layer and sdl_texture classes do the work.  The ball is
% drawn once into a texture by Cairo; the SDL renderer then moves it on
% the GPU.  The label is an ordinary graphical, drawn on top by Cairo.

main(_) :-
    new(Window, sdl_window('XPCE SDL demo', size(640, 480))),
    send(Window, background, colour('#1b1b2f')),

    % The sprite: a circle drawn once into a texture, shown by a layer.
    % scale(none) shows the texture at its own size; the hot spot is the
    % point of the texture that lands on the layer's area position and
    % around which ->angle rotates.
    new(Ball, circle(20)),
    send(Ball, fill, colour('#3050ff')),
    send(Ball, pen, 2),
    new(Texture, sdl_texture(Ball)),
    send(Texture, hot_spot, point(10, 10)),       % the centre of the ball
    new(Layer, sdl_layer(Texture, area(100, 220, 0, 0), none)),
    send(Window, append, Layer),

    % Graphicals are drawn on top of the layers.
    send(Window, display, new(Label, text('An sdl_window with a sprite')),
          point(10, 10)),
    send(Label, colour, white),

    send(Window, open),

    % Animate the sprite.  Closing the window ends the process, so the
    % timer needs no cleanup.
    new(Timer, timer(0.016, message(@prolog, tick, Layer))),
    send(Timer, start).

tick(Layer) :-
    get(Layer, area, Area),
    get(Area, x, X),
    get(Area, y, Y),
    X1 is (X + 4) mod 620,
    send(Layer, area, area(X1, Y, 0, 0)),
    get(Layer, angle, A),
    send(Layer, angle, A + 3).

:- initialization(pce_main_loop(main)).
%main :- main(_).