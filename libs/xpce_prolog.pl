:- use_module(library(pce)).
:- style_check(-singleton).

% Pure XPCE bridge for Cosmos.
%
% Lets Cosmos programs use SWI-Prolog's XPCE GUI toolkit directly: create
% objects, send messages, read attributes, and run Cosmos relations as
% event callbacks.  This is deliberately NOT the Space canvas API
% (libs/space_xpce*): no drawing primitives, no game loop, no backend
% state -- just objects identified by integer handles.
%
% Only XPCE calls verified safe are used (see xpce-events.md for what the
% toolkit supports, XPCE_LIBRARY.md for the rules).  In particular this
% file never calls device draw_*/clip/pointer primitives or destroys
% opened windows.
%
% Require hook so Cosmos `require('xpce_prolog', _)` loads this file
% through the ordinary module path, then succeeds.
xpce_prolog(_).

:- dynamic xpce_obj/2.      % xpce_obj(Handle, XPCE reference)
:- dynamic xpce_callback/2. % xpce_callback(Id, Cosmos clos term)
:- dynamic xpce_next_id/1.
:- dynamic xpce_data/2.     % xpce_data(Key, Cosmos value as received)
:- dynamic xpce_event_cb/2. % xpce_event_cb(Handle, Cosmos clos term)

% --- value conversion ----------------------------------------------------
% Cosmos only speaks numbers, strings, lists, tables and closures, so the
% bridge converts at the boundary in both directions.

% Incoming: integral floats become ints (XPCE slots usually want ints;
% genuine fractions pass through untouched), strings become atoms (XPCE
% accepts atoms everywhere a name or text is needed).
xpce_in(Value, Value) :- var(Value), !.
xpce_in(Value, Int) :- float(Value), Value =:= round(Value), !, Int is round(Value).
xpce_in(Value, Value) :- number(Value), !.
xpce_in(String, Atom) :- string(String), !, atom_string(Atom, String).
xpce_in(List, Converted) :- is_list(List), !, maplist(xpce_in, List, Converted).
xpce_in(Value, Value).

