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
:- dynamic space_width/2.    % space_window(Prefix, WidthNumber)
:- dynamic space_font/2.       % space_font(Prefix, spec(Fam, Style, Size))
:- dynamic space_font_object/2. % space_font_object(Prefix, Font), built lazily
:- dynamic space_image/3.    % space_image(Prefix, Name, ImageObject)
:- dynamic space_xform/8.    % space_xform(Prefix, DX, DY, Angle, SX, SY, SHX, SHY)
:- dynamic space_xstack/2.   % space_xstack(Prefix, [xform(DX,DY,Angle,SX,SY,SHX,SHY)|...])
:- dynamic space_scissor/5.  % space_scissor(Prefix, X, Y, W, H) recorded only
:- dynamic space_mouse/4.     % space_mouse(Prefix, X, Y, [HeldButton|...])
:- dynamic space_keys/2.      % space_keys(Prefix, [KeyName|...]) held
:- dynamic space_focus/2.     % space_focus(Prefix, true|false) window has input focus
:- dynamic space_bg/2.        % space_bg(Prefix, ColourString) background colour
:- dynamic space_fg/2.        % space_fg(Prefix, ColourString) foreground colour
:- dynamic space_line_style/2. % space_line_style(Prefix, 'smooth'|'rough')
:- dynamic space_created/2.   % space_created(Prefix, Time) backend creation time
:- dynamic space_size/2.      % space_size(Prefix, size(W,H)) last known window size

% --- per-frame state ------------------------------------------------------
%
% The things that change every frame - the state the program hands back,
% the ink, the clock and the event queue - live in non-backtrackable
% globals rather than in dynamic facts.
%
% A dynamic fact has to be retracted and re-asserted to change it, and
% the retraction is the expensive half: it scans the clause store and it
% leaves the old term behind for the collector.  Measured on this
% machine, rewriting one small fact cost 2.2 us with retract/1 and
% 616 us with retractall/1, while storing the same value in a global
% costs 0.5 us.
%
% nb_linkval/2 stores the value *without copying it*, which matters for
% the state: the Cosmos state of a Space program is a table holding the
% level and the flow field, and copying it every frame was the single
% biggest cost of the backend.  The value stays alive as long as the
% global refers to it, and the caller's own reference stays valid.
%
% The event queue is the exception: it is stored with nb_setval/2, which
% copies.  An event table is built inside XPCE's event dispatch, and the
% cells of that dispatch do not survive it, so a queue that only *refers*
% to those tables comes back as half-built trees -- event tables whose
% keys and values have become unbound variables.  A half-built table is
% not an assoc any more, so get_assoc/3 fails on it and the event is
% simply not there: the queue answered "no keydown" for a key press that
% had clearly arrived.  See space_push_event/2.
%
% The event queue is kept newest-first so that adding an event is
% constant time; it is reversed when it is read.  Appending to the end
% of a list and re-asserting it was quadratic in the number of events
% that piled up between two reads.

% The globals are keyed by an atom (nb_setval/2 and friends want one),
% so the key is the kind of value with the prefix of the window
% appended.  The default window is the common case and needs no work
% at all; other prefixes pay one atom_concat, which is a lookup in the
% atom table rather than an allocation.
space_key(Kind, Prefix, Key) :-
    (   Prefix == default
    ->  Key = Kind
    ;   space_key_atom(Prefix, PrefixAtom),
        atom_concat(Kind, PrefixAtom, Key)
    ).

space_key_atom(Prefix, Atom) :-
    (   atom(Prefix)
    ->  Atom = Prefix
    ;   term_to_atom(Prefix, Atom)
    ).

space_state(Prefix, State) :-
    space_key(space_state_, Prefix, Key),
    catch(nb_getval(Key, State), _, fail).

space_set_state(Prefix, State) :-
    space_key(space_state_, Prefix, Key),
    nb_linkval(Key, State).

space_ink(Prefix, Colour) :-
    space_key(space_ink_, Prefix, Key),
    catch(nb_getval(Key, Colour), _, fail).

space_set_ink(Prefix, Colour) :-
    space_key(space_ink_, Prefix, Key),
    nb_linkval(Key, Colour).

space_last(Prefix, Time) :-
    space_key(space_last_, Prefix, Key),
    catch(nb_getval(Key, Time), _, fail).

space_set_last(Prefix, Time) :-
    space_key(space_last_, Prefix, Key),
    nb_linkval(Key, Time).

% The frame (interval and callbacks) is written once and read every
% frame; the state is what changes.
space_frame(Prefix, IntervalMs, Callbacks) :-
    space_key(space_frame_, Prefix, Key),
    catch(nb_getval(Key, Frame), _, fail),
    Frame = frame(IntervalMs, Callbacks).

space_set_frame(Prefix, IntervalMs, Callbacks) :-
    space_key(space_frame_, Prefix, Key),
    nb_linkval(Key, frame(IntervalMs, Callbacks)).

% The event queue, newest first.
%
% The queue is stored with nb_setval/2, NOT nb_linkval/2, and the copy it
% makes is what keeps the events alive.  An event table is built inside
% XPCE's event dispatch, and the cells of that dispatch do not survive it:
% a term that is only *referenced* from the global variable space (which is
% what nb_linkval/2 does) is reclaimed with the dispatch, and what comes
% back is a half-built tree -- an event table whose keys and values have
% turned into unbound variables.  A half-built table is not an assoc any
% more, so get_assoc/3 fails on it and the event disappears: the queue
% answered "no keydown" for a key press that had clearly arrived, which is
% what made the Space programs ignore the keyboard.
%
% nb_setval/2 copies the queue into the protected area of the global
% variable space, so the tables stay whole.  Reading copies as well, so the
% caller never holds cells that the next push can free.
space_events(Prefix, Events) :-
    space_key(space_events_, Prefix, Key),
    catch(nb_getval(Key, Queue), _, fail),
    copy_term(Queue, QueueCopy),
    reverse(QueueCopy, Events).

space_push_event(Prefix, Event) :-
    space_key(space_events_, Prefix, Key),
    (   catch(nb_getval(Key, Queue), _, fail)
    ->  true
    ;   Queue = []
    ),
    nb_setval(Key, [Event|Queue]).

space_clear_events(Prefix) :-
    space_key(space_events_, Prefix, Key),
    nb_delete(Key).

% Replace the queue from an oldest-first list, which is the order
% space_events/2 answers.  The queue itself is kept newest-first.
space_set_events(Prefix, Events) :-
    space_key(space_events_, Prefix, Key),
    reverse(Events, NewestFirst),
    nb_setval(Key, NewestFirst).

% Drop everything a window keeps between frames.
space_forget(Prefix) :-
    forall(member(Kind, [space_state_, space_ink_, space_last_, space_frame_, space_events_]),
           (   space_key(Kind, Prefix, Key)
           ->  nb_delete(Key)
           ;   true
           )).

