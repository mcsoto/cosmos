# Cosmos `llm` user library

`require('llm', llm)` exposes text-only chat calls with a common signature:

```cosmos
llm.openai(model, prompt, reply)
llm.mistral(model, prompt, reply)
```

Credentials stay outside Cosmos source:

```powershell
$env:OPENAI_API_KEY = '...'
# or
$env:MISTRAL_API_KEY = '...'
```

Then run the example:

```powershell
.\cosmos.bat -l userlibs\llm\demo.co
```

The caller selects the model; no provider model is hard-coded by the library.
The OpenAI route uses `POST /v1/chat/completions`; the Mistral route uses its
matching `POST /v1/chat/completions` endpoint.  This library handles one
non-streaming user message per call and returns the first text response.