% Outgoing: numbers and strings pass through, atoms become strings so
% Cosmos string operations work on them, live objects become fresh
% handles, and empty (@nil) becomes Cosmos null.
%
% XPCE 10 hands an object back in one of two shapes:
%
%   * a NAMED object -- @display, @off, @(nil) -- as the compound
%     @(Name): functor @, arity 1.
%   * an UNNAMED object -- the editor of a view, a text buffer -- as a
%     SWI pce_reference term, which prints as "<pce>(0xADDRESS,CLASS)".
%
% The older bridge only recognised the first shape, so every unnamed
% object came out of get/3 as a raw reference instead of a handle, and
% the next call with it died with
%
%   xpce_handle '<pce>(0x21bacaae210,editor)' does not exist
%
% which is what stopped xpce/notepad.co from running at all.
%
% The object test therefore has to come BEFORE the atom clause: an
% object reference is not an atom, but it is not a compound either, so
% the older `compound(Ref), functor(Ref, F, 1), F == '@'' test never
% matched it either.
xpce_out(Value, Value) :- var(Value), !.
xpce_out(Ref, fc_null) :- xpce_null_ref(Ref), !.
xpce_out(Ref, Handle) :- xpce_object_ref(Ref), !,
    xpce_remember(Ref, Handle).
xpce_out(Value, Value) :- number(Value), !.
xpce_out(Value, Value) :- string(Value), !.
xpce_out(Atom, String) :- xpce_plain_atom(Atom), !, atom_string(Atom, String).
xpce_out(Value, Value).

% The nil object, which Cosmos sees as null.
xpce_null_ref(Value) :-
    functor(Value, '@', 1),
    arg(1, Value, nil).

% Is this an XPCE object reference?
%
% XPCE's own object/1 recognises both shapes.  The shape test below is
% the fallback for a build whose object/1 does not: it cannot look inside
% a pce_reference with sub_string/5 (that rejects it outright), but
% term_to_atom/2 can, and the printed form is distinctive.
xpce_object_ref(Value) :-
    (   object(Value)
    ->  true
    ;   functor(Value, '@', 1)
    ->  true
    ;   functor(Value, _, 0),
        term_to_atom(Value, Atom),
        sub_string(Atom, 0, 5, _, "<pce>(")
    ).

% A plain atom: an ordinary value, not an object reference.
xpce_plain_atom(Value) :-
    functor(Value, _, 0),
    \+ xpce_object_ref(Value).

xpce_remember(Ref, Handle) :-
    xpce_next_handle(Handle),
    assertz(xpce_obj(Handle, Ref)).

% Reserve a number without attaching an object yet: the timer's own
% message must carry its handle, so the number has to be ground BEFORE
% the message term is built (XPCE copies message arguments).
xpce_reserve_handle(Handle) :-
    xpce_next_handle(Handle).

xpce_next_handle(Handle) :-
    (   retract(xpce_next_id(N)) -> Handle is N + 1 ; Handle = 1 ),
    assertz(xpce_next_id(Handle)).

% Handles are small ints, but a trip through Cosmos arithmetic can turn 3
% into 3.0, so normalize before lookup.  An unbound handle is a Cosmos bug;
% fail loudly instead of unifying with someone else's object.
xpce_resolve(Handle, _) :-
    var(Handle), !,
    throw(error(instantiation_error, xpce_handle)).
xpce_resolve(Handle, Ref) :-
    ( number(Handle) -> H is round(Handle) ; H = Handle ),
    ( xpce_obj(H, Ref) -> true
    ; throw(error(existence_error(xpce_handle, Handle), _))
    ).

% Send-argument conversion: like xpce_in/2, except a number that matches a
% live handle resolves to its object (so handles compose inside arg lists).
xpce_arg(Number, Ref) :- number(Number),
    H is round(Number),
    xpce_obj(H, Ref), !.
xpce_arg(Value, Converted) :- xpce_in(Value, Converted).
xpce_args([], []).
xpce_args([H|T], [H2|T2]) :- xpce_arg(H, H2), xpce_args(T, T2).

% --- objects ---------------------------------------------------------------

% xpce_new(+ClassString, +Args, -Handle).
xpce_new(ClassString, Args, Handle) :-
    atom_string(Class, ClassString),
    xpce_args(Args, Args2),
    Term =.. [Class|Args2],
    new(Ref, Term),
    % Top-level windows quit the process on close, Space-style: without
    % this the loop would spin forever over an empty display.
    ( memberchk(Class, [picture, frame, dialog]) ->
        catch(send(Ref, done_message, message(@prolog, halt)), _, true)
    ; true
    ),
    xpce_remember(Ref, Handle).

% xpce_send(+Handle, +MethodString, +Args).
xpce_send(Handle, MethodString, Args) :-
    xpce_resolve(Handle, Ref),
    atom_string(Method, MethodString),
    xpce_args(Args, Args2),
    Msg =.. [Method|Args2],
    send(Ref, Msg).

% xpce_get(+Handle, +AttrString, -Value).
xpce_get(Handle, AttrString, Value) :-
    xpce_resolve(Handle, Ref),
    atom_string(Attr, AttrString),
    get(Ref, Attr, Raw),
    xpce_out_value(Raw, Value).

% get/3 on a string object yields another string object; unwrap those to
% plain text instead of handing out handles to them.  Everything else that
% is a live XPCE object becomes a handle, so the caller can use it again.
%
% The object test is the shape test of xpce_object_ref/1, for the reason
% given there.
xpce_out_value(Raw, Value) :-
    xpce_object_ref(Raw), !,
    (   catch((get(Raw, class, C), get(C, name, string)), _, fail)
    ->  (   catch(get(Raw, value, V), _, fail), xpce_plain_atom(V)
        ->  atom_string(V, Value)
        ;   xpce_remember(Raw, Value)
        )
    ;   xpce_remember(Raw, Value)
    ).
xpce_out_value(Raw, Value) :- xpce_out(Raw, Value).

% xpce_free(+Handle): destroy the object and forget the handle.  Never
% call on an open window outside the event loop -- close it instead.
xpce_free(Handle) :-
    xpce_resolve(Handle, Ref),
    retractall(xpce_obj(Handle, _)),
    send(Ref, free).

% --- value constructors (XPCE compounds Cosmos cannot spell) ----------------

hex_digit_value(Code, Value) :-
    Code >= 0'0, Code =< 0'9, !, Value is Code - 0'0.
hex_digit_value(Code, Value) :-
    Code >= 0'a, Code =< 0'f, !, Value is Code - 0'a + 10.
hex_digit_value(Code, Value) :-
    Code >= 0'A, Code =< 0'F, !, Value is Code - 0'A + 10.

hex_pair_value([Hi, Lo], Value) :-
    hex_digit_value(Hi, H), hex_digit_value(Lo, L),
    Value is H * 16 + L.

% xpce_color(+SpecString, -Handle): '#rrggbb' or a colour name.
xpce_color(Spec, Handle) :-
    (   string(Spec), sub_string(Spec, 0, 1, _, "#"),
        sub_string(Spec, 1, 6, _, Hex), string_codes(Hex, [R1, R2, G1, G2, B1, B2]),
        hex_pair_value([R1, R2], R), hex_pair_value([G1, G2], G), hex_pair_value([B1, B2], B)
    ->  new(Ref, colour(@default, R, G, B))
    ;   atom_string(Name, Spec),
        new(Ref, colour(Name))
    ),
    xpce_remember(Ref, Handle).

% xpce_point(+X, +Y, -Handle) / xpce_size(+W, +H, -Handle).
xpce_point(X0, Y0, Handle) :-
    xpce_in(X0, X), xpce_in(Y0, Y),
    new(Ref, point(X, Y)),
    xpce_remember(Ref, Handle).

xpce_size(W0, H0, Handle) :-
    xpce_in(W0, W), xpce_in(H0, H),
    new(Ref, size(W, H)),
    xpce_remember(Ref, Handle).

% xpce_font(+FamilyString, +StyleString, +Size, -Handle).
xpce_font(FamilyString, StyleString, Size0, Handle) :-
    atom_string(Family, FamilyString),
    atom_string(Style, StyleString),
    xpce_in(Size0, Size),
    new(Ref, font(Family, Style, Size)),
    xpce_remember(Ref, Handle).

% --- callbacks: SWI-Prolog -> Cosmos ----------------------------------------
% A Cosmos closure is an ordinary Prolog term, so the bridge just files it
% under a fresh id and hands XPCE message(@prolog, xpce_cosmos_fire, Id).
% Message arguments must be ground at construction time, which an integer
% id always is.

xpce_on_click(Handle, Closure) :-
    xpce_resolve(Handle, Ref),
    xpce_next_callback(Id),
    assertz(xpce_callback(Id, Closure)),
    send(Ref, message, message(@prolog, xpce_cosmos_fire, Id, Handle)).

% xpce_timer(+Seconds, +Closure, -Handle): repeating timer.  Seconds pass
% through untouched (fractional intervals are the normal case).  The
% callback gets the timer's own handle, so a one-shot frees itself.
xpce_timer(Secs, Closure, Handle) :-
    xpce_next_callback(Id),
    assertz(xpce_callback(Id, Closure)),
    xpce_reserve_handle(Handle),
    new(Ref, timer(Secs, message(@prolog, xpce_cosmos_fire, Id, Handle))),
    send(Ref, start),
    assertz(xpce_obj(Handle, Ref)).

xpce_next_callback(Id) :-
    (   retract(xpce_next_id(N)) -> Id is N + 1 ; Id = 1 ),
    assertz(xpce_next_id(Id)).

% Fired by XPCE on the event loop.  The closure gets the source handle,
% so one relation can serve many objects.  A throwing Cosmos callback must
% never take the loop down -- but halt/abort travel as unwind/1 balls and
% must be rethrown, or every clean quit becomes exit code 1.
xpce_cosmos_fire(Id, Handle) :-
    (   xpce_callback(Id, Closure)
    ->  catch(call_cl(Closure, [Handle]), Error,
              (   ( Error = unwind(_) ; Error = '$abort' )
              ->  throw(Error)
              ;   print_message(warning, Error)
              ))
    ;   print_message(warning, unknown_xpce_callback(Id))
    ).

% --- keyboard ----------------------------------------------------------------
%
% XPCE 10.0.0 exposes the keyboard as an INPUT DEVICE, @keyboard_device, and
% it answers whether a key is held down right now:
%
%   get(@keyboard_device, key_down, Key, @on)    % held
%   get(@keyboard_device, key_down, Key, @off)   % not held
%
% `Key' is a name XPCE understands: one of its own event names (RET, ESC,
% TAB, BS, DEL, space, insert, pause, cursor_home, end, page_up, page_down,
% cursor_left, cursor_right, cursor_up, cursor_down), f1..f24, a single
% character, or the name SDL uses for the key ("Left Shift").
%
% This is the same call XPCE's own games use -- see prolog/demo/asteroids.pl:
%
%   key_down(Key) :- get(@keyboard_device, key_down, Key, @on).
%
% A name XPCE does not know makes the get fail with "Unknown key".  That is
% an error raised in C++, and an XPCE error during the event loop opens a
% modal dialog that freezes the app, so the name is checked against the
% list XPCE accepts BEFORE it is polled.
%
% The names are QUOTED on purpose: RET, ESC, TAB, BS and DEL start with a
% capital, so unquoted they are Prolog VARIABLES -- and a fact with a
% variable in it matches every name at all.
xpce_device_named('RET').
xpce_device_named('ESC').
xpce_device_named('TAB').
xpce_device_named('BS').
xpce_device_named('DEL').
xpce_device_named(space).
xpce_device_named(insert).
xpce_device_named(pause).
xpce_device_named(cursor_home).
xpce_device_named(end).
xpce_device_named(page_up).
xpce_device_named(page_down).
xpce_device_named(cursor_left).
xpce_device_named(cursor_right).
xpce_device_named(cursor_up).
xpce_device_named(cursor_down).
% The SDL names of the modifier keys.
xpce_device_named('Left Shift').
xpce_device_named('Right Shift').
xpce_device_named('Left Ctrl').
xpce_device_named('Right Ctrl').
xpce_device_named('Left Alt').
xpce_device_named('Right Alt').
xpce_device_named('Left GUI').
xpce_device_named('Right GUI').