% --- profiling hook --------------------------------------------------------
%
% A Space program runs until its window is closed, so it never returns to
% the caller and a profiler cannot take its measurement from the
% outside.  The hook is called once per frame so the profiler can count
% frames and write its report from inside the loop.
%
% The predicate is dynamic with a no-op default, so the cost when nobody
% is profiling is one dynamic call per frame.  The Cosmos profiler
% (compiler/platform/profile.pl) asserts its own clause in front of the
% default when it starts.
:- dynamic space_profile_frame/1.

space_profile_frame(_).

% --- input plumbing ---------------------------------------------------------
%
% XPCE 10.0.0 has TWO ways to see the keyboard, and this backend uses both.
%
% 1. Polling: the `keyboard' INPUT DEVICE class, reachable as @keyboard_device.
%    It answers whether a key is currently held:
%
%      get(@keyboard_device, key_down, Key, @on)   % held
%      get(@keyboard_device, key_down, Key, @off)  % not held
%
%    `Key' is a name XPCE understands: one of its own event names (RET, ESC,
%    TAB, BS, DEL, space, insert, pause, cursor_home, end, page_up,
%    page_down, cursor_left, cursor_right, cursor_up, cursor_down), f1..f24,
%    a single character, or the name SDL uses for the key ("Left Shift").
%    This is the API XPCE's own games use -- see prolog/demo/asteroids.pl:
%
%      key_down(Key) :- get(@keyboard_device, key_down, Key, @on).
%
%    A key XPCE does not know makes the get FAIL with "Unknown key"; that is
%    an error in C++, so it must never be allowed to reach XPCE unguarded
%    (see constraint 1 below).  space_xpce_device_key/2 validates the name
%    against the list XPCE accepts before polling.
%
% 2. Events: the ->event method of class graphical, redefined on a subclass:
%
%      graphical ->event: event
%        "May be redefined to modify event processing.  This is a class-level
%         alternative for graphical ->recogniser."
%
%    The recogniser alternative needs a recogniser class per event kind and is
%    much heavier, so ->event is what this backend uses.
%
%    XPCE 10.0.0 DOES deliver key releases.  The release event is `key_up',
%    and it sits under `any' in @event_tree rather than under `keyboard/',
%    which is why looking only under keyboard/ makes it look like it does not
%    exist.  Its id is the atom key_up; the key itself comes from
%    `event <-key', which answers the Emacs-style name of the matching
%    key-down ("a", "A", "RET", "<f1>").
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
    ; Color=fc_rgb(R,G,B) 
	; R = 255, G = 255, B = 255
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
    (   space_ink(Prefix, Colour)
    ->  true
    ;   new(Colour, colour(@default, 255, 255, 255)),
        space_set_ink(Prefix, Colour)
    ).

space_width_for(Prefix, Width) :-
    ( space_width(Prefix, Width) -> true ; Width = 1 ).

% The size of the canvas, as the window actually is.  getWidth/1 and
% getHeight/1 used to answer a hardcoded 640x480 whatever the program asked
% for in init/2, so a program that sized its window differently still got
% the wrong numbers.
space_xpce_window_size(Prefix, W, H) :-
    (   space_window(Prefix, Window),
        catch(get(Window, width, W0), _, fail),
        catch(get(Window, height, H0), _, fail),
        number(W0), number(H0)
    ->  W = W0, H = H0,
        retractall(space_size(Prefix, _)),
        assertz(space_size(Prefix, size(W0, H0)))
    ;   (   space_size(Prefix, size(W2, H2))
        ->  W = W2, H = H2
        ;   space_pending(Prefix, W3, H3)
        ->  W = W3, H = H3
        ;   W = 640, H = 480
        )
    ).

space_xpce_get_width(Prefix0, W) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_window_size(Prefix, W, _).

space_xpce_get_height(Prefix0, H) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_window_size(Prefix, _, H).

space_xpce_get_dimensions(Prefix0, Width, Height) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_window_size(Prefix, Width, Height).

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

% Current transform -> point mapping (shear, scale, rotate, translate).
%
% The order is the one the Space API describes: the current transform is
% applied to the point, and the transform stack (push/pop) holds the whole
% thing.  Shear comes first, then the scale, then the rotation and finally
% the translation.
space_apply(Prefix, X, Y, X2, Y2) :-
    ( space_xform(Prefix, DX, DY, Ang, SX, SY, SHX, SHY) -> true
    ; DX = 0, DY = 0, Ang = 0, SX = 1, SY = 1, SHX = 0, SHY = 0
    ),
    Xs is SX * (X + SHX * Y),
    Ys is SY * (Y + SHY * X),
    Cos is cos(Ang), Sin is sin(Ang),
    X2 is DX + (Xs * Cos - Ys * Sin),
    Y2 is DY + (Xs * Sin + Ys * Cos).

space_scale_factor(Prefix, F) :-
    ( space_xform(Prefix, _, _, _, SX, SY, _, _) -> F is (abs(SX) + abs(SY)) / 2.0
    ; F = 1.0
    ).

space_angle_is_zero(Prefix) :-
    ( space_xform(Prefix, _, _, Ang, _, _, _, _) -> abs(Ang) < 0.0001 ; true ).

% A sheared rectangle is not a box any more, so it is drawn as a polygon,
% like a rotated one.
space_shear_is_zero(Prefix) :-
    ( space_xform(Prefix, _, _, _, _, _, SHX, SHY) -> abs(SHX) < 0.0001, abs(SHY) < 0.0001
    ; true
    ).

% Display a graphical with current ink (fill and/or outline) at a point.
% Test the mode with space_is_fill/1, not by matching the atom `fill`: Cosmos
% single-quoted literals are strings, so a caller sends "fill" and a head match
% on the atom silently fell through to the outline clause.
%
% The method that fills a graphical in XPCE 10 is `->fill`.  It is NOT
% `->fill_pattern`: that method simply does not exist on box/circle/ellipse
% (verified -- the send fails with "No implementation for: ->fill_pattern"),
% and because the failing send aborted the caller it took every filled
% rectangle and circle with it.  `->colour` strokes the OUTLINE; a filled
% shape needs both when the fill is meant to cover the stroke too.
space_show_shape(Window, Prefix, Obj, Mode, XI, YI) :-
    space_ink_for(Prefix, Colour),
    space_width_for(Prefix, W), space_round(W, WI),
    ( space_is_fill(Mode) ->
        send(Obj, fill, Colour),
        catch(send(Obj, colour, Colour), _, true)
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
    ( space_xform(Prefix, _, _, _, _, _, _, _) -> true
    ; assertz(space_xform(Prefix, 0, 0, 0, 1, 1, 0, 0))
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
      % Drop what the previous window left behind BEFORE the new window is
      % built: opening a window can already deliver events (the keyboard
      % focus arrives with it), and clearing the queue afterwards threw those
      % away again.
      space_clear_events(Prefix),
      % space_picture, not picture: the subclass is what routes ->event into
      % space_xpce_capture/2.  A plain picture would simply ignore input.
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
      retractall(space_focus(Prefix, _))
    ).

% NOTE: never destroy/hide an opened XPCE window programmatically: outside
% the XPCE event loop those calls crash the process. Just forget the state;
% the OS reclaims the window on process exit (or the user closes it, which
% halts via done_message).
space_xpce_forget_window(Prefix) :-
    retractall(space_window(Prefix, _)),
    space_forget(Prefix),
    retractall(space_mouse(Prefix, _, _, _)),
    retractall(space_keys(Prefix, _)),
    retractall(space_focus(Prefix, _)),
    retractall(space_size(Prefix, _)).

space_xpce_start(Prefix0, IntervalMs, Callbacks, InitialState) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_start_loop(Prefix, IntervalMs, Callbacks, InitialState).

space_xpce_start(Prefix0, IntervalMs, Callbacks, InitialState, W, H) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_init(Prefix, W, H),
    space_xpce_start_loop(Prefix, IntervalMs, Callbacks, InitialState).

space_xpce_start_loop(Prefix0, IntervalMs, Callbacks, State) :-
    space_prefix(Prefix0, Prefix),
    space_set_frame(Prefix, IntervalMs, Callbacks),
    space_set_state(Prefix, State),
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
    space_frame(Prefix, IntervalMs, _),
    get_time(Now),
    space_set_last(Prefix, Now),
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
    % One frame hook, so a profiler can measure a program that never
    % returns.  A no-op unless somebody asserted a clause for it.
    space_profile_frame(Prefix),
    ( space_frame(Prefix, Ms, Callbacks),
      space_state(Prefix, State),
      space_window(Prefix, Window) ->
        get_time(Now),
        ( space_last(Prefix, Last) -> Dt is Now - Last ; Dt = 0.016 ),
        space_set_last(Prefix, Now),
        % The Space API says the held key and mouse-button state is cleared
        % when the canvas loses focus, and a key pressed while another window
        % had the focus never produces a release.  The window reports its own
        % focus, so the change is picked up here, once a frame.
        space_xpce_update_focus(Prefix, Window),
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
            catch(space_xpce_call_update(Update, Dt, State, NewState), E,
                  ( print_message(warning, E), NewState = State ))
        ; NewState = State
        ),
        space_set_state(Prefix, NewState),
        %catch(send(Window, clear), _, true),
        ( get_assoc("draw", Callbacks, Draw) ->
            catch(call_cl(Draw, [NewState]), E2, print_message(warning, E2))
        ; true
        ),
        catch(send(Window, flush), _, true)
    ; true
    ).

% Space demos use both callback shapes: update(state, newState) and
% update(dt, state, newState).  Closures retain the generated predicate name,
% so inspect its arity before invoking it instead of passing an extra dt to a
% two-argument callback.
space_xpce_call_update(Update, _Dt, State, NewState) :-
    Update = clos(_, Pred),
    current_predicate(Pred/3),
    !,
    call_cl(Update, [State, NewState]).
space_xpce_call_update(Update, Dt, State, NewState) :-
    call_cl(Update, [Dt, State, NewState]).

% --- graphics ---------------------------------------------------------------

space_xpce_clear(Prefix0, Color) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_colour(Color, Colour),
    space_xpce_remember_colour(Prefix, bg, Color),
    catch((send(Window, background, Colour), send(Window, clear)), _, true).

% The foreground colour (the ink) and the background colour are kept apart.
% setBackgroundColor used to call the same routine as setColor, so naming a
% background colour changed the colour every later drawing call used.
space_xpce_set_color(Prefix0, Color) :-
    space_prefix(Prefix0, Prefix),
    space_colour(Color, Colour),
    space_set_ink(Prefix, Colour),
    space_xpce_remember_colour(Prefix, fg, Color).

space_xpce_get_color(Prefix0, Color) :-
    space_prefix(Prefix0, Prefix),
    ( space_fg(Prefix, C) -> Color = C ; Color = "#ffffff" ).

space_xpce_set_background_color(Prefix0, Color) :-
    space_prefix(Prefix0, Prefix),
    space_colour(Color, Colour),
    space_xpce_remember_colour(Prefix, bg, Color),
    (   space_window(Prefix, Window)
    ->  catch(send(Window, background, Colour), _, true)
    ;   true
    ).

space_xpce_get_background_color(Prefix0, Color) :-
    space_prefix(Prefix0, Prefix),
    ( space_bg(Prefix, C) -> Color = C ; Color = "#000000" ).

% Remember a colour the way the program wrote it, so getColor/1 and
% getBackgroundColor/1 can hand it back unchanged.  XPCE's own colour object
% cannot answer with the string the program used.
space_xpce_remember_colour(Prefix, bg, Color) :-
    space_xpce_colour_string(Color, Hex),
    retractall(space_bg(Prefix, _)),
    assertz(space_bg(Prefix, Hex)).
space_xpce_remember_colour(Prefix, fg, Color) :-
    space_xpce_colour_string(Color, Hex),
    retractall(space_fg(Prefix, _)),
    assertz(space_fg(Prefix, Hex)).

% A colour as "#rrggbb".  A string is kept as it was written; a component
% list is turned into hex.  Anything else falls back to white, the same
% fallback space_colour/2 uses.
space_xpce_colour_string(Color, Hex) :-
    (   string(Color)
    ->  Hex = Color
    ;   catch(space_colour_channels(Color, R, G, B), _, fail)
    ->  format(atom(A), "#~2.16.0b~2.16.0b~2.16.0b", [R, G, B]),
        atom_string(A, Hex)
    ;   Hex = "#ffffff"
    ).

space_xpce_rectangle(Prefix0, Mode, X0, Y0, W0, H0) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    ( space_angle_is_zero(Prefix), space_shear_is_zero(Prefix) ->
        space_apply(Prefix, X0, Y0, XA, YA),
        space_round(XA, XI), space_round(YA, YI),
        space_xform(Prefix, _, _, _, SX, SY, _, _),
        WI is round(W0 * SX), HI is round(H0 * SY),
        new(Obj, box(WI, HI)),
        space_show_shape(Window, Prefix, Obj, Mode, XI, YI)
    ; % rotated or sheared: draw as polygon of the four corners
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

% A single point.  XPCE has no dot primitive, so a one-pixel filled box
% stands in for it.
space_xpce_point(Prefix0, X, Y) :-
    space_xpce_points(Prefix0, [X, Y]).

% Several points, each its own dot.
space_xpce_points(Prefix0, Points) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_ink_for(Prefix, Colour),
    space_pairs(Points, Verts),
    forall(member([X, Y], Verts),
           ( space_apply(Prefix, X, Y, XA, YA),
             space_round(XA, XI), space_round(YA, YI),
             new(Obj, box(1, 1)),
             catch(send(Obj, fill, Colour), _, true),
             send(Window, display, Obj, point(XI, YI))
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

% An arc.
%
% Three things the Space API and XPCE disagree about, all of which made
% every arc come out wrong:
%   * XPCE wants DEGREES, the Space API speaks RADIANS.
%   * XPCE's third argument is the SIZE of the sweep, not its end angle.
%   * XPCE's first argument is the RADIUS, not the diameter.
%
% The angles keep the Space API's convention: 0 is the positive x-axis and
% they grow counter-clockwise on screen, which is what XPCE does as well.
space_xpce_arc(Prefix0, Mode, ArcType, X, Y, R0, A0, A1) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    space_scale_factor(Prefix, F),
    R is R0 * F,
    space_round(R, RI),
    D is max(1, RI),
    ( space_xform(Prefix, _, _, Ang, _, _, _, _) -> B0 is A0 + Ang, B1 is A1 + Ang
    ; B0 = A0, B1 = A1
    ),
    D0 is B0 * 180.0 / pi,
    D1 is B1 * 180.0 / pi,
    Size is D1 - D0,
    new(Obj, arc(D, D0, Size)),
    space_xpce_arc_close(ArcType, Obj),
    space_show_at(Window, Prefix, Obj, Mode, X - R, Y - R).

% The Space API spells the two kinds of arc 'open' and 'pie'; XPCE closes an
% arc with none, pie_slice or chord.
space_xpce_arc_close(ArcType, Obj) :-
    (   space_xpce_arc_type(ArcType, Close)
    ->  catch(send(Obj, close, Close), _, true)
    ;   true
    ).

space_xpce_arc_type(ArcType, pie_slice) :-
    (   ArcType == "pie" ; ArcType == pie ; ArcType == "pie_slice" ), !.
space_xpce_arc_type(ArcType, chord) :-
    (   ArcType == "chord" ; ArcType == chord ), !.
space_xpce_arc_type(_, none).

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
        send(Obj, fill, Colour),
        send(Window, display, Obj, point(XI, YI))
    ; true
    ),
    space_fill_pairs(Rest, Y, Window, Prefix, Colour).
space_fill_pairs(_, _, _, _, _).

% Draw text.  The point is the TOP-LEFT of the text, which is the
% convention the Space API uses and the one XPCE's text objects already
% follow.
space_xpce_print(Prefix0, Text, X, Y) :-
    space_xpce_print_at(Prefix0, Text, X, Y, none, 0.0).

% printf/5: the text is laid out inside a box of the given width and
% aligned in it.  The width was ignored before, so a right-aligned line came
% out at the left edge of the box.
space_xpce_printf(Prefix0, Text, X, Y, Width, Align) :-
    space_xpce_print_at(Prefix0, Text, X, Y, Align, Width).

space_xpce_print_at(Prefix0, Text, X, Y, Align, Width) :-
    space_window_checked(Prefix0, Window),
    space_prefix(Prefix0, Prefix),
    ( string(Text) -> atom_string(Atom, Text) ; Atom = Text ),
    space_font_for(Prefix, Font),
    space_ink_for(Prefix, Colour),
    new(Obj, text(Atom)),
    catch(send(Obj, font, Font), _, true),
    catch(send(Obj, colour, Colour), _, true),
    space_xpce_text_width(Prefix, Obj, Atom, TW),
    space_xpce_align_offset(Align, Width, TW, DX),
    space_apply(Prefix, X + DX, Y, X2, Y2),
    space_round(X2, XI), space_round(Y2, YI),
    send(Window, display, Obj, point(XI, YI)).

% The width of a text object.  XPCE can measure a text object, but one that
% was never displayed may not have a size yet, so the font size times a
% rough per-character width is the fallback.
space_xpce_text_width(Prefix, Obj, Text, TW) :-
    (   catch(get(Obj, size, Size), _, fail),
        catch(get(Size, width, W), _, fail),
        number(W)
    ->  TW = W
    ;   ( space_font(Prefix, spec(_, _, FontSize)) -> true ; FontSize = 12 ),
        atom_length(Text, Len),
        TW is 0.6 * FontSize * Len
    ).

% Where the text starts inside the box it was given.
space_xpce_align_offset(Align, Width, TW, DX) :-
    (   ( Align == "center" ; Align == center )
    ->  DX is (Width - TW) / 2
    ;   ( Align == "right" ; Align == right )
    ->  DX is Width - TW
    ;   DX = 0.0
    ).

% --- transform stack (Prolog-side; XPCE-safe) --------------------------------

space_xpce_push(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    ( space_xform(Prefix, DX, DY, A, SX, SY, SHX, SHY) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1, SHX = 0, SHY = 0,
      assertz(space_xform(Prefix, DX, DY, A, SX, SY, SHX, SHY))
    ),
    ( space_xstack(Prefix, Stack) -> retract(space_xstack(Prefix, Stack)) ; Stack = [] ),
    assertz(space_xstack(Prefix, [xform(DX, DY, A, SX, SY, SHX, SHY) | Stack])).

space_xpce_pop(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    ( space_xstack(Prefix, [xform(DX, DY, A, SX, SY, SHX, SHY) | Rest]) ->
        retract(space_xstack(Prefix, _)),
        assertz(space_xstack(Prefix, Rest)),
        retractall(space_xform(Prefix, _, _, _, _, _, _, _)),
        assertz(space_xform(Prefix, DX, DY, A, SX, SY, SHX, SHY))
    ; true
    ).

space_xpce_translate(Prefix0, TX, TY) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY, SHX, SHY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1, SHX = 0, SHY = 0
    ),
    NDX is DX + TX, NDY is DY + TY,
    assertz(space_xform(Prefix, NDX, NDY, A, SX, SY, SHX, SHY)).

space_xpce_rotate(Prefix0, Angle) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY, SHX, SHY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1, SHX = 0, SHY = 0
    ),
    NA is A + Angle,
    assertz(space_xform(Prefix, DX, DY, NA, SX, SY, SHX, SHY)).

space_xpce_scale(Prefix0, FX, FY) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY, SHX, SHY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1, SHX = 0, SHY = 0
    ),
    NSX is SX * FX, NSY is SY * FY,
    assertz(space_xform(Prefix, DX, DY, A, NSX, NSY, SHX, SHY)).

% Shear was a no-op before, which drew the shape as if it had not been
% sheared at all -- the picture was silently wrong rather than absent.
space_xpce_shear(Prefix0, SHX, SHY) :-
    space_prefix(Prefix0, Prefix),
    ( retract(space_xform(Prefix, DX, DY, A, SX, SY, OldX, OldY)) -> true
    ; DX = 0, DY = 0, A = 0, SX = 1, SY = 1, OldX = 0, OldY = 0
    ),
    % The factors compose: a second shear multiplies into the first.
    NewX is OldX + SHX,
    NewY is OldY + SHY,
    assertz(space_xform(Prefix, DX, DY, A, SX, SY, NewX, NewY)).

space_xpce_origin(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    retractall(space_xform(Prefix, _, _, _, _, _, _, _)),
    assertz(space_xform(Prefix, 0, 0, 0, 1, 1, 0, 0)).

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

% The scissor rectangle.  It was reported as a hardcoded 640x480 whatever
% the window was; with no scissor set the whole canvas is the answer.
space_xpce_get_scissor(Prefix0, X, Y, W, H) :-
    space_prefix(Prefix0, Prefix),
    (   space_scissor(Prefix, X0, Y0, W0, H0)
    ->  X = X0, Y = Y0, W = W0, H = H0
    ;   space_xpce_window_size(Prefix, WW, HH),
        X = 0, Y = 0, W = WW, H = HH
    ).

% --- line width / font / images ----------------------------------------------

space_xpce_set_line_width(Prefix0, W) :-
    space_prefix(Prefix0, Prefix),
    retractall(space_width(Prefix, _)),
    assertz(space_width(Prefix, W)).

space_xpce_get_line_width(Prefix0, W) :-
    space_prefix(Prefix0, Prefix),
    ( space_width(Prefix, Width) -> W = Width ; W = 1.0 ).

% The line style.  XPCE has no rough/smooth switch of its own -- its lines
% are antialiased -- so the style is remembered and answered back, and
% 'rough' is approximated by leaving the pen alone.
space_xpce_set_line_style(Prefix0, Style) :-
    space_prefix(Prefix0, Prefix),
    (   ( Style == "rough" ; Style == rough )
    ->  Kept = "rough"
    ;   Kept = "smooth"
    ),
    retractall(space_line_style(Prefix, _)),
    assertz(space_line_style(Prefix, Kept)).

space_xpce_get_line_style(Prefix0, Style) :-
    space_prefix(Prefix0, Prefix),
    ( space_line_style(Prefix, S) -> Style = S ; Style = "smooth" ).

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

% The font in use, as the Space API spells it.  getFont/1 used to answer a
% hardcoded size 12 sans-serif whatever had been set.
space_xpce_get_font(Prefix0, Size, Family, Style) :-
    space_prefix(Prefix0, Prefix),
    (   space_font(Prefix, spec(Fam, Sty, Sz))
    ->  Size = Sz,
        ( space_xpce_family_name(Fam, Family) -> true ; Family = "sans" ),
        ( space_xpce_style_name(Sty, Style) -> true ; Style = "normal" )
    ;   Size = 12, Family = "sans", Style = "normal"
    ).

space_xpce_family_name(helvetica, "sans").
space_xpce_family_name(times, "serif").
space_xpce_family_name(courier, "mono").

space_xpce_style_name(roman, "normal").
space_xpce_style_name(bold, "bold").
space_xpce_style_name(italic, "italic").

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

debug_write(X,Y) :- true. %write(X), writeln(Y).


space_xpce_capture(Window, Ev) :-
    ( space_xpce_prefix_of(Window, Prefix) -> true ; Prefix = default ),
    space_xpce_read(Ev, Type, Fields),
    % Build the table FIRST and pass that on.  Downstream code indexes it
    % with get_assoc/3, which needs the assoc -- passing the raw Key-Value
    % list raises "'$btree_find_node'/5: Type error: `btree' expected".
    space_event_assoc(Fields, Event),
    space_xpce_update_state(Prefix, Type, Event),
    space_push_event(Prefix, Event),
	debug_write("Ev:",Fields),
    % A key press that carries a printable character is also text input.
    space_xpce_text_input(Prefix, Type, Event),!.

