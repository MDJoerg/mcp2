# Architecture — ABAP MCP SDK v2 (`mcp2`)

## Why a v2

The original SDK (`mcp`, prefix `zcl_mcp_*`) was built around the stateful,
`initialize`-and-session protocol generation and later grew a parallel draft layer
(`zif_mcp_server_v2`). Two structural problems made a clean restart preferable to more
patching:

1. **Statefulness baked in.** Sessions (`Mcp-Session-Id`, ICF stateful mode, session DDIC
   tables) run through the core. The upcoming `2026-07-28` generation is explicitly stateless;
   bolting that onto a session-centric core produced two parallel server stacks.
2. **Central, brittle JSON↔ABAP conversion.** Serialization relied on hand-written camelCase
   path strings spread across ~40 response classes plus a partially-adopted central mapping
   layer. Typos and new spec fields failed silently; the "result envelope" (`resultType`,
   `ttlMs`, `cacheScope`) had to be stamped onto raw JSON after the fact.

v2 keeps the parts that worked — data classes, vendored ajson, abapGit/abaplint workflow,
local-test-class coverage — and changes the foundation: **stateless only**, a **single server
contract** serving both protocol eras, **conversion localized in each data class**, and a
**platform-abstraction layer** that isolates the calls that will differ on ABAP Cloud.

The old SDK stays installed and untouched. v2 uses the distinct `mcp2` object prefix so both
can live in one ABAP system.

## Guiding principles

- **Stateless only.** No protocol sessions, ever. No `Mcp-Session-Id`, no stateful ICF, and no
  session DDIC tables. Every request is self-contained; the server infers nothing from a
  previous request. Continuation state (MRTR) is offloaded to the client as an opaque
  `requestState` token. The separate `zmcp2_tasks` table is for the explicit Tasks extension,
  not protocol sessions.
- **One server contract, two eras.** A single `zif_mcp2_server` / `zcl_mcp2_server_base`
  serves both the legacy era (`2025-03-26` … `2025-11-25`) and the modern era (`2026-07-28`).
  Era differences are handled by the dispatcher and by per-field gating in the data classes,
  not by separate server stacks.
- **Conversion lives in the data class.** Each request/response class parses/serializes its own
  fields explicitly. The only central conversion code is the JSON-RPC envelope and the
  result-type/cache stamp.
- **Isolate environment-sensitive calls.** Anything that will differ on ABAP Cloud (HTTP
  request/response, DDIC metadata reads) goes behind an interface with a 7.5x implementation.
  The first iteration ships 7.5x only; a later cloud port is one factory change.
- **Modern ABAP, ≤30 chars, no Hungarian.** No `iv_`/`lv_` prefixes. abaplint `v752`.

## Protocol eras

| Era | Versions | Entry condition |
| --- | --- | --- |
| Legacy | `2025-03-26`, `2025-06-18`, `2025-11-25` | `initialize` request, or a request whose `_meta` does not carry a modern protocol version |
| Modern | `2026-07-28` | per-request `_meta` `io.modelcontextprotocol/protocolVersion` (and matching `MCP-Protocol-Version` header) names a modern version |

The legacy protocol versions are wire-compatible with one another, so the SDK negotiates the
version at `initialize` and otherwise operates in **`2025-11-25` data types**. Older clients
simply ignore the newer fields they do not understand and do not use newer features. This keeps
one data-class set instead of one per legacy version.

Because there are no sessions and no SSE, the SDK supports the **request/response subset** of
each era and excludes everything that requires a server-initiated stream. See
[ProtocolSupport.md](ProtocolSupport.md) for the exact method matrix.

## Package layout (`src/`, abapGit `PREFIX` sub-packages)

```
src/
  ajson/      vendored ajson, renamed zmcp2 (abaplint noIssues)
  platform/   environment-sensitive call abstraction (HTTP, DDIC) + 7.5x impls
  protocol/   transport-neutral core: jsonrpc, errors, version, result, dispatch, server base
  data/       request/response data classes (per-field conversion)
  server/     ICF entry handler, server factory, config reader
  ddic/       minimal tables: zmcp2_servers, zmcp2_origins, zmcp2_config
              (delivery class C, data class APPL2 — this exact combination is what
              abapGit's default data supporter requires to deserialize table content
              from a repo's data/ folder; zmcp2_tasks is runtime data, class A)
  demo/       example servers
```

