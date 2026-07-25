# Protocol support matrix

> Source of truth: the public MCP draft specification at
> <https://modelcontextprotocol.io/specification/draft> and its TypeScript schema; legacy
> compatibility is pinned to the last session-era SDK shapes (`2025-11-25`) where the draft
> no longer carries those wire details.

## Supported protocol versions

| Version | Era | Notes |
| --- | --- | --- |
| `2025-03-26` | legacy | negotiated at `initialize`; served with `2025-11-25` data shapes |
| `2025-06-18` | legacy | as above |
| `2025-11-25` | legacy | the legacy data-type baseline |
| `2026-07-28` | modern | stateless native shape |

The supported native profile is synchronous request/response. SSE, subscriptions, streaming
responses, sessions, and server-pushed notifications are unsupported. Legacy revisions are
served statelessly with the latest legacy (`2025-11-25`) data shapes.

Version is negotiated once at `initialize` (legacy) or named per-request in `_meta` /
`MCP-Protocol-Version` (modern). Unsupported or header/body-mismatched version → HTTP `400` with
the appropriate spec error.

## The hard constraint: no sessions, no SSE

ICF without server-initiated streaming cannot push to the client, and we hold no per-client
state. Therefore **anything that requires a server→client stream or a stored session is out**,
in both eras. This is a transport-level impossibility, not a deferred feature.

This v2 SDK is for **stateless MCP servers**. Backward compatibility means stateless
request/response compatibility with legacy protocol versions (`2025-03-26` through
`2025-11-25`), not the old stateful transport model. Servers that require legacy sessions,
SSE, or `Mcp-Session-Id` lifecycle behavior should stay on the v1 SDK.

Excluded as features everywhere:

- all **server-sent/change notifications** (`notifications/*` delivered from server to client,
  including list/resource/task/log/progress/message notifications)
- modern **`subscriptions/listen`** (the replacement for the legacy GET stream)
- legacy **`resources/subscribe`** / **`unsubscribe`**
- **request-scoped SSE** responses and **stream-close cancellation**
- **stateful sessions** — the legacy `initialize` handshake is answered, but **no session is
  created**, no `Mcp-Session-Id` is ever issued, and inbound session ids are ignored
- **logging** — the Logging feature is deprecated in `2026-07-28` (SEP-2577) and the stateless
  runtime can never deliver `notifications/message`, so the SDK does not implement it at all:
  no `logging` capability is advertised in either era and `logging/setLevel` is
  `method_not_found` everywhere (the `2026-07-28` draft removed the RPC anyway; per-request
  `_meta` `io.modelcontextprotocol/logLevel` replaces it)
- **roots** — deprecated in `2026-07-28` (SEP-2577) and meaningless to a remote ABAP server
  (client filesystem roots); the SDK ships no `roots/list` input builder

Note on **sampling**: SEP-2577 also deprecates the Sampling feature (≥12-month removal
window). The SDK keeps the `zcl_mcp2_input_sampling` MRTR builder because it is the only
key-less LLM access path from ABAP; prefer direct LLM provider integration for new designs
where feasible.

## Method matrix

### Legacy era (`2025-03-26` … `2025-11-25`)