% Text input: the character a key press produced.  XPCE only reports real
% text input for a text item that holds the focus; a plain canvas gets the
% character from the key press instead, so that is where it comes from.
space_xpce_text_input(Prefix, Type, Event) :-
    Type == "keydown",
    !,
    (   get_assoc("char", Event, Char), Char \== ""
    ->  space_event_assoc([ "type"-textinput, "text"-Char ], TextEvent),
        space_push_event(Prefix, TextEvent)
    ;   true
    ).

% A resize of the window is reported as an event.  XPCE calls the message
% after the window has been resized, so the size read here is the new one.
space_xpce_resize(Prefix) :-
    (   space_window(Prefix, Window),
        catch(get(Window, width, W), _, fail),
        catch(get(Window, height, H), _, fail),
        number(W), number(H)
    ->  retractall(space_size(Prefix, _)),
        assertz(space_size(Prefix, size(W, H))),
        space_event_assoc([ "type"-resize, "width"-W, "height"-H ], Event),
        space_push_event(Prefix, Event)
    ;   true
    ).

space_xpce_prefix_of(Window, Prefix) :-
    space_window(Prefix, Window).

% The Space API says the held key and mouse-button state is cleared when the
% canvas loses focus.  XPCE reports the focus of the window, so the change
% is noticed once a frame.
%
% Losing focus also has to clear the SET of held keys: a key that was down
% when the window lost the focus never gets a release event, so the set
% would keep saying it is held for ever.  The keyboard device does not have
% that problem -- it reports the hardware -- but the set is the fallback
% when the device is not available, so it has to be cleaned too.
space_xpce_update_focus(Prefix, Window) :-
    (   catch(get(Window, input_focus, Focus), _, fail)
    ->  true
    ;   Focus = @off
    ),
    (   Focus == @on
    ->  HasFocus = true
    ;   HasFocus = false
    ),
    (   space_focus(Prefix, Was) -> true ; Was = false ),
    retractall(space_focus(Prefix, _)),
    assertz(space_focus(Prefix, HasFocus)),
    (   Was == HasFocus
    ->  true
    ;   retractall(space_keys(Prefix, _)),
        assertz(space_keys(Prefix, [])),
        retractall(space_mouse(Prefix, _, _, _)),
        assertz(space_mouse(Prefix, 0, 0, [])),
        (   HasFocus
        ->  Type = "focus"
        ;   Type = "blur"
        ),
        space_event_assoc([ "type"-Type ], Event),
        space_push_event(Prefix, Event)
    ).

