# Troubleshooting

Symptom-first index of the failures you are most likely to hit. Each entry names the cause and
links to the guide that explains the mechanism.

## The endpoint does not answer at all

| Symptom | Likely cause |
| --- | --- |
| **HTTP 404**, no JSON-RPC body | The ICF node is not active, or the path does not resolve. Check SICF, then confirm an `zmcp2_servers` row exists for exactly this `AREA` / `SERVER` — the match is **case-sensitive**. Path is `POST /zmcp2/{AREA}/{SERVER}` (an `mcp` prefix segment is also accepted). |
| **HTTP 500**, `-32603` internal error | The registered `CLASS` cannot be instantiated or does not implement `zif_mcp2_server`. Deliberately distinct from the 404 for "not registered". The response hides the class name — check the row and the class activation state yourself. |
| **HTTP 405** with `Allow: POST, OPTIONS` | Something sent `GET` or `DELETE`. There is no GET stream in this SDK; a client trying to open one is assuming SSE. See [Protocol support](ProtocolSupport.md#the-hard-constraint-no-sessions-no-sse). |
| **HTTP 401 / logon popup** | ICF logon procedure, before the SDK runs. Nothing to configure in the SDK. |
| **HTTP 403**, `-32600` | Either the `Origin` header was rejected (see below), or the server's `check_authorization` denied the caller. The message distinguishes them: `Origin is not allowed` vs `Not authorized for this MCP server`. |

## HTTP 403 on browser calls that work from curl

Requests **without** an `Origin` header (curl, server-to-server, most desktop clients) always
pass. A browser sends one, and with **no matching `zmcp2_origins` rows at all**, every such
request is rejected.

Add rows for the calling origin. Remember the lookup order — exact `area`/`server` →
`area`/`*` → `*`/`server` → `*`/`*`, and the **first level with any rows wins**, so an exact
row set shields that server from your broader wildcards. Details in
[Configuration and security](ConfigurationAndSecurity.md#zmcp2_origins--browser-origin-allow-list).

## HTTP 403 "Not authorized for this MCP server"

The server class redefines `check_authorization` and it returned `abap_false` for this user.
The reason is deliberately not echoed back — check the authorization object your
implementation tests, for the authenticated ICF user. Note the check runs before the body is
parsed, so *every* method is blocked, including `initialize` and `server/discover`; a client
reporting "cannot connect" rather than "call denied" is expected. See
[Configuration and security](ConfigurationAndSecurity.md#endpoint-authorization--check_authorization).

## Modern-era request errors

These only occur in the `2026-07-28` era, where every request is self-describing.

| Code | Meaning | What to check |
| --- | --- | --- |
| **`-32022`** UnsupportedProtocolVersion (HTTP 400) | The version in the header or `_meta` is not one this SDK serves | Send `2026-07-28`, or a legacy version via `initialize`. See the [version table](ProtocolSupport.md#supported-protocol-versions). |
| **`-32020`** HeaderMismatch (HTTP 400) | A mirrored header disagrees with the body, or a required one is missing | Body is the source of truth. `Mcp-Method` is always required; `Mcp-Name` is required for `tools/call`, `prompts/get`, `resources/read` and every `tasks/*`; `Mcp-Param-{Name}` is required for each argument whose schema declares `x-mcp-header`. See [header mirroring](ProtocolSupport.md#header-mirroring-modern-streamable-http). |
| **`-32021`** MissingRequiredClientCapability (HTTP 400) | The handler returned something the client never said it could parse | You returned an `inputRequired` or task result without gating. Gate with `can_request_input( )` / `client_supports_tasks( )` and provide a fallback — see [Input required](InputRequired.md#gating-who-can-do-mrtr). The error's `data.requiredCapabilities` names what was missing. |
| **`-32602`** on a request that looks well-formed | Malformed required `_meta` | `clientCapabilities` values must be **objects** (`sampling: false` is invalid, so is a tasks extension value of `false`). `clientInfo` is optional but, when present, needs non-empty `name` + `version`. |
| **HTTP 406 / 415** | `Accept` or `Content-Type` | Modern non-notification requests need `Content-Type: application/json` and an `Accept` containing **both** `application/json` and `text/event-stream` — even though the server only ever returns JSON. |

## Tools

| Symptom | Cause |
| --- | --- |
| **Tool call returns `isError` instead of running** | Arguments failed the advertised `inputSchema`. The framework validates before your handler in both eras. The message names the failing path. Turn it off per server with `tool_input_validation_enabled` only if handlers validate themselves — see [input validation](Tools.md#input-validation). |
| **`-32602` unknown tool** for a tool you implemented | The name is not in `define_tools( )`. `zcl_mcp2_tool_server_base` rejects undeclared names before `call_tool` runs. Keep names in one shared constants block so catalog and dispatch cannot drift. |
| **A client silently omits your tool from its list** | Reference clients drop tools whose `x-mcp-header` declarations collide. Header names must be case-insensitively unique per tool. |
| **`destructiveHint: false` has no effect** | `destructiveHint` and `openWorldHint` default to *true* in the spec, so an explicit false needs the paired `destructive_hint_set` / `open_world_hint_set` flag. |
| **Structured output rejected by the client** | You advertised an `output_schema` and returned content that does not conform. The SDK does **not** validate outputs for you. |

## Resources, prompts, completions

| Symptom | Cause |
| --- | --- |
| **`method_not_found` for a feature you implemented** | The matching `supports_*` method still returns `abap_false`. Resources, prompts and completions are each gated by their own flag; only the tool base derives `supports_tools` for you. |
| **Completion inserts values like `AAda`** | The client **replaces** the argument with what you return — it does not append. Return whole candidates filtered by the typed prefix, never prefix + suffix. See [Completions](Completions.md#return-whole-values-never-the-typed-text-plus-a-suffix). |
| **A template lists but never reads** | Every advertised template expansion must have a working path in `resources_read`. Unknown URIs should use `zcx_mcp2_error=>raise_resource_not_found( )` so the dispatcher emits the era-correct code (legacy `-32002`, modern `-32602`). |

## Tasks

| Symptom | Cause |
| --- | --- |
| **Task created but nothing ever runs** | The SDK persists and serves task state; it never launches work. `start_task( )` gives you an id — you must hand it to a job, bgRFC or other worker. Implementing `zif_mcp2_task_executor` registers nothing. See [Tasks](Tasks.md#finishing-from-the-background-unit). |
| **`-32600` on a legacy `tools/call` returning a task** | Legacy clients must opt in **per request** with `params.task`. Gate with `client_supports_tasks( )`, which covers both eras, and fall back to a synchronous result. |
| **Legacy client never offers task execution** | `task_support` is omitted on the tool, which legacy clients read as `forbidden`. Set it on every tool that may return a task. |
| **`tasks/result` answers `-32600`** | The task is not terminal. A stateless request cannot block — poll `tasks/get` instead. This is a [documented deviation](ProtocolSupport.md#legacy-era-2025-03-26--2025-11-25) from legacy blocking behavior. |
| **Task rows pile up** | Schedule `ZMCP2_CLEAR_TASKS`. Note it also purges non-terminal rows older than **24 hours** as stuck — adjust the cutoff first if your tasks legitimately run longer. |
| **Client never sees intermediate progress** | Correct and expected. `statusMessage` is a stored value, not a stream; a slow poller can go straight from step 1 to `completed`. Never make progress messages load-bearing. |
| **Another user cannot see a task** | By design. `tasks/list` filters by user + area + server, and direct operations verify the creating user. |

## MRTR / elicitation

| Symptom | Cause |
| --- | --- |
| **`-32600` with a pointing message on a legacy client** | MRTR is modern-only. Give legacy clients an explanatory result instead — and do not claim a side effect the fallback did not perform. |
| **Retry arrives but your key is unanswered** | `try_get_input_response` returns unbound; `get_input_response` raises `-32602`. Treat a wrong key as a tool error the model can correct. |
| **Form renders wrong or is rejected** | Elicitation schemas are deliberately flat. Build with `zcl_mcp2_elicit_schema`, never reuse a tool input schema — nesting and `x-mcp-header` are invalid there. |
| **Retry results are being cached** | They are not: the dispatcher forces `ttlMs = 0` / `cacheScope = private` on any completed response to a request carrying `requestState` or `inputResponses`. |

## Behavior that is intentional, not a bug

- **No `Mcp-Session-Id` is ever issued**, and inbound ones are ignored. Servers needing session
  lifecycle belong on the v1 SDK.
- **`ping` is `method_not_found` in the modern era** — removed from the `2026-07-28` vocabulary.
  It still works on legacy.
- **`logging/setLevel` is `method_not_found` everywhere**, and no `logging` capability is
  advertised. Use the `_meta` log-level hint via `get_log_level( )`.
- **`resources/subscribe` is never advertised** — the capability is `resources: {}`.
- **JSON-RPC batches are rejected** with 400, including for `2025-03-26`-pinned clients.
- **Legacy `MethodNotFound` is HTTP 200**, modern is HTTP 404. Both carry `-32601`.
- **An `initialize` request with an unknown or modern version gets a `2025-11-25` counter-offer**,
  not an error.

## Still stuck

Every dispatch path is unit-testable without ICF — build the request and call the dispatcher
directly ([Getting started §6](GettingStarted.md#6-test-it-without-http)). That isolates whether
the problem is your handler or the transport in one step.
