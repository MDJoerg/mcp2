# Changelog

All notable changes to the `mcp2` SDK are recorded here.

The SDK version is available at runtime as `zif_mcp2_const=>sdk_version`. It is independent of
the MCP protocol version (`zif_mcp2_const=>protocol`) and of the version your own server reports
via `get_version( )`.

## 1.0.0 - 2026-07-26

First stable release, cut alongside the `2026-07-28` spec generation. Everything below is relative to the `0.1.0` beta.

### Protocol

- `Mcp-Name` is no longer required on `tasks/get` / `tasks/update` / `tasks/cancel`. A header that
  is sent must still match `params.taskId` (`-32020`), an absent one is accepted: the Tasks
  extension puts that MUST on the client, and this SDK reads every task from `ZMCP2_TASKS`, so
  there is no app-server affinity to protect. `tools/call`, `prompts/get` and `resources/read`
  still require the header.
- `Mcp-Name` errors now name the body field the header has to carry (`params.name`, `params.uri`,
  `params.taskId`) instead of just reporting a mismatch.
- `server/discover` no longer writes the superseded top-level `serverInfo` field. Modern server
  identity is now emitted only in `_meta["io.modelcontextprotocol/serverInfo"]`, on every modern
  result, which is where the `2026-07-28` draft put it on 2026-07-16. The top-level write existed
  because every published TypeScript v2 SDK up to `2.0.0-beta.4` bundled a `DiscoverResultSchema`
  that required it; `2.0.0-beta.5` (2026-07-21) reads `_meta` instead, so the workaround is gone.
  Clients pinned to `2.0.0-beta.4` or earlier will misclassify the server as non-modern — upgrade
  them. Legacy `initialize` is unchanged: `serverInfo` stays a top-level result field there.
  No ABAP API change; `get_title` / `get_description` / `get_website_url` / `get_icons` behave
  exactly as before.

### Fixed (downport only, 7.02 – 7.4x)

- Open SQL host variables named like a column of the table they address now go through renamed
  locals (`task_id_arg`, `area_arg`, `server_arg`). Without the `@` escape the column wins, so
  `WHERE task_id = task_id` matched *every* row — foreign task reads and updates, unscoped CORS
  allowlists, arbitrary server classes. 7.5x was never affected.
- `zcl_mcp2_schema_builder_ddic` passes a typed `ddobjname` instead of `CONV #( )`, which
  downported to `TYPE undefined`.
- `ZMCP2_CLEAR_TASKS` no longer sets `LDBNAME` to `&NC&` ("local database &NC& is unknown").
- The downport now post-processes what abaplint leaves in strict-syntax form: commas in
  `UPDATE … SET`, `UP TO n ROWS` after `ORDER BY`, and trailing blanks. Lines over 255 characters
  abort the build instead of being silently truncated on import.

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