% Build the Cosmos-facing event table.  A Cosmos "table" is a Prolog assoc
% (swi.pl: cosmos_type/2 maps is_assoc/1 to "Table"), so list_to_assoc/2 is
% the right bridge.
space_event_assoc(Fields, Event) :-
    list_to_assoc(Fields, Event).

% Verified accessors for this XPCE build:
%   get(Ev, id, Id)              integer (ASCII) or atom (named key / event)
%   get(Ev, key, K)              the Emacs-style name of a key event; for a
%                                 key_up it is the name of the key that was
%                                 released
%   get(Ev, position, Pt)        a point object; coords come from
%   get(Pt, x, X), get(Pt, y, Y) which is why there is no ?/2 anywhere here
%   get(Ev, button, B)           left | middle | right
%   get(Ev, multiclick, Mc)      single | double | triple
%   get(Ev, rotation, R)         wheel rotation in 1/15th of a notch; @nil
%                                 for every other event
%   send(Ev, is_a, mouse)        type test
%   send(Ev, is_a, key_up)       type test: a key release
%   send(Ev, is_down|is_up|is_drag)   zero-argument behaviours (send/2)
%   send(Ev, has_modifier, s|c|m)     bare atoms; 'e' is NOT accepted
% Absent in this build: event <-modifiers, event <-click_time, event <-dy.
% An event is a MOUSE event, a KEY event, or neither.  The distinction
% matters: XPCE also delivers focus management to the graphical that holds
% the keyboard focus (obtain_keyboard_focus, activate_keyboard_focus,
% deactivate_keyboard_focus), and those are neither.  They used to be read as
% key presses here, and space_xpce_key/3 then named them after their FIRST
% LETTER -- obtain_keyboard_focus became the key "o" -- so every program saw
% a bogus key press as soon as its window came up.  The Space API reports the
% focus separately (the backend polls input_focus for that), so these events
% are simply not queued.
%
% A key press is recognised three ways, and any one of them is enough:
%   * the id is an integer -- the ASCII code of the character as typed;
%   * the id is an atom that names a key (RET, TAB, cursor_left, f1 ...), or
%     is a single character;
%   * the event answers `event <-key', which XPCE gives for every key
%     event, key press and key release alike.
% The last test is the one that matters most: it needs no list of key names,
% so a key this file has never heard of is still recognised as a key.
space_xpce_read(Ev, Type, Fields) :-
    get(Ev, id, Id),
    (   send(Ev, is_a, mouse)
    ->  space_xpce_read_mouse(Ev, Id, Type, Fields)
    ;   send(Ev, is_a, key_up)
    ->  space_xpce_read_key(Ev, Id, Type, Fields)
    ;   space_xpce_key_event(Ev, Id)
    ->  space_xpce_read_key(Ev, Id, Type, Fields)
    ;   fail
    ).

% Is this event a key press?
space_xpce_key_event(Ev, Id) :-
    (   integer(Id)
    ->  true
    ;   atom(Id),
        (   space_xpce_named_key(Id, _)
        ->  true
        ;   atom_length(Id, 1)
        ->  true
        ;   catch(get(Ev, key, _), _, fail)
        )
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
    % The wheel ROTATION is read from event <-rotation, which is an ordinary
    % get method and answers a non-number for every event that is not a
    % wheel.  It reports 1/15th of a notch, so a whole notch is 15.
    (   catch(get(Ev, rotation, Rot0), _, fail), number(Rot0)
    ->  Wheel is Rot0 / 15.0
    ;   Wheel = 0.0
    ),
    % Keys are STRINGS, not atoms.  A Cosmos table is an assoc and every
    % Cosmos-level lookup goes through cosmos_get/3 with a string key, so an
    % atom-keyed assoc reads back as missing and `ev.type' yields null.
    Fields = [ "type"-Type, "mod"-Mod,
               "posx"-X0, "posy"-Y0, "x"-X0, "y"-Y0,
               "button"-ButtonNumber, "clicks"-Clicks, "wheel"-Wheel ].

