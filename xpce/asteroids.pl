/*  Part of XPCE --- The SWI-Prolog GUI toolkit

    Author:        Jan Wielemaker
    E-mail:        jan@swi-prolog.org
    WWW:           https://www.swi-prolog.org/packages/xpce/
    Copyright (c)  2026, SWI-Prolog Solutions b.v.
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in
       the documentation and/or other materials provided with the
       distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

:- module(asteroids,
          [ asteroids/0
          ]).
:- use_module(library(pce)).
:- use_module(library(random)).
:- autoload(library(pce_class_variable_editor), [class_variable_editor/1]).

/** <module> A game like Asteroids

Fly a ship through a field of asteroids and shoot them.  A large
asteroid breaks into two medium ones, a medium one into two small ones.
Clear the field to get to the next level, which has more asteroids.
The playing field follows the size of the window.

Controls: cursor left/right rotate, cursor up thrusts, space fires,
p pauses and Enter starts a new game or resumes a paused one.  F1
shows the controls.  A gamepad works as well: the
left stick rotates, the right trigger or `north` button thrusts and the
`south` button fires.

On start-up, after the game is over and while it is paused, the field
shows buttons to play, to change the settings and to show the
controls.  The settings are the class variables of the game, edited
with the class variable editor (see library(pce_preferences)).  While
playing, the pointer is hidden.

The field is an sdl_window.  Everything that moves is a sprite: an
sdl_layer that holds its own state.  The sprites are the ship, the
asteroids, the bullets, the particles of an explosion and the stars.
Below the stars, two layers of dust repeat a small texture over the
field (sdl_layer `scale` `tile`) and drift at different speeds by
changing their offset.  The exhaust trail of the ship is drawn into an
sdl_canvas that keeps its pixels, fading them on every tick.  The particles use additive blending
(sdl_layer `blend` `add`), so they glow where they overlap.
The renderer of the frame draws them on the GPU, so moving and rotating
them costs no Cairo drawing.  Their looks are designed as figures that
are drawn once into an sdl_texture.  The texts of the scoreboard are
ordinary graphicals that appear on top of the sprites.  The objects
that move keep their position and velocity as floats, as rounding to
pixels on every tick would make slow objects stick.  The window holds the state of the game
as a whole: the score, the lives, the level and the duration of the
current tick.  The parameters of the game are class variables of the
classes they belong to, so they can be changed in the user's xpce
defaults file.  A class variable with the same name as a variable
provides the initial value of the variable.

The game is driven by a timer.  On each tick the window sends `tick` to
all its layers and graphicals:

    send(Window?layers, for_all, message(@arg1, tick))

Each object then moves, checks whether it hits something and destroys
itself when its time is up.  `chain->for_all` works on a copy of the
chain and skips objects that are destroyed during the iteration, so a
tick may freely add and remove sprites.  The ship gets its controls
from `window<-input`, which polls the keyboard (`keyboard<-key_down`)
and the gamepad.  A sprite is moved using `sdl_layer->transform` and
rotated using `sdl_layer->angle`.  The texture of a sprite has a hot
spot at the origin of the figure it was drawn from, so the sprite
rotates around that point.  The sounds are computed as samples that are played using
an audio_stream.

Run with:

    ?- asteroids.
*/

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


%   The window holds the state of the game as a whole and drives the
%   game using a timer.  The sprites are its layers.  A key binding
%   handles p (pause), Enter (new game or resume) and F1 (help).  The
%   controls of the ship are polled on each tick.

:- pce_begin_class(asteroids_window(size), sdl_window,
                   "The field of the game").

variable(timer,        timer*, get, "Timer that drives the game").
variable(score,        int,    get, "Score of the player").
variable(lives,        int,    get, "Ships left").
variable(level,        int,    get, "Current level").
variable(mode,  {intro,playing,respawn,game_over}, get,
         "State of the game").
variable(respawn,      num,    get, "Seconds until the next ship appears").
variable(level_break,  num,    get, "Seconds left of the break after a level").
variable(paused,       bool,   get, "Game is paused").
variable(help,         bool,   get, "Show the controls").
variable(time,         num,    get, "Time of the last tick").
variable(dt,           num,    get, "Seconds since the last tick").
variable(gamepad,      any*,   get, "Gamepad used to play").
variable(trail,        sdl_canvas*, get, "Exhaust trail of the ship").

class_variable(tick,           num, 0.02, "Seconds per tick").
class_variable(lives,          int, 3,    "Ships at the start of a game").
class_variable(respawn,        num, 2.0,  "Seconds until a new ship appears").
class_variable(level_break,    num, 2.0,  "Seconds between two levels").
class_variable(max_dt,         num, 0.05, "Longest tick in seconds").
class_variable(base_asteroids, int, 3,    "Asteroids are this + level").
class_variable(star_area,      int, 5000, "Square pixels per star").
class_variable(volume,         '0.0..1.0', 0.4, "Volume of the sound effects").

initialise(P, Size:size=size) :->
    send_super(P, initialise, 'Asteroids', Size),
    send(P, background, colour(black)),
    send(P, slot, paused, @off),
    send(P, slot, help, @off),
    get_time(Now),
    send(P, slot, time, Now),
    send(P, slot, dt, 0.0),
    (   get(@display, gamepads, Pads),  % the first connected gamepad
        get(Pads, head, Pad)
    ->  send(P, slot, gamepad, Pad)
    ;   true
    ),
    send(P, recogniser, new(KB, key_binding)),
    send(KB, function,  p,    message(@receiver, toggle_paused)),
    send(KB, function, 'RET', message(@receiver, start)),
    send(KB, function,  f1,   message(@receiver, toggle_help)).

unlink(P) :->
    "Stop the timer"::
    send(P?timer, stop),
    send_super(P, unlink).

input(P, In:prolog) :<-
    "Get action from the keyboard or gamepad"::
    (   get(P, input_focus, @on)
    ->  get(P, rotate, R),
        get(P, thrust, T),
        get(P, fire, Fire),
        In = #{rotate:R, thrust:T, fire:Fire}
    ;   In = #{rotate:0, thrust:false, fire:false}
    ).

rotate(P, R:num) :<-
    "Get desired ship rotation"::
    key(cursor_left, L), key(cursor_right, Rt),
    KR is Rt - L,
    pad_rotate(P, PR),
    R is max(-1, min(1, KR + PR)).

