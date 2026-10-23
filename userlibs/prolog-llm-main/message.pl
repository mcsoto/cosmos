/*
  Author:   Pieter Van den Abeele
  E-mail:   pvdabeel@mac.com
  Copyright (c) 2005-2026, Pieter Van den Abeele

  Distributed under the terms of the LICENSE file in the root directory of this
  project.
*/


/** <module> MESSAGE
Standalone, dependency-free pretty-printing shim used by `llm.pl` and
`llm/claude.pl`. Provides just the colour/style/horizontal-line predicates
that the streaming code calls before and after each LLM response.

This module is intentionally tiny so that `prolog-llm` has no compile-time
dependency on the much larger `message.pl` from `portage-ng`. If you embed
this library in a host application that already defines a `message`
module, drop this file and let the host implementation take over — the
predicate names below are deliberately the same.

Predicates:
  - message:color(+Name)   - switch foreground colour
  - message:style(+Name)   - switch text style (italic / normal)
  - message:hl             - print a horizontal rule across the terminal
  - message:hl(+Label)     - print a horizontal rule with an inline label
*/


% =============================================================================
%  MESSAGE declarations
% =============================================================================

:- module(message, []).


% -----------------------------------------------------------------------------
%  Colour table
% -----------------------------------------------------------------------------

%! message:ansi_color(?Name, ?Code)
%
% Maps a symbolic colour name onto its ANSI SGR code. `normal` resets all
% attributes (colour, style, background) at once.

message:ansi_color(black,      '30').
message:ansi_color(red,        '31').
message:ansi_color(green,      '32').
message:ansi_color(yellow,     '33').
message:ansi_color(blue,       '34').
message:ansi_color(magenta,    '35').
message:ansi_color(cyan,       '36').
message:ansi_color(white,      '37').
message:ansi_color(lightgray,  '37').
message:ansi_color(darkgray,   '90').
message:ansi_color(normal,     '0').


% -----------------------------------------------------------------------------
%  Style table
% -----------------------------------------------------------------------------

%! message:ansi_style(?Name, ?Code)
%
% Maps a symbolic style name onto its ANSI SGR code.

message:ansi_style(italic,     '3').
message:ansi_style(bold,       '1').
message:ansi_style(underline,  '4').
message:ansi_style(normal,     '0').


% -----------------------------------------------------------------------------
%  Public API
% -----------------------------------------------------------------------------

%! message:color(+Name)
%
% Switch the foreground colour of `current_output` to Name. Unknown names
% silently reset to the terminal default so a host with a custom palette
% does not crash the streaming loop.

message:color(Name) :-
  ( message:ansi_color(Name, Code)
  -> format('\e[~wm', [Code])
  ;  format('\e[0m', [])
  ),
  flush_output.


%! message:style(+Name)
%
% Switch the text style of `current_output` to Name (italic, bold,
% underline or normal). Unknown styles reset to normal.

message:style(Name) :-
  ( message:ansi_style(Name, Code)
  -> format('\e[~wm', [Code])
  ;  format('\e[0m', [])
  ),
  flush_output.


%! message:hl
%
% Print a horizontal rule across the full width of the terminal. Falls
% back to a fixed 78-column rule when the terminal width cannot be
% determined (e.g. when running non-interactively).

message:hl :-
  message:terminal_width(W),
  message:repeat_char('-', W, Bar),
  format('~n~w~n', [Bar]),
  flush_output.


%! message:hl(+Label)
%
% Print a horizontal rule annotated with Label, e.g. "----- claude -----".

message:hl(Label) :-
  message:terminal_width(W),
  format(string(Tag), ' ~w ', [Label]),
  string_length(Tag, TLen),
  Pad is max(0, (W - TLen)) // 2,
  message:repeat_char('-', Pad, Left),
  Right0 is W - Pad - TLen,
  Right is max(0, Right0),
  message:repeat_char('-', Right, RightBar),
  format('~n~w~w~w~n', [Left, Tag, RightBar]),
  flush_output.


% -----------------------------------------------------------------------------
%  Internal helpers
% -----------------------------------------------------------------------------

%! message:terminal_width(-Width)
%
% Best-effort terminal width detection. Uses `tty_size/2` when a tty is
% attached, otherwise falls back to 78 columns.

message:terminal_width(Width) :-
  catch(tty_size(_, Width), _, Width = 78),
  Width > 0,
  !.
message:terminal_width(78).


%! message:repeat_char(+Char, +N, -String)
%
% Build a string of N copies of single-character atom Char.

message:repeat_char(_, N, "") :-
  N =< 0, !.
message:repeat_char(Char, N, String) :-
  length(Codes, N),
  atom_codes(Char, [Code]),
  maplist(=(Code), Codes),
  string_codes(String, Codes).