% f1 .. f24.
xpce_function_key(F) :-
    atom_length(F, L),
    L >= 2, L =< 3,
    sub_atom(F, 0, 1, _, "f"),
    sub_atom(F, 1, _, 0, Digits),
    atom_number(Digits, N),
    between(1, 24, N).

% Is this a name the keyboard device is guaranteed to know?
xpce_device_key_known(Key) :-
    (   xpce_device_named(Key)
    ->  true
    ;   atom_length(Key, 1)
    ->  true
    ;   xpce_function_key(Key)
    ).

% xpce_key_down(+Key, -Down): is the key held down?  Down is 1 or 0.
%
% The key is a name XPCE understands; see the note above.  A name XPCE does
% not know is reported as "not down" rather than as an error.
xpce_key_down(Key0, Down) :-
    (   atom(Key0)
    ->  Key = Key0
    ;   atom_string(Key0, Key)
    ),
    (   xpce_device_key_known(Key),
        catch(get(@keyboard_device, key_down, Key, @on), _, fail)
    ->  Down = 1
    ;   Down = 0
    ).

% --- keyboard and mouse events -----------------------------------------------
%
% XPCE delivers key and mouse events to the graphical that has the keyboard
% or pointer focus, and the documented hook is the ->event method of class
% graphical.  That method is a CLASS-level method, so it cannot be attached
% to a plain picture from Prolog; it has to be redefined on a subclass.  That
% is what xpce_canvas is: a picture that hands its events to Cosmos.
%
% Create one with
%
%   xp.create('xpce_canvas', ['Title'], Handle)
%
% and attach a callback with xp.on_event/2.