pad_rotate(P, R) :-
    (   pad(P, Pad),
        get(Pad, axis, left_x, X),
        abs(X) > 0.25
    ->  R = X
    ;   R = 0
    ).

thrust(P, Thrust:{true,false}) :<-
    "Should the ship accelerate?"::
    (   key_down(cursor_up)
    ->  Thrust = true
    ;   pad_thrust(P)
    ->  Thrust = true
    ;   Thrust = false
    ).

pad_thrust(P) :-
    pad(P, Pad),
    (   get(Pad, button, north, @on)
    ->  true
    ;   get(Pad, axis, right_trigger, T),
        T > 0.3
    ).

fire(P, Fire:{true,false}) :<-
    "Should the ship fire?"::
    (   key_down(space)
    ->  Fire = true
    ;   pad_button(P, south)
    ->  Fire = true
    ;   Fire = false
    ).

pad_button(P, B) :-
    pad(P, Pad),
    get(Pad, button, B, @on).

pad(P, Pad) :-
    get(P, gamepad, Pad),
    Pad \== @nil,
    get(Pad, connected, @on).

%!  ->intro
%
%   Show the field with asteroids, but without a ship, and the buttons
%   to start playing.

intro(P) :->
    "Show the field before the first game"::
    send(P, reset),
    send(P, slot, mode, intro),
    send(P, new_level),
    send(P, panel).

new_game(P) :->
    "Start a new game"::
    send(P, reset),
    send(P, new_level),
    send(P, spawn_ship),
    send(P, panel).

reset(P) :->
    "Empty the field and reset the state of the game"::
    send(P, start_ticking),
    send(P?layers, for_all, message(@arg1, free)),
    send(P, clear),
    send(P, slot, score, 0),
    get(P, class_variable_value, lives, Lives),
    send(P, slot, lives, Lives),
    send(P, slot, level, 0),
    send(P, slot, respawn, 0.0),
    send(P, slot, level_break, 0.0),
    send(P, slot, paused, @off),
    send(P, slot, help, @off),
    send(P, stars),
    send(P, dust),
    send(P, trail),
    send(P, display, new(asteroids_score), point(10, 8)),
    send(P, display, new(asteroids_banner)),
    send(P, display, new(asteroids_panel(P))),
    send(P, display, new(asteroids_help)).

playing(P) :->
    "True when the player is flying, i.e., not paused or game over"::
    get(P, mode, Mode),
    memberchk(Mode, [playing, respawn]),
    get(P, paused, @off).

%!  ->panel
%
%   Show the buttons and the pointer if the game is not being played,
%   and hide them otherwise.  The help is only shown with the buttons.

panel(P) :->
    "Show or hide the buttons and the pointer"::
    get(P, member, panel, Panel),
    get(P, member, help, Help),
    (   send(P, playing)
    ->  send(Panel, displayed, @off),
        send(Help, displayed, @off),
        send(P, keyboard_focus, @nil),  % keys must reach the key binding
        send(P, cursor, none)
    ;   send(Panel, update),
        send(Panel, displayed, @on),
        send(Help, displayed, P?help),
        send(P, cursor, @nil)
    ).

start(P) :->
    "Resume a paused game or start a new one"::
    (   get(P, paused, @on),
        get(P, mode, Mode),
        Mode \== game_over
    ->  send(P, toggle_paused)
    ;   send(P, new_game)
    ).

toggle_help(P) :->
    "Show or hide the controls"::
    (   send(P, playing)
    ->  send(P, toggle_paused)          % F1 while playing pauses
    ;   true
    ),
    send(P, slot, help, P?help?negate),
    send(P, panel).

settings(P) :->
    "Edit the settings of the game"::
    class_variable_editor(P).

start_ticking(P) :->
    "Start the game ticker"::
    (   get(P, timer, @nil)
    ->  get(P, tick, Tick),
        send(P, slot, timer,
             new(Timer, timer(Tick, message(P, tick)))),
        send(Timer, start)
    ;   true
    ).

tick(P) :->
    "Advance the game one tick"::
    get_time(Now),
    get(P, time, T0),
    get(P, max_dt, MaxDt),
    Dt is min(MaxDt, Now - T0),
    send(P, slot, time, Now),
    send(P, slot, dt, Dt),
    (   get(P, paused, @on)
    ->  send(P?graphicals, for_all, message(@arg1, tick))
    ;   send(P?layers, for_all, message(@arg1, tick)),
        send(P?graphicals, for_all, message(@arg1, tick)),
        respawn(P, Dt),
        next_level(P)
    ).

new_level(P) :->
    "Start the next level with more asteroids"::
    get(P, level, Level0),
    Level is Level0 + 1,
    send(P, slot, level, Level),
    get(P, base_asteroids, Base),
    N is Base + Level,
    forall(between(1, N, _), new_asteroid(P)).

spawn_ship(P) :->
    "Put a new ship in the middle of the field"::
    get(P, width, W),
    get(P, height, H),
    X is W/2, Y is H/2,
    send(P, append, asteroids_ship(X, Y)),
    send(P, slot, mode, playing).

ship_lost(P) :->
    "The ship was destroyed"::
    get(P, lives, Lives0),
    Lives is Lives0 - 1,
    send(P, slot, lives, Lives),
    get(P, class_variable_value, respawn, RT),
    send(P, slot, respawn, RT),
    (   Lives > 0
    ->  send(P, slot, mode, respawn)
    ;   send(P, slot, mode, game_over),
        send(P, panel)
    ).

add_score(P, Points:int) :->
    "Add Points to the score"::
    get(P, score, Score0),
    Score is Score0 + Points,
    send(P, slot, score, Score).

toggle_paused(P) :->
    "Pause the game on 'p'"::
    (   get(P, mode, Mode),
        memberchk(Mode, [playing, respawn])
    ->  send(P, slot, paused, P?paused?negate),
        send(P, panel)
    ;   true
    ).

respawn(P, Dt) :-
    get(P, mode, respawn),
    !,
    get(P, respawn, Left0),
    Left is Left0 - Dt,
    (   Left =< 0
    ->  send(P, spawn_ship)
    ;   send(P, slot, respawn, Left)
    ).