### `src/platform/` — environment abstraction

The one place that knows about ICF and other release-sensitive APIs.

- `zif_mcp2_http_request` / `zif_mcp2_http_response` — transport-neutral request/response access
  (method, headers, body, status, content type).
- `zcl_mcp2_http_factory` — wraps ICF `if_http_request` / `if_http_response` into those
  interfaces. 7.5x implementation only for now.
- `zif_mcp2_ddic` + `zcl_mcp2_ddic_75` — wraps the DDIC structure/field metadata reads used by
  the schema builder.

See [PlatformAbstraction.md](PlatformAbstraction.md) for the cloud roadmap and rationale.

### `src/protocol/` — transport-neutral core

- `zcl_mcp2_jsonrpc` — the single central envelope: parse/serialize JSON-RPC request, result,
  error, notification. No batches.
- `zif_mcp2_const` / `zcx_mcp2_error` — version constants and spec error helpers (standard
  `-32700/-32600/-32601/-32602/-32603` plus modern `-32020` HeaderMismatch, `-32021`
  MissingRequiredClientCapability, `-32022` UnsupportedProtocolVersion — the spec-correct codes,
  replacing the old SDK's non-standard `-32001/-32004`).
- `zcl_mcp2_version` — era detection and version negotiation.
- `zif_mcp2_result` — implemented by result data classes; exposes `to_json`, `result_type`,
  `ttl_ms`, `cache_scope` so the dispatcher stamps the modern envelope centrally instead of each
  handler doing it by hand.
- `zcl_mcp2_dispatch_modern` / `zcl_mcp2_dispatch_legacy` — route each era's method set.
  `dispatch_modern` also stamps `resultType` on every result, validates required `_meta` and
  header-mirroring, and returns `-32601` for methods removed from the `2026-07-28` draft
  (e.g. `ping`, `logging/setLevel`). `dispatch_legacy` stamps a minimal per-request context
  (era + baseline version) for every request, since initialize context cannot carry over
  statelessly.
- `zif_mcp2_server` / `zcl_mcp2_server_base` — the stateless server contract SDK users implement.
  The base provides era-aware capability checks (`client_supports_elicitation/elicit_url/sampling`,
  `client_supports_tasks` — modern: declared extension, legacy: per-request `params.task`
  opt-in — and `era_is_modern`), `get_protocol_version`, `has_client_cap`, and a schema
  fallback. All handler
  methods default to `method_not_found`; subclasses override only what they need —
  except `get_name` / `get_version`, which are abstract so no server ships under a
  placeholder identity. `validate_tool_input` lets subclasses make the dispatcher check
  `tools/call` arguments against `get_tool_schema` before the handler runs. Schema violations
  are returned as `isError` tool results in both eras. For the tasks extension the base
  offers protected `get_tasks( )` (the scoped store) and `start_task( )` —
  one call that persists a 'working' row and returns the era-appropriate create-task result
  plus the task id for the background unit.
- `zcl_mcp2_tool_server_base` — the preferred authoring base for tool servers. Subclasses
  implement `define_tools( )` and `call_tool( )`; the base derives tool capability
  advertisement, `tools/list`, schema lookup, unknown-tool rejection and default input
  validation from the catalog.
- `zcl_mcp2_tasks` — lifecycle manager for the `io.modelcontextprotocol/tasks` extension (create,
  get, list, update, cancel, complete, fail, expire). Tasks are persisted in `zmcp2_tasks` (DDIC)
  and are background-safe. Rows are stamped with user/area/server; `list` filters by all three,
  while `get` / `get_payload` / `cancel` are keyed by task id and check the creating user only —
  the UUID is unguessable and the same user may poll a task through any of their servers.

### `src/data/` — data classes

Requests `zcl_mcp2_req_*`, responses `zcl_mcp2_resp_*`. Each owns its conversion per-field. One
data-type set modeled on `2025-11-25`; modern-only fields are emitted only in the modern era.
See [Conversion.md](Conversion.md).

Also in `src/data/`:

- **Input builders** (`zcl_mcp2_input_elicitation`, `zcl_mcp2_input_sampling`) — fluent
  builders for the input-request kinds used in MRTR flows. All implement
  `zif_mcp2_input_request` (`get_method` / `get_params`), so `zcl_mcp2_resp_input_req` and
  `zcl_mcp2_tasks` accept any kind through one typed entry point. Adding a future input type
  never touches those callers. `zcl_mcp2_server_base->can_request_input( )` inspects the same
  interface to gate form elicitation, URL elicitation and sampling safely. (Roots is deprecated
  in `2026-07-28` and meaningless for a
  remote server — no builder is shipped; Sampling is deprecated but kept as the only key-less
  LLM access path from ABAP.)
- **`zcl_mcp2_input_elicitation`** — form- and URL-mode elicitation; builds the JSON Schema
  payload via `zcl_mcp2_schema_builder`.
- **`zcl_mcp2_elicit_result`** — parses inbound elicitation responses (accept/decline/cancel +
  form data); used in the MRTR retry path via `req->get_input_response( key )`.
- **Schema helpers**: `zcl_mcp2_schema_builder` (fluent JSON Schema builder),
  `zcl_mcp2_schema_builder_ddic` (DDIC-driven derivation), `zcl_mcp2_schema_validator` (runtime
  validation).

### `src/server/` — ICF entry

`zcl_mcp2_http_handler` implements `if_http_extension`, immediately wraps the ICF objects via
`zcl_mcp2_http_factory`, and delegates to the transport-neutral core. `zcl_mcp2_server_factory`
resolves the configured server instance; a config reader loads `zmcp2_*` settings.

## Request flow (stateless)

1. **ICF entry.** `zcl_mcp2_http_handler` receives the request and wraps `if_http_request` /
   `if_http_response` into `zif_mcp2_http_*`. Nothing below this point touches ICF.
2. **Method gate / CORS.** `POST` is handled. `GET` and `DELETE` → `405` with
   `Allow: POST, OPTIONS`. `OPTIONS` → CORS preflight. `Origin` is validated against
   `zmcp2_origins`.
3. **Parse.** `zcl_mcp2_jsonrpc` parses one JSON-RPC request or notification (no batches).
   Notifications → HTTP `202`, empty body.
4. **Era + negotiation.** `zcl_mcp2_version` decides the era: an `initialize` request → legacy;
   per-request `_meta` / `MCP-Protocol-Version` → modern. Unsupported/mismatched version →
   spec error + HTTP `400`.
5. **Modern validation.** For modern requests: validate `_meta` (`protocolVersion` vs header,
   optional `clientInfo`, `clientCapabilities`), validate mirrored `x-mcp-header` values against
   the body, and check required capabilities per request.
6. **Dispatch.** The era dispatcher calls the SDK user's typed handler, which returns a
   `zif_mcp2_result`.
7. **Envelope + serialize.** The dispatcher stamps the envelope centrally — `resultType` /
   `ttlMs` / `cacheScope` / `_meta` `serverInfo` for modern, a plain result for legacy — and
   `zcl_mcp2_jsonrpc` serializes it back through `zif_mcp2_http_response`.

## What is deliberately excluded

Everything that needs a server-initiated stream or stored session state:

- notifications of any kind, `subscriptions/listen`, `resources/subscribe`
- request-scoped SSE responses, stream-close cancellation
- stateful `initialize` sessions (the handshake is supported, but no session is created)

These are protocol-level impossibilities on stateless ICF without SSE, not gaps to be filled
later within this design. See [ProtocolSupport.md](ProtocolSupport.md).

## Testing strategy

**Unit tests** — local test classes (`*.clas.testclasses.abap`, `ltcl_*`) per production class,
asserting on pinned JSON output. Because `zif_mcp2_http_*` is an interface, the entire dispatch
path is unit-testable with a mocked request/response — no ICF, no running server needed.

**Integration tests** — a Jest + TypeScript suite in the sibling `mcp2_tests/test/` project runs
tests against a live ABAP system (`http://…/zmcp2`). The suite covers both protocol eras, all
HTTP status conventions, JSON-RPC id type preservation, header mirroring, MRTR flows, tasks
lifecycle, and negative paths (version mismatch, missing capability, header mismatch). A
full-capability test server (`zcl_mcp2_test_full`) in `mcp2_tests/src/` exercises all SDK entry
points end-to-end.
