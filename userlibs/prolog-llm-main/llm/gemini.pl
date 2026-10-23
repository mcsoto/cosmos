/*
  Author:   Pieter Van den Abeele
  E-mail:   pvdabeel@mac.com
  Copyright (c) 2005-2026, Pieter Van den Abeele

  Distributed under the terms of the LICENSE file in the root directory of this
  project.
*/


/** <module> GEMINI
Implements interaction with Google Gemini.
We implement real-time streaming.

We support any model available, default is set to 'gemini-3-pro-preview'.
*/

:- module(gemini, [gemini/0, gemini/1, gemini/2]).

% =============================================================================
%  GEMINI declarations
% =============================================================================

% -----------------------------------------------------------------------------
%  Conversation history
% -----------------------------------------------------------------------------

:- dynamic history/1.

history([]).


%! gemini:update_history(+History)
%
% Replace the stored conversation history.

update_history(History) :-
  retractall(gemini:history(_)),
  assertz(gemini:history(History)).


% -----------------------------------------------------------------------------
%  Entry points
% -----------------------------------------------------------------------------

%! gemini:gemini(+Input, -ResponseContent)
%
% Send Input to Gemini and unify ResponseContent with the response text.

gemini(Input,ResponseContent) :-
  llm:chat(gemini, llm:stream, Input, ResponseContent).


%! gemini:gemini(+Input)
%
% Send Input to Gemini, discarding the response content.

gemini(Input) :-
  gemini(Input,_).


%! gemini:gemini
%
% Interactive prompt: read user input, then send to Gemini.

gemini :-
  llm:get_input(Msg),
  gemini(Msg).