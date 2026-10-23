/*  ollama.pl -- Prompt a locally running Ollama through prolog-llm.

    Uses the prolog-llm library that lives next to this file:

        prolog-llm-main/llm.pl          shared streaming runtime
        prolog-llm-main/llm/ollama.pl   Ollama frontend (ollama/0..2)
        prolog-llm-main/config.pl       endpoint + model for local Ollama
        prolog-llm-main/message.pl      terminal colour helper

    config.pl declares Ollama as a local, key-less service:

        endpoint:  http://localhost:11434/v1/chat/completions
        model:     llama3.2        (override with $OLLAMA_MODEL or set_model/1)

    Prerequisites:

        1) start Ollama                    ollama serve
        2) pull the configured model once  ollama pull llama3.2

    Command line (answers stream live to the terminal):

        swipl -q ollama.pl -- "Why is Prolog cool?"   % one-shot prompt
        swipl -q ollama.pl -- repl                    % interactive chat loop
        swipl -q ollama.pl -- ping                    % diagnose Ollama
        swipl -q ollama.pl -- clear                   % reset conversation
        swipl -q -t main ollama.pl                    % built-in demo prompt

    Inside SWI-Prolog:

        ?- [ollama].
        ?- ask("Explain tail recursion in one sentence.").
        ?- ask("Now give an example of it.", Reply).   % continues the chat
        ?- repl.
        ?- clear_history.
        ?- set_model('qwen2.5:0.5b').
        ?- ping.
*/

:- use_module(library(http/http_open)).     % HTTP client behind llm:stream/5
:- use_module(library(http/http_json)).     % lets http_open post json(...) payloads
:- use_module(library(http/json)), use_module(library(readutil)).  % dicts + streams
:- use_module(library(pcre)).               % <call:...> tag replay in llm.pl
:- use_module(library(sandbox)).            % sandboxed <call:swi_prolog> replay

% ---------------------------------------------------------------------------
%  Load prolog-llm relative to this file (order: config, message, llm, ollama)
% ---------------------------------------------------------------------------

:- prolog_load_context(source, Me),
   file_directory_name(Me, Here),
   format(atom(LlmHome), '~w/prolog-llm-main', [Here]),
   forall(member(Sub, ['config', 'message', 'llm', 'llm/ollama']),
          ( format(atom(File), '~w/~w.pl', [LlmHome, Sub]),
            use_module(File) )).

% set_model/1 patches the model clause at runtime, so it must be dynamic.
:- dynamic(config:llm_model/2).

% ---------------------------------------------------------------------------
%  Small helpers
% ---------------------------------------------------------------------------

% as_text(+Any, -Text): unify Text with a string rendering of Any.
as_text(A, S) :- atom(A), !, atom_string(A, S).
as_text(S, S) :- string(S), !.
as_text(X, S) :- format(string(S), '~w', [X]).

% arg_atom(+Arg, -Atom): normalise a command line argument to an atom.
arg_atom(A, A) :- atom(A), !.
arg_atom(S, A) :- string(S), !, atom_string(A, S).
arg_atom(X, A) :- format(atom(A), '~w', [X]).

% plain_arg(+Atom): an argument that is a prompt, not an option or script.
plain_arg(A) :- atom_concat('-', _, A), !, fail.
plain_arg(A) :- atom_concat(_, '.pl', A), !, fail.
plain_arg(_).

% ---------------------------------------------------------------------------
%  Configuration helpers
% ---------------------------------------------------------------------------

%!  set_model(+Model) is det.
%
%   Switch the Ollama model used from now on, e.g.
%   set_model('qwen2.5:0.5b').

set_model(Model) :-
    as_text(Model, M),
    retractall(config:llm_model(ollama, _)),
    assertz(config:llm_model(ollama, M)).

%!  model(-Model) is det.
%
%   Ollama model to use.  Prefers the configured one; if it is not
%   pulled locally, falls back to the first model Ollama has and
%   selects it for the rest of the session.

model(Configured) :-
    config:llm_model(ollama, Configured),
    model_available(Configured),
    !.

model(Fallback) :-
    config:llm_model(ollama, _),
    available_model(Fallback),
    !,
    format(user_error, '[model] not pulled locally, using ~w~n[models] pull more: ollama pull llama3.2~n', [Fallback]),
    set_model(Fallback).

model(Configured) :-
    config:llm_model(ollama, Configured).

%!  ensure_model is det.
%
%   Make sure the configured Ollama model is actually pulled locally;
%   otherwise switch to the first available one (and keep using it).

ensure_model :-
    config:llm_model(ollama, Configured),
    (   model_available(Configured)
    ->  true
    ;   catch(available_model(Fallback), _, fail),
        format(user_error,
               '~N[model] ~w is not pulled locally, using ~w instead~n[model] pull it with: ollama pull ~w~n',
               [Configured, Fallback, Configured]),
        set_model(Fallback)
    ).

