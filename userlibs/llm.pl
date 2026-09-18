% HTTP bridge for text-only OpenAI and Mistral chat requests.
% Keys are read only from the process environment: OPENAI_API_KEY and
% MISTRAL_API_KEY.  They are never accepted as Cosmos arguments or written to
% generated programs.
:- use_module(library(http/http_open)).
:- use_module(library(http/json)).

llm(Value) :-
    new(Empty),
    set_(Empty, "openai", clos(upvals([]), llm_openai_cl), OpenAI),
    set_(OpenAI, "mistral", clos(upvals([]), llm_mistral_cl), Value).

llm_openai_cl(Model, Prompt, Reply, upvals([])) :-
    llm_environment_key('OPENAI_API_KEY', Key),
    llm_chat('https://api.openai.com/v1/chat/completions', Key, Model, Prompt, Reply).

llm_mistral_cl(Model, Prompt, Reply, upvals([])) :-
    llm_environment_key('MISTRAL_API_KEY', Key),
    llm_chat('https://api.mistral.ai/v1/chat/completions', Key, Model, Prompt, Reply).

llm_environment_key(Name, Key) :-
    ( getenv(Name, Key), Key \== '' -> true
    ; throw(error(existence_error(environment_variable, Name), llm/1))
    ).

llm_chat(URL, Key, Model, Prompt, Reply) :-
    format(string(Authorization), 'Bearer ~s', [Key]),
    Request = _{model:Model, messages:[_{role:"user", content:Prompt}]},
    setup_call_cleanup(
        http_open(URL, Stream,
                  [ method(post),
                    post(json(Request)),
                    request_header('Authorization'=Authorization),
                    status_code(Status)
                  ]),
        json_read_dict(Stream, Response),
        close(Stream)),
    ( Status >= 200, Status < 300 -> llm_response_text(Response, Reply)
    ; throw(error(llm_http_status(Status, Response), llm_chat/5))
    ).

llm_response_text(Response, Reply) :-
    get_dict(choices, Response, [Choice|_]),
    get_dict(message, Choice, Message),
    get_dict(content, Message, Reply).
