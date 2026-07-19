# Changelog

All notable changes to the `mcp2` SDK are recorded here.

This SDK is pre-release. Until `1.0.0`, **breaking changes may land in any release** — the ABAP
API surface is not yet frozen. Breaking changes are always listed first in their entry.

The SDK version is available at runtime as `zif_mcp2_const=>sdk_version`. It is independent of
the MCP protocol version (`zif_mcp2_const=>protocol`) and of the version your own server reports
via `get_version( )`.

## 0.1.0 — first beta - 2026-07-19

First beta of the v2 SDK. This is a from-scratch rewrite of the ABAP MCP server SDK, not an
upgrade of the v1 package — see [docs/MigrationV1.md](docs/MigrationV1.md).

### Protocol

- Serves the `2026-07-28` draft generation (stateless, per-request `_meta` negotiation,
  `server/discover`) alongside the legacy era `2025-03-26` … `2025-11-25`, from one server class.
- Multi-round-trip requests (MRTR): `inputRequired` results carrying form elicitation, URL
  elicitation, or sampling, correlated by an opaque `requestState` the client echoes back.
- Tasks extension in both eras — modern `io.modelcontextprotocol/tasks` and the legacy
  `2025-11-25` shape, including task-scoped input requests.
- Header mirroring (`Mcp-Method`, `Mcp-Name`, `Mcp-Param-*`) with body-as-source-of-truth
  validation.
- Spec-correct error codes `-32020` / `-32021` / `-32022`, replacing v1's non-standard
  `-32001` / `-32004`.

### Authoring

- `zcl_mcp2_tool_server_base`: declare `define_tools( )` once, implement `call_tool( )`; the base
  derives `tools/list`, schema lookup, unknown-tool rejection and input validation.
- Common server-authoring paths need no hand-written JSON — typed request getters, response
  factories and builders, fluent schema builders, typed input-request builders, typed content
  annotations and icons. Pre-built ajson remains available for rich prompt content and custom
  extensions.
- Era-aware capability helpers (`client_supports_elicitation` / `_elicit_url` / `_sampling` /
  `_tasks`, `can_request_input`, `era_is_modern`) so handlers gate features instead of hitting
  framework errors.
- Request context — client identity, protocol, log level, W3C trace context — via typed getters,
  with no `_meta` parsing.
- Framework input validation: advertised-schema violations return `isError` tool results in both
  eras; malformed calls and unknown tools remain `-32602`.
- Schema builder and request accessors are symmetric — every shape you can declare has a typed
  reader. `add_number` is matched by `get_arg_number` / `_or` / `require_` (`decfloat34`,
  converted from the raw JSON literal so decimals are not rounded through a binary float), and
  each primitive-array builder by `get_arg_string_table` / `_integer_table` / `_number_table` /
  `_boolean_table`.
- Schema builder covers the common JSON Schema vocabulary: `title` on every property,
  `default` on scalars (emitted even for `0` / `false` / empty string), and
  `add_string_array` / `add_integer_array` / `add_number_array` / `add_boolean_array`.
  Composition keywords, `$ref` and dialect negotiation remain deliberately out of scope.

### Structure

- Stateless by construction: no sessions, no `Mcp-Session-Id`, no session tables.
- JSON↔ABAP conversion localized per data class; only the JSON-RPC envelope and the modern result
  stamp are central.
- Environment-sensitive calls (HTTP, DDIC) behind interfaces with 7.5x implementations, so an
  ABAP Cloud port is a factory change.
- Full dispatch path unit-testable without ICF; external Jest integration suite in the sibling
  `mcp2_tests` repository covers both eras against the reference TypeScript SDK.

### Security

- `check_authorization` on the server contract: an optional per-server access check that runs
  before the request body is parsed, so denial (HTTP 403) blocks every method including
  `initialize` and `server/discover`. It refines ICF logon and `S_ICF` service authorization,
  which gate the node itself — it does not replace them. The SDK ships **no authorization
  object**; v1's fixed `ZMCP_SRV` clashed with customer naming conventions, so servers bring
  their own where one node hosts servers with different audiences.

### Not implemented, by design

Server-sent notifications of any kind, `subscriptions/listen`, `resources/subscribe`, SSE,
sessions, logging, and roots. All require a server→client stream or stored session state. See
[docs/ProtocolSupport.md](docs/ProtocolSupport.md).

### Known deviations

- `tasks/result` on a non-terminal task answers `-32600` instead of blocking; clients poll
  `tasks/get`.
- JSON-RPC batches are rejected, including for `2025-03-26`-pinned clients.
- Modern results carry `serverInfo` both top-level and in `_meta`, because released TypeScript v2
  SDKs still require the top-level field. To be dropped once a released SDK reads `_meta`.

### Differences from the v1 SDK

No OAuth layer or request-nonce table, and no fixed `ZMCP_SRV` authorization object — v1 checked
one in its HTTP handler; v2 offers the `check_authorization` hook instead so you can use your own
object. Servers that used `ZMCP_SRV` to separate audiences across servers under one ICF node
should port that distinction. Full mapping in [docs/MigrationV1.md](docs/MigrationV1.md).