| Method | Supported | Notes |
| --- | --- | --- |
| `initialize` | ✅ | answered statelessly; negotiates version + advertises capabilities; no session created. A supported legacy version is echoed back; any other requested version (older, unknown, or modern) is answered with a **counter-offer of `2025-11-25`** per spec — never an error. Missing `protocolVersion` → `-32602` |
| `ping` | ✅ | |
| `tools/list`, `tools/call` | ✅ | advertised-`inputSchema` violations return a normal `CallToolResult` with `isError: true`; structurally malformed calls and unknown tools remain `-32602` |
| `resources/list`, `resources/read`, `resources/templates/list` | ✅ | |
| `prompts/list`, `prompts/get` | ✅ | |
| `completion/complete` | ✅ | including the `2025-06-18` `context` field (`has_context` / `get_context_json`) |
| `tasks/get`, `tasks/result`, `tasks/list`, `tasks/cancel` | ✅ | 2025-11-25 experimental-tasks semantics: capability advertised as `capabilities.tasks = {list, cancel, requests.tools.call}` at `initialize`; a create-task result requires the **per-request `params.task` opt-in** on `tools/call` (else `-32600`; gate with the era-aware `client_supports_tasks( )` for a synchronous fallback); tools advertise `execution.taskSupport`; root-level task fields with `pollInterval`/`ttl` (ms, `null` = unlimited) and `createdAt`/`lastUpdatedAt`; `tasks/result` re-raises the stored JSON-RPC error of `fail( )`-ed tasks and stamps the `related-task` `_meta`; terminal-state cancels are `-32602`. Validated against the official SDK zod schemas and the v1 TypeScript SDK in the integration suite. **Known deviation:** `tasks/result` on a non-terminal task answers `-32600` instead of blocking — a stateless request cannot block; clients poll `tasks/get` |
| `tasks/update` | ❌ | MRTR continuation is modern-only; `-32600` with a pointing message |
| `logging/setLevel` | ❌ | Logging is deprecated (SEP-2577) and stateless ICF can never deliver the resulting notifications; `method_not_found`, no `logging` capability advertised |
| `resources/subscribe` / `unsubscribe` | ❌ | requires notifications; the capability is never advertised (`resources: {}` without `subscribe`) |
| `notifications/*` (client-sent: `initialized`, `cancelled`, `progress`) | ⚠️ | accepted with HTTP `202` and dropped — correct for a stateless server (progress/cancellation have no effect on a request that completes within its own POST) |
| JSON-RPC **batches** | ❌ | `2025-03-26` allowed batching (removed again in `2025-06-18`); a batch body is rejected with `400`. Known deviation for `2025-03-26`-pinned clients — accepted, since no mainstream client ever sent batches and the vocabulary lived for one revision |
| `MCP-Protocol-Version` header (`2025-06-18`+) | ✅ | validated on every request: known legacy → legacy era, unknown → `400`/`-32022`, absent → legacy assumed (pre-`06-18` client) |

### Modern era (`2026-07-28`)

| Method | Supported | Notes |
| --- | --- | --- |
| `server/discover` | ✅ | returns `supportedVersions`, capabilities, instructions, cache hints; `resultType = complete`. `serverInfo` is carried in `_meta`, not in the result body (see below) |
| `tools/list`, `tools/call` | ✅ | `tools/call` may return `inputRequired` (MRTR); advertised-`inputSchema` violations return `isError` tool results |
| `resources/list`, `resources/read`, `resources/templates/list` | ✅ | |
| `prompts/list`, `prompts/get` | ✅ | |
| `completion/complete` | ✅ | |
| `tasks/get`, `tasks/update`, `tasks/cancel` | ✅ | modern Tasks extension (`io.modelcontextprotocol/tasks`) request/response subset. Shapes are **flat**: `CreateTaskResult = Result & Task` and `GetTaskResult = Result & DetailedTask` — `taskId`/`status`/`createdAt`/`lastUpdatedAt`/`ttlMs`(number\|null)/`pollIntervalMs` plus `result`/`error`/`inputRequests` at the result root, not under a `task` wrapper. `tasks/get` embeds terminal results and pending `inputRequests` (keyed; no `requestState`); `tasks/update` / `tasks/cancel` acknowledge with an empty `complete` result. `tasks/cancel` acks a task already in a terminal state instead of erroring (cooperative). Every `tasks/*` request mirrors `params.taskId` into `Mcp-Name` (validated, mismatch → `-32020`). A create-task result requires the client to have declared the extension in `clientCapabilities.extensions` (else `-32021`) |
| `ping` | ❌ | removed from the `2026-07-28` vocabulary; `method_not_found` (`-32601`, HTTP 404) |
| `logging/setLevel` | ❌ | removed in `2026-07-28` (replaced by `_meta` `io.modelcontextprotocol/logLevel`); `method_not_found` (`-32601`, HTTP 404). No `logging` capability is advertised |
| `subscriptions/listen` | ❌ | requires a long-lived stream |
| server-sent notifications / `subscriptions/listen` | ❌ | no server→client stream; notification POSTs are transport-valid but the modern core defines no useful client→server notification workflow |

