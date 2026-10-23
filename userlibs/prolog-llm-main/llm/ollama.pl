/*
  Author:   Pieter Van den Abeele
  E-mail:   pvdabeel@mac.com
  Copyright (c) 2005-2026, Pieter Van den Abeele

  Distributed under the terms of the LICENSE file in the root directory of this
  project.
*/


/** <module> OLLAMA
Implements interaction with Ollama (typically locally running).
We implement real-time streaming.

We support any model available, default is set to 'llama3.2'.
*/

:- module(ollama, [ollama/0, ollama/1, ollama/2]).

% =============================================================================
%  OLLAMA declarations
% =============================================================================

% -----------------------------------------------------------------------------
%  Conversation history
% -----------------------------------------------------------------------------

:- dynamic history/1.

history([]).


%! ollama:update_history(+History)
%
% Replace the stored conversation history.

update_history(History) :-
  retractall(ollama:history(_)),
  assertz(ollama:history(History)).


% -----------------------------------------------------------------------------
%  Entry points
% -----------------------------------------------------------------------------

%! ollama:ollama(+Input, -ResponseContent)
%
% Send Input to Ollama and unify ResponseContent with the response text.

ollama(Input,ResponseContent) :-
  llm:chat(ollama, llm:stream, Input, ResponseContent).


%! ollama:ollama(+Input)
%
% Send Input to Ollama, discarding the response content.

ollama(Input) :-
  ollama(Input,_).


%! ollama:ollama
%
% Interactive prompt: read user input, then send to Ollama.

ollama :-
  llm:get_input(Msg),
  ollama(Msg).