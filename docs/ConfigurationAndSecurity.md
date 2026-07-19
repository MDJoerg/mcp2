# Configuration and security

## The three config tables

### `zmcp2_servers` — server registry

| Field | Meaning |
| --- | --- |
| `AREA` | First path segment under the ICF service |
| `SERVER` | Second path segment |
| `CLASS` | Your server class (implements `zif_mcp2_server`, normally via `zcl_mcp2_tool_server_base` or `zcl_mcp2_server_base`) |

`POST /zmcp2/{AREA}/{SERVER}` instantiates `CLASS` per request — servers are stateless
and carry no instance state between calls. Unknown paths answer 404.

### `zmcp2_origins` — browser origin allow-list

| Field | Meaning |
| --- | --- |
| `AREA` / `SERVER` | Exact server, or `*` wildcards |
| `ID` | Row key (free) |
| `ORIGIN` | `scheme://host[:port]`, or `*` to allow all |

Lookup order: exact `area`/`server` → `area`/`*` → `*`/`server` → `*`/`*` — the **first
level with rows wins** (an exact row set shields the server from broader wildcards).
Matching is case-insensitive (RFC 6454). With no matching rows at all, every request that
carries an `Origin` header is rejected with **403**; requests without one (curl, desktop
clients, server-to-server) always pass. CORS preflights (`OPTIONS`) echo the allowed
origin and the concrete requested `Mcp-Param-*` headers.

### `zmcp2_config` — global switches

One row per SAP client (`MANDT`) — not per MCP client. `CORS_MODE`: `C` (default when the table
is empty) validates the
`Origin` header against `zmcp2_origins` whenever one is present; `I` skips origin
validation entirely; `E` behaves like `C` (reserved for a stricter require-Origin mode).

The current Streamable HTTP draft requires servers to validate the `Origin` header whenever
one is present. Therefore `CORS_MODE = I` is intentionally **non-compliant** and should only be
used in controlled local/dev deployments where another layer has already enforced the browser
origin policy. Public MCP endpoints should use `C` and explicit rows in `zmcp2_origins`.

## Provisioning config via abapGit

All three tables are delivery class `C`, data class `APPL2` — exactly what abapGit's
table-content feature requires. You can version config rows as `data/*.conf.json` +
`*.tabu.json` files in a repo and have pulls maintain them (confirm the TABU entries in
the pull dialog). See the `mcp2_tests` repository for a working example.

## Authentication and authorization

The SDK adds **no authentication of its own** — the ICF node's logon procedure (basic
auth, SSO tickets, X.509) runs before the handler. Everything a handler does executes
with the authenticated user's authorizations, so standard SAP authorization checks apply
inside your tool implementations. [Task](Tasks.md) rows are additionally scoped to the
creating user.

Reaching the endpoint at all already requires a successful ICF logon **and** authorization to
call that ICF service (`S_ICF`), both enforced by the platform before the SDK runs. Restrict
the service node the way you restrict any other ICF service.

What the SDK adds no opinion about is granularity *within* an authorized node: a user who may
call `/zmcp2` may call every `AREA`/`SERVER` registered under it. The SDK ships **no
authorization object** of its own — deliberately, because v1's fixed `ZMCP_SRV` clashed with
customer naming conventions. Where servers under one node need different audiences, either put
them behind separate ICF nodes or redefine `check_authorization`, below.

## Endpoint authorization — `check_authorization`

An optional per-server check on top of the ICF node's own authorization, for when one node
serves several servers with different audiences. Redefine one method; it runs once per request,
after the server class is resolved and **before the body is parsed**, so a denied caller reaches
no handler at all — not `initialize`, not `server/discover`, not `tools/list`:

```abap
METHOD zif_mcp2_server~check_authorization.
  " area / server are the path segments the request was routed to.
  AUTHORITY-CHECK OBJECT 'Z_MY_MCP'
                  ID 'ZAREA' FIELD area
                  ID 'ACTVT' FIELD '16'.
  result = xsdbool( sy-subrc = 0 ).
ENDMETHOD.
```

Use whatever authorization object your namespace already has — the SDK does not prescribe one.
The check runs under the authenticated ICF user, so `sy-uname` and normal authority checks
apply.

- Denial answers **HTTP 403** with a generic `Not authorized for this MCP server`. Your reason
  is never echoed to the caller; log it server-side if you need an audit trail.
- An exception escaping the method aborts the request, so a bug in your check **fails closed**.
- It is **endpoint-level**. Per-tool or per-record checks belong in the handler that knows what
  is being touched — a tool reading HR data should still check there.

Migrating from v1, this is where the `ZMCP_SRV` check moves ([migration guide](MigrationV1.md)).

Recommendations:

- Use a dedicated ICF node per exposure level; TLS only. Node-level `S_ICF` restriction is the
  primary control — `check_authorization` refines it, it does not replace it.
- Redefine `check_authorization` when one node hosts servers that should not share an audience.
- Write tool handlers defensively — treat arguments as untrusted input and use
  [input validation](Tools.md#input-validation) where it helps.
- Keep `zmcp2_origins` empty unless browsers genuinely call the endpoint.

## HTTP behavior and error mapping

| Situation | HTTP | JSON-RPC |
| --- | --- | --- |
| Success or application-level error | 200 | result / error in body |
| Modern `MethodNotFound` | 404 | `-32601` |
| Legacy `MethodNotFound` | 200 | `-32601` |
| Notification (no `id`) | 202 | empty body |
| Header mismatch (modern mirroring) | 400 | `-32020` |
| Missing client capability (modern) | 400 | `-32021` |
| Unsupported protocol version (header/`_meta`) | 400 | `-32022` |
| Malformed required modern `_meta` | 400 | `-32602` |
| Invalid modern `Accept` / `Content-Type` | 406 / 415 | `-32600` |
| Unparseable body / batch array / client-sent response | 400 | `-32700` / `-32600` |
| Unknown endpoint path or server | 404 | `-32600` / `-32601` |
| Registered server class invalid (not instantiable / missing interface) | 500 | `-32603` |
| Disallowed `Origin` | 403 | `-32600` |
| `GET` / `DELETE` / others | 405 (`Allow: POST, OPTIONS`) | — |

Application errors generally ride in HTTP 200 (the JSON-RPC-over-HTTP convention legacy
clients expect). Modern `MethodNotFound` is the exception required by Streamable HTTP:
it surfaces as HTTP 404 with the JSON-RPC `-32601` error body.

Custom protocol errors in handlers: raise `zcx_mcp2_error` via its typed helpers
(`raise_invalid_params`, `raise_method_not_found`, `raise_resource_not_found`, …) — the
dispatcher converts them to proper JSON-RPC error responses. Anything else that escapes a
handler becomes `-32603`.

`raise_resource_not_found` is deliberately an era-neutral handler signal: the legacy dispatcher
preserves `-32002`, while the modern dispatcher maps it to `-32602` and retains `error.data.uri`.

A `zmcp2_servers` row whose class cannot be instantiated or does not implement
`zif_mcp2_server` answers HTTP 500 with a generic `-32603` error — deliberately distinct
from the 404 for a server that is not registered at all. The response does not expose the
configured ABAP class name or other server configuration details.