respawn(_, _).

%   The field is clear.  After a break of <-level_break seconds, during
%   which the banner congratulates the player, the next level starts.

next_level(P) :-
    \+ get(P, mode, game_over),
    \+ get(P?layers, find, message(@arg1, instance_of, asteroid), _),
    !,
    get(P, level_break, Left0),
    (   Left0 > 0                       % in the break
    ->  get(P, dt, Dt),
        Left is Left0 - Dt,
        (   Left > 0
        ->  send(P, slot, level_break, Left)
        ;   send(P, slot, level_break, 0.0),
            start_level(P)
        )
    ;   get(P, class_variable_value, level_break, Break),
        (   Break > 0
        ->  send(P, slot, level_break, Break)
        ;   start_level(P)
        )
    ).
next_level(_).

%   The new asteroids appear at the edge, so the ship gets a little time
%   to get out of their way.

start_level(P) :-
    send(P, new_level),
    (   get(P?layers, find, message(@arg1, instance_of, asteroids_ship),
            Ship)
    ->  get(Ship, class_variable_value, safe, Safe),
        send(Ship, slot, safe, Safe)
    ;   true
    ).

%   A new large asteroid at the edge of the field, away from the ship.

new_asteroid(P) :-
    get(P, width, W),
    get(P, height, H),
    (   maybe
    ->  X is random_float*W, Y = 0
    ;   X = 0, Y is random_float*H
    ),
    send(P, append, asteroid(large, X, Y)).

%!  ->resize
%
%   The user resized the window.  The starfield is made anew for the
%   new size.  Objects outside a smaller field come back through the
%   edges (see wrap/5).

resize(P) :->
    "Make a new starfield for the new size"::
    send(P?layers, for_all,
         if(message(@arg1, instance_of, asteroids_star),
            message(@arg1, free))),
    send(P, stars),
    send(P?layers, for_all,             % keep the dust below the stars
         if(message(@arg1, instance_of, asteroids_dust),
            message(@arg1, hide))),
    get(P, trail, Trail),
    (   Trail == @nil
    ->  true
    ;   send(Trail, size, P?size)
    ).

%!  ->stars
%
%   The stars are put below all other layers. The number of stars depends
%   on the size of the field.

stars(P) :->
    "Add random stars below everything"::
    get(P, size, size(W,H)),
    get(P, star_area, Area),
    N is W*H//Area,
    forall(between(1, N, _),
           ( X is random(W), Y is random(H),
             random_member(Size, [1, 1, 2, 2, 3]),
             send(P, append, new(Star, asteroids_star(Size, X, Y))),
             send(Star, hide)
           )).

%!  ->trail
%
%   The exhaust trail of the ship is an sdl_canvas the size of the field
%   that is not cleared (`clear` @off).  On every tick it is drawn
%   again: a translucent black layer darkens the old pixels and a spark
%   is drawn at the tail of the ship while it thrusts (see exhaust/2).
%   The window shows the canvas using additive blending, so its black
%   adds nothing.

trail(P) :->
    "Add the canvas of the exhaust trail"::
    get(P, size, Size),
    send(P, append, new(L, asteroids_trail(Size))),
    get(L, texture, C),
    send(P, slot, trail, C).

%!  ->dust
%
%   Two layers of faint dust below the stars.  Each repeats a texture of
%   random dots over the whole field (scale `tile`) and drifts by
%   changing its offset.  The nearer layer is brighter and drifts
%   faster, which suggests depth (parallax).  As the layers cover the
%   window, they need not be made anew when it is resized.

dust(P) :->
    "Add two layers of drifting dust below everything"::
    forall(member(Depth, [near, far]),
           ( send(P, append, new(Dust, asteroids_dust(Depth))),
             send(Dust, hide)
           )).

%   Each play uses a new audio_stream that gets the samples of the
%   effect and is freed after it is played.  The samples are computed
%   the first time an effect is used.  Without an audio device, the
%   game is silent.

play(P, Effect:{fire,bang,bang_small,explosion}) :->
    "Play a sound effect"::
    (   get(@display_manager, audio_output, @on)
    ->  rate(Rate),
        effect_samples(Effect, Samples),
        get(P, volume, Volume),
        new(AS, audio_stream(s16, Rate, 1)),
        send(AS, volume, Volume),
        (   send(AS, append, Samples),
            send(AS, close),
            send(AS, play)
        ->  true
        ;   free(AS)
        )
    ;   true
    ).

effect(fire,       0.12, chirp(1400, 500)).
effect(bang,       0.35, noise(0.6)).
effect(bang_small, 0.20, noise(0.4)).
effect(explosion,  0.9,  noise(0.9)).

rate(22050).

%!  effect_samples(+Effect, -Samples:string) is det.
%
%   Samples are the 16-bit mono samples of Effect as a string of bytes.
%   audio_stream expects native byte order; we assume little endian.

:- table effect_samples/2.

effect_samples(Effect, Samples) :-
    effect(Effect, Seconds, Gen),
    rate(Rate),
    N is round(Rate*Seconds),
    findall(B,
            ( between(0, N, I),
              sample(Gen, I, N, Rate, V),
              S is max(-32767, min(32767, round(V*32767))) /\ 0xffff,
              (   B is S /\ 0xff
              ;   B is S >> 8
              )
            ), Bytes),
    string_codes(Samples, Bytes).

%   A tone sweeping from F0 to F1 and noise, both fading out.

sample(chirp(F0, F1), I, N, Rate, V) :-
    T is I/Rate,
    F is F0 + (F1-F0)*I/N,
    V is 0.5*sin(2*pi*F*T)*(1-I/N).
sample(noise(Level), I, N, _, V) :-
    Fade is (1-I/N)**2,
    V is Level*(random_float*2-1)*Fade.

:- pce_end_class(asteroids_window).


		 /*******************************
		 *	       THE SHIP		*
		 *******************************/

:- pce_begin_class(asteroids_ship(px, py), sdl_layer,
                   "The ship of the player").

variable(px,     num, get, "X of the centre").
variable(py,     num, get, "Y of the centre").
variable(vx,     num, get, "Horizontal velocity").
variable(vy,     num, get, "Vertical velocity").
variable(safe,   num, get, "Seconds the ship remains invulnerable").
variable(reload, num, get, "Seconds until the ship can fire again").

