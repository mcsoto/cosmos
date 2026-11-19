
asteroids :-
    new(F, asteroids_game),
    send(F, open).

		 /*******************************
		 *	       THE GAME		*
		 *******************************/

:- pce_begin_class(asteroids_game, frame, "A game like Asteroids").

initialise(F) :->
    send_super(F, initialise, 'Asteroids'),
    send(F, append, new(P, asteroids_window(size(800, 600)))),
    send(P, intro).

:- pce_end_class(asteroids_game).

init_window(Prefix,W,H) :-
    bound(W) -> true ; W = 640, H = 480,
	new(Window, space_picture('Cosmos Space')),
	send(Window, size, size(W, H)),
	send(Window, open),
	% Keyboard events are delivered to the graphical selected by
	% ->keyboard_focus.  The space_picture subclass is the event hook that
	% captures them into the Space queue, so focus it after opening.
	( catch(send(Window, keyboard_focus, Window), _, fail) -> true ; true ),
	% Fractional wheel steps are worth having: a trackpad then reports
	% fractions of a notch instead of whole notches.
	catch(send(Window, smooth_scroll, @on), _, true),
	% XPCE calls this message after the window has been resized, which is
	% how the Space API learns that the canvas changed size.
	catch(send(Window, resize_message, message(@prolog, space_xpce_resize, Prefix)), _, true),
	assertz(space_window(Prefix, Window)),
	retractall(space_size(Prefix, _)),
	assertz(space_size(Prefix, size(W, H))),
	( space_created(Prefix, _) -> true
	; get_time(Now), assertz(space_created(Prefix, Now))
	),
	( space_bg(Prefix, _) -> true ; assertz(space_bg(Prefix, "#000000")) ),
	( space_fg(Prefix, _) -> true ; assertz(space_fg(Prefix, "#ffffff")) ),
	( space_line_style(Prefix, _) -> true ; assertz(space_line_style(Prefix, "smooth")) ),
	retractall(space_mouse(Prefix, _, _, _)),
	retractall(space_keys(Prefix, _)),
	space_clear_focus(Prefix)
	).


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

%:- initialization(pce_main_loop(main)).
