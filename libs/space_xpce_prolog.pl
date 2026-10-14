:- use_module(library(pce)).
:- use_module(library(pce_main)).
:- style_check(-singleton).

% XPCE Space Backend for Cosmos (basic native canvas).
%
% Provides the Prolog predicates backing libs/space_xpce.co. Only XPCE
% calls verified against SWI-Prolog 10 are used:
%   retained graphical objects (box/circle/ellipse/arc/line/text/path),
%   picture display/clear/flush/background/foreground/pen(int),
%   timer + pce_main_loop.
% Unsafe device calls (draw_*/clip/graph_device/pointer polling) are
% deliberately NOT used: some crash the process on bad arity instead of
% failing cleanly.
%
% All public predicates take a Prefix first; an unbound prefix defaults
% to the atom `default`, so single-window programs just work.

:- dynamic space_window/2.   % space_window(Prefix, Window)
:- dynamic space_pending/3.  % space_pending(Prefix, Width, Height) from init
:- dynamic space_ink/2.      % space_window(Prefix, colour-object)
:- dynamic space_width/2.    % space_window(Prefix, WidthNumber)
:- dynamic space_font/2.       % space_font(Prefix, spec(Fam, Style, Size))
:- dynamic space_font_object/2. % space_font_object(Prefix, Font), built lazily
:- dynamic space_frame/4.    % space_frame(Prefix, IntervalMs, Callbacks, State)
:- dynamic space_last/2.     % space_last(Prefix, WallSeconds)
:- dynamic space_image/3.    % space_image(Prefix, Name, ImageObject)
:- dynamic space_xform/6.    % space_xform(Prefix, DX, DY, Angle, SX, SY)
:- dynamic space_xstack/2.   % space_xstack(Prefix, [xform(DX,DY,Angle,SX,SY)|...])
:- dynamic space_scissor/5.  % space_scissor(Prefix, X, Y, W, H) recorded only
:- dynamic space_events/2.   % space_events(Prefix, [Event|...]) oldest first
:- dynamic space_mouse/4.     % space_mouse(Prefix, X, Y, [HeldButton|...])
:- dynamic space_keys/2.      % space_keys(Prefix, [KeyName|...]) held

% --- input plumbing ---------------------------------------------------------
%
% XPCE has no polling API in this build: there is no push_event/4,
% push_global_event/4, get_event/3 or key_name/2 (the Prolog layer under
% C:\Program Files\swipl\xpce does not define them, and library(pce) exports
% only new/send/get plus the threading helpers).  Input therefore arrives as
% callbacks.  The documented hook is the ->event method of class graphical,
% redefined on a subclass:
%
%   graphical ->event: event
%     "May be redefined to modify event processing.  This is a class-level
%      alternative for graphical ->recogniser."
%
% The recogniser alternative needs a recogniser class per event kind and is
% much heavier, so ->event is what this backend uses.
%
% Two hard constraints shape everything below, both learned the hard way:
%
%  1. An XPCE error raised while the loop is running opens a MODAL dialog.
%     That dialog blocks dispatch for good, so one bad call freezes the app
%     with no way back.  catch/3 does NOT help: the error is raised in C++ and
%     aborts the goal rather than becoming a Prolog exception.  Every call in
%     space_xpce_read/4 is therefore verified against this build.
%  2. The ?/2 shortcut does not exist here -- it raises
%     existence_error(procedure, (?)/2) even after use_module(library(yall)).
%     Use get/3 and send/2,3 only.

% XPCE pushes these operators into its own compilation units rather than
% exporting them, so a client file has to declare them itself.
:- op(1200, xfx, :->).
:- op(1200, xfx, :<-).

:- pce_begin_class(space_picture, picture,
                   "Cosmos Space picture: routes XPCE input into the event queue").

event(G, Ev:event) :->
    (   space_xpce_capture(G, Ev)
    ;   true
    ),
    (   send_super(G, event, Ev)
    ;   true
    ).

:- pce_end_class.

% --- helpers ---------------------------------------------------------------

space_prefix(Prefix0, Prefix) :-
    ( var(Prefix0) -> Prefix = default ; Prefix = Prefix0 ).

space_window_checked(Prefix0, Window) :-
    space_prefix(Prefix0, Prefix),
    ( space_window(Prefix, Window) -> true
    ; space_xpce_boot_window(Prefix),
      space_window(Prefix, Window)
    ).

space_round(Value, Int) :-
    ( number(Value) -> Int is round(Value) ; Int = 0 ).

% Hex "#rrggbb" (string) or [R,G,B] number list (floats or ints) to colour.
% Anything else -- including a short "#fff", whose sub_string/5 raises
% domain_error, and non-hex digits -- falls back to white rather than
% failing.  The fallback has to be caught here: the callers
% (space_xpce_clear/2 and friends) are not wrapped, so a failure would
% propagate out of the rel and abort the frame.
space_colour(Color, Colour) :-
    (   catch(space_colour_channels(Color, R, G, B), _, fail)
    ->  true
    ;   R = 255, G = 255, B = 255
    ),
    new(Colour, colour(@default, R, G, B)).

space_colour_channels(Color, R, G, B) :-
    (   string(Color), sub_string(Color, 0, 1, _, "#") ->
        sub_string(Color, 1, 2, _, RHex),
        sub_string(Color, 3, 2, _, GHex),
        sub_string(Color, 5, 2, _, BHex),
        space_hex(RHex, R), space_hex(GHex, G), space_hex(BHex, B)
    ;   is_list(Color), Color = [R0, G0, B0], maplist(number, [R0, G0, B0]) ->
        space_channel(R0, R), space_channel(G0, G), space_channel(B0, B)
    ;   R = 255, G = 255, B = 255
    ).

