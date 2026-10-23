/*
  Author:   Pieter Van den Abeele
  E-mail:   pvdabeel@mac.com
  Copyright (c) 2005-2026, Pieter Van den Abeele

  Distributed under the terms of the LICENSE file in the root directory of this
  project.
*/


/** <module> CONFIG (sample)
Sample configuration for `prolog-llm`. Copy this file to `config.pl` (or to
`config.local.pl` and reference it from your host application) and fill in
the API keys for the providers you intend to use.

The streaming runtime in `llm.pl` and the per-service modules in `llm/`
look up every parameter through the `config:` namespace, so loading any
file that defines these predicates is enough — there is no init step.

If you embed `prolog-llm` in a larger application that already exposes a
`config` module, simply make sure the predicates listed below are
available before you call any of `chatgpt/1`, `claude/1`, `gemini/1`,
`grok/1`, or `ollama/1`.

Predicates declared here:
  - config:llm_api_key(?Service, ?Key)        - bearer token per service
  - config:llm_endpoint(?Service, ?URL)       - chat-completions URL
  - config:llm_local(?Service)                - service runs locally (no key)
  - config:llm_model(?Service, ?ModelName)    - model name per service
  - config:llm_max_tokens(?N)                 - hard upper bound on tokens
  - config:llm_temperature(?T)                - sampling temperature 0.0-1.0
  - config:llm_sandboxed_execution(?Bool)     - sandbox <call:swi_prolog>
  - config:llm_capability(?Name, ?Prompt)     - capability prompts (optional)

Loading order in your host application:
  ?- [config], [message], [llm], ['llm/chatgpt'], ['llm/claude'],
     ['llm/gemini'], ['llm/grok'], ['llm/ollama'].
*/


% =============================================================================
%  CONFIG declarations
% =============================================================================

:- module(config, []).


% -----------------------------------------------------------------------------
%  API keys (REPLACE with real keys before use)
% -----------------------------------------------------------------------------

%! config:llm_api_key(?Service, ?Key)
%
% Private API key for each service. Ollama runs locally and ignores the
% key, so any non-empty placeholder is fine for that one. The remote
% providers will return HTTP 401/403 if the key is missing or invalid.
%
% In production, prefer keeping these out of source control: split this
% file into `config.pl` (committed, no keys) and `api_key.pl` (ignored
% by `.gitignore`, holds only the api_key clauses), then `:- include`
% the latter from the former.

config:llm_api_key(grok,    'REPLACE-WITH-GROK-API-KEY').
config:llm_api_key(chatgpt, 'REPLACE-WITH-OPENAI-API-KEY').
config:llm_api_key(claude,  'REPLACE-WITH-ANTHROPIC-API-KEY').
config:llm_api_key(gemini,  'REPLACE-WITH-GEMINI-API-KEY').
config:llm_api_key(ollama,  'ollama-local-no-key-required').


% -----------------------------------------------------------------------------
%  Endpoints (chat-completions URLs)
% -----------------------------------------------------------------------------

%! config:llm_endpoint(?Service, ?URL)
%
% HTTPS endpoint that accepts streaming chat-completions requests.
% All endpoints except Anthropic Claude follow the OpenAI wire format.
% The Claude module talks to Anthropic's `/v1/messages` endpoint
% directly and converts payloads internally.

config:llm_endpoint(grok,    'https://api.x.ai/v1/chat/completions').
config:llm_endpoint(chatgpt, 'https://api.openai.com/v1/chat/completions').
config:llm_endpoint(claude,  'https://api.anthropic.com/v1/messages').
config:llm_endpoint(gemini,  'https://generativelanguage.googleapis.com/v1beta/chat/completions').
config:llm_endpoint(ollama,  'http://localhost:11434/v1/chat/completions').


% -----------------------------------------------------------------------------
%  Local services
% -----------------------------------------------------------------------------

%! config:llm_local(?Service)
%
% Declares which services run locally and therefore need no API key. The chat
% driver (llm:check_api_key/2) skips the key requirement for these services, so
% there is no need to configure a placeholder key for them above.

config:llm_local(ollama).


% -----------------------------------------------------------------------------
%  Models
% -----------------------------------------------------------------------------

%! config:llm_model(?Service, ?ModelName)
%
% Default model per service. Override these to pick a faster, cheaper,
% or smarter variant.  Model names are passed through verbatim, so use
% the exact string the provider documents.

config:llm_model(grok,    'grok-4-1-fast-reasoning').
config:llm_model(chatgpt, 'gpt-4o').
config:llm_model(claude,  'claude-sonnet-4-6').
config:llm_model(gemini,  'gemini-3-pro-preview').
config:llm_model(ollama,  'llama3.2').


% -----------------------------------------------------------------------------
%  Generation parameters
% -----------------------------------------------------------------------------

%! config:llm_max_tokens(?N)
%
% Maximum number of tokens the model is allowed to emit per response.

config:llm_max_tokens(4096).


%! config:llm_temperature(?T)
%
% Sampling temperature. 0.0 = deterministic, 1.0 = highly creative.

config:llm_temperature(0.7).


% -----------------------------------------------------------------------------
%  Code-execution sandbox
% -----------------------------------------------------------------------------

%! config:llm_sandboxed_execution(?Bool)
%
% Controls whether SWI-Prolog code wrapped in `<call:swi_prolog>` tags
% by the LLM is executed inside SWI-Prolog's sandbox library
% (`sandboxed(true)` for `load_files/2`). Set to `false` only when you
% fully trust the model output — sandboxing prevents unsafe builtins
% from running.

config:llm_sandboxed_execution(true).


% -----------------------------------------------------------------------------
%  Capability prompts (optional)
% -----------------------------------------------------------------------------

%! config:llm_capability(?Name, ?Prompt)
%
% Capability prompts injected by `llm:prompt/1` into the first message
% of a conversation. They tell the model what `<call:...>` tags it can
% emit and how the tag-replay loop works. Add or remove clauses to
% customise the bootstrap prompt; the order of clauses determines the
% order in the concatenated prompt.

config:llm_capability(chat, Capability) :-
  Description = "When formulating a response, you may optionally enclose a
                 message (e.g., a question) in <call:chatgpt>, <call:gemini>,
                 <call:ollama>, <call:grok> or <call:claude> tags to send it
                 to the respective LLM. The response is automatically returned
                 to you, with each LLM maintaining its own history of your
                 queries.",
  normalize_space(string(Capability), Description).

config:llm_capability(code, Capability) :-
  Description = "When asked to write SWI-Prolog code, you may optionally
                 enclose the code in <call:swi_prolog> XML tags. Any code
                 within these tags will be executed locally in a temporary
                 module, with the output automatically returned to you. Do
                 not mention the XML tags unless you include SWI-Prolog code
                 between them. Write the code as if it were loaded from a
                 separate source file, including triggering execution of your
                 main function using a :- directive, such as :- main. The
                 temporary module is destroyed after execution.",
  normalize_space(string(Capability), Description).