class_variable(safe,            num, 2.5,   "Seconds safe after a respawn").
class_variable(reload,          num, 0.18,  "Seconds between two shots").
class_variable(rotate_speed,    num, 270,   "Degrees/second").
class_variable(thrust,          num, 350,   "Pixels/second^2").
class_variable(max_speed,       num, 450,   "Pixels/second").
class_variable(friction,        num, 0.995, "Speed kept per tick").
class_variable(bullet_speed,    num, 550,   "Pixels/second, relative to ship").
class_variable(max_bullets,     int, 6,     "Bullets that can be in flight").
class_variable(hit_radius,      num, 12,    "Radius for collisions").
class_variable(burst_particles, int, 30,    "Particles of an explosion").

initialise(S, X:num, Y:num) :->
    texture(ship(none), Texture),
    send_super(S, initialise, Texture, @nil, none),
    send(S, slot, px, X),
    send(S, slot, py, Y),
    set_velocity(S, 0.0, 0.0),
    send(S, angle, -90),
    send(S, slot, reload, 0.0),
    place(S, X, Y).

%   The ship as a figure around (0,0), pointing to the right.  Flame is
%   the colour of the flame of the engine or `none`.

ship_figure(Flame, Fig) :-
    new(Fig, figure),
    Hull = [point(16, 0), point(-12, 10), point(-7, 0), point(-12, -10)],
    closed_path(Hull, Glow),                % a soft glow below the hull
    send(Glow, colour, colour(cyan)),
    send(Glow, pen, 7),
    send(Glow, opacity, 0.35),
    send(Fig, display, Glow),
    closed_path(Hull, Body),
    send(Body, colour, colour(white)),
    send(Body, fill, colour(midnight_blue)),
    send(Body, pen, 2),
    send(Fig, display, Body),
    (   Flame == none
    ->  true
    ;   new(FP, path),
        send_list(FP, append, [point(-9, 5), point(-20, 0), point(-9, -5)]),
        send(FP, colour, colour(Flame)),
        send(FP, pen, 2),
        send(Fig, display, FP)
    ).

tick(S) :->
    "Steer, move, fire and check for a collision"::
    get(S, device, P),
    get(P, dt, Dt),
    get(P, input, In),
    get(S, rotate_speed, RS),
    get(S, thrust, Th),
    get(S, max_speed, Max),
    get(S, friction, Fr),
    get(S, angle, Angle0),
    Angle is Angle0 + In.rotate*RS*Dt,
    send(S, angle, Angle),
    get(S, vx, VX0), get(S, vy, VY0),
    (   In.thrust == true
    ->  Rad is Angle*pi/180,
        VX1 is VX0 + cos(Rad)*Th*Dt,
        VY1 is VY0 + sin(Rad)*Th*Dt
    ;   VX1 = VX0, VY1 = VY0
    ),
    Speed is sqrt(VX1*VX1+VY1*VY1),
    (   Speed > Max
    ->  VX2 is VX1*Max/Speed, VY2 is VY1*Max/Speed
    ;   VX2 = VX1, VY2 = VY1
    ),
    VX is VX2*Fr, VY is VY2*Fr,
    set_velocity(S, VX, VY),
    move(S, X, Y, Dt),
    place(S, X, Y),
    flame(S, In.thrust),
    blink(S, Dt),
    fire(S, In.fire, Dt),
    collide(S).

%   The flame flickers by switching between textures of the ship with a
%   flame of a different colour.

flame(S, Thrust) :-
    (   Thrust == true
    ->  random_member(FC, [orange, yellow, orange_red])
    ;   FC = none
    ),
    texture(ship(FC), Texture),
    send(S, texture, Texture),
    exhaust(S, Thrust).

%   While thrusting, draw a spark at the tail of the ship into the
%   trail canvas.  The tail is 20 pixels behind the hot spot.

exhaust(S, Thrust) :-
    get(S, device, P),
    get(P, trail, Trail),
    get(Trail?layers, tail, Spark),
    (   Thrust == true
    ->  get(S, px, X), get(S, py, Y),
        get(S, angle, Angle),
        Rad is Angle*pi/180,
        TX is X - 20*cos(Rad), TY is Y - 20*sin(Rad),
        send(Spark, area, area(TX, TY, 0, 0)),
        send(Spark, displayed, @on)
    ;   send(Spark, displayed, @off)
    ).

%   Blink while invulnerable.

blink(S, Dt) :-
    get(S, safe, Safe0),
    (   Safe0 > 0
    ->  Safe is Safe0 - Dt,
        send(S, slot, safe, Safe),
        Blink is truncate(Safe*8) mod 2,
        (   Blink == 0
        ->  send(S, displayed, @on)
        ;   send(S, displayed, @off)
        )
    ;   send(S, displayed, @on)
    ).

fire(S, Fire, Dt) :-
    get(S, reload, Reload0),
    Reload is Reload0 - Dt,
    (   Fire == true,
        Reload =< 0,
        get(S, device, P),
        get(P?layers, find_all,
            message(@arg1, instance_of, asteroids_bullet), Bullets),
        get(Bullets, size, NB),
        get(S, max_bullets, Max),
        NB < Max
    ->  get(S, bullet_speed, BS),
        get(S, angle, Angle),
        get(S, px, X0), get(S, py, Y0),
        get(S, vx, VX0), get(S, vy, VY0),
        Rad is Angle*pi/180,
        X is X0 + cos(Rad)*16, Y is Y0 + sin(Rad)*16,
        VX is VX0 + cos(Rad)*BS, VY is VY0 + sin(Rad)*BS,
        send(P, append, asteroids_bullet(X, Y, VX, VY)),
        send(P, play, fire),
        get(S, class_variable_value, reload, Interval),
        send(S, slot, reload, Interval)
    ;   Left is max(0, Reload),
        send(S, slot, reload, Left)
    ).

collide(S) :-
    get(S, safe, Safe),
    Safe =< 0,
    get(S, px, X), get(S, py, Y),
    get(S, hit_radius, R),
    hit_asteroid(S, X, Y, R, _),
    !,
    get(S, device, P),
    get(S, burst_particles, NP),
    burst(P, X, Y, NP),
    send(P, play, explosion),
    send(S, free),
    send(P, ship_lost).