% A key release is an event of its own: the id is the atom key_up and the
% key it releases is NOT in the id but in `event <-key', which answers the
% Emacs-style name of the matching key-down.  A key press is identified by
% its id: an integer for a printable character (the code of the character as
% typed, so shift is already folded in) or an atom for a named key.
space_xpce_read_key(Ev, Id, Type, Fields) :-
    space_xpce_mods(Ev, Mod),
    (   send(Ev, is_a, key_up)
    ->  Type = "keyup",
        (   catch(get(Ev, key, Released0), _, fail)
        ->  space_xpce_emacs_key(Released0, Key)
        ;   Key = ""
        ),
        Char = ""
    ;   Type = "keydown",
        % space_xpce_key/3 already applies shift: XPCE reports the shifted
        % code, so `char' is the character as typed and `key' the lower-case
        % name.
        space_xpce_key(Id, Key, Char)
    ),
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

% Space numbers its mouse buttons like the browser canvas and Love2D do:
% 1 left, 2 right, 3 middle.  XPCE names them left/right/middle, so the
% mapping is not the identity -- getting it wrong swaps the right and the
% middle button, which is exactly the kind of bug nobody notices until a
% right-click menu opens in the wrong place.
space_xpce_button_number(none, N) :- !, N = 0.
space_xpce_button_number(B, N) :-
    ( B == left -> N = 1 ; B == right -> N = 2 ; B == middle -> N = 3 ; N = 0 ).

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
%
% Three naming schemes meet in this file:
%
%   * the EVENT ID: an integer for a printable character -- the code of the
%     character as typed, so shift is already folded in -- or an atom for a
%     named key.  space_xpce_key/3 turns this into a Love2D name.
%   * `event <-key': the Emacs-style name of a key event ("a", "A", "RET",
%     "SPC", "<cursor_left>", "\C-a").  A key RELEASE carries its key this
%     way, because the release event's id is only the atom key_up.
%     space_xpce_emacs_key/2 turns this into a Love2D name.
%   * the Love2D NAMES the Space API speaks: lowercase, "left", "return",
%     "space", "f1".  space_xpce_device_key/2 turns one of those into the
%     name the XPCE keyboard device understands.
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

% `event <-key' on a key release answers the Emacs-style name of the
% matching key-down, so the two sides of a press/release pair always agree:
% a press of "a" is answered "a" and its release is answered "a" too; a
% press of shift+a is answered "A" and its release is answered "A".
%
% The names XPCE produces are:
%   "a" .. "z", "A" .. "Z"   the character as typed
%   "SPC" "RET" "TAB" "BS" "DEL"   the named keys
%   "\e"                  escape
%   "<cursor_left>" "<f1>" "<page_up>" ...   the lower-case named keys and
%                            the function keys, in angle brackets
%   "\C-a" "\e-x"         with a control or meta modifier in front
space_xpce_emacs_key(Raw, Name) :-
    atom_string(Raw, Text0),
    (   Text0 == "\\e"
    % The escape key is reported as "\e" -- the same prefix a meta key
    % gets, but on its own.  It has to be recognised before the prefix is
    % stripped, or the name comes out empty.
    ->  Name = "escape"
    ;   space_xpce_strip_modifiers(Text0, Text),
        (   space_xpce_emacs_named(Text, Love)
        ->  Name = Love
        ;   atom_string(Atom, Text),
            downcase_atom(Atom, Lower),
            atom_string(Lower, Name)
        )
    ).