space_channel(V0, V) :-
    ( V0 =< 1.0 -> V is round(V0 * 255) ; V is round(V0) ).

% Hex must be parsed from a STRING of codes.  The previous form built an
% atom ('0x1b') and called number_string/2, which throws
% type_error(list, '0x1b') on atoms -- the catch turned every channel into
% 255, so '#1b1b2f', '#3050ff' and '#000000' all rendered as pure white.
% string_codes over a "0x"-prefixed string parses correctly and throws on
% garbage, which space_colour/2 turns into the documented white fallback.
space_hex(HexString, Int) :-
    string_concat("0x", HexString, Prefixed),
    string_codes(Prefixed, Codes),
    catch(number_codes(Int, Codes), _, fail).

space_ink_for(Prefix, Colour) :-
    ( space_ink(Prefix, Colour) -> true
    ; new(Colour, colour(@default, 255, 255, 255)),
      assertz(space_ink(Prefix, Colour))
    ).

space_width_for(Prefix, Width) :-
    ( space_width(Prefix, Width) -> true ; Width = 1 ).

% XPCE objects cannot be built before the event loop has realised the
% display: `new(Font, font(...))` called at top level, before sp.start/3,
% FAILS.  That matters because a Cosmos program quite reasonably configures
% its font up front:
%
%     require('space', sp)
%     sp.setFont({size=14 and family='sans' and style='normal'})
%     sp.start(...)
%
% so setFont only records the SPEC here, and the real font object is
% materialised on first use -- by which time the loop is running.
space_font_for(Prefix, Font) :-
    (   space_font_object(Prefix, Font)
    ->  true
    ;   (   space_font(Prefix, spec(Fam, Sty, Size))
        ->  true
        ;   Fam = helvetica, Sty = roman, Size = 12
        ),
        new(Font, font(Fam, Sty, Size)),
        assertz(space_font_object(Prefix, Font))
    ).

% Fill-mode test for Cosmos "fill"/"line" strings (atoms tolerated).
space_is_fill(Mode) :- Mode == "fill", !.
space_is_fill(Mode) :- Mode == fill, !.

% Current transform -> point mapping (scale, rotate, translate).
space_apply(Prefix, X, Y, X2, Y2) :-
    ( space_xform(Prefix, DX, DY, Ang, SX, SY) -> true
    ; DX = 0, DY = 0, Ang = 0, SX = 1, SY = 1
    ),
    Cos is cos(Ang), Sin is sin(Ang),
    X2 is DX + SX * (X * Cos - Y * Sin),
    Y2 is DY + SY * (X * Sin + Y * Cos).

space_scale_factor(Prefix, F) :-
    ( space_xform(Prefix, _, _, _, SX, SY) -> F is (abs(SX) + abs(SY)) / 2.0
    ; F = 1.0
    ).

space_angle_is_zero(Prefix) :-
    ( space_xform(Prefix, _, _, Ang, _, _) -> abs(Ang) < 0.0001 ; true ).

% Display a graphical with current ink (fill and/or outline) at a point.
% Test the mode with space_is_fill/1, not by matching the atom `fill`: Cosmos
% single-quoted literals are strings, so a caller sends "fill" and a head match
% on the atom silently fell through to the outline clause. The box then had no
% fill_pattern at all and drew nothing but a default-pen outline, which is
% invisible against a dark background. space_xpce_polygon/3 already went
% through space_is_fill/1, which is why polygons filled and these did not.
space_show_shape(Window, Prefix, Obj, Mode, XI, YI) :-
    space_ink_for(Prefix, Colour),
    space_width_for(Prefix, W), space_round(W, WI),
    ( space_is_fill(Mode) ->
        send(Obj, fill_pattern, Colour)
    ; catch(send(Obj, colour, Colour), _, true)
    ),
    catch(send(Obj, pen, WI), _, true),
    send(Window, display, Obj, point(XI, YI)).

space_show_at(Window, Prefix, Obj, Mode, X, Y) :-
    space_apply(Prefix, X, Y, X2, Y2),
    space_round(X2, XI), space_round(Y2, YI),
    space_show_shape(Window, Prefix, Obj, Mode, XI, YI).

% --- init / main loop ------------------------------------------------------

space_xpce_init(Prefix0, W0, H0) :-
    space_prefix(Prefix0, Prefix),
    space_round(W0, W), space_round(H0, H),
    retractall(space_pending(Prefix, _, _)),
    assertz(space_pending(Prefix, W, H)),
    ( space_window(Prefix, Window) ->
        catch(send(Window, size, size(W, H)), _, true)
    ; true
    ),
    ( space_xform(Prefix, _, _, _, _, _) -> true
    ; assertz(space_xform(Prefix, 0, 0, 0, 1, 1))
    ).

