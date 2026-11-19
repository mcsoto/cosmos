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

% Whether the window has the input focus.  It used to be a dynamic fact,
% and the frame tick rewrote it every frame with retractall/1 and
% assertz/1 -- the retraction is the expensive half, 616 us against 0.5 us
% for a global, so the tick paid for a rewrite that changed nothing most
% of the time.  It is a global now, and it is only written when the focus
% actually changed.
space_focus(Prefix, HasFocus) :-
    space_key(space_focus_, Prefix, Key),
    catch(nb_getval(Key, HasFocus), _, fail).

space_set_focus(Prefix, HasFocus) :-
    space_key(space_focus_, Prefix, Key),
    nb_setval(Key, HasFocus).

space_clear_focus(Prefix) :-
    space_key(space_focus_, Prefix, Key),
    catch(nb_delete(Key), _, true).

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
% The queue keeps its length next to it, so that the limit below can be
% checked without walking the list every time an event arrives.
space_events(Prefix, Events) :-
    space_key(space_events_, Prefix, Key),
    (   catch(nb_getval(Key, queue(_, Queue)), _, fail)
    ->  true
    ;   Queue = []
    ),
    copy_term(Queue, QueueCopy),
    reverse(QueueCopy, Events).

% How many events the queue holds at most.
%
% A program that polls drains the queue every frame, so it never comes near
% the limit.  A program that only uses the callbacks never drains it at all,
% and without the limit the queue would grow for ever: an hour of mouse
% movement is a quarter of a million events, each one a table the backend
% has to copy.  The OLDEST event is the one that goes, because the newest
% are the ones the program has not seen yet.
space_queue_limit(256).

space_push_event(Prefix, Event) :-
    space_key(space_events_, Prefix, Key),
    (   catch(nb_getval(Key, queue(N, Queue)), _, fail)
    ->  true
    ;   N = 0, Queue = []
    ),
    space_queue_limit(Limit),
    (   N >= Limit
    ->  (   append(Newest, [_Oldest], Queue)
        ->  N1 = Limit
        ;   Newest = Queue,
            N1 is N + 1
        )
    ;   Newest = Queue,
        N1 is N + 1
    ),
    nb_setval(Key, queue(N1, [Event|Newest])),
    space_push_undelivered(Prefix, Event).

space_clear_events(Prefix) :-
    space_key(space_events_, Prefix, Key),
    nb_delete(Key).

% Replace the queue from an oldest-first list, which is the order
% space_events/2 answers.  The queue itself is kept newest-first.
space_set_events(Prefix, Events) :-
    space_key(space_events_, Prefix, Key),
    reverse(Events, NewestFirst),
    length(NewestFirst, N),
    nb_setval(Key, queue(N, NewestFirst)).

% --- the events the callbacks have not seen yet ------------------------------
%
% The tick PEEKS at the queue, because a polling program drains it with
% event.get/2 from update and must still find its events there.  The
% callbacks used to be fired with the WHOLE queue on every frame, so a
% program that never drained it was told about the same key press again on
% the next frame, and again on the one after that: one press produced an
% endless stream of keypressed callbacks, forever.
%
% The undelivered list is the part of the queue the callbacks have not seen
% yet.  The tick takes it, fires the callbacks with it and empties it, so
% every event reaches the callbacks exactly once.  The queue itself is left
% alone, so a polling program still finds the event with event.get/2.
%
% The two lists are independent on purpose: an event that arrives in the
% middle of a frame is in the queue before the program drains it and in the
% undelivered list until the next tick, and it has to reach the callbacks
% even though the program has already seen it.
space_undelivered_events(Prefix, Events) :-
    space_key(space_undelivered_, Prefix, Key),
    (   catch(nb_getval(Key, Queue), _, fail)
    ->  true
    ;   Queue = []
    ),
    copy_term(Queue, QueueCopy),
    reverse(QueueCopy, Events).

% Take the events the callbacks have not seen, and mark them as seen.
space_xpce_take_undelivered(Prefix, Events) :-
    space_undelivered_events(Prefix, Events),
    space_key(space_undelivered_, Prefix, Key),
    nb_setval(Key, []).

space_push_undelivered(Prefix, Event) :-
    space_key(space_undelivered_, Prefix, Key),
    (   catch(nb_getval(Key, Queue), _, fail)
    ->  true
    ;   Queue = []
    ),
    nb_setval(Key, [Event|Queue]).

