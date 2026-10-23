/* bootstrap.pl
   Simple bootstrap to load required SWI-Prolog libraries and prolog-llm modules.

   Usage:
     ?- ['bootstrap'].
     ?- start.
     ?- send("Hello", Reply).

   This file ensures the HTTP/JSON/PCRE libraries are loaded, sets UTF-8
   output encoding, then consults your config and the prolog-llm modules.
*/

:- use_module(library(http/http_open)).
:- use_module(library(http/http_json)).
:- use_module(library(json)).
:- use_module(library(pcre)).

% Windows consoles may refuse encoding changes; that is not fatal.
:- catch(set_stream(current_output, encoding(utf8)), _, true).

% start/0 loads configuration and the llm modules. It prefers config.pl if
% present, otherwise falls back to config.sample.pl so you can try quickly.
start :-
    ( exists_file('config.pl') -> consult('config') ; consult('config.sample') ),
    consult('message'),
    consult('llm'),
    consult('llm/ollama'),
    format('Loaded config, message, llm and llm/ollama~n').

% send(+Prompt, -Reply) ensures the modules are loaded then calls ollama/2.
send(Prompt, Reply) :-
    ( current_predicate(ollama:ollama/2) -> true ; start ),
    ollama:ollama(Prompt, Reply).