% Create (or reuse) the window. Called from inside pce_main_loop's boot
% goal so pce_loop tracks the frame and dispatches until it is closed.
% No done_message override.  Overriding it is what made closing the window
% pop a modal "OK" dialog and leave the process alive: XPCE's handler gets
% stuck and never tears the window down.  Left alone, clicking X closes the
% picture and pce_loop ends the process by itself -- see the comment on
% space_xpce_start_loop/4, which has to cope with that.  (Verified: with
% the override a modal SWI-Prolog/OK window appears and the process
% survives; without it the process exits 0 with no dialog.)
space_xpce_boot_window(Prefix) :-
    ( space_window(Prefix, _) -> true
    ; ( space_pending(Prefix, W, H) -> true ; W = 640, H = 480 ),
      % space_picture, not picture: the subclass is what routes ->event into
      % space_xpce_capture/2.  A plain picture would simply ignore input.
      new(Window, space_picture('Cosmos Space')),
      send(Window, size, size(W, H)),
      send(Window, open),
      % window ->keyboard_focus takes a GRAPHICAL, not @on/@off; pointing it
      % at the picture is what makes keyboard events arrive here.  It has to
      % come AFTER open: asking for focus on a picture that is not on screen
      % yet is an XPCE error, which the event loop turns into a modal dialog.
      send(Window, keyboard_focus, Window),
      assertz(space_window(Prefix, Window)),
      retractall(space_events(Prefix, _)),
      retractall(space_mouse(Prefix, _, _, _)),
      retractall(space_keys(Prefix, _))
    ).

% NOTE: never destroy/hide an opened XPCE window programmatically: outside
% the XPCE event loop those calls crash the process. Just forget the state;
% the OS reclaims the window on process exit (or the user closes it, which
% halts via done_message).
space_xpce_forget_window(Prefix) :-
    retractall(space_window(Prefix, _)),
    retractall(space_frame(Prefix, _, _, _)),
    retractall(space_last(Prefix, _)),
    retractall(space_events(Prefix, _)),
    retractall(space_mouse(Prefix, _, _, _)),
    retractall(space_keys(Prefix, _)).

space_xpce_start(Prefix0, IntervalMs, Callbacks, InitialState) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_start_loop(Prefix, IntervalMs, Callbacks, InitialState).

space_xpce_start(Prefix0, IntervalMs, Callbacks, InitialState, W, H) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_init(Prefix, W, H),
    space_xpce_start_loop(Prefix, IntervalMs, Callbacks, InitialState).

space_xpce_start_loop(Prefix0, IntervalMs, Callbacks, State) :-
    space_prefix(Prefix0, Prefix),
    retractall(space_frame(Prefix, _, _, _)),
    assertz(space_frame(Prefix, IntervalMs, Callbacks, State)),
    % The window must be created inside pce_main_loop's boot goal:
    % pce_loop only dispatches frames created by that goal.
    %
    % When the user closes the window, pce_loop does NOT return -- it halts
    % the process itself, and that arrives here as the ball unwind(halt(0)).
    % So rethrow that rather than reporting it as an error and halting 1,
    % which is what a plain catch/3 would do (verified: exit code 1).
    % Reaches halt(0) below only if the loop ever does return, so that case
    % exits too instead of dropping to the interactive toplevel.
    catch(pce_main_loop(space_xpce_boot(Prefix)), E, space_xpce_loop_error(E)),
    halt(0).

space_xpce_loop_error('$abort') :- !, throw('$abort').
space_xpce_loop_error(E) :-
    (   E = unwind(_) -> throw(E) ; true ),
    print_message(error, E),
    halt(1).

% Boot goal run by pce_loop (called with argv appended).
space_xpce_boot(Prefix, _Argv) :-
    space_xpce_boot_window(Prefix),
    space_frame(Prefix, IntervalMs, _, _),
    get_time(Now),
    retractall(space_last(Prefix, _)),
    assertz(space_last(Prefix, Now)),
    Secs is IntervalMs / 1000.0,
    new(_Timer, timer(Secs, message(@prolog, space_xpce_tick, Prefix))),
    send(_Timer, start).

space_xpce_start_canvas(Prefix, Fps, Callbacks, State) :-
    Ms is 1000.0 / Fps,
    space_xpce_start(Prefix, Ms, Callbacks, State).

space_xpce_start_canvas(Prefix, Fps, Callbacks, State, W, H) :-
    Ms is 1000.0 / Fps,
    space_xpce_start(Prefix, Ms, Callbacks, State, W, H).

space_xpce_tick(Prefix) :-
    ( space_frame(Prefix, Ms, Callbacks, State),
      space_window(Prefix, Window) ->
        get_time(Now),
        ( retract(space_last(Prefix, Last)) -> Dt is Now - Last ; Dt = 0.016 ),
        assertz(space_last(Prefix, Now)),
        % XPCE has delivered whatever input arrived since the last tick.
        % Callbacks registered under "on" fire here, BEFORE update/draw, so a
        % handler sees the frame's events.  The queue is only PEEKED at: it is
        % drained by event.get/2, which is what a polling program calls from
        % update.  Draining here instead would starve every polling caller.
        space_xpce_events_pending(Prefix, Events),
        ( Events == [] -> true
        ; space_xpce_dispatch_callbacks(Prefix, Events)
        ),
        ( get_assoc("update", Callbacks, Update) ->
            catch(call_cl(Update, [Dt, State, NewState]), E,
                  ( print_message(warning, E), NewState = State ))
        ; NewState = State
        ),
        retractall(space_frame(Prefix, _, _, _)),
        assertz(space_frame(Prefix, Ms, Callbacks, NewState)),
        catch(send(Window, clear), _, true),
        ( get_assoc("draw", Callbacks, Draw) ->
            catch(call_cl(Draw, [NewState]), E2, print_message(warning, E2))
        ; true
        ),
        catch(send(Window, flush), _, true)
    ; true
    ).

% --- graphics ---------------------------------------------------------------

space_xpce_clear(Prefix0, Color) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_colour(Color, Colour),
    catch((send(Window, background, Colour), send(Window, clear)), _, true).

space_xpce_set_color(Prefix0, Color) :-
    space_prefix(Prefix0, Prefix),
    space_colour(Color, Colour),
    retractall(space_ink(Prefix, _)),
    assertz(space_ink(Prefix, Colour)).