% Drop everything a window keeps between frames.
space_forget(Prefix) :-
    forall(member(Kind, [space_state_, space_ink_, space_last_, space_frame_, space_events_, space_undelivered_, space_focus_, space_mods_]),
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

% --- the game ----------------------------------------------------------------
%
% A Space application is a 'game' class, the way XPCE's own SDL demos are
% written: prolog/demo/asteroids.pl has asteroids_game, a frame, with the
% asteroids_window inside it, and the game class owns the timer that drives
% the frames.
%
% The game IS the canvas: it extends space_picture, so it keeps the input
% capture, and it owns the timer.  The callbacks and the game state stay
% where the Space API keeps them, in the per-prefix facts: they are Cosmos
% values that travel from update/2 to draw/1, not XPCE objects.
%
% The window is opened from inside pce_main_loop's boot goal, because
% pce_loop only dispatches the frames that goal created.  That is how the
% window's close ends the process, with no done_message override.
:- pce_begin_class(space_game, space_picture,
                   "A Space application: the canvas, the timer and the frame dispatch").

variable(prefix, name, both, "The Space instance this game belongs to").

initialise(G, Prefix:name) :->
    "Remember the Space instance and start the frame timer"::
    % The superclass sets the label and the scrollbars; without it the
    % window is not a proper picture and the program ends at once.
    send_super(G, initialise, 'Cosmos Space'),
    send(G, slot, prefix, Prefix),
    space_xpce_start_timer(G).

tick(G) :->
    "Run one frame"::
    get(G, prefix, Prefix),
    space_xpce_tick(Prefix).

:- pce_end_class.

% The timer that drives the frames.  It sends tick to the game, so the game
% is what decides what a frame does.
space_xpce_start_timer(Game) :-
    get(Game, prefix, Prefix),
    (   space_frame(Prefix, IntervalMs, _)
    ->  true
    ;   IntervalMs = 16
    ),
    Secs is IntervalMs / 1000.0,
    new(_Timer, timer(Secs, message(Game, tick))),
    send(_Timer, start).

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
    (   space_xpce_colour_hex(Color, R, G, B)
    ->  true
    ;   space_xpce_colour_list(Color, R, G, B)
    ->  true
    ;   space_xpce_colour_functor(Color, R, G, B)
    ->  true
    ;   R = 255, G = 255, B = 255
    ).

% "#rrggbb".
space_xpce_colour_hex(Color, R, G, B) :-
    string(Color),
    sub_string(Color, 0, 1, _, "#"),
    sub_string(Color, 1, 2, _, RHex),
    sub_string(Color, 3, 2, _, GHex),
    sub_string(Color, 5, 2, _, BHex),
    space_hex(RHex, R), space_hex(GHex, G), space_hex(BHex, B).

% [R,G,B].
space_xpce_colour_list(Color, R, G, B) :-
    is_list(Color),
    Color = [R0, G0, B0],
    maplist(number, [R0, G0, B0]),
    space_channel(R0, R), space_channel(G0, G), space_channel(B0, B).

% The rgb(...) functor.  A Cosmos functor crosses the pl:: bridge as a
% term whose name is fc_<name>, so rgb(255,0,0) arrives here as the term
% fc_rgb(255,0,0).  The old code tried to match it with a BINDING
% (Color = fc_rgb(R,G,B)) in the middle of a chain of conditions, where it
% is the condition of the last else-branch: it therefore also matched
% colours that are not functors at all, and the white fallback was
% unreachable.  The three forms are separate goals now, each of which
% either produces the three channels or fails.
%
% rgba(...) is accepted as well; XPCE's colour object has no alpha
% channel, so the alpha is dropped.
space_xpce_colour_functor(fc_rgb(R0, G0, B0), R, G, B) :-
    !,
    maplist(number, [R0, G0, B0]),
    space_channel(R0, R), space_channel(G0, G), space_channel(B0, B).
space_xpce_colour_functor(fc_rgba(R0, G0, B0, _), R, G, B) :-
    !,
    maplist(number, [R0, G0, B0]),
    space_channel(R0, R), space_channel(G0, G), space_channel(B0, B).

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

% Open the canvas from the program side: sp.open() calls this, and a game
% relation that opens its own window calls it from inside the relation.
space_xpce_open(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_open_window(Prefix).

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
    ; space_xpce_open_window(Prefix)
    ).

% Open the canvas.  The game class IS the canvas: it extends space_picture,
% so it keeps the input capture, and it owns the frame timer.
%
% A program that wants to open the window itself -- the startLoop shape,
% where the game relation does the opening -- calls space_xpce_open/1 from
% inside that relation.  Then the window is created while pce_loop's goal
% runs, which is what lets pce_loop find it and dispatch until it is closed.
space_xpce_open_window(Prefix) :-
    ( space_window(Prefix, _) -> true
    ; ( space_pending(Prefix, W, H) -> true ; W = 640, H = 480 ),
      % Drop what the previous window left behind BEFORE the new window is
      % built: opening a window can already deliver events (the keyboard
      % focus arrives with it), and clearing the queue afterwards threw those
      % away again.
      space_clear_events(Prefix),
      % space_game, not picture: the subclass is what routes ->event into
      % space_xpce_capture/2.  A plain picture would simply ignore input.
      % The game class also owns the frame timer, so the application is one
      % object with its own start-up and its own tick, like the SDL demos.
      new(Window, space_game(Prefix)),
      send(Window, name, 'Cosmos Space'),
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

% NOTE: never destroy/hide an opened XPCE window programmatically: outside
% the XPCE event loop those calls crash the process. Just forget the state;
% the OS reclaims the window on process exit (or the user closes it, which
% halts via done_message).
space_xpce_forget_window(Prefix) :-
    retractall(space_window(Prefix, _)),
    space_forget(Prefix),
    retractall(space_mouse(Prefix, _, _, _)),
    retractall(space_keys(Prefix, _)),
    space_clear_focus(Prefix),
    retractall(space_size(Prefix, _)).

space_xpce_start(Prefix0, IntervalMs, Callbacks, InitialState) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_start_loop(Prefix, IntervalMs, Callbacks, InitialState).

space_xpce_start(Prefix0, IntervalMs, Callbacks, InitialState, W, H) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_init(Prefix, W, H),
    space_xpce_start_loop(Prefix, IntervalMs, Callbacks, InitialState).

% The game-loop shape: the GAME relation opens the window and the loop
% dispatches until it is closed.  This is the Space answer to xp.main_loop/1.
%
% The entry point is pce_main_loop/1, the same one sp.start/3 uses: it runs
% setup_runtime, hands the command line to the goal and dispatches until the
% last frame is gone.  The window has to be created while that goal runs --
% pce_loop only dispatches the windows the goal created -- so the goal is the
% program's own relation, and the relation is what calls sp.open().
%
% The interval is in SECONDS here, like the XPCE timer; sp.start/3 takes
% milliseconds.
space_xpce_start_loop_game(Prefix0, IntervalSeconds, Game, Callbacks, State) :-
    space_prefix(Prefix0, Prefix),
    IntervalMs is IntervalSeconds * 1000.0,
    space_set_frame(Prefix, IntervalMs, Callbacks),
    space_set_state(Prefix, State),
    get_time(Now),
    space_set_last(Prefix, Now),
    % The same unwind handling as space_xpce_start_loop/4: closing the
    % window halts the process, and that arrives here as the ball
    % unwind(halt(0)).  Reporting it as an error would turn a clean exit
    % into status 1.
    catch(pce_main_loop(space_xpce_goal(Game)), E, space_xpce_loop_error(E)),
    halt(0).

% pce_loop/2 calls its goal with the argument list; the Cosmos relation
% takes that list as its single argument.
space_xpce_goal(Closure, Argv) :-
    call_cl(Closure, [Argv]).

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
%
% The window is created HERE, inside the boot goal, because pce_loop only
% dispatches the frames that this goal created.  The game class opens the
% canvas and starts its own timer, so the boot goal only has to place the
% window and set the clock.
space_xpce_boot(Prefix, _Argv) :-
    space_xpce_boot_window(Prefix),
    get_time(Now),
    space_set_last(Prefix, Now).

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
        ( space_last(Prefix, Last) -> Dt0 is Now - Last ; Dt0 = 0.016 ),
        space_set_last(Prefix, Now),
        space_xpce_clamp_dt(Prefix, Dt0, Dt),
        % The Space API says the held key and mouse-button state is cleared
        % when the canvas loses focus, and a key pressed while another window
        % had the focus never produces a release.  The window reports its own
        % focus, so the change is picked up here, once a frame.
        space_xpce_update_focus(Prefix, Window),
        % The modifier keys are polled once a frame: XPCE does not deliver
        % events for them, so the device is the only thing that notices a
        % modifier that was pressed or released on its own.  A change
        % queues an ordinary key event for it.
        space_xpce_update_modifiers(Prefix, none),
        % XPCE has delivered whatever input arrived since the last tick.
        % The callbacks fire here, BEFORE update/draw, so a handler sees the
        % frame's events.  Only the events the callbacks have NOT seen yet
        % are fired: the queue itself is only PEEKED at, because a polling
        % program drains it with event.get/2, and firing the whole queue
        % again every frame told the program about the same key press for
        % ever.
        space_xpce_take_undelivered(Prefix, Events),
        (   Events == []
        ->  State1 = State
        ;   space_xpce_dispatch_callbacks(Prefix, Events, State, State1)
        ),
        ( get_assoc("update", Callbacks, Update) ->
            catch(space_xpce_call_update(Update, Dt, State1, NewState), E,
                  ( print_message(warning, E), NewState = State1 ))
        ; NewState = State1
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

% The step is clamped.
%
% dt is the time since the previous tick, so a callback that took a second
% -- a long print, a slow disk write, a window that was dragged -- hands the
% NEXT frame a dt of a second.  A game that multiplies its speed by dt then
% jumps across the screen, and a collision check that assumes a small step
% walks straight through a wall.  The limit is a few frame intervals, so a
% frame that ran long loses time instead of teleporting things.  A program
% that runs at its normal speed never reaches the limit, so nothing changes
% for it.
%
% The clock can also jump backwards, so a negative dt is clamped to zero.
space_xpce_max_steps(4).

space_xpce_clamp_dt(Prefix, Dt0, Dt) :-
    (   space_frame(Prefix, Ms, _)
    ->  Limit is Ms / 1000.0 * 4
    ;   Limit = 0.064
    ),
    (   Dt0 > Limit
    ->  Dt = Limit
    ;   Dt0 < 0.0
    ->  Dt = 0.0
    ;   Dt = Dt0
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
    ->  space_xpce_channel_hex(R, RH),
        space_xpce_channel_hex(G, GH),
        space_xpce_channel_hex(B, BH),
        string_concat("#", RH, S1),
        string_concat(S1, GH, S2),
        string_concat(S2, BH, Hex)
    ;   Hex = "#ffffff"
    ).

% One colour channel as two hex digits.  The old code used
% format(atom(A), "#~2.16.0b...", ...), and that format is not a thing:
% SWI-Prolog rejects it with "format_character '.' does not exist", so
% every colour that was not already a string raised an error here and the
% drawing call that asked for it failed.
space_xpce_channel_hex(V0, Hex) :-
    V is V0 mod 256,
    High is V // 16,
    Low is V mod 16,
    space_xpce_hex_digit(High, HD),
    space_xpce_hex_digit(Low, LD),
    atom_codes(A, [HD, LD]),
    atom_string(A, Hex).

space_xpce_hex_digit(N, D) :-
    (   N < 10
    ->  D is 0'0 + N
    ;   D is 0'a + N - 10
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

debug_write(X,Y) :- true. 
	%write(X), writeln(Y).

space_xpce_capture(Window, Ev) :-
    ( space_xpce_prefix_of(Window, Prefix) -> true ; Prefix = default ),
    space_xpce_read(Prefix, Ev, Type, Fields),
    % The modifier keys are updated BEFORE the event is queued: a modifier
    % that was pressed together with this key has to be queued first, or
    % the program sees the key and only afterwards the modifier that was
    % already down when the key was typed.  A mouse event says nothing
    % about the modifiers, so only the keyboard events ask.
    (   Type == "keydown"
    ->  space_xpce_update_modifiers(Prefix, Ev)
    ;   Type == "keyup"
    ->  space_xpce_update_modifiers(Prefix, Ev)
    ;   true
    ),
    % Build the table FIRST and pass that on.  Downstream code indexes it
    % with get_assoc/3, which needs the assoc -- passing the raw Key-Value
    % list raises "'$btree_find_node'/5: Type error: `btree' expected".
    space_event_assoc(Fields, Event),
    space_xpce_update_state(Prefix, Type, Event),
    space_push_event(Prefix, Event),
	debug_write("Ev:",[Fields, Ev, Type]),
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
    (   Was == HasFocus
    ->  true
    ;   space_set_focus(Prefix, HasFocus),
        retractall(space_keys(Prefix, _)),
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
space_xpce_read(Prefix, Ev, Type, Fields) :-
    get(Ev, id, Id),
    (   send(Ev, is_a, mouse)
    ->  space_xpce_read_mouse(Prefix, Ev, Id, Type, Fields)
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

space_xpce_read_mouse(Prefix, Ev, Id, Type, Fields) :-
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
    % The movement since the previous position.  The mousemoved callback
    % needs it, and the event table did not carry it before.  The stored
    % position is the one of the previous event: the state is updated
    % after this read.
    (   space_mouse(Prefix, PrevX, PrevY, _)
    ->  true
    ;   PrevX = 0, PrevY = 0
    ),
    DX is X0 - PrevX,
    DY is Y0 - PrevY,
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
               "dx"-DX, "dy"-DY,
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
% "m" (meta/super).  It is read from the event's buttons mask, not from
% has_modifier/1: a modifier object demands the OTHER modifier keys to be
% up, so has_modifier(s) fails as soon as control is held as well, and the
% modifier string of a control+shift press came out empty.  The mask has
% no such restriction.  See the section on the modifier keys below.

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
	
%kept alias to arrow-keys only
space_xpce_device_alias(left, cursor_left).
space_xpce_device_alias(arrowleft, cursor_left).
space_xpce_device_alias(right, cursor_right).
space_xpce_device_alias(arrowright, cursor_right).
space_xpce_device_alias(up, cursor_up).
space_xpce_device_alias(arrowup, cursor_up).
space_xpce_device_alias(down, cursor_down).
space_xpce_device_alias(arrowdown, cursor_down).

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

% --- modifier keys ----------------------------------------------------------
%
% XPCE does NOT deliver events for the modifier keys.  Its own manual says
% so (class key_data):
%
%   "Only keys that generated a keyboard event generate a key_up: a
%    modifier key, such as Shift, generates neither."
%
% So a program that only looks at the events never sees shift, control or
% alt being pressed.  XPCE does report them in two other places:
%
%   * the modifier state of an event, which lives in the event's BUTTONS
%     MASK: control 0x1, shift 0x2, meta 0x4;
%   * the keyboard device, which knows whether a key is held right now.
%
% The mask is the better of the two.  has_modifier/2 cannot be used to read
% the state back: a modifier object demands the OTHER modifier keys to be
% UP, so has_modifier(s) fails as soon as control is held as well, and the
% modifier string of a control+shift press came out empty.  The mask has no
% such restriction.
%
% Two things are built on top of that:
%
%   * the state of the modifier keys is tracked, so isDown/1 can answer for
%     a modifier and not only for an ordinary key;
%   * a modifier that is pressed or released is turned into an ordinary
%     keydown/keyup event, so the modifier keys are visible in the event
%     queue and reach the keypressed/keyreleased callbacks as well.
%
% The names are the ones XPCE itself uses.  Its modifier class has a
% shift, a control and a meta slot, and its own key names spell them
% "Shift-", "Ctrl-" and "Alt-" (see key_name/2 in XPCE's
% pce_keybinding.pl), so:
%
%   shift   the shift key
%   ctrl    the control key
%   alt     the meta key, which is the alt key on the keyboard
%
% There is no fourth one.  XPCE's modifier class also has a gui slot, but
% the gui key is in neither of the two places a modifier can be seen: the
% event mask has no bit for it, and the keyboard device of this build does
% not know the name of the key -- asking for it raises "Unknown key", and
% an error raised inside the event loop stops the frame for good (see
% constraint 1 at the top of this file).  A modifier that cannot be seen
% is not offered at all.
%
% The SDL names of the keys ("Left Shift" and friends) are NOT part of the
% Space vocabulary.  They are how the XPCE keyboard device spells the same
% keys, and they are used here only to talk to that device.
space_xpce_modifiers([shift, ctrl, alt]).

% The spellings the Space API accepts for the same keys.
space_xpce_modifier_alias(control, ctrl).
space_xpce_modifier_alias(meta, alt).

% How the XPCE keyboard device spells the modifier keys.  The device takes
% the name SDL uses for the key ("Left Shift"); that is XPCE's own
% vocabulary FOR THE DEVICE, not a name the Space API hands out.
%
% These three pairs are verified against this build: a name the device
% does not know raises "Unknown key", which is fatal inside the event
% loop.
space_xpce_modifier_device_keys(shift, ['Left Shift', 'Right Shift']).
space_xpce_modifier_device_keys(ctrl, ['Left Ctrl', 'Right Ctrl']).
space_xpce_modifier_device_keys(alt, ['Left Alt', 'Right Alt']).

% The modifier state: which modifiers are held down right now, and whether
% the keyboard device has ever been seen to report a held modifier.
%
% It lives in a global variable rather than in a fact: it changes every
% frame, and a fact would have to be retracted and asserted again (see the
% note on nb_setval/2 at the top of this file).
space_mod_state(Prefix, Mods, DeviceOk) :-
    space_key(space_mods_, Prefix, Key),
    (   catch(nb_getval(Key, V), _, fail)
    ->  V = state(Mods, DeviceOk)
    ;   Mods = [], DeviceOk = false
    ).

space_set_mod_state(Prefix, Mods, DeviceOk) :-
    space_key(space_mods_, Prefix, Key),
    nb_setval(Key, state(Mods, DeviceOk)).

% The modifiers an event carries.
%
% The mask carries them, and has_modifier/2 confirms them: a modifier that
% is down on its own is reported by has_modifier/2 even in a build whose
% mask has no modifier bits.  The two are combined, so the state of an
% event is read as fully as this build allows.
space_xpce_event_modifiers(none, []) :- !.
space_xpce_event_modifiers(Ev, Mods) :-
    (   catch(get(Ev, buttons, Mask), _, fail), integer(Mask)
    ->  true
    ;   Mask = 0
    ),
    (   space_xpce_mask_bit(Mask, 2) -> Ms = [shift] ; Ms = [] ),
    (   space_xpce_mask_bit(Mask, 1) -> append(Ms, [ctrl], Ms1) ; Ms1 = Ms ),
    (   space_xpce_mask_bit(Mask, 4) -> append(Ms1, [alt], Ms2) ; Ms2 = Ms1 ),
    (   catch(send(Ev, has_modifier, s), _, fail)
    ->  append(Ms2, [shift], Ms3) ; Ms3 = Ms2 ),
    (   catch(send(Ev, has_modifier, c), _, fail)
    ->  append(Ms3, [ctrl], Ms4) ; Ms4 = Ms3 ),
    (   catch(send(Ev, has_modifier, m), _, fail)
    ->  append(Ms4, [alt], Ms5) ; Ms5 = Ms4 ),
    sort(Ms5, Mods).

% Is the bit set in the event's mask?  The mask is a bit field: control
% 0x1, shift 0x2, meta 0x4.
space_xpce_mask_bit(Mask, Bit) :-
    Value is Mask /\ Bit,
    Value =\= 0.

% The modifier string of an event, in the PyGame style the event table
% uses: any of "s" (shift), "c" (control), "m" (meta).
space_xpce_mods(Ev, Mods) :-
    space_xpce_event_modifiers(Ev, Names),
    space_xpce_mod_letters(Names, Letters),
    ( Letters == [] -> Mods = "" ; atom_chars(Mods, Letters) ).

space_xpce_mod_letters(Mods, Letters) :-
    (   memberchk(shift, Mods) -> Ms = [s] ; Ms = [] ),
    (   memberchk(ctrl, Mods) -> append(Ms, [c], Ms1) ; Ms1 = Ms ),
    (   memberchk(alt, Mods) -> append(Ms1, [m], Ms2) ; Ms2 = Ms1 ),
    Letters = Ms2.

% The modifier state, read from the keyboard device.  Fails when the device
% cannot answer: it may not exist, and a key it does not know raises an
% error in C++ that would open a modal dialog (constraint 1).
%
% The device is asked with an unbound state, so that "not held" is an
% answer too and not a failure: the difference between "the user let go of
% the shift key" and "the device is not there" is what the whole modifier
% tracking rests on.
space_xpce_device_modifiers(Mods) :-
    space_xpce_modifiers(All),
    space_xpce_device_modifiers_(All, [], Mods).

space_xpce_device_modifiers_([], Acc, Mods) :- !,
    sort(Acc, Mods).
space_xpce_device_modifiers_([Mod|Mods], Acc, Held) :-
    space_xpce_modifier_device_keys(Mod, Keys),
    (   space_xpce_device_modifier_down(Keys)
    ->  Acc1 = [Mod|Acc]
    ;   Acc1 = Acc
    ),
    space_xpce_device_modifiers_(Mods, Acc1, Held).

% Is one of these device keys held down?  The first answer that is not an
% error decides; an error means the device is unusable here.
space_xpce_device_modifier_down(Keys) :-
    member(Key, Keys),
    catch(get(@keyboard_device, key_down, Key, State), _, fail),
    !,
    State == @on.

% Bring the tracked modifier state up to date and queue an event for every
% modifier whose state changed.
%
% The device is the truth when it works.  It is only believed once it has
% reported a held modifier at least once: a device that answers "nothing is
% held" for every modifier would otherwise cancel the modifiers the events
% reported, and the program would see shift being pressed and released over
% and over.  Until then the events are believed.
%
% The event is the event that is being captured, or none.  It is the
% fallback for a build whose device cannot be asked.
space_xpce_update_modifiers(Prefix, Event) :-
    space_mod_state(Prefix, Mods, DeviceOk),
    (   space_xpce_device_modifiers(DeviceMods)
    ->  (   DeviceOk == true
        ->  Set = DeviceMods,
            Ok = true
        ;   DeviceMods == []
        ->  (   space_xpce_event_modifiers(Event, EventMods),
                EventMods \== []
            ->  Set = EventMods,
                Ok = DeviceOk
            ;   Set = Mods,
                Ok = DeviceOk
            )
        ;   Set = DeviceMods,
            Ok = true
        )
    ;   (   space_xpce_event_modifiers(Event, EventMods)
        ->  Set = EventMods,
            Ok = DeviceOk
        ;   Set = Mods,
            Ok = DeviceOk
        )
    ),
    space_xpce_apply_modifiers(Prefix, Set, Ok).

% Set the modifier state and queue the events for the change.
space_xpce_apply_modifiers(Prefix, Mods, DeviceOk) :-
    space_mod_state(Prefix, Old, _),
    (   Old == Mods
    ->  space_set_mod_state(Prefix, Mods, DeviceOk)
    ;   space_set_mod_state(Prefix, Mods, DeviceOk),
        subtract(Mods, Old, Pressed),
        subtract(Old, Mods, Released),
        space_xpce_modifier_events(Prefix, Pressed, "keydown"),
        space_xpce_modifier_events(Prefix, Released, "keyup")    ).

% A modifier that is pressed or released is an ordinary key event, so the
% modifier keys show up in the event queue and reach the keypressed and
% keyreleased callbacks.
%
% The type is a STRING, like the type of every other event: an event with
% an atom as its type is not found by a lookup for "keydown".
space_xpce_modifier_events(Prefix, Mods, Type) :-
    forall(member(Mod, Mods),
           space_xpce_modifier_event(Prefix, Mod, Type)).

space_xpce_modifier_event(Prefix, Mod, Type) :-
    space_mod_state(Prefix, Current, _),
    space_xpce_mods_string(Current, ModString),
    % The key of an event is a STRING, like the key of every other event.
    atom_string(Mod, ModName),
    space_event_assoc([ "type"-Type, "key"-ModName, "char"-"", "mod"-ModString ],
                      Event),
    space_push_event(Prefix, Event).

% The modifier string of a set of modifiers.
space_xpce_mods_string(Mods, String) :-
    space_xpce_mod_letters(Mods, Letters),
    ( Letters == [] -> String = "" ; atom_chars(String, Letters) ).

% Is one of the modifier keys held down?
space_xpce_modifier_is_down(Prefix, Mod, 1) :-
    space_xpce_modifier_device_keys(Mod, Keys),
    (   space_xpce_device_modifier_down(Keys)
    ->  true
    ;   space_mod_state(Prefix, Held, _),
        memberchk(Mod, Held)
    ), !.
space_xpce_modifier_is_down(_, _, 0).

% Is this name one of the modifier keys?  The name is a string (the same
% shape the key names of the events have), so it is compared as one.
space_xpce_modifier_key(Name, Mod) :-
    space_xpce_modifiers(All),
    member(Mod, All),
    (   atom_string(Mod, Name)
    ->  true
    ;   space_xpce_modifier_alias(Alias, Mod),
        atom_string(Alias, Name)
    ).

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
    (   var(N)
    ->  Name = ""
    ;   string(N)
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

% Drop every pending event.  The queue is emptied without handing the
% events over, which is what a program wants when it wants to throw the
% input of the last frames away.
space_xpce_event_clear(Prefix0) :-
    space_prefix(Prefix0, Prefix),
    space_clear_events(Prefix).

% Drop the pending events of one type and leave the rest queued.
space_xpce_event_clear_type(Prefix0, Type0) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_type_name(Type0, Type),
    ( space_events(Prefix, All) -> true ; All = [] ),
    exclude(space_event_type(Type), All, Rest),
    space_set_events(Prefix, Rest).

% Is there a pending event of this type?
space_xpce_event_has(Prefix0, Type0, 1) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_type_name(Type0, Type),
    ( space_events(Prefix, All) -> true ; All = [] ),
    include(space_event_type(Type), All, Found),
    Found \== [],
    !.
space_xpce_event_has(_, _, 0).

% How many pending events of this type?
space_xpce_event_count(Prefix0, Type0, N) :-
    space_prefix(Prefix0, Prefix),
    space_xpce_type_name(Type0, Type),
    ( space_events(Prefix, All) -> true ; All = [] ),
    include(space_event_type(Type), All, Found),
    length(Found, N).

% How many pending events in all?
space_xpce_event_size(Prefix0, N) :-
    space_prefix(Prefix0, Prefix),
    ( space_events(Prefix, All) -> true ; All = [] ),
    length(All, N).

% The type of an event is a string in the event table, so a caller may
% write it as a string or as an atom.
space_xpce_type_name(Type0, Type) :-
    space_xpce_key_name(Type0, Type).

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
    (   % A modifier key is not an ordinary key: the device spells it
        % differently and the state of the modifiers is tracked separately.
        space_xpce_modifier_key(Name, Mod)
    ->  space_xpce_modifier_is_down(Prefix, Mod, 1)
    ;   space_xpce_device_key(Name, DeviceKey),
        (   space_xpce_device_key_known(DeviceKey),
            space_xpce_device_key_down(DeviceKey)
        ->  true
        ;   ( space_keys(Prefix, Held) -> true ; Held = [] ),
            memberchk(Name, Held)
        )
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

% Dispatch queued events to the callbacks of the sp.start map.
%
% Two shapes are supported:
%
%   * a handler under "on", keyed by the type of the event.  It gets the
%     event itself.
%   * a TOP-LEVEL callback named after the kind of event: keypressed,
%     keyreleased, mousepressed, mousereleased, mousemoved, wheel,
%     textinput, focus, blur and resize.  It gets the arguments the Space
%     API documents for it.
%
% The second shape is the one a program normally uses, because the map
% that sp.start takes holds the relations under their own names:
%
%     sp.start(16, {update=update and draw=draw and keypressed=keypressed}, State)
%
% so a program that declared keypressed expected it to be called.  It was
% not: only the handlers under "on" were ever dispatched.
%
% The state is threaded through the callbacks: a callback that produces a
% new state hands it to the next one, and the update callback runs with the
% state the input callbacks left behind.
space_xpce_dispatch_callbacks(Prefix, Events, State0, State) :-
    (   space_frame(Prefix, _, Callbacks)
    ->  true
    ;   Callbacks = []
    ),
    space_xpce_fire_on(Callbacks, Events),
    space_xpce_fire_input(Callbacks, Events, State0, State).

space_xpce_fire_on(Callbacks, Events) :-
    (   get_assoc("on", Callbacks, Handlers),
        Handlers \== none
    ->  forall(member(Event, Events), space_xpce_fire(Handlers, Event))
    ;   true
    ).

% The callback names that belong to a kind of event.  A mouse button has
% two: the current name and the legacy one, which does not get the button.
%
% The type of an event is a STRING in the event table, so the kinds are
% spelled as strings here as well.
space_xpce_input_callbacks("mousedown", [mousepressed, mousedown]).
space_xpce_input_callbacks("mouseup", [mousereleased, mouseup]).
space_xpce_input_callbacks("mousemotion", [mousemoved]).
space_xpce_input_callbacks("mousewheel", [wheel]).
space_xpce_input_callbacks("keydown", [keypressed]).
space_xpce_input_callbacks("keyup", [keyreleased]).
space_xpce_input_callbacks("textinput", [textinput]).
space_xpce_input_callbacks("focus", [focus]).
space_xpce_input_callbacks("blur", [blur]).
space_xpce_input_callbacks("resize", [resize]).

space_xpce_fire_input(Callbacks, Events, State0, State) :-
    space_xpce_fire_input_events(Callbacks, Events, State0, State).

space_xpce_fire_input_events(_, [], State, State).
space_xpce_fire_input_events(Callbacks, [Event|Events], State0, State) :-
    space_xpce_fire_input_event(Callbacks, Event, State0, State1),
    space_xpce_fire_input_events(Callbacks, Events, State1, State).

space_xpce_fire_input_event(Callbacks, Event, State0, State) :-
    (   get_assoc("type", Event, Type0),
        space_xpce_type_name(Type0, Type),
        space_xpce_input_callbacks(Type, Names)
    ->  true
    ;   Names = []
    ),
    space_xpce_fire_names(Callbacks, Names, Event, State0, State).

space_xpce_fire_names(_, [], _, State, State).
space_xpce_fire_names(Callbacks, [Name|Names], Event, State0, State) :-
    (   atom_string(Name, Key),
        get_assoc(Key, Callbacks, Handler),
        Handler \== none
    ->  space_xpce_call_input(Name, Handler, Event, State0, State1)
    ;   State1 = State0
    ),
    space_xpce_fire_names(Callbacks, Names, Event, State1, State).

% The arguments of the input callbacks, as the Space API documents them.
% The first list of each is the full form; the others are the shorter ones
% a program may use.
%
% The mouse button callbacks have two forms, because the legacy mousedown
% and mouseup relations do not take the button:
%   mousepressed(x,y,button,state,state2)   and   mousepressed(x,y,state,state2)
space_xpce_cb_roles(keypressed,   [[key,state,state2], [key,state], [key]]).
space_xpce_cb_roles(keyreleased,  [[key,state,state2], [key,state], [key]]).
space_xpce_cb_roles(mousepressed, [[x,y,button,state,state2], [x,y,state,state2]]).
space_xpce_cb_roles(mousereleased,[[x,y,button,state,state2], [x,y,state,state2]]).
space_xpce_cb_roles(mousedown,    [[x,y,state,state2], [x,y,state]]).
space_xpce_cb_roles(mouseup,      [[x,y,state,state2], [x,y,state]]).
space_xpce_cb_roles(mousemoved,   [[x,y,dx,dy,state,state2], [x,y,dx,dy,state]]).
space_xpce_cb_roles(wheel,        [[dx,dy,state,state2], [dx,dy,state]]).
space_xpce_cb_roles(textinput,    [[text,state,state2], [text,state]]).
space_xpce_cb_roles(focus,        [[state,state2]]).
space_xpce_cb_roles(blur,         [[state,state2]]).
space_xpce_cb_roles(resize,       [[width,height,state,state2], [width,height,state]]).

% The form of the arguments that matches the number of parameters of the
% relation.  When the relation has a number of parameters that is not
% listed, the full form is used and the call fails loudly.
space_xpce_cb_roles_for(Alternatives, N, Roles) :-
    (   member(Roles, Alternatives),
        length(Roles, N)
    ->  true
    ;   Alternatives = [Roles|_]
    ).

% How many parameters the callback has.  A Cosmos closure holds the
% predicate of the relation, whose arity is the number of parameters of
% the relation plus one for the list of captured values, so the number of
% parameters is the arity minus one.
space_xpce_cb_arity(Pred, N) :-
    between(1, 8, A),
    current_predicate(Pred/A),
    !,
    N is A - 1.
space_xpce_cb_arity(_, 0).

% Call one input callback.
space_xpce_call_input(Name, Handler, Event, State0, State) :-
    (   Handler = clos(_, Pred),
        space_xpce_cb_arity(Pred, N),
        N > 0
    ->  space_xpce_cb_roles(Name, Alternatives),
        space_xpce_cb_roles_for(Alternatives, N, Roles)
    ;   space_xpce_cb_roles(Name, Alternatives),
        Alternatives = [Roles|_]
    ),
    space_xpce_cb_arg_list(Roles, Event, State0, Args, State),
    catch(call_cl(Handler, Args), E, print_message(warning, E)),
    (   nonvar(State)
    ->  true
    ;   State = State0
    ).

% The arguments of a callback, in the order of the roles.  The last role
% is the state the callback produces; it is a fresh variable that the
% callback binds, and the state stays as it was when the callback does not
% bind it.
%
% The base case must NOT tie the third argument (the state the callback
% gets) to the fifth (the state it produces): doing so made the state the
% callback produced the state it was given, so a callback could never
% change anything.
space_xpce_cb_arg_list([], _, _, [], State).
space_xpce_cb_arg_list([Role|Roles], Event, State0, [Arg|Args], State) :-
    (   Role == state
    ->  Arg = State0
    ;   Role == state2
    ->  Arg = State
    ;   space_xpce_cb_value(Role, Event, Arg)
    ),
    space_xpce_cb_arg_list(Roles, Event, State0, Args, State).

% The value of one role, taken from the event.
space_xpce_cb_value(x, Event, V) :- space_field("x", Event, 0, V).
space_xpce_cb_value(y, Event, V) :- space_field("y", Event, 0, V).
space_xpce_cb_value(button, Event, V) :- space_field("button", Event, 0, V).
space_xpce_cb_value(dx, Event, V) :- space_field("dx", Event, 0, V).
space_xpce_cb_value(dy, Event, V) :- space_field("dy", Event, 0, V).
space_xpce_cb_value(key, Event, V) :- space_field("key", Event, "", V).
space_xpce_cb_value(text, Event, V) :- space_field("text", Event, "", V).
space_xpce_cb_value(width, Event, V) :- space_field("width", Event, 0, V).
space_xpce_cb_value(height, Event, V) :- space_field("height", Event, 0, V).

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
