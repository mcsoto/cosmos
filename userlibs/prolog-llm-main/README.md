# prolog-llm

Streaming SWI-Prolog client for the major Large Language Model services.

`prolog-llm` provides a small, dependency-light layer for talking to
publicly hosted and locally hosted LLMs from SWI-Prolog. Responses are
streamed token-by-token to the current output stream, optionally captured
into a Prolog string, and threaded through a per-service conversation
history. The library also implements a tag-replay loop so that models
can call other models (or execute sandboxed SWI-Prolog code) by emitting
`<call:...>` XML tags inside their answers.

Originally extracted from
[portage-ng](https://github.com/pvdabeel/portage-ng), where it powers
the `--explain` command.

## Supported services

| Service | Module          | Wire format        | Streaming |
|---------|-----------------|--------------------|-----------|
| Grok    | `llm/grok.pl`   | OpenAI-compatible  | Yes       |
| ChatGPT | `llm/chatgpt.pl`| OpenAI-compatible  | Yes       |
| Claude  | `llm/claude.pl` | Anthropic native   | Yes       |
| Gemini  | `llm/gemini.pl` | OpenAI-compatible  | Yes       |
| Ollama  | `llm/ollama.pl` | OpenAI-compatible  | Yes       |

Anthropic Claude uses its own `/v1/messages` protocol; the rest of the
services share the OpenAI chat-completions wire format and run through
the shared `llm:stream/5` predicate.

## Features

- Real-time word-by-word output to `current_output`
- Returns the full response as a Prolog string for downstream processing
- UTF-8 safe (emoji and complex scripts work out of the box)
- Per-service chat history maintained as `dynamic history/1`
- Interactive entry points (`grok/0`, `chatgpt/0`, ...) drop you into
  your `$EDITOR` to compose multi-line prompts
- LLM-to-LLM message passing via `<call:gemini>...</call:gemini>` etc.
- Sandboxed execution of `<call:swi_prolog>...</call:swi_prolog>` blocks
- Batched embedding generation against Ollama-style endpoints
  (`llm:embed/4`, one HTTP round-trip for a whole list of texts)
- Single point of configuration through the `config:` namespace

## Layout

```
prolog-llm/
├── llm.pl              # shared streaming runtime + tag-replay loop
├── llm/
│   ├── chatgpt.pl
│   ├── claude.pl       # Anthropic-specific protocol
│   ├── gemini.pl
│   ├── grok.pl
│   └── ollama.pl
├── message.pl          # tiny ANSI colour/style/hl shim used by the
│                       # streaming code (replace with your own if you
│                       # already have a `message` module)
├── config.sample.pl    # copy to config.pl and fill in your API keys
├── LICENSE
└── README.md
```

## Install

```sh
git clone https://github.com/pvdabeel/prolog-llm.git
cd prolog-llm
cp config.sample.pl config.pl
$EDITOR config.pl                       # paste your API keys
```

Then load the library inside SWI-Prolog:

```prolog
?- ['config'].
?- ['message'].
?- ['llm'].
?- ['llm/chatgpt'], ['llm/claude'], ['llm/gemini'],
   ['llm/grok'],    ['llm/ollama'].
```

## Usage

### Quick one-shot call

```prolog
?- chatgpt("Explain the difference between SLD and SLG resolution.", Reply).
```

`Reply` is unified with the full response string. The same answer is
streamed to `current_output` while the call is in flight.

### Discard the response

```prolog
?- claude("Tell me a joke about Prolog.").
```

### Interactive prompt (opens `$EDITOR`)

```prolog
?- gemini.
```

Quit your editor (`:wq` in vim) to send the buffer to the model.

### Mixing services in one conversation

Each service maintains its own `history/1` in its own module, so calls
do not bleed between services:

```prolog
?- grok("Draft a one-paragraph summary of monotonic reasoning.", Draft),
   claude(Draft, Critique),
   format("~nClaude says: ~w~n", [Critique]).
```

### LLM-to-LLM and code execution

When `config:llm_capability/2` clauses for `chat` and `code` are loaded
(see `config.sample.pl`), models can emit special tags inside their
answers and `prolog-llm` will replay the result back to the model:

- `<call:chatgpt>What is the time complexity of unification?</call:chatgpt>`
  forwards the inner text to ChatGPT and feeds the answer back.
- `<call:swi_prolog>:- between(1, 5, X), writeln(X), fail.</call:swi_prolog>`
  loads the code into a temporary sandboxed module and feeds the
  captured output back.

The replay loop runs until no more tags are emitted, so a model can
chain several tool calls before producing its final answer.

### Embeddings

`llm:embed/4` posts a whole list of texts to an Ollama-style embedding
endpoint in a single HTTP round-trip and returns one vector per input,
in order. Always batch your inputs instead of looping one request per
text — for large corpora this is an order of magnitude faster:

```prolog
?- llm:embed('http://localhost:11434/api/embed', 'nomic-embed-text',
             ["a web browser", "kernel sources"], [E1, E2]),
   length(E1, Dim).
Dim = 768.
```

The legacy `/api/embeddings` single-input response format
(`{"embedding": [...]}`) is also understood.

## Configuration reference

All knobs are looked up in the `config:` namespace, so you can place
them anywhere in your load path as long as a `config` module exists at
load time.

| Predicate                                       | Purpose                                  |
|-------------------------------------------------|------------------------------------------|
| `config:llm_api_key(?Service, ?Key)`            | Bearer token (one clause per service)    |
| `config:llm_endpoint(?Service, ?URL)`           | Chat-completions URL                     |
| `config:llm_model(?Service, ?Model)`            | Default model name                       |
| `config:llm_max_tokens(?N)`                     | Hard upper bound on response length      |
| `config:llm_temperature(?T)`                    | Sampling temperature (0.0 - 1.0)         |
| `config:llm_sandboxed_execution(?Bool)`         | Sandbox `<call:swi_prolog>` execution    |
| `config:llm_capability(?Name, ?Prompt)`         | Optional capability prompts (chat, code) |

`Service` is one of `grok`, `chatgpt`, `claude`, `gemini`, `ollama`.

## Embedding into a host application

If your application already exports a `message` module that handles
colour and styling, delete this repository's `message.pl` and let yours
take over. The streaming code calls only `message:color/1`,
`message:style/1`, `message:hl/0` and `message:hl/1`.

If your application already exposes a `config` module, drop
`config.pl`/`config.sample.pl` and add the `config:llm_*` clauses
directly to your existing config file. The library does not care
where they come from as long as they are visible at runtime.

## Origin

This code was extracted from
[portage-ng](https://github.com/pvdabeel/portage-ng) using
`git filter-repo`, so the full per-file history is preserved. The
extraction renames `Source/Application/llm.pl` → `llm.pl` and
`Source/Application/Llm/<svc>.pl` → `llm/<svc>.pl`; older paths
(`Source/llm.pl`, `Source/Llm/<svc>.pl`) are also rewritten so that
`git log --follow` keeps working.

## License

See `LICENSE`.