space_xpce_rectangle(Prefix0, Mode, X0, Y0, W0, H0) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    ( space_angle_is_zero(Prefix) ->
        space_apply(Prefix, X0, Y0, XA, YA),
        space_round(XA, XI), space_round(YA, YI),
        space_xform(Prefix, _, _, _, SX, SY),
        WI is round(W0 * SX), HI is round(H0 * SY),
        new(Obj, box(WI, HI)),
        space_show_shape(Window, Prefix, Obj, Mode, XI, YI)
    ; % rotated: draw as polygon of the four corners
      X1 is X0 + W0, Y1 is Y0 + H0,
      space_xpce_polygon(Prefix0, Mode, [X0, Y0, X1, Y0, X1, Y1, X0, Y1])
    ).

space_xpce_line(Prefix0, Points) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_ink_for(Prefix, Colour),
    space_width_for(Prefix, W), space_round(W, WI),
    space_segments(Points, Segments),
    forall(member([Ax, Ay, Bx, By], Segments),
           ( space_apply(Prefix, Ax, Ay, XA, YA),
             space_apply(Prefix, Bx, By, XB, YB),
             space_round(XA, XAI), space_round(YA, YAI),
             space_round(XB, XBI), space_round(YB, YBI),
             new(Obj, line(XAI, YAI, XBI, YBI)),
             catch(send(Obj, colour, Colour), _, true),
             catch(send(Obj, pen, WI), _, true),
             send(Window, display, Obj)
           )).

space_segments([Ax, Ay, Bx, By | Rest], [[Ax, Ay, Bx, By] | Tail]) :- !,
    space_segments([Bx, By | Rest], Tail).
space_segments(_, []).

space_xpce_circle(Prefix0, Mode, X, Y, R0) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_scale_factor(Prefix, F),
    R is R0 * F,
    space_round(R, RI), D is max(1, 2 * RI),
    new(Obj, circle(D)),
    space_show_at(Window, Prefix, Obj, Mode, X - R, Y - R).

space_xpce_ellipse(Prefix0, Mode, X, Y, RX0, RY0) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_scale_factor(Prefix, F),
    RX is RX0 * F, RY is RY0 * F,
    space_round(RX, RXI), space_round(RY, RYI),
    DW is max(1, 2 * RXI), DH is max(1, 2 * RYI),
    new(Obj, ellipse(DW, DH)),
    space_show_at(Window, Prefix, Obj, Mode, X - RX, Y - RY).

space_xpce_arc(Prefix0, Mode, _ArcType, X, Y, R0, A0, A1) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_scale_factor(Prefix, F),
    R is R0 * F,
    space_round(R, RI), D is max(1, 2 * RI),
    ( space_xform(Prefix, _, _, Ang, _, _) -> B0 is A0 + Ang, B1 is A1 + Ang
    ; B0 = A0, B1 = A1
    ),
    new(Obj, arc(D, B0, B1)),
    space_show_at(Window, Prefix, Obj, Mode, X - R, Y - R).

space_xpce_polygon(Prefix0, Mode, Points) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    ( space_is_fill(Mode) ->
        space_polygon_fill(Window, Prefix, Points)
    ; space_polygon_outline(Window, Prefix, Points)
    ).

space_polygon_outline(Window, Prefix, Points) :-
    space_close_points(Points, Closed),
    space_xpce_line_for(Window, Prefix, Closed).

space_xpce_line_for(Window, Prefix, Points) :-
    space_ink_for(Prefix, Colour),
    space_width_for(Prefix, W), space_round(W, WI),
    space_segments(Points, Segments),
    forall(member([Ax, Ay, Bx, By], Segments),
           ( space_apply(Prefix, Ax, Ay, XA, YA),
             space_apply(Prefix, Bx, By, XB, YB),
             space_round(XA, XAI), space_round(YA, YAI),
             space_round(XB, XBI), space_round(YB, YBI),
             new(Obj, line(XAI, YAI, XBI, YBI)),
             catch(send(Obj, colour, Colour), _, true),
             catch(send(Obj, pen, WI), _, true),
             send(Window, display, Obj)
           )).

space_close_points([X0, Y0 | Rest], Closed) :-
    append([X0, Y0 | Rest], [X0, Y0], Closed).

% Even-odd scanline fill using 1px-high filled boxes (all XPCE-safe calls).
space_polygon_fill(Window, Prefix, Points) :-
    space_pairs(Points, Verts),
    Verts = [_ | _],
    findall(Y, (member([_, Y], Verts), space_round(Y, _)), _),
    space_bounds(Verts, _X0, YMin0, _X1, YMax0),
    space_round(YMin0, YMin), space_round(YMax0, YMax),
    space_ink_for(Prefix, Colour),
    forall(between(YMin, YMax, Y),
           space_scan_span(Verts, Y, Window, Prefix, Colour)).

space_pairs([], []).
space_pairs([X, Y | Rest], [[X, Y] | Tail]) :- space_pairs(Rest, Tail).

space_bounds([[X0, Y0] | Rest], XMin, YMin, XMax, YMax) :-
    space_extend_all(Rest, X0, Y0, X0, Y0, XMin, YMin, XMax, YMax).

space_extend_all([], Ax, Ay, Bx, By, Ax, Ay, Bx, By).
space_extend_all([[X, Y] | Rest], Ax, Ay, Bx, By, XMin, YMin, XMax, YMax) :-
    Nx is min(Ax, X), Ny is min(Ay, Y), Xx is max(Bx, X), Xy is max(By, Y),
    space_extend_all(Rest, Nx, Ny, Xx, Xy, XMin, YMin, XMax, YMax).