## Modern request metadata (`params._meta`)

Validated per request (no `initialize`):

- `io.modelcontextprotocol/protocolVersion` — **must** equal the `MCP-Protocol-Version` header,
  else `HeaderMismatch` (`-32020`, HTTP 400)
- `io.modelcontextprotocol/clientInfo` — optional (clients SHOULD include it); when present, must
  be an object with non-empty `name` + `version`, else `InvalidParams`
- `io.modelcontextprotocol/clientCapabilities` — object whose capability values are objects;
  `extensions` is likewise an object whose extension values are objects (for example, neither
  `sampling: false` nor a Tasks extension value of `false` is valid)
- optional: `io.modelcontextprotocol/logLevel`, `traceparent`, `tracestate`, `baggage` —
  exposed to handlers through typed base-class getters (`get_log_level`, `get_traceparent`,
  `get_tracestate`, generic `get_meta_string`); no runtime OpenTelemetry or dynamic
  log-level control

When present, `io.modelcontextprotocol/logLevel` must be one of `debug`, `info`,
`notice`, `warning`, `error`, `critical`, `alert`, or `emergency`; other values
are `InvalidParams` (`-32602`).

A request needing a capability the client did not declare → `MissingRequiredClientCapability`
(`-32021`, HTTP 400).

Malformed required metadata (`_meta`, protocol version, or `clientCapabilities`), or a malformed
`clientInfo` when one is present, is `InvalidParams` (`-32602`) at the JSON-RPC layer and HTTP `400`.

## Header mirroring (modern Streamable HTTP)

The body is the source of truth; selected fields are mirrored into headers and must match.

| Header | Body source |
| --- | --- |
| `MCP-Protocol-Version` | `_meta` protocol version |
| `Mcp-Method` | JSON-RPC `method` |
| `Mcp-Name` | `params.name` (`tools/call`, `prompts/get`), `params.uri` (`resources/read`), or `params.taskId` (`tasks/get`, `tasks/update`, `tasks/cancel`) |
| `Mcp-Param-{Name}` | tool arguments annotated `x-mcp-header = "{Name}"` |

`Mcp-Param-*` supports string/integer/boolean properties that are statically reachable through
object `properties` (arrays and composition keywords are rejected), decodes `=?base64?…?=`
values (the only defined encoding — everything else, including `%XX` sequences, is compared as
a literal), compares integers numerically within JS safe-integer bounds, requires lowercase
`true`/`false` for booleans, rejects duplicate suffixes (case-insensitive), invalid field-name
suffixes, and unsafe/control characters. Missing or mismatched required mirrored headers →
`HeaderMismatch` (`-32020`, HTTP 400).

Header presence is checked independently of its value, so an explicitly present empty header
validly mirrors an empty string argument. For `tasks/*`, `Mcp-Name` is compared exactly with the
body's `taskId` before the task ID is normalized for database lookup; matching lowercase UUIDs
are valid.

## Multi-round-trip (MRTR) — supported, statelessly

The modern `inputRequired` flow fits stateless ICF well because continuation state is offloaded
to the client. A handler that needs more input returns an `InputRequiredResult` carrying
`inputRequests` (sampling / elicitation, server-keyed) and/or an opaque `requestState`
token; the client echoes `inputResponses` + `requestState` on the next request. The server keeps
nothing between round-trips. URL-mode elicitation is a first-class mode in the modern era.

## Caching / discovery

`server/discover` and cacheable results carry `cacheScope` (`public` / `private`) and `ttlMs`.
If a handler does not provide cache hints, the modern dispatcher emits `ttlMs = 0` and
`cacheScope = private`, which is schema-valid and conservative. The discover hints are
configurable via `get_discover_cache` on the server contract — advertise a generous TTL when
the capability set only changes with transports. Legacy results carry no envelope.