% XPCE pushes these operators into its own compilation units rather than
% exporting them, so this file has to declare them itself.
% XPCE pushes these operators into its own compilation units rather than
% exporting them, so this file has to declare them itself.
:- op(1200, xfx, :->).
:- op(1200, xfx, :<-).

:- pce_begin_class(xpce_canvas, picture,
                   "A picture that hands its XPCE events to Cosmos").

event(G, Ev:event) :->
    (   xpce_capture(G, Ev)
    ->  true
    ;   true
    ),
    (   send_super(G, event, Ev)
    ->  true
    ;   true
    ).

:- pce_end_class.

% Hand the event to the Cosmos callback registered for this object, if any.
% Nothing here may raise: an error inside the XPCE dispatch opens a modal
% dialog and freezes the application.
xpce_capture(G, Ev) :-
    (   xpce_event_callback(G, Closure)
    ->  (   catch(xpce_event_table(Ev, Fields), _, fail)
        ->  list_to_assoc(Fields, Table),
            % The table is built inside XPCE's event dispatch, and the cells
            % of that dispatch do not survive it.  A callback that keeps the
            % event (in the program state, say) would then find a half-built
            % table, so hand it a copy that owns its cells.
            copy_term(Table, Owned),
            catch(call_cl(Closure, [Owned]), Error,
                  print_message(warning, Error))
        ;   true
        )
    ;   true
    ).