space_scan_span(Verts, Y, Window, Prefix, Colour) :-
    space_edge_xs(Verts, Y, Xs),
    msort(Xs, Sorted),
    space_fill_pairs(Sorted, Y, Window, Prefix, Colour).

space_edge_xs(Verts, Y, Xs) :-
    space_edges(Verts, Edges),
    findall(X, (member([[X1, Y1], [X2, Y2]], Edges),
                Y1 =\= Y2,
                Y >= min(Y1, Y2), Y < max(Y1, Y2),
                X is X1 + (Y - Y1) * (X2 - X1) / (Y2 - Y1)),
            Xs).

space_edges(Verts, Edges) :-
    Verts = [First | _],
    append(Verts, [First], Closed),
    space_adjacent(Closed, Edges).

space_adjacent([_], []) :- !.
space_adjacent([A, B | Rest], [[A, B] | Tail]) :- space_adjacent([B | Rest], Tail).
space_adjacent([], []).

space_fill_pairs([Xa, Xb | Rest], Y, Window, Prefix, Colour) :- !,
    space_apply(Prefix, Xa, Y, PXa, PY),
    space_apply(Prefix, Xb, Y, PXb, _),
    space_round(PXa, XI), space_round(PY, YI),
    space_round(PXb, XB),
    ( XB > XI ->
        W is XB - XI,
        new(Obj, box(W, 1)),
        send(Obj, fill_pattern, Colour),
        send(Window, display, Obj, point(XI, YI))
    ; true
    ),
    space_fill_pairs(Rest, Y, Window, Prefix, Colour).
space_fill_pairs(_, _, _, _, _).

space_xpce_print(Prefix0, Text, X, Y) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    ( string(Text) -> atom_string(Atom, Text) ; Atom = Text ),
    space_font_for(Prefix, Font),
    space_ink_for(Prefix, Colour),
    new(Obj, text(Atom)),
    catch(send(Obj, font, Font), _, true),
    catch(send(Obj, colour, Colour), _, true),
    space_apply(Prefix, X, Y, X2, Y2),
    space_round(X2, XI), space_round(Y2, YI),
    send(Window, display, Obj, point(XI, YI)).

% --- transform stack (Prolog-side; XPCE-safe) --------------------------------

space_xpce_push(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    ( space_xform(Prefix, DX, DY, A, SX, SY) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1,
      assertz(space_xform(Prefix, DX, DY, A, SX, SY))
    ),
    ( space_xstack(Prefix, Stack) -> retract(space_xstack(Prefix, Stack)) ; Stack = [] ),
    assertz(space_xstack(Prefix, [xform(DX, DY, A, SX, SY) | Stack])).

space_xpce_pop(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    ( space_xstack(Prefix, [xform(DX, DY, A, SX, SY) | Rest]) ->
        retract(space_xstack(Prefix, _)),
        assertz(space_xstack(Prefix, Rest)),
        retractall(space_xform(Prefix, _, _, _, _, _)),
        assertz(space_xform(Prefix, DX, DY, A, SX, SY))
    ; true
    ).

space_xpce_translate(Prefix0, TX, TY) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1
    ),
    NDX is DX + TX, NDY is DY + TY,
    assertz(space_xform(Prefix, NDX, NDY, A, SX, SY)).

space_xpce_rotate(Prefix0, Angle) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1
    ),
    NA is A + Angle,
    assertz(space_xform(Prefix, DX, DY, NA, SX, SY)).

space_xpce_scale(Prefix0, FX, FY) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1
    ),
    NSX is SX * FX, NSY is SY * FY,
    assertz(space_xform(Prefix, DX, DY, A, NSX, NSY)).