collide(_).

:- pce_end_class(asteroids_ship).


		 /*******************************
		 *	      BULLETS		*
		 *******************************/

:- pce_begin_class(asteroids_bullet(px, py, vx, vy), sdl_layer,
                   "A bullet fired by the ship").

variable(px,   num, get, "X of the centre").
variable(py,   num, get, "Y of the centre").
variable(vx,   num, get, "Horizontal velocity").
variable(vy,   num, get, "Vertical velocity").
variable(life, num, get, "Seconds until the bullet vanishes").

class_variable(life,       num, 1.0, "Seconds until the bullet vanishes").
class_variable(hit_radius, num, 2,   "Radius for collisions").

initialise(B, X:num, Y:num, VX:num, VY:num) :->
    texture(bullet, Texture),
    send_super(B, initialise, Texture, @nil, none),
    send(B, slot, px, X),
    send(B, slot, py, Y),
    set_velocity(B, VX, VY),
    place(B, X, Y).

%   A bullet destroys at most one asteroid.

tick(B) :->
    "Move and check whether we hit an asteroid"::
    move(B, X, Y, Dt),
    get(B, life, Life0),
    Life is Life0 - Dt,
    (   Life < 0
    ->  send(B, free)
    ;   get(B, hit_radius, R),
        hit_asteroid(B, X, Y, R, A)
    ->  send(B, free),
        send(A, explode)
    ;   send(B, slot, life, Life),
        place(B, X, Y)
    ).

:- pce_end_class(asteroids_bullet).


		 /*******************************
		 *	     ASTEROIDS		*
		 *******************************/

:- pce_begin_class(asteroid(size, px, py), sdl_layer,
                   "A rock floating through space").

variable(size,       {large,medium,small}, get, "Size class").
variable(hit_radius, int, get, "Radius for collisions").
variable(px,         num, get, "X of the centre").
variable(py,         num, get, "Y of the centre").
variable(vx,         num, get, "Horizontal velocity").
variable(vy,         num, get, "Vertical velocity").
variable(spin,       num, get, "Rotation speed in degrees/second").

class_variable(large_hit_radius,  int, 42,  "Radius of a large rock").
class_variable(medium_hit_radius, int, 24,  "Radius of a medium rock").
class_variable(small_hit_radius,  int, 13,  "Radius of a small rock").
class_variable(large_score,       int, 20,  "Points for a large rock").
class_variable(medium_score,      int, 50,  "Points for a medium rock").
class_variable(small_score,       int, 100, "Points for a small rock").
class_variable(large_min_speed,   num, 30,  "Minimal speed of a large rock").
class_variable(large_max_speed,   num, 70,  "Maximal speed of a large rock").
class_variable(medium_min_speed,  num, 50,  "Minimal speed of a medium rock").
class_variable(medium_max_speed,  num, 100, "Maximal speed of a medium rock").
class_variable(small_min_speed,   num, 70,  "Minimal speed of a small rock").
class_variable(small_max_speed,   num, 140, "Maximal speed of a small rock").
class_variable(max_spin,          num, 60,  "Maximal spin in degrees/second").
class_variable(corners,           int, 11,  "Corners of the outline").
class_variable(burst_particles,   int, 10,  "Particles of an explosion").

initialise(A, Size:{large,medium,small}, X:num, Y:num) :->
    "Create a rock of Size at X,Y with a random velocity"::
    size_property(A, Size, hit_radius, R),
    get(A, corners, N),
    findall(point(PX, PY),
            ( between(1, N, I),
              Ang is 2*pi*I/N,
              Rr is R*(0.75 + random_float*0.4),
              PX is round(cos(Ang)*Rr), PY is round(sin(Ang)*Rr)
            ), Outline),
    rock_figure(Outline, R, Fig),
    new(Texture, sdl_texture(Fig)),
    free(Fig),
    send_super(A, initialise, Texture, @nil, none),
    send(A, slot, size, Size),
    send(A, slot, hit_radius, R),
    send(A, slot, px, X),
    send(A, slot, py, Y),
    random_velocity(A, Size, VX, VY),
    set_velocity(A, VX, VY),
    get(A, max_spin, MaxSpin),
    Spin is (random_float*2-1)*MaxSpin,
    Angle is random_float*360,
    send(A, slot, spin, Spin),
    send(A, angle, Angle),
    place(A, X, Y).

%   Every rock has its own shape and colours.  We draw it as a figure
%   around (0,0) and turn that into the texture of the rock.

rock_figure(Outline, R, Fig) :-
    new(Fig, figure),
    rock_colours(Light, Dark, Edge),
    closed_path(Outline, Glow),             % soft glow around the rock
    send(Glow, colour, colour(Edge)),
    send(Glow, pen, 8),
    send(Glow, opacity, 0.3),
    send(Fig, display, Glow),
    closed_path(Outline, Rock),             % the shaded rock
    new(Shade, gradient(radial, point(0.3, 0.3), point(0.5, 0.5),
                        0, 0.6, units := bounding_box)),
    send(Shade, add_stop, 0, colour(Light)),
    send(Shade, add_stop, 1, colour(Dark)),
    send(Rock, fill, Shade),
    send(Rock, colour, colour(Edge)),
    send(Rock, pen, 2),
    send(Fig, display, Rock),
    craters(Fig, R, Dark).

tick(A) :->
    "Float and spin"::
    move(A, X, Y, Dt),
    get(A, angle, Angle0),
    get(A, spin, Spin),
    Angle is Angle0 + Spin*Dt,
    send(A, angle, Angle),
    place(A, X, Y).

hit(A, X:num, Y:num, R:num) :->
    "Test whether a circle at X,Y with radius R touches the rock"::
    get(A, px, AX), get(A, py, AY),
    get(A, hit_radius, AR),
    DX is X - AX, DY is Y - AY,
    D is AR + R,
    DX*DX + DY*DY < D*D.

explode(A) :->
    "Hit by a bullet: score, burst and split into two smaller rocks"::
    get(A, device, P),
    get(A, size, Size),
    get(A, px, X), get(A, py, Y),
    size_property(A, Size, score, Score),
    get(A, burst_particles, NP),
    send(A, free),
    send(P, add_score, Score),
    burst(P, X, Y, NP),
    (   split(Size, Smaller)
    ->  send(P, play, bang),
        forall(between(1, 2, _),
               send(P, append, asteroid(Smaller, X, Y)))
    ;   send(P, play, bang_small)
    ).

