/*
  Author:   Pieter Van den Abeele
  E-mail:   pvdabeel@mac.com
  Copyright (c) 2005-2026, Pieter Van den Abeele

  Distributed under the terms of the LICENSE file in the root directory of this
  project.
*/


/** <module> CLAUDE
Implements interaction with Anthropic Claude.
We implement real-time streaming.

We support any model available, default is set to 'claude-sonnet-4-5'.

Interfacing with Claude requires a specific protocol, different from OpenAI.
We define the Claude specific protocol in this file.
*/

:- module(claude, [claude/0, claude/1, claude/2]).

% =============================================================================
%  CLAUDE declarations
% =============================================================================

% -----------------------------------------------------------------------------
%  Conversation history
% -----------------------------------------------------------------------------

:- dynamic history/1.

history([]).


%! claude:update_history(+History)
%
% Replace the stored conversation history.

update_history(History) :-
  retractall(claude:history(_)),
  assertz(claude:history(History)).


% -----------------------------------------------------------------------------
%  Claude-specific streaming
% -----------------------------------------------------------------------------

%! claude:llm_stream_claude(+Endpoint, +APIKey, +Model, +Messages, -Response)
%
% Send a streaming chat request to the Claude API and collect the response.

llm_stream_claude(Endpoint, APIKey, Model, Messages, Response) :-
    config:llm_max_tokens(Max),
    config:llm_temperature(Temperature),
    set_stream(current_output, encoding(utf8)),
    Payload = _{
        model: Model,
        messages: Messages,
        stream: json_true,
        max_tokens: Max,
        temperature: Temperature
    },
    with_output_to(string(JsonString),
		    json_write_dict(current_output, Payload, [true(json_true), width(0)])),
    Headers = [method(post),
               post(string(JsonString)),
               request_header('x-api-key'=APIKey),
               request_header('anthropic-version'='2023-06-01'),
               request_header('Content-Type'='application/json'),
               request_header('Accept'='text/event-stream')],

    catch(
        (
            http_open(Endpoint, In, Headers),
            set_stream(In, encoding(utf8)),

            message:color(lightgray),
            message:style(italic),
            message:hl(Model),

	    process_stream_claude(In, Contents),
            close(In),

            nl,
            message:hl,
            message:color(normal),
            message:style(normal),

            atomic_list_concat(Contents, ResponseContent),

            reverse(Messages, Reversed),
            llm:find_first_assistant(Reversed, LastAssistantMessage),
            put_dict(content, LastAssistantMessage, ResponseContent, UpdatedAssistantMessage),
            (  append(Prefix, [LastAssistantMessage|Rest], Messages)
            -> append(Prefix, [UpdatedAssistantMessage|Rest], NewMessages)
            ;  append(Messages, [UpdatedAssistantMessage], NewMessages) ),
            Response = _{contents: Contents, history: NewMessages}
        ),
        Error,
        (
            Response = _{error: Error, history: Messages}
        )
    ).


% -----------------------------------------------------------------------------
%  Stream processing
% -----------------------------------------------------------------------------

%! claude:process_stream_claude(+In, -Contents)
%
% Read and process a Claude SSE stream, collecting content text fragments.

process_stream_claude(In, Contents) :-
    process_stream_claude(In, Contents, []).

process_stream_claude(In, Contents, Acc) :-
    read_line_to_string(In, Line),
    (   Line == end_of_file
    ->  reverse(Acc, Contents)
    ;   (   sub_string(Line, 0, 7, _, 'event: ')
        ->  process_stream_claude(In, Contents, Acc)
        ;   sub_string(Line, 0, 6, _, "data: ")
        ->  sub_string(Line, 6, _, 0, Data),
            (   Data == "[DONE]"
            ->  reverse(Acc, Contents)
            ;   (   atom_json_dict(Data, Dict, [])
                ->  (   get_dict(type, Dict, "content_block_delta")
                    ->  get_dict(delta, Dict, Delta),
                        get_dict(text, Delta, Content)
                    ;   (   get_dict(type, Dict, "message_delta"),
                            get_dict(delta, Dict, MessageDelta),
                            get_dict(text, MessageDelta, Content)
                        )
                        ->  true
                        ;   Content = ""
                    )
                ;   Content = ""
                ),
                (   Content \= ""
                ->  write(Content), flush_output,
                    process_stream_claude(In, Contents, [Content | Acc])
                ;   process_stream_claude(In, Contents, Acc)
                )
            )
        ;   process_stream_claude(In, Contents, Acc)
        )
    ).


% -----------------------------------------------------------------------------
%  Streaming callback
% -----------------------------------------------------------------------------

%! claude:claude_llm_stream(+APIKey, +Model, +History, +Query, -Response)
%
% Prepare messages and invoke the Claude streaming endpoint.

claude_llm_stream(APIKey, Model, History, Query, Response) :-
    config:llm_endpoint(claude,Endpoint),
    UserMessage = _{role: user, content: Query},
    append(History, [UserMessage], Messages),
    llm_stream_claude(Endpoint, APIKey, Model, Messages, Response).


% -----------------------------------------------------------------------------
%  Entry points
% -----------------------------------------------------------------------------

%! claude:claude(+Input, -ResponseContent)
%
% Send Input to Claude and unify ResponseContent with the response text.

claude(Input,ResponseContent) :-
  llm:chat(claude, claude:llm_stream_claude, Input, ResponseContent).


%! claude:claude(+Input)
%
% Send Input to Claude, discarding the response content.

claude(Input) :-
  claude(Input,_).


%! claude:claude
%
% Interactive prompt: read user input, then send to Claude.

claude :-
  llm:get_input(Msg),
  claude(Msg).