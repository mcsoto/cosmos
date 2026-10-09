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
:- dynamic space_font/2.     % space_window(Prefix, font-object)
:- dynamic space_frame/4.    % space_frame(Prefix, IntervalMs, Callbacks, State)
:- dynamic space_last/2.     % space_last(Prefix, WallSeconds)
:- dynamic space_image/3.    % space_image(Prefix, Name, ImageObject)
:- dynamic space_xform/6.    % space_xform(Prefix, DX, DY, Angle, SX, SY)
:- dynamic space_xstack/2.   % space_xstack(Prefix, [xform(DX,DY,Angle,SX,SY)|...])
:- dynamic space_scissor/5.  % space_scissor(Prefix, X, Y, W, H) recorded only

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

space_font_for(Prefix, Font) :-
    ( space_font(Prefix, Font) -> true
    ; new(Font, font(helvetica, roman, 12)),
      assertz(space_font(Prefix, Font))
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
      new(Window, picture('Cosmos Space')),
      send(Window, size, size(W, H)),
      send(Window, open),
      assertz(space_window(Prefix, Window))
    ).

% NOTE: never destroy/hide an opened XPCE window programmatically: outside
% the XPCE event loop those calls crash the process. Just forget the state;
% the OS reclaims the window on process exit (or the user closes it, which
% halts via done_message).
space_xpce_forget_window(Prefix) :-
    retractall(space_window(Prefix, _)),
    retractall(space_frame(Prefix, _, _, _)),
    retractall(space_last(Prefix, _)).

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
    new(Font, font(Fam, Sty, Size)),
    assertz(space_font(Prefix, Font)).

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

% --- input (stubs: XPCE has no polling API; events later) --------------------

space_xpce_keyboard_is_down(_Prefix, _Key, 0).

space_xpce_mouse_get_position(_Prefix, 0, 0).

space_xpce_mouse_is_down(_Prefix, _Button, 0).

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