% Strip the modifier prefixes XPCE puts in front: "\C-" (control), "\e"
% (meta), "\S-" (shift) and "\s-" (gui).
%
% The After argument is pinned to 0: sub_string/5 enumerates every split
% when it is left open, and the first one it offers for "\C-a" is the
% EMPTY string, so the name came out as nothing at all.
space_xpce_strip_modifiers(Text0, Text) :-
    (   sub_string(Text0, 0, 3, _, "\\C-")
    ->  sub_string(Text0, 3, _, 0, Rest), space_xpce_strip_modifiers(Rest, Text)
    ;   sub_string(Text0, 0, 3, _, "\\S-")
    ->  sub_string(Text0, 3, _, 0, Rest), space_xpce_strip_modifiers(Rest, Text)
    ;   sub_string(Text0, 0, 3, _, "\\s-")
    ->  sub_string(Text0, 3, _, 0, Rest), space_xpce_strip_modifiers(Rest, Text)
    ;   sub_string(Text0, 0, 2, _, "\\e")
    ->  sub_string(Text0, 2, _, 0, Rest), space_xpce_strip_modifiers(Rest, Text)
    ;   Text = Text0
    ).

% The named keys, in the two spellings XPCE uses: bare (SPC, RET, ...) and
% in angle brackets (the lower-case ones and the function keys).
space_xpce_emacs_named("SPC", "space").
space_xpce_emacs_named("RET", "return").
space_xpce_emacs_named("TAB", "tab").
space_xpce_emacs_named("BS",  "backspace").
space_xpce_emacs_named("DEL", "delete").
space_xpce_emacs_named("\\e", "escape").
space_xpce_emacs_named("<cursor_left>",  "left").
space_xpce_emacs_named("<cursor_right>", "right").
space_xpce_emacs_named("<cursor_up>",    "up").
space_xpce_emacs_named("<cursor_down>",  "down").
space_xpce_emacs_named("<cursor_home>",  "home").
space_xpce_emacs_named("<begin>",        "home").
space_xpce_emacs_named("<end>",          "end").
space_xpce_emacs_named("<page_up>",      "pageup").
space_xpce_emacs_named("<page_down>",    "pagedown").
space_xpce_emacs_named("<insert>",       "insert").
space_xpce_emacs_named("<pause>",        "pause").
space_xpce_emacs_named("<print>",        "printscreen").
space_xpce_emacs_named("<scroll_lock>",  "scrolllock").
space_xpce_emacs_named("<num_lock>",     "numlock").
space_xpce_emacs_named("<caps_lock>",    "capslock").
% f1 .. f24, in the angle-bracket spelling XPCE uses: "<f1>".
%
% atom_string/2 takes the ATOM first and answers the string, so the name
% has to come out of the SECOND argument: the other way round the key came
% back as the atom f1 instead of the string "f1", and a program comparing
% it against "f1" never matched.
space_xpce_emacs_named(Text, F) :-
    sub_string(Text, 0, 1, _, "<"),
    sub_string(Text, _, 1, 0, ">"),
    sub_string(Text, 1, _, 1, Inner),
    atom_string(Atom, Inner),
    space_xpce_function_number(Atom, _),
    atom_string(Inner, F).

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
space_xpce_named_key('LFD', "return").
space_xpce_named_key('ESC', "escape").
space_xpce_named_key('BS',  "backspace").
space_xpce_named_key('DEL', "delete").
% SPC is the space bar as XPCE names it when it arrives as an event id
% rather than as the ASCII code 32.  Without this it fell through to the
% generic single-letter branch and reported itself as "s".
space_xpce_named_key('SPC', "space").
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
% f1..f24.  Name and key are the same atom, so f1 stays "f1" rather than
% collapsing to "f".
%
% The number has to be read from the digits AFTER the "f": atom_number/2
% only accepts a numeric literal, so atom_number(f1, N) FAILS and the whole
% clause used to be skipped -- which is why a function key reported itself as
% "f" before.
space_xpce_named_key(F, F) :-
    space_xpce_function_number(F, _).