xpce_event_callback(Ref, Closure) :-
    xpce_obj(Handle, Ref),
    xpce_event_cb(Handle, Closure).

% The XPCE event as a Cosmos table.  The keys are STRINGS, because a Cosmos
% table is an assoc and every lookup goes through cosmos_get/3 with a
% string key.
%
% Verified accessors for this build:
%   get(Ev, id, Id)          integer (ASCII) or atom (named key / event)
%   get(Ev, key, K)          the Emacs-style name of a key event; for a
%                             key_up it is the name of the key released
%   get(Ev, position, Pt)    a point object; the coordinates come from
%   get(Pt, x, X), get(Pt, y, Y)
%   get(Ev, button, B)       left | middle | right
%   get(Ev, multiclick, Mc)  single | double | triple
%   send(Ev, is_a, mouse)    type test
%   send(Ev, is_a, key_up)   type test: a key release
%   send(Ev, has_modifier, s|c|m)
xpce_event_table(Ev, Fields) :-
    get(Ev, id, Id),
    (   catch(send(Ev, is_a, mouse), _, fail)
    ->  xpce_mouse_table(Ev, Id, Fields)
    ;   xpce_key_table(Ev, Id, Fields)
    ).

xpce_mouse_table(Ev, Id, Fields) :-
    (   catch(get(Ev, position, Pt), _, fail),
        catch(get(Pt, x, X), _, fail),
        catch(get(Pt, y, Y), _, fail)
    ->  true
    ;   X = 0, Y = 0
    ),
    (   catch(send(Ev, is_down), _, fail) -> Type = "mousedown"
    ;   catch(send(Ev, is_up), _, fail)   -> Type = "mouseup"
    ;   xpce_mouse_id(Id, Type)
    ),
    (   catch(get(Ev, button, Button), _, fail) -> true ; Button = none ),
    (   catch(get(Ev, multiclick, Clicks), _, fail) -> true ; Clicks = none ),
    Fields = [ "type"-Type, "x"-X, "y"-Y, "posx"-X, "posy"-Y,
               "button"-Button, "clicks"-Clicks ].

xpce_mouse_id(loc_move, Type) :- !, Type = "mousemotion".
xpce_mouse_id(loc_still, Type) :- !, Type = "mousemotion".
xpce_mouse_id(wheel, Type) :- !, Type = "mousewheel".
xpce_mouse_id(_, Type) :- Type = "mousemotion".

