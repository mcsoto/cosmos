/*
  Author:   Pieter Van den Abeele
  E-mail:   pvdabeel@mac.com
  Copyright (c) 2005-2026, Pieter Van den Abeele

  Distributed under the terms of the LICENSE file in the root directory of this
  project.
*/


/** <module> GROK
Implements interaction with x.AI Grok.
We implement real-time streaming.

We support any model available, default is set to 'grok-4-1-fast-reasoning'.
*/

:- module(grok, [grok/0, grok/1, grok/2]).

% =============================================================================
%  GROK declarations
% =============================================================================

% -----------------------------------------------------------------------------
%  Conversation history
% -----------------------------------------------------------------------------

:- dynamic history/1.

history([]).


%! grok:update_history(+History)
%
% Replace the stored conversation history.

update_history(History) :-
  retractall(grok:history(_)),
  assertz(grok:history(History)).


% -----------------------------------------------------------------------------
%  Entry points
% -----------------------------------------------------------------------------

%! grok:grok(+Input, -ResponseContent)
%
% Send Input to Grok and unify ResponseContent with the response text.

grok(Input,ResponseContent) :-
  llm:chat(grok, llm:stream, Input, ResponseContent).


%! grok:grok(+Input)
%
% Send Input to Grok, discarding the response content.

grok(Input) :-
  grok(Input,_).


%! grok:grok
%
% Interactive prompt: read user input, then send to Grok.

grok :-
  llm:get_input(Msg),
  grok(Msg).