%!  size_property(+Asteroid, +Size, +Property, -Value) is det.
%
%   Value is the class variable <Size>_<Property> of Asteroid.

size_property(A, Size, Property, Value) :-
    atomic_list_concat([Size, Property], '_', Name),
    get(A, Name, Value).

split(large,  medium).
split(medium, small).

random_velocity(A, Size, VX, VY) :-
    size_property(A, Size, min_speed, Min),
    size_property(A, Size, max_speed, Max),
    Speed is Min + random_float*(Max-Min),
    Dir is random_float*2*pi,
    VX is cos(Dir)*Speed, VY is sin(Dir)*Speed.

%!  rock_colours(-Light, -Dark, -Edge) is det.
%
%   A colour scheme for an asteroid: the lit and the dark side of the
%   rock and its glowing edge.

rock_colours(Light, Dark, Edge) :-
    random_member(Light-Dark-Edge,
                  [ burlywood-saddle_brown-orange,
                    light_steel_blue-dark_slate_blue-deep_sky_blue,
                    plum-dark_violet-violet,
                    light_salmon-firebrick-orange_red,
                    pale_green-dark_olive_green-lime_green
                  ]).

%   A few craters: darker, translucent ellipses on the rock.

craters(Fig, R, Dark) :-
    N is 2 + random(2),
    forall(between(1, N, _),
           ( D is max(4, round(R*(0.2 + random_float*0.2))),
             Ang is random_float*2*pi,
             Dist is R*0.35*random_float,
             CX is round(cos(Ang)*Dist - D/2),
             CY is round(sin(Ang)*Dist - D/2),
             DH is round(D*0.8),
             new(C, ellipse(D, DH)),
             send(C, fill, colour(Dark)),
             send(C, colour, colour(black)),
             send(C, opacity, 0.6),
             send(Fig, display, C, point(CX, CY))
           )).

:- pce_end_class(asteroid).


		 /*******************************
		 *	     PARTICLES		*
		 *******************************/

%   Particles fly from an explosion and fade out during their life.

:- pce_begin_class(asteroids_particle(px, py), sdl_layer,
                   "A spark of an explosion").

variable(px,       num, get, "X of the centre").
variable(py,       num, get, "Y of the centre").
variable(vx,       num, get, "Horizontal velocity").
variable(vy,       num, get, "Vertical velocity").
variable(life,     num, get, "Seconds until the particle vanishes").
variable(lifetime, num, get, "Total life time in seconds").

class_variable(min_speed,    num, 40,  "Minimal speed in pixels/second").
class_variable(max_speed,    num, 200, "Maximal speed in pixels/second").
class_variable(min_lifetime, num, 0.4, "Minimal life time in seconds").
class_variable(max_lifetime, num, 1.0, "Maximal life time in seconds").

initialise(Pt, X:num, Y:num) :->
    random_member(Colour, [white, yellow, gold, orange, orange_red, red]),
    texture(particle(Colour), Texture),
    send_super(Pt, initialise, Texture, @nil, none),
    send(Pt, slot, px, X),
    send(Pt, slot, py, Y),
    Dir is random_float*2*pi,
    get(Pt, min_speed, MinSpeed),
    get(Pt, max_speed, MaxSpeed),
    Speed is MinSpeed + random_float*(MaxSpeed-MinSpeed),
    VX is cos(Dir)*Speed, VY is sin(Dir)*Speed,
    set_velocity(Pt, VX, VY),
    get(Pt, min_lifetime, MinLife),
    get(Pt, max_lifetime, MaxLife),
    Life is MinLife + random_float*(MaxLife-MinLife),
    send(Pt, slot, life, Life),
    send(Pt, slot, lifetime, Life),
    send(Pt, blend, add),               % overlapping sparks glow
    place(Pt, X, Y).

tick(Pt) :->
    "Fly and fade"::
    move(Pt, X, Y, Dt),
    get(Pt, life, Life0),
    Life is Life0 - Dt,
    (   Life < 0
    ->  send(Pt, free)
    ;   send(Pt, slot, life, Life),
        place(Pt, X, Y),
        get(Pt, lifetime, Total),
        Alpha is Life/Total,
        send(Pt, alpha, Alpha)
    ).

:- pce_end_class(asteroids_particle).


		 /*******************************
		 *	       STARS		*
		 *******************************/

%   A star twinkles now and then: it dims for a moment.

:- pce_begin_class(asteroids_star, sdl_layer, "A star in the background").

variable(twinkle, num, get, "Seconds left of the current twinkle").

class_variable(twinkle,         num, 0.3,  "Duration of a twinkle in seconds").
class_variable(twinkle_odds,    int, 1000, "Twinkle once in so many ticks").
class_variable(twinkle_alpha,   num, 0.3,  "Opacity of a twinkling star").

initialise(S, Size:int, X:int, Y:int) :->
    random_member(Colour, [grey40, grey60, grey80, white, light_sky_blue]),
    texture(star(Size, Colour), Texture),
    send_super(S, initialise, Texture, @nil, none),
    place(S, X, Y),
    send(S, slot, twinkle, 0.0).

tick(S) :->
    "Maybe twinkle"::
    get(S, twinkle, T0),
    (   T0 > 0
    ->  get(S?device, dt, Dt),
        T is T0 - Dt,
        (   T > 0
        ->  send(S, slot, twinkle, T)
        ;   send(S, slot, twinkle, 0.0),
            send(S, alpha, 1)
        )
    ;   get(S, twinkle_odds, Odds),
        random(Odds) =:= 0
    ->  get(S, class_variable_value, twinkle, Time),
        get(S, twinkle_alpha, Alpha),
        send(S, slot, twinkle, Time),
        send(S, alpha, Alpha)
    ;   true
    ).

:- pce_end_class(asteroids_star).


:- pce_begin_class(asteroids_trail, sdl_layer,
                   "Shows the canvas of the exhaust trail").