% A key press is identified by its id: an integer for a printable character
% (the code of the character as typed, so shift is folded in) or an atom for
% a named key.  A key RELEASE is an event of its own: the id is the atom
% key_up and the key it releases comes from `event <-key', which answers the
% Emacs-style name of the matching key-down ("a", "A", "RET", "<f1>").
xpce_key_table(Ev, Id, Fields) :-
    (   catch(send(Ev, is_a, key_up), _, fail)
    ->  Type = "keyup",
        (   catch(get(Ev, key, Released), _, fail)
        ->  Key = Released
        ;   Key = ""
        )
    ;   Type = "keydown",
        xpce_key_id(Id, Key, Char)
    ),
    Fields = [ "type"-Type, "key"-Key, "char"-Char ].

xpce_key_id(Id, Key, Char) :-
    (   integer(Id)
    ->  char_code(C, Id),
        (   xpce_control_key(C, Name)
        ->  Key = Name, Char = ""
        ;   atom_chars(Atom, [C]),
            atom_string(Atom, Key),
            atom_chars(CharAtom, [C]),
            atom_string(CharAtom, Char)
        )
    ;   atom(Id)
    ->  atom_string(Id, Key), Char = ""
    ;   Key = "", Char = ""
    ).

% The control characters, which have names rather than characters.
xpce_control_key(8, "backspace").
xpce_control_key(9, "tab").
xpce_control_key(10, "return").
xpce_control_key(13, "return").
xpce_control_key(27, "escape").
xpce_control_key(32, "space").

% xpce_on_event(+Handle, +Closure): hand every XPCE event of this object to
% the Cosmos relation.  The relation gets one argument: a table with the
% event fields.
xpce_on_event(Handle, Closure) :-
    xpce_resolve(Handle, Ref),
    retractall(xpce_event_cb(Handle, _)),
    assertz(xpce_event_cb(Handle, Closure)).

% --- shared slots -------------------------------------------------------------
% Callbacks take exactly one argument (their source handle), so they
% cannot see top-level bindings -- a 1-argument rel capturing anything
% would become 2-argument and miss the call.  These named slots are the
% shared state instead: plain terms, stored and returned untouched.
xpce_set_data(Key, Value) :-
    retractall(xpce_data(Key, _)),
    assertz(xpce_data(Key, Value)).

xpce_get_data(Key, Value) :-
    xpce_data(Key, Value).

% --- menu bitmap priming ------------------------------------------------------
% Labelled popups die in initialise converting the submenu-arrow program
% default (@ms_left_arrow_image): this install keeps its bitmaps outside
% XPCE's built-in image path.  Preloading the file primes the image cache
% and later popups just work.  Harmless where bitmaps resolve already;
% silent no-op when the file is absent.
xpce_prime_menu_bitmaps :-
    (   get(@pce, home, Home),
        atom_concat(Home, '/bitmaps/left_arrow.png', Path),
        catch(new(_, image(Path)), _, fail)
    ->  true
    ;   true
    ).

:- xpce_prime_menu_bitmaps.

% --- event loop --------------------------------------------------------------
% xpce_loop: dispatch XPCE events until the process ends (window close is
% wired to halt at creation sites the program controls, and quit() ends
% it from a callback).  Like pce_main_loop/1 this never returns; unlike
% it, windows may be created BEFORE the loop starts, because the loop
% does not track frames -- it just pumps the display.  Control balls
% (halt/abort) are rethrown so quit() from a callback really quits.
xpce_loop :-
    repeat,
    catch(send(@display, dispatch), Error,
          (   ( Error = unwind(_) ; Error = '$abort' )
          ->  throw(Error)
          ;   true
          )),
    sleep(0.01),
    fail.
xpce_loop.

% xpce_poll: pump the display exactly once, for tests and custom loops.
% Succeeds except for control balls, which are rethrown as above.
xpce_poll :-
    catch(send(@display, dispatch), Error,
          (   ( Error = unwind(_) ; Error = '$abort' )
          ->  throw(Error)
          ;   true
          )).