%!  model_available(+Name) is semidet.
%
%   Succeeds if Ollama reports a locally pulled model called Name.

model_available(Name) :-
    catch(( ollama_models(Models),
            member(M, Models),
            get_dict(name, M, Name)
          ), _, fail).

%!  available_model(-Name) is semidet.
%
%   Name of the first locally available model (from Ollama's own list).

available_model(Name) :-
    catch(( ollama_models([First|_]),
            get_dict(name, First, Name)
          ), _, fail).

%!  ollama_models(-Models) is semidet.
%
%   Ask Ollama for its list of locally pulled models.

ollama_models(Models) :-
    http_open('http://localhost:11434/api/tags', In, []),
    call_cleanup(json_read_dict(In, Reply), close(In)),
    get_dict(models, Reply, Models),
    Models \== [].

%!  clear_history is det.
%
%   Forget the conversation so far.

clear_history :-
    retractall(ollama:history(_)),
    assertz(ollama:history([])).

% ---------------------------------------------------------------------------
%  Native Ollama (/api/chat) fallback
%
%  Some Ollama builds (e.g. certain desktop releases) 404 the OpenAI-
%  compatible /v1/chat/completions route while /api/* works.  The probe
%  at the bottom of this file picks the backend once per session.
% ---------------------------------------------------------------------------

%!  backend(?Backend)
%
%   Which streaming path ask/2 uses: openai (via prolog-llm's llm:stream/5)
%   or native (our own /api/chat NDJSON streamer below).

:- dynamic backend/1.

backend(openai).

%!  native_stream(+Endpoint, +APIKey, +Model, +Messages, -Response)
%
%   Stream a chat-completions request to Ollama's native /api/chat
%   endpoint (NDJSON: one JSON object per line, {"done":true} last).

native_stream(Endpoint, _APIKey, Model, Messages, Response) :-
    config:llm_max_tokens(Max),
    config:llm_temperature(Temperature),
    Payload = _{model: Model, messages: Messages, stream: true,
               options: _{num_predict: Max, temperature: Temperature, think: false}},
    catch(set_stream(current_output, encoding(utf8)), _, true),
    Headers = [method(post),
               request_header('Content-Type'='application/json'),
               post(json(Payload)),
               timeout(300)],
    catch(( http_open(Endpoint, In, Headers),
            set_stream(In, encoding(utf8)),
            setup_call_cleanup((llm:begin_stream(Model)),
                               (native_chunks(In, Contents)),
                               (llm:end_stream(Model),
                                close(In))),
            llm:prepare_history(Contents, Messages, NewMessages),
            Response = _{contents: Contents, history: NewMessages}
          ),
          Error,
          Response = _{error: Error, history: Messages}).

%!  native_chunks(+Stream, -Contents)
%
%   Consume the NDJSON stream; Contents is a list of content strings.

native_chunks(In, Contents) :-
    native_chunks(In, [], Contents).

native_chunks(In, Acc, Contents) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  reverse(Acc, Contents)
    ;   Line == ""
    ->  native_chunks(In, Acc, Contents)
    ;   catch(json_read_dict(Line, Dict, []), _, Dict = _{}),
        (   get_dict(done, Dict, true)
        ->  reverse(Acc, Contents)
        ;   (   get_dict(error, Dict, Error)
            ->  throw(error(ollama_error, Error))
            ;   true
            ),
            get_dict(message, Dict, Msg),
            get_dict(content, Msg, Content),
            (   Content == ""
            ->  native_chunks(In, Acc, Contents)
            ;   write(Content), flush_output,
                native_chunks(In, [Content|Acc], Contents)
            )
        )
    ).

%!  native_chat(+Input, -Reply)
%
%   One native-backend chat turn: mirrors what llm:chat/4 does for the
%   OpenAI path (same message prep, same ollama:history/1 bookkeeping),
%   but without the <call:...> tag-replay loop.

native_chat(Input, Reply) :-
    config:llm_model(ollama, Model),
    ollama:history(History),
    llm:prepare_message(History, 'user', Input, Messages),
    native_stream('http://localhost:11434/api/chat', '', Model, Messages, Response),
    (   Response = _{contents: Contents, history: NewHistory}
    ->  atomic_list_concat(Contents, Reply),
        ollama:update_history(NewHistory)
    ;   Response = _{error: Error}
    ->  write('Error: '), write(Error), nl,
        Reply = ''
    ).

% ---------------------------------------------------------------------------
%  Diagnostics
% ---------------------------------------------------------------------------

%!  ping is det.
%
%   Check that Ollama is reachable and show available models.

ping :-
    Url = 'http://localhost:11434/api/tags',
    catch(
        ( http_open(Url, In, []),
          call_cleanup(json_read_dict(In, Reply), close(In)),
          format('~N[ping] Ollama is up at ~w~n', [Url]),
          (   get_dict(models, Reply, Models)
          ->  forall(member(M, Models),
                     ( get_dict(name, M, N),
                       format('~N[ping]   model available: ~w~n', [N])) )
          ;   true
          ),
          (   model(Cur)
          ->  format('~N[ping] using model: ~w~n', [Cur])
          ;   true
          )
        ),
        Error,
        (   format(user_error, '~N[ping] Ollama not reachable at ~w~n', [Url]),
            format(user_error, '[ping] error: ~w~n', [Error]),
            format(user_error, '[ping] start it with: ollama serve~n', []),
            format(user_error, '[ping] pull a model:  ollama pull llama3.2~n', [])
        )
    ).

% ---------------------------------------------------------------------------
%  Asking Ollama
% ---------------------------------------------------------------------------

%!  ask(+Input) is det.
%
%   Send Input to Ollama; the answer streams to current_output and is
%   discarded.

ask(Input) :-
    ask(Input, _).

%!  ask(+Input, -Reply) is det.
%
%   Send Input to local Ollama and unify Reply with the full answer.
%   The conversation is remembered across calls (ollama:history/1), so
%   follow-up questions keep their context until clear_history/0.

ask(Input, Reply) :-
    ensure_model,
    (   backend(openai)
    ->  ollama:ollama(Input, Raw)
    ;   native_chat(Input, Raw)
    ),
    as_text(Raw, Reply),
    (   Reply == ""
    ->  format(user_error,
               '~N[ask] Ollama returned an empty reply. Try ?- ping. to diagnose.~n',
               [])
    ;   true
    ).

% ---------------------------------------------------------------------------
%  Interactive REPL
% ---------------------------------------------------------------------------

%!  repl is det.
%
%   Line-based chat loop.  Type a prompt; "q"/"quit"/"exit" leaves,
%   "reset" clears the conversation, "model" shows the model in use.

repl :-
    clear_history,
    model(M),
    format('~N[repl] Chatting with Ollama (~w). "q" quits, "reset" clears history.~n', [M]),
    repl_loop.

repl_loop :-
    format('~N> ', []),
    flush_output,
    catch(read_line_to_string(user_input, LineStr), _, LineStr = end_of_file),
    repl_dispatch(LineStr).

repl_dispatch(end_of_file) :- !.

repl_dispatch(LineStr) :-
    atom_string(Line, LineStr),
    downcase_atom(Line, Low),
    (   Low == ''
    ->  repl_loop
    ;   Low == 'reset'
    ->  clear_history,
        model(M2),
        format('~N[reset] History cleared. Model: ~w~n', [M2]),
        repl_loop
    ;   Low == 'model'
    ->  model(M3),
        format('~N[model] ~w~n', [M3]),
        repl_loop
    ;   (   Low == 'q'
        ;   Low == 'quit'
        ;   Low == 'exit'
        )
    ->  format('~N[bye]~n')
    ;   ask(LineStr, _),
        repl_loop
    ).

% ---------------------------------------------------------------------------
%  Entry points
% ---------------------------------------------------------------------------

%!  main is det.
%
%   Command line entry point (via :- initialization(main, main)):
%
%       swipl -q ollama.pl -- repl
%       swipl -q ollama.pl -- ping
%       swipl -q ollama.pl -- clear
%       swipl -q ollama.pl -- help
%       swipl -q ollama.pl -- "Why is Prolog cool?"

main :-
    (   catch(current_prolog_flag(argv, Argv), _, fail)
    ->  true
    ;   Argv = []
    ),
    main(Argv).

main(Argv0) :-
    maplist(arg_atom, Argv0, Atoms),
    (   memberchk(repl, Atoms) -> repl
    ;   memberchk(ping, Atoms) -> ping
    ;   memberchk(clear, Atoms) -> clear_history
    ;   memberchk(help, Atoms) -> print_usage
    ;
	include(plain_arg, Atoms, Plain), Plain \== [],
    !,  atomic_list_concat(Plain, ' ', Prompt),
        ask(Prompt)
    ;   throw(1),default_prompt(P),            % no usable argument: demo prompt
        normalize_space(string(Prompt), P),
        ask(Prompt)
    ), !.

default_prompt('In two short sentences, explain what makes Prolog different
                from mainstream programming languages.').

print_usage :-
    format('~NUsage:  swipl -q ollama.pl -- [ repl | ping | clear | help | "prompt ..." ]~n', []).

% ---------------------------------------------------------------------------
%  Hooks
% ---------------------------------------------------------------------------

% Apply $OLLAMA_MODEL (if set) once all definitions above are loaded.

env_model :-
    getenv('OLLAMA_MODEL', V),
    as_text(V, T),
    T \== "",
    set_model(T).

:- ( catch(env_model, _, true) ; true ).

:- initialization(main, main).
