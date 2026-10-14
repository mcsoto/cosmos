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
xpce_out(Value, Value) :- var(Value), !.
xpce_out(Value, Value) :- number(Value), !.
xpce_out(Value, Value) :- string(Value), !.
xpce_out(Atom, String) :- atom(Atom), !, atom_string(Atom, String).
xpce_out(Ref, fc_null) :- compound(Ref), functor(Ref, F, 1), F == '@', arg(1, Ref, nil), !.
xpce_out(Ref, Handle) :- compound(Ref), functor(Ref, F, 1), F == '@', !,
    xpce_remember(Ref, Handle).
xpce_out(Value, Value).

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
% plain text instead of handing out handles to them.
xpce_out_value(Raw, Value) :-
    compound(Raw), functor(Raw, F, 1), F == '@', arg(1, Raw, Arg), number(Arg), !,
    (   catch((get(Raw, class, C), get(C, name, string)), _, fail)
    ->  (   catch(get(Raw, value, V), _, fail), atom(V)
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