initialise(L, Size:size) :->
    new(C, sdl_canvas(Size)),
    send(C, clear, @off),
    new(Black, image(@nil, 1, 1, pixmap)),
    send(Black, fill, colour(black)),
    send(C, append, new(Fade, sdl_layer(sdl_texture(Black), @nil, stretch))),
    send(Fade, alpha, 0.12),
    texture(exhaust, Spark),
    send(C, append, new(S, sdl_layer(Spark, @nil, none))),
    send(S, displayed, @off),
    send_super(L, initialise, C, @nil, stretch),
    send(L, blend, add).

tick(L) :->
    "Draw the trail again: fade and add a spark"::
    get(L, texture, C),
    send(C, render).

:- pce_end_class(asteroids_trail).


:- pce_begin_class(asteroids_dust, sdl_layer, "Drifting dust in the background").

variable(ox, num, get, "Horizontal offset of the tiles").
variable(oy, num, get, "Vertical offset of the tiles").
variable(vx, num, get, "Horizontal drift in pixels/second").
variable(vy, num, get, "Vertical drift in pixels/second").

%   dust(Depth, Alpha, VX, VY)

dust(near, 0.6, -9, 4).
dust(far,  0.3, -3, 1.5).

initialise(D, Depth:{near,far}) :->
    dust(Depth, Alpha, VX, VY),
    texture(dust(Depth), Texture),
    send_super(D, initialise, Texture, @nil, tile),
    send(D, alpha, Alpha),
    send(D, slot, ox, 0.0),
    send(D, slot, oy, 0.0),
    send(D, slot, vx, VX),
    send(D, slot, vy, VY).

tick(D) :->
    "Drift"::
    get(D?device, dt, Dt),
    get(D, ox, X0), get(D, oy, Y0),
    get(D, vx, VX), get(D, vy, VY),
    X is X0 + VX*Dt, Y is Y0 + VY*Dt,
    send(D, slot, ox, X),
    send(D, slot, oy, Y),
    send(D, offset, point(X, Y)).

:- pce_end_class(asteroids_dust).


		 /*******************************
		 *	    SCOREBOARD		*
		 *******************************/

:- pce_begin_class(asteroids_score, text, "Score, lives and level").

class_variable(font, font, font(mono, bold, 16)).

initialise(T) :->
    send_super(T, initialise, ''),
    send(T, colour, colour(white)).

tick(T) :->
    "Show the state of the game"::
    get(T, device, P),
    (   get(P, mode, intro)
    ->  String = ''
    ;   get(P, score, Score),
        get(P, lives, Lives),
        get(P, level, Level),
        format(string(String), 'Score ~w   Lives ~w   Level ~w',
               [Score, Lives, Level])
    ),
    send(T, string, String).

:- pce_end_class(asteroids_score).

:- pce_begin_class(asteroids_banner, text,
                   "Message in the middle of the field").

class_variable(font,   font, font(sans, bold, 28)).
class_variable(format, name, center).

initialise(T) :->
    send_super(T, initialise, ''),
    send(T, name, banner),
    send(T, colour, colour(white)).

tick(T) :->
    "Show whether the game is over, paused or a level is done"::
    get(T, device, P),
    (   get(P, mode, intro)
    ->  String = 'ASTEROIDS'
    ;   get(P, mode, game_over)
    ->  String = 'GAME OVER'
    ;   get(P, paused, @on)
    ->  String = 'PAUSED'
    ;   get(P, level_break, Break),
        Break > 0
    ->  get(P, level, Level),
        format(string(String), 'LEVEL ~w CLEARED', [Level])
    ;   String = ''
    ),
    send(T, string, String),
    get(P, member, panel, Panel),
    get(Panel, center, point(X, Y)),
    send(T, center, point(X, Y-60)).

:- pce_end_class(asteroids_banner).


%   The buttons are shown on start-up, after the game is over and while
%   the game is paused.

:- pce_begin_class(asteroids_panel, device,
                   "Buttons to play, change the settings and get help").

class_variable(gap, int, 12, "Pixels between the buttons").

initialise(D, Field:asteroids_window) :->
    send_super(D, initialise),
    send(D, name, panel),
    send(D, display, button(play,     message(Field, start))),
    send(D, display, button(settings, message(Field, settings))),
    send(D, display, button(help,     message(Field, toggle_help))),
    send(D, layout).

layout(D) :->
    "Put the buttons next to each other"::
    get(D, gap, Gap),
    get(D, graphicals, Buttons),
    send(Buttons, for_all,
         message(D, place_button, @arg1, Gap)).

place_button(D, B:button, Gap:int) :->
    "Place B to the right of the previous button"::
    get(D?graphicals, index, B, I),
    (   I > 1
    ->  get(D?graphicals, nth1, I-1, Prev),
        get(Prev, right_side, R),
        send(B, x, R+Gap)
    ;   send(B, x, 0)
    ).

update(D) :->
    "Play resumes a paused game"::
    get(D, device, P),
    get(D, member, play, Play),
    (   get(P, paused, @on)
    ->  send(Play, label, 'Resume')
    ;   send(Play, label, 'Play')
    ),
    send(D, layout),
    send(D, tick).

tick(D) :->
    "Stay in the middle of the field, higher if the help is shown"::
    get(D, device, P),
    get(P, visible, Area),
    get(Area, center, point(X, Y)),
    (   get(P, member, help, Help),
        get(Help, displayed, @on)
    ->  get(Help, height, H),
        CY is Y - H//2
    ;   CY = Y
    ),
    send(D, center, point(X, CY)).

:- pce_end_class(asteroids_panel).


%   The controls, shown with the buttons by the help button or F1.

:- pce_begin_class(asteroids_help, figure, "The controls of the game").

class_variable(font, font, font(mono, normal, 14)).

initialise(H) :->
    send_super(H, initialise),
    send(H, name, help),
    send(H, displayed, @off),
    send(H, border, 12),
    send(H, radius, 8),
    send(H, background, colour(grey15)),
    send(H, pen, 1),
    send(H, colour, colour(grey50)),
    get(H, font, Font),
    findall(Line, help_line(Line), Lines),
    atomic_list_concat(Lines, '\n', String),
    new(T, text(String, left, Font)),
    send(T, colour, colour(white)),
    send(H, display, T).

help_line(Line) :-
    help(Key, Action),
    format(atom(Line), '~w~t~15|~w', [Key, Action]).