space_xpce_origin(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    retractall(space_xform(Prefix, _, _, _, _, _)),
    assertz(space_xform(Prefix, 0, 0, 0, 1, 1)).

% --- scissor (recorded; XPCE device clip is unsafe to call) ------------------

space_xpce_set_scissor(Prefix0, X0, Y0, W0, H0) :-
    space_prefix(Prefix0, Prefix),
    space_round(X0, X), space_round(Y0, Y),
    space_round(W0, W), space_round(H0, H),
    retractall(space_scissor(Prefix, _, _, _, _)),
    assertz(space_scissor(Prefix, X, Y, W, H)).

space_xpce_clear_scissor(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    retractall(space_scissor(Prefix, _, _, _, _)).

% --- line width / font / images ----------------------------------------------

space_xpce_set_line_width(Prefix0, W) :-
    space_prefix(Prefix0, Prefix),
    retractall(space_width(Prefix, _)),
    assertz(space_width(Prefix, W)).

space_xpce_set_font(Prefix0, Size0, Family, Style) :-
    space_prefix(Prefix0, Prefix),
    space_round(Size0, Size),
    space_font_name(Family, Fam),
    space_font_style(Style, Sty),
    retractall(space_font(Prefix, _)),
    % Record the SPEC, not the real font object: see space_font_for/2 for
    % why a font cannot be built before the loop realises the display.
    % Any already-materialised font is dropped so the new spec takes effect.
    assertz(space_font(Prefix, spec(Fam, Sty, Size))),
    retractall(space_font_object(Prefix, _)).

space_font_name(Family, Fam) :-
    ( Family == "serif" ; Family == serif ) -> Fam = times ;
    ( Family == "mono" ; Family == mono ) -> Fam = courier ;
    Fam = helvetica.

space_font_style(Style, Sty) :-
    ( Style == "bold" ; Style == bold ) -> Sty = bold ;
    ( Style == "italic" ; Style == italic ) -> Sty = italic ;
    Sty = roman.

space_xpce_load_image(Prefix0, Source, Name) :-
    space_prefix(Prefix0, Prefix),
    ( string(Source) -> atom_string(File, Source) ; File = Source ),
    catch((new(Image, image(File)),
           retractall(space_image(Prefix, Name, _)),
           assertz(space_image(Prefix, Name, Image))), _, true).

space_xpce_draw_image(Prefix0, Name, X, Y) :-
    space_prefix(Prefix0, Prefix),
    space_image(Prefix, Name, Image),
    space_window(Prefix, Window),
    space_apply(Prefix, X, Y, X2, Y2),
    space_round(X2, XI), space_round(Y2, YI),
    catch(send(Window, display, Image, point(XI, YI)), _, true).

% --- input ------------------------------------------------------------------
%
% space_xpce_capture/2 runs inside XPCE's event dispatch.  It must not fail
% (the guard in the ->event method above swallows failure) and, more
% importantly, must not raise: see the two constraints at the top.

space_xpce_capture(Window, Ev) :-
    ( space_xpce_prefix_of(Window, Prefix) -> true ; Prefix = default ),
    space_xpce_read(Ev, Type, Fields),
    % Build the table FIRST and pass that on.  Downstream code indexes it
    % with get_assoc/3, which needs the assoc -- passing the raw Key-Value
    % list raises "'$btree_find_node'/5: Type error: `btree' expected".
    space_event_assoc(Fields, Event),
    space_xpce_update_state(Prefix, Type, Event),
    retractall(space_events(Prefix, _)),
    ( space_events(Prefix, Queue) -> true ; Queue = [] ),
    append(Queue, [Event], Queue1),
    assertz(space_events(Prefix, Queue1)).

space_xpce_prefix_of(Window, Prefix) :-
    space_window(Prefix, Window).

% Build the Cosmos-facing event table.  A Cosmos "table" is a Prolog assoc
% (swi.pl: cosmos_type/2 maps is_assoc/1 to "Table"), so list_to_assoc/2 is
% the right bridge.
space_event_assoc(Fields, Event) :-
    list_to_assoc(Fields, Event).

% Verified accessors for this XPCE build:
%   get(Ev, id, Id)              integer (ASCII) or atom (named key / event)
%   get(Ev, position, Pt)        a point object; coords come from
%   get(Pt, x, X), get(Pt, y, Y) which is why there is no ?/2 anywhere here
%   get(Ev, button, B)           left | middle | right
%   get(Ev, multiclick, Mc)      single | double | triple
%   send(Ev, is_a, mouse)        type test
%   send(Ev, is_down|is_up|is_drag)   zero-argument behaviours (send/2)
%   send(Ev, has_modifier, s|c|m)     bare atoms; 'e' is NOT accepted
% Absent in this build: event <-modifiers, event <-click_time.
space_xpce_read(Ev, Type, Fields) :-
    get(Ev, id, Id),
    ( send(Ev, is_a, mouse) -> Mouse = true ; Mouse = false ),
    ( Mouse == true -> space_xpce_read_mouse(Ev, Id, Type, Fields)
                     ; space_xpce_read_key(Ev, Id, Type, Fields)
    ).

space_xpce_read_mouse(Ev, Id, Type, Fields) :-
    get(Ev, position, Pt),
    get(Pt, x, X0), get(Pt, y, Y0),
    ( send(Ev, is_down) -> Down = true ; Down = false ),
    ( send(Ev, is_up)   -> Up   = true ; Up   = false ),
    ( send(Ev, is_drag) -> Drag = true ; Drag = false ),
    ( catch(get(Ev, button, Button0), _, fail) -> Button = Button0 ; Button = none ),
    ( catch(get(Ev, multiclick, Clicks0), _, fail) -> Clicks = Clicks0 ; Clicks = none ),
    space_xpce_mouse_type(Id, Down, Up, Drag, Type),
    space_xpce_mods(Ev, Mod),
    space_xpce_button_number(Button, ButtonNumber),
    % The wheel ROTATION amount is deliberately not read.  The documented
    % accessor is `->attribute', and nothing in this build has been verified
    % to accept it; an XPCE error here would open a modal dialog and kill the
    % event loop (see the constraints at the top of this file).  The wheel
    % EVENT itself still arrives, with type, position and button.
    %
    % Keys are STRINGS, not atoms.  A Cosmos table is an assoc and every
    % Cosmos-level lookup goes through cosmos_get/3 with a string key, so an
    % atom-keyed assoc reads back as missing and `ev.type' yields null.
    Fields = [ "type"-Type, "mod"-Mod,
               "posx"-X0, "posy"-Y0, "x"-X0, "y"-Y0,
               "button"-ButtonNumber, "clicks"-Clicks, "wheel"-0.0 ].

space_xpce_read_key(Ev, Id, Type, Fields) :-
    space_xpce_mods(Ev, Mod),
    % space_xpce_key/3 already applies shift: XPCE reports the shifted code,
    % so `char' is the character as typed and `key' the lower-case name.
    space_xpce_key(Id, Key, Char),
    Type = "keydown",
    Fields = [ "type"-Type, "key"-Key, "char"-Char, "mod"-Mod ].

% Mouse event ids.  XPCE reports press/release/drag separately, and pointer
% motion as loc_move (moving) or loc_still (present but stationary).
space_xpce_mouse_type(Id, Down, Up, Drag, Type) :-
    (   Down == true
    ->  Type = "mousedown"
    ;   Up == true
    ->  Type = "mouseup"
    ;   Drag == true
    ->  Type = "mousemotion"
    ;   space_xpce_mouse_id(Id, Type)
    ).

space_xpce_mouse_id(loc_move, Type) :- !, Type = "mousemotion".
space_xpce_mouse_id(loc_still, Type) :- !, Type = "mousemotion".
space_xpce_mouse_id(wheel, Type) :- !, Type = "mousewheel".
% A down/up/drag id reached us with the corresponding behaviour false (XPCE
% reported it out of the usual order); fall back to the id itself.
space_xpce_mouse_id(Id, Type) :-
    atom_concat('ms_', Rest, Id),
    atom_concat(Button, Suffix, Rest),
    space_xpce_button_name(Button),
    (   suffix(Suffix, "_down") -> Type = "mousedown"
    ;   suffix(Suffix, "_up")   -> Type = "mouseup"
    ;   suffix(Suffix, "_drag") -> Type = "mousemotion"
    ;   Type = "mousemotion"
    ).
space_xpce_mouse_id(_, Type) :- Type = "mousemotion".

space_xpce_button_number(none, N) :- !, N = 0.
space_xpce_button_number(B, N) :-
    ( B == left -> N = 1 ; B == middle -> N = 2 ; B == right -> N = 3 ; N = 0 ).

space_xpce_button_name(Button) :-
    memberchk(Button, [left, middle, right]).

% Modifier string in PyGame style: any of "s" (shift), "c" (control),
% "m" (meta/super).  Only these three are accepted by has_modifier/1.
space_xpce_mods(Ev, Mods) :-
    findall(L,
            ( member(L, [s, c, m]), send(Ev, has_modifier, L) ),
            Ms),
    ( Ms == [] -> Mods = "" ; atom_chars(Mods, Ms) ).

% Key naming.  XPCE gives a printable key as its ASCII code and everything
% else as an atom from the @event_tree hierarchy.  Names are returned as
% STRINGS, not atoms: the whole event table has to be Cosmos-shaped, where
% `ev.key' is compared against string literals.
space_xpce_key(Id, Name, Char) :-
    (   integer(Id)
    ->  space_xpce_ascii_atom(Id, KeyAtom, CharAtom)
    ;   atom(Id)
    ->  (   space_xpce_named_key(Id, Named)
        ->  KeyAtom = Named, CharAtom = ''
        ;   atom_chars(Id, Chars),
            (   Chars == []
            ->  KeyAtom = '', CharAtom = ''
            ;   Chars = [C|_],
                downcase_atom(C, KeyAtom),
                CharAtom = C
            )
        )
    ;   KeyAtom = '', CharAtom = ''
    ),
    atom_string(KeyAtom, Name),
    atom_string(CharAtom, Char).

% A printable key arrives as its ASCII code, so shift is already folded into
% the number: shift+a is 65, plain a is 97.  That gives PyGame's split for
% free -- `key' is the lower-case name, `char' is the character as typed.
% Control codes carry no printable character, so char is empty for them.
space_xpce_ascii_atom(Code, KeyAtom, CharAtom) :-
    char_code(C, Code),
    (   space_xpce_control_char(C, Special)
    ->  KeyAtom = Special, CharAtom = ''
    ;   downcase_atom(C, KeyAtom), CharAtom = C
    ).

% These are CHARACTERS, not codes: the caller has already done char_code/2.
space_xpce_control_char('\b',  "backspace").
space_xpce_control_char('\t',  "tab").
space_xpce_control_char('\n',  "return").
space_xpce_control_char('\r',  "return").
space_xpce_control_char('\e',  "escape").
space_xpce_control_char(' ',   "space").

space_xpce_named_key('TAB', "tab").
space_xpce_named_key('RET', "return").
space_xpce_named_key('ESC', "escape").
space_xpce_named_key('BS',  "backspace").
space_xpce_named_key('DEL', "delete").
space_xpce_named_key(cursor_left,  "left").
space_xpce_named_key(cursor_right, "right").
space_xpce_named_key(cursor_up,    "up").
space_xpce_named_key(cursor_down,  "down").
space_xpce_named_key(cursor_home,  "home").
space_xpce_named_key(begin,         "home").
space_xpce_named_key(end,           "end").
space_xpce_named_key(page_up,       "pageup").
space_xpce_named_key(page_down,     "pagedown").
space_xpce_named_key(insert,        "insert").
space_xpce_named_key(delete,        "delete").
space_xpce_named_key(undo,          "undo").
space_xpce_named_key(redo,          "redo").
space_xpce_named_key(cancel,        "escape").
space_xpce_named_key(execute,       "enter").
space_xpce_named_key(print,         "printscreen").
space_xpce_named_key(select,        "select").
space_xpce_named_key(menu,          "menu").
space_xpce_named_key(find,          "find").
space_xpce_named_key(help,          "help").
space_xpce_named_key(pause,         "pause").
space_xpce_named_key(break,         "pause").
% f1..f12.  Name and key are the same atom, so f1 stays "f1" rather than
% collapsing to "f".
space_xpce_named_key(F, F) :-
    atom_length(F, 2),
    sub_atom(F, 0, 1, _, "f"),
    atom_number(F, N),
    between(1, 12, N).

% --- polling state ----------------------------------------------------------

% Every event carries only SOME of the fields: a keydown has no button or
% position, a mousedown has no key.  get_assoc/3 simply FAILS on a missing
% key, so a direct call would abort space_xpce_update_state/3 -- and because
% the ->event method swallows failure, the event would be silently dropped.
% All lookups therefore go through this tolerant accessor.
space_field(Key, Fields, Default, Value) :-
    (   get_assoc(Key, Fields, V)
    ->  Value = V
    ;   Value = Default
    ).

% ...and the same for the internal lookups, which use the same string keys.

space_xpce_update_state(Prefix, Type, Fields) :-
    space_field("posx", Fields, 0, X),
    space_field("posy", Fields, 0, Y),
    space_xpce_mouse_buttons(Prefix, Type, Fields, Buttons),
    retractall(space_mouse(Prefix, _, _, _)),
    assertz(space_mouse(Prefix, X, Y, Buttons)),
    (   Type == "keydown"
    ->  space_field("key", Fields, "", Key0),
        space_xpce_key_name(Key0, Key),
        retractall(space_keys(Prefix, _)),
        assertz(space_keys(Prefix, [Key]))
    ;   true
    ).

space_xpce_mouse_buttons(Prefix, Type, Fields, Buttons) :-
    ( space_mouse(Prefix, _, _, Held0) -> true ; Held0 = [] ),
    space_field("button", Fields, 0, N),
    (   Type == "mousedown"
    ->  exclude(==(N), Held0, Kept), Buttons = [N|Kept]
    ;   Type == "mouseup"
    ->  exclude(==(N), Held0, Buttons)
    ;   Buttons = Held0
    ).

% Normalise whatever a caller passed as a key name into a string.  Event
% keys arrive as strings (space_xpce_key/3), a Cosmos program passes a
% string, and an old caller may pass an atom or a number.
space_xpce_key_name(N, Name) :-
    (   string(N)
    ->  Name = N
    ;   atom(N)
    ->  atom_string(N, Name)
    ;   number_string(N, Name)
    ).

% PyGame-style event queue.  get/2 hands the accumulated list over and
% clears it, so a program that never calls get/1 does not grow the queue
% without bound -- the tail is simply dropped on the next get/2.
space_xpce_events_pending(Prefix0, Events) :-
    space_prefix(Prefix0, Prefix),
    ( space_events(Prefix, Events) -> true ; Events = [] ).

space_xpce_event_get(Prefix0, Events) :-
    space_prefix(Prefix0, Prefix),
    ( space_events(Prefix, Events) -> true ; Events = [] ),
    retractall(space_events(Prefix, _)).

space_xpce_event_get(Prefix0, Type, Events) :-
    space_prefix(Prefix0, Prefix),
    ( space_events(Prefix, All) -> true ; All = [] ),
    include(space_event_type(Type), All, Events),
    retractall(space_events(Prefix, _)).

space_event_type(Type, Event) :-
    ( get_assoc("type", Event, Type) -> true ; fail ).

% Filtering on an unbound-or-different Type simply drops the event.

space_xpce_keyboard_is_down(Prefix0, Key, 1) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_key_name(Key, Name),
    ( space_keys(Prefix, Held) -> true ; Held = [] ),
    memberchk(Name, Held), !.
space_xpce_keyboard_is_down(_, _, 0).

space_xpce_mouse_get_position(Prefix0, X, Y) :-
    space_prefix(Prefix0, Prefix),
    ( space_mouse(Prefix, X0, Y0, _) -> true ; X0 = 0, Y0 = 0 ),
    X = X0, Y = Y0.

space_xpce_mouse_is_down(Prefix0, Button, 1) :-
    space_prefix(Prefix0, Prefix),
    ( space_mouse(Prefix, _, _, Held) -> true ; Held = [] ),
    memberchk(Button, Held), !.
space_xpce_mouse_is_down(_, _, 0).

% Dispatch queued events to Love2D-style callbacks supplied in the sp.start
% map under "on".  Called from the frame tick, after XPCE has had the whole
% frame to deliver input.
space_xpce_dispatch_callbacks(Prefix, Events) :-
    space_frame(Prefix, _, Callbacks, _),
    ( get_assoc("on", Callbacks, Handlers) -> true ; Handlers = none ),
    Handlers \== none,
    forall(member(Event, Events), space_xpce_fire(Handlers, Event)),
    !.
space_xpce_dispatch_callbacks(_, _).

% Kept separate on purpose.  Nesting an if-then-else inside the conjunction
% passed to forall/2 made the parser collapse forall/2 into a call to
% forall/1, which does not exist; because this runs inside the XPCE event
% dispatch that surfaced as a modal "SWI-Prolog" error dialog that froze the
% app before a single frame ran.
space_xpce_fire(Handlers, Event) :-
    (   get_assoc("type", Event, Type),
        get_assoc(Type, Handlers, Handler)
    ->  catch(call_cl(Handler, [Event]), E, print_message(warning, E))
    ;   true
    ).

% --- timer --------------------------------------------------------------------

space_xpce_get_time(_Prefix, Time) :-
    get_time(Time).

space_xpce_get_delta(Prefix0, Delta) :-
    space_prefix(Prefix0, Prefix),
    ( space_last(Prefix, Last) -> get_time(Now), Delta is Now - Last
    ; Delta = 0.016
    ).

space_xpce_get_fps(Prefix0, Fps) :-
    space_prefix(Prefix0, Prefix),
    ( space_frame(Prefix, Ms, _, _), Ms > 0 -> Fps is 1000.0 / Ms
    ; Fps = 60.0
    ).

% --- quit ---------------------------------------------------------------------

% An explicit quit has to end the process, exactly as closing the window does
% (done_message -> message(@prolog, halt)). Retracting the window fact alone is
% not enough: pce_main_loop keeps dispatching, the tick guard then fails, and
% the result is a frozen orphan window with a live process that has to be killed
% from the task manager. halt lets process exit release the window.
space_xpce_quit(_) :-
    halt.

% dispose is currently just another name for quit.
space_xpce_dispose(Prefix0) :-
    space_xpce_quit(Prefix0).