When a cacheable completed response follows a `tools/call`, `prompts/get`, or `resources/read`
request containing `requestState` or `inputResponses`, the dispatcher overrides application
hints with `ttlMs = 0` and `cacheScope = private`. Input-dependent retry results therefore
cannot accidentally become publicly cacheable.

`serverInfo` carries optional `title`, `description`, and `websiteUrl` in both eras when the
server overrides `get_title` / `get_description` / `get_website_url`. Legacy keeps it as a
top-level `initialize` result field, unchanged. The modern era has exactly one location for it:
`_meta["io.modelcontextprotocol/serverInfo"]`, the `ResultMetaObject` shape the draft moved to on
2026-07-16. It is stamped on **every** modern result, not just `server/discover`, and the
discover result carries no top-level `serverInfo`.

The `2026-07-28` draft recommends returning `tools/list` in a deterministic order so results
stay cache-friendly. The SDK preserves the order in which tools are declared (`define_tools`
entries, or `add_tool` calls when you build `tools/list` yourself) — build the list in a fixed
order and don't reorder it per request.

## Error codes

Standard JSON-RPC: `-32700` ParseError, `-32600` InvalidRequest, `-32601` MethodNotFound,
`-32602` InvalidParams, `-32603` InternalError. Modern MCP: `-32020` HeaderMismatch, `-32021`
MissingRequiredClientCapability, `-32022` UnsupportedProtocolVersion. (These spec-correct codes
replace the old SDK's non-standard `-32001` / `-32004`.)

An unknown `resources/read` URI is `-32602` in the modern draft and `-32002` in the legacy
profile. Tool arguments that fail an advertised `inputSchema` produce a normal
`CallToolResult` with `isError: true` in both eras; malformed calls and unknown tools remain
`-32602`.

The `MissingRequiredClientCapability` error carries
`data.requiredCapabilities` as a `ClientCapabilities`-shaped object (e.g.
`{"extensions":{"io.modelcontextprotocol/tasks":{}}}`, `{"elicitation":{"url":{}}}`), not a
string list. The SDK uses the core draft's renumbered `-32021`; note the `io.modelcontextprotocol/tasks`
extension prose still shows the pre-renumber `-32003` for the same condition — clients matching
literally on `-32003` should be updated to `-32021`.

## HTTP behavior summary

- `POST`: one JSON-RPC request or notification (no batches). Transport-valid notifications
  receive `202`, empty body; the SDK does not implement any notification-driven feature.
  Modern non-notification requests must use `Content-Type: application/json` and an `Accept`
  header containing both `application/json` and `text/event-stream`; the server still only
  returns JSON because ABAP ICF has no SSE support.
- Client-sent JSON-RPC **response** bodies are invalid.
- `GET` / `DELETE` → `405`, `Allow: POST, OPTIONS`.
- `OPTIONS` → CORS preflight advertising `POST, OPTIONS` and the modern header allow-list.
- `Origin` validated against `zmcp2_origins` (exact area/server entries + wildcard fallback);
  origin values compare case-insensitively (RFC 6454 — scheme and host are case-insensitive).
  `CORS_MODE = I` can disable this for controlled local/dev systems, but that mode is explicitly
  non-compliant with Streamable HTTP.
- No `Mcp-Session-Id` is ever issued or honored.
- **HTTP status of a dispatched JSON-RPC response**: successes and most application errors
  are carried in HTTP `200`. Modern `MethodNotFound` (`-32601`) is HTTP `404`; legacy
  `MethodNotFound` remains HTTP `200` for older JSON-RPC-over-HTTP clients. Modern
  `HeaderMismatch`, `MissingRequiredClientCapability`, `UnsupportedProtocolVersion`, and
  malformed required `_meta` (`-32602`) surface as HTTP `400`. Malformed-envelope and routing
  failures handled before dispatch keep their own `400` / `403` / `404` / `406` / `415` statuses.
- The JSON-RPC `id` is echoed with the exact wire type received: a numeric id as a JSON
  number (at full precision), a string id as a JSON string — never coerced between the two.