% f1 .. f24, as the function-key number.
space_xpce_function_number(F, N) :-
    atom_length(F, L),
    L >= 2, L =< 3,
    sub_atom(F, 0, 1, _, "f"),
    sub_atom(F, 1, _, 0, Digits),
    atom_number(Digits, N),
    between(1, 24, N).

% --- the XPCE keyboard device ------------------------------------------------
%
% XPCE 10.0.0 exposes the keyboard as an input device, @keyboard_device, and
% answers whether a key is held down:
%
%   get(@keyboard_device, key_down, Key, @on)    % held
%   get(@keyboard_device, key_down, Key, @off)   % not held
%
% `Key' is a name XPCE understands: one of ITS OWN event names (RET, ESC,
% TAB, BS, DEL, space, insert, pause, cursor_home, end, page_up, page_down,
% cursor_left, cursor_right, cursor_up, cursor_down), f1..f24, a single
% character, or the name SDL uses for the key ("Left Shift").
%
% This is the same call XPCE's own games use -- see prolog/demo/asteroids.pl:
%
%   key_down(Key) :- get(@keyboard_device, key_down, Key, @on).
%
% A key XPCE does not know makes the get fail with "Unknown key".  That is an
% error raised in C++, and an XPCE error during the event loop opens a modal
% dialog that freezes the app (see constraint 1 at the top of this file), so
% the name is checked against the list XPCE accepts BEFORE it is polled.
%
% Polling beats following the events for a game: the events only say that a
% key went down, and a key that was pressed while another window had the
% focus never produces a release, so a set built from the events drifts.
% The device reports the hardware state, so it is the source of truth here.

% The names the XPCE keyboard device accepts, apart from a single character
% and the function keys.
%
% The names are QUOTED on purpose: RET, ESC, TAB, BS and DEL start with a
% capital, so unquoted they are ProLOG VARIABLES -- and a fact with a
% variable in it matches every name at all, which made every key look
% known to the device.
space_xpce_device_named('RET').
space_xpce_device_named('ESC').
space_xpce_device_named('TAB').
space_xpce_device_named('BS').
space_xpce_device_named('DEL').
space_xpce_device_named(space).
space_xpce_device_named(insert).
space_xpce_device_named(pause).
space_xpce_device_named(cursor_home).
space_xpce_device_named(end).
space_xpce_device_named(page_up).
space_xpce_device_named(page_down).
space_xpce_device_named(cursor_left).
space_xpce_device_named(cursor_right).
space_xpce_device_named(cursor_up).
space_xpce_device_named(cursor_down).
% The SDL names of the modifier keys.
space_xpce_device_named('Left Shift').
space_xpce_device_named('Right Shift').
space_xpce_device_named('Left Ctrl').
space_xpce_device_named('Right Ctrl').
space_xpce_device_named('Left Alt').
space_xpce_device_named('Right Alt').
space_xpce_device_named('Left GUI').
space_xpce_device_named('Right GUI').

% Love2D name -> the name the XPCE keyboard device knows.  The DOM arrow
% aliases are accepted as well, because the Space API documents both
% "left" and "arrowleft".
space_xpce_device_key(Name0, DeviceKey) :-
    space_xpce_key_name(Name0, Name),
    atom_string(Atom, Name),
    downcase_atom(Atom, Lower),
    (   space_xpce_device_alias(Lower, DeviceKey)
    ->  true
    ;   DeviceKey = Lower
    ).

space_xpce_device_alias(left, cursor_left).
space_xpce_device_alias(arrowleft, cursor_left).
space_xpce_device_alias(right, cursor_right).
space_xpce_device_alias(arrowright, cursor_right).
space_xpce_device_alias(up, cursor_up).
space_xpce_device_alias(arrowup, cursor_up).
space_xpce_device_alias(down, cursor_down).
space_xpce_device_alias(arrowdown, cursor_down).
space_xpce_device_alias(enter, 'RET').
space_xpce_device_alias(return, 'RET').
space_xpce_device_alias(escape, 'ESC').
space_xpce_device_alias(esc, 'ESC').
space_xpce_device_alias(space, space).
space_xpce_device_alias(tab, 'TAB').
space_xpce_device_alias(backspace, 'BS').
space_xpce_device_alias(delete, 'DEL').
space_xpce_device_alias(del, 'DEL').
space_xpce_device_alias(pageup, page_up).
space_xpce_device_alias(pagedown, page_down).
space_xpce_device_alias(home, cursor_home).
space_xpce_device_alias(end, end).
space_xpce_device_alias(insert, insert).
space_xpce_device_alias(pause, pause).
space_xpce_device_alias(lshift, 'Left Shift').
space_xpce_device_alias(rshift, 'Right Shift').
space_xpce_device_alias(lctrl, 'Left Ctrl').
space_xpce_device_alias(rctrl, 'Right Ctrl').
space_xpce_device_alias(lalt, 'Left Alt').
space_xpce_device_alias(ralt, 'Right Alt').

% Is this a name the device is guaranteed to know?  Anything else is not
% polled, so XPCE never raises "Unknown key" on it.
space_xpce_device_key_known(DeviceKey) :-
    (   space_xpce_device_named(DeviceKey)
    ->  true
    ;   atom_length(DeviceKey, 1)
    ->  true
    ;   space_xpce_function_number(DeviceKey, _)
    ).

% Ask the device whether a key is held.  Fails when it is not held, when
% the device is not there, or when the key is one XPCE does not know -- the
% last case is filtered out before we get here, so an error means the
% device itself is unusable and the caller falls back to the event set.
space_xpce_device_key_down(DeviceKey) :-
    catch(get(@keyboard_device, key_down, DeviceKey, @on), _, fail).

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
        % A proper SET: several keys can be held at once, and a key that is
        % pressed again while held is still just one entry.
        ( space_keys(Prefix, Held0) -> true ; Held0 = [] ),
        ( memberchk(Key, Held0) -> Held = Held0 ; Held = [Key|Held0] ),
        retractall(space_keys(Prefix, _)),
        assertz(space_keys(Prefix, Held))
    ;   Type == "keyup"
    ->  space_field("key", Fields, "", Key0),
        space_xpce_key_name(Key0, Key),
        ( space_keys(Prefix, Held0) -> true ; Held0 = [] ),
        exclude(==(Key), Held0, Held),
        retractall(space_keys(Prefix, _)),
        assertz(space_keys(Prefix, Held))
    ;   true
    ).

% The held-key set is a fallback for isDown/1, used when the XPCE keyboard
% device is not available.  It is kept in step with the events: a press adds
% a key, a release removes it.
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
    space_clear_events(Prefix).

% getType/2 drains only the events of the requested type.  The other
% events stay queued in their original order: clearing the whole queue
% here used to throw away pending mouse, resize and text events just
% because a caller asked for a keydown.
space_xpce_event_get(Prefix0, Type, Events) :-
    space_prefix(Prefix0, Prefix),
    ( space_events(Prefix, All) -> true ; All = [] ),
    include(space_event_type(Type), All, Events),
    exclude(space_event_type(Type), All, Rest),
    space_set_events(Prefix, Rest).

space_event_type(Type, Event) :-
    ( get_assoc("type", Event, Type) -> true ; fail ).

% Filtering on an unbound-or-different Type simply drops the event.

% Is a key held down?
%
% The XPCE keyboard device is asked first: it reports the hardware state, so
% it is right even when the app missed an event (a key pressed while another
% window had the focus, for instance).  The set built from the press and
% release events is only used when the device cannot answer, which is the
% case on an XPCE older than 10.0.0.
%
% The device is not asked about a key it does not know: that makes the get
% fail with an XPCE error, and an error during the event loop opens a modal
% dialog (constraint 1 at the top of this file).
space_xpce_keyboard_is_down(Prefix0, Key, 1) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_key_name(Key, Name),
    space_xpce_device_key(Name, DeviceKey),
    (   space_xpce_device_key_known(DeviceKey),
        space_xpce_device_key_down(DeviceKey)
    ->  true
    ;   ( space_keys(Prefix, Held) -> true ; Held = [] ),
        memberchk(Name, Held)
    ), !.
space_xpce_keyboard_is_down(_, _, 0).

space_xpce_mouse_get_position(Prefix0, X, Y) :-
    space_prefix(Prefix0, Prefix),
    ( space_mouse(Prefix, X0, Y0, _) -> true ; X0 = 0, Y0 = 0 ),
    X = X0, Y = Y0.

% Is a mouse button held down?  The buttons are numbered the way the Space
% API numbers them: 1 left, 2 right, 3 middle.
space_xpce_mouse_is_down(Prefix0, Button, 1) :-
    space_prefix(Prefix0, Prefix),
    ( space_mouse(Prefix, _, _, Held) -> true ; Held = [] ),
    space_xpce_button_number_of(Button, Number),
    memberchk(Number, Held), !.
space_xpce_mouse_is_down(_, _, 0).

% A button number the caller passed, in Space numbering.  Both the numbers
% and the names are accepted, because a program may say buttonDown(1) or
% buttonDown('left').
space_xpce_button_number_of(Button, Number) :-
    (   number(Button)
    ->  Number is round(Button)
    ;   atom_string(Button, Name0), downcase_atom(Name0, Name),
        (   space_xpce_button_label(Number, Name)
        ->  true
        ;   Number = 0
        )
    ).

space_xpce_button_label(1, "left").
space_xpce_button_label(2, "right").
space_xpce_button_label(3, "middle").

% Dispatch queued events to Love2D-style callbacks supplied in the sp.start
% map under "on".  Called from the frame tick, after XPCE has had the whole
% frame to deliver input.
space_xpce_dispatch_callbacks(Prefix, Events) :-
    space_frame(Prefix, _, Callbacks),
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
%
% The Space API says:
%   getTime()   seconds since the backend was created
%   getDelta()  the update interval in milliseconds
%   getFPS()    the corresponding target FPS
%
% getTime/2 used to answer the raw wall-clock time, which is no use to a
% program that wants "how long has this been running".

space_xpce_get_time(Prefix0, Time) :-
    space_prefix(Prefix0, Prefix),
    get_time(Now),
    (   space_created(Prefix, Created)
    ->  Time is Now - Created
    ;   assertz(space_created(Prefix, Now)),
        Time = 0.0
    ).

space_xpce_get_delta(Prefix0, Delta) :-
    space_prefix(Prefix0, Prefix),
    ( space_frame(Prefix, Ms, _), Ms > 0 -> Delta = Ms
    ; Delta = 16.666666666666668
    ).

space_xpce_get_fps(Prefix0, Fps) :-
    space_prefix(Prefix0, Prefix),
    ( space_frame(Prefix, Ms, _), Ms > 0 -> Fps is 1000.0 / Ms
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

% --- frame helpers ------------------------------------------------------------
%
% XPCE presents every drawing call at once, so a frame is only a marker:
% beginFrame and endFrame have nothing to do.  stop ends the program the
% way quit does.

space_xpce_begin_frame(_) :- true.

space_xpce_end_frame(_) :- true.

space_xpce_stop(Prefix0) :-
    space_xpce_quit(Prefix0).