help('Cursor left',   'Rotate left').
help('Cursor right',  'Rotate right').
help('Cursor up',     'Thrust').
help('Space',         'Fire').
help('P',             'Pause or resume').
help('Enter',         'Play or resume').
help('F1',            'Show or hide this help').
help('Control-comma', 'Settings').
help('',              '').
help('Gamepad',       '').
help('Left stick',    'Rotate').
help('Right trigger', 'Thrust (or north button)').
help('South button',  'Fire').

tick(H) :->
    "Stay below the buttons"::
    (   get(H, displayed, @on)
    ->  get(H, device, P),
        get(P, member, panel, Panel),
        get(Panel, center_x, X),
        get(Panel, bottom_side, Y),
        send(H, center_x, X),
        send(H, y, Y+20)
    ;   true
    ).

:- pce_end_class(asteroids_help).


		 /*******************************
		 *	      SETTINGS		*
		 *******************************/

%   The settings shown by the class variable editor.

:- multifile pce_preferences:preferences/2.

pce_preferences:preferences(asteroids_window,
    [ asteroids_window - [lives, base_asteroids, respawn, level_break,
                          volume],
      asteroids_ship   - [rotate_speed, thrust, max_speed, friction,
                          reload, max_bullets, bullet_speed, safe],
      asteroid         - [max_spin, corners,
                          large_min_speed, large_max_speed,
                          medium_min_speed, medium_max_speed,
                          small_min_speed, small_max_speed]
    ]).


		 /*******************************
		 *	   SHARED HELPERS	*
		 *******************************/

%!  wrap(+Graphical, +X0, +Y0, -X, -Y) is det.
%
%   Objects leaving the field on one side come back on the other.

wrap(Gr, X0, Y0, X, Y) :-
    get(Gr, device, P),
    get(P, width, W),
    get(P, height, H),
    X is X0 - W*floor(X0/W),
    Y is Y0 - H*floor(Y0/H).

%!  move(+Sprite, -X, -Y, -Dt) is det.
%
%   Move Sprite according to its velocity for the duration of this
%   tick.  Sprite has the slots `px`, `py`, `vx` and `vy`.

move(Gr, X, Y, Dt) :-
    get(Gr?device, dt, Dt),
    get(Gr, px, X0), get(Gr, py, Y0),
    get(Gr, vx, VX), get(Gr, vy, VY),
    wrap(Gr, X0 + VX*Dt, Y0 + VY*Dt, X, Y),
    send(Gr, slot, px, X),
    send(Gr, slot, py, Y).

set_velocity(Gr, VX, VY) :-
    send(Gr, slot, vx, VX),
    send(Gr, slot, vy, VY).

key_down(Key) :-
    get(@keyboard_device, key_down, Key, @on).

key(Key, V) :-
    (   key_down(Key)
    ->  V = 1
    ;   V = 0
    ).

%!  hit_asteroid(+Graphical, +X, +Y, +R, -Asteroid) is semidet.
%
%   True when a circle at X,Y with radius R on the window of Sprite
%   touches Asteroid.

hit_asteroid(Gr, X, Y, R, A) :-
    get(Gr?device?layers, find,
        and(message(@arg1, instance_of, asteroid),
            message(@arg1, hit, X, Y, R)),
        A).

burst(P, X, Y, N) :-
    forall(between(1, N, _),
           send(P, append, asteroids_particle(X, Y))).

closed_path(Points, Path) :-
    new(Path, path),
    send_list(Path, append, Points),
    send(Path, closed, @on).

%!  place(+Sprite, +X, +Y) is det.
%
%   Move the hot spot of Sprite to X,Y.  The sprites are created with
%   `scale` `none` and no `area`, so their hot spot is at the origin of
%   the window and their transform moves them.  The sprite rotates
%   around its hot spot using `sdl_layer->angle`.  Unlike a graphical,
%   a sprite need not know the area it occupied, so we can change its
%   transform and send it again to show it.

place(Sprite, X, Y) :-
    get(Sprite, transform, T0),
    (   T0 == @nil
    ->  new(T, transform)
    ;   T = T0
    ),
    send(T, set, 1, 0, 0, 1, X, Y),
    send(Sprite, transform, T).

%!  texture(+Spec, -Texture) is det.
%
%   Texture is the sdl_texture of the sprites described by Spec.  The
%   textures are made from a figure when first needed and shared by all
%   sprites that look the same.

:- pce_global(@asteroids_textures, new(hash_table)).

texture(Spec, Texture) :-
    term_to_atom(Spec, Key),
    (   get(@asteroids_textures, member, Key, Texture)
    ->  true
    ;   texture_figure(Spec, Fig),
        new(Texture, sdl_texture(Fig)),
        free(Fig),
        send(@asteroids_textures, append, Key, Texture)
    ).

texture_figure(ship(Flame), Fig) :-
    ship_figure(Flame, Fig).
texture_figure(bullet, Fig) :-
    new(Fig, circle(4)),
    send(Fig, fill, colour(white)),
    send(Fig, colour, colour(cyan)),
    send(Fig, center, point(0, 0)).
texture_figure(exhaust, Fig) :-
    new(Fig, circle(8)),
    send(Fig, pen, 0),
    send(Fig, fill, colour(orange)),
    send(Fig, center, point(0, 0)).
texture_figure(particle(Colour), Fig) :-
    new(Fig, circle(3)),
    send(Fig, fill, colour(Colour)),
    send(Fig, colour, colour(Colour)),
    send(Fig, center, point(0, 0)).
texture_figure(dust(Depth), Fig) :-
    new(Fig, figure),                   % random dots on 256x256
    send(Fig, display, new(Tile, box(256, 256))),
    send(Tile, pen, 0),
    (   Depth == near
    ->  N = 25, Colour = grey60
    ;   N = 60, Colour = grey40
    ),
    forall(between(1, N, _),
           ( X is random(256), Y is random(256),
             send(Fig, display, new(Dot, box(1, 1)), point(X, Y)),
             send(Dot, pen, 0),
             send(Dot, fill, colour(Colour))
           )).
texture_figure(star(Size, Colour), Fig) :-
    new(Fig, box(Size, Size)),
    send(Fig, pen, 0),
    send(Fig, fill, colour(Colour)).
