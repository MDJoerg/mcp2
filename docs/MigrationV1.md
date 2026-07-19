# Migrating from the v1 SDK

This guide maps the released v1 SDK (`zmcp` prefix, `zif_mcp_server`) onto v2 (`zmcp2`).

**Both SDKs can run side by side.** v2 uses a distinct object prefix, its own DDIC tables and its
own ICF node, so there is no big-bang cutover: install v2, port one server, run both until you are
satisfied, then retire the v1 node. Nothing in v2 touches v1 objects.

## Decide whether to migrate at all

v2 is **stateless only**. That is the whole design, not a temporary limitation.

**Stay on v1** if your server needs protocol sessions, `Mcp-Session-Id` lifecycle, ICF stateful
mode, or anything that depends on state surviving between requests — v2 cannot express those.

**Move to v2** if you want the `2026-07-28` generation, the modern per-request negotiation,
multi-round-trip elicitation and sampling, cloud-readiness, or simply a smaller surface to reason
about. v2 also serves legacy clients (`2025-03-26` … `2025-11-25`) statelessly, so a v1 server
that never actually relied on session state usually ports cleanly.

> The draft-2026 experiment inside the v1 repository (the `*_v2` classes and their docs) is
> **not published** and is not a migration path. It was the exploration that led to this SDK
> being written from scratch instead. Migrate from v1's released `zif_mcp_server` API.

## Authorization: what changed

v1's HTTP handler performed `AUTHORITY-CHECK OBJECT 'ZMCP_SRV'` against the requested area and
server on every call. **v2 ships no authorization object.** ICF logon and `S_ICF` service
authorization still gate the node itself, so this is not a hole — but v2 makes no distinction
*between* the servers registered under one node, where v1's object did.

The fixed object is gone on purpose — it clashed with customer naming conventions. v2 gives you
the hook instead of the object: redefine `check_authorization` on your server class and use
whatever authorization object you already have.

```abap
METHOD zif_mcp2_server~check_authorization.
  AUTHORITY-CHECK OBJECT 'Z_MY_MCP' ID 'ZAREA' FIELD area.
  result = xsdbool( sy-subrc = 0 ).
ENDMETHOD.
```

It runs before the body is parsed, so denial (HTTP 403) blocks every method including
`initialize` and `server/discover` — the same reach the v1 check had. If you relied on
`ZMCP_SRV` to separate audiences across servers, port that distinction here; if your nodes are
already restricted per exposure level, node-level `S_ICF` may be all you need. See
[Configuration and security](ConfigurationAndSecurity.md#endpoint-authorization--check_authorization).

## The three changes that matter

Everything else is renaming. These three are real rewrites.

### 1. Errors are exceptions, not a response field

v1 handlers received a `CHANGING` response struct with `result` and `error` components, and
signalled failure by filling `error`:

```abap
" v1
METHOD handle_call_tool.
  CASE request->get_name( ).
    WHEN `greet`.
      response-result->add_text_content( |Hello!| ).
    WHEN OTHERS.
      response-error-code    = zcl_mcp_jsonrpc=>error_codes-invalid_params.
      response-error-message = |Tool { request->get_name( ) } not found.|.
  ENDCASE.
ENDMETHOD.
```

v2 handlers **return** a result object and **raise** protocol errors:

```abap
" v2
METHOD call_tool.
  CASE request->get_name( ).
    WHEN `greet`.
      result = zcl_mcp2_resp_call_tool=>text( |Hello!| ).
    WHEN OTHERS.
      zcx_mcp2_error=>raise_invalid_params( |Unknown tool: { request->get_name( ) }| ).
  ENDCASE.
ENDMETHOD.
```

While porting, keep the distinction v2 makes explicit: a **business** failure the model should
see and correct is `zcl_mcp2_resp_call_tool=>error_text( )` inside a normal result; a **protocol**
failure is a raised `zcx_mcp2_error`. v1 code that funnelled both into `response-error` should be
split. See [Tools](Tools.md#errors-iserror-vs-protocol-errors).

### 2. Tools are declared once, not built per request

v1 built the catalog inside `handle_list_tools` and dispatched separately in `handle_call_tool` —
two places to keep in sync. v2's `zcl_mcp2_tool_server_base` takes the catalog from
`define_tools( )` and derives `supports_tools`, `tools/list`, schema lookup, unknown-tool
rejection and input validation from it:

```abap
METHOD define_tools.
  result = VALUE #( ( name         = `greet`
                      description  = `Greets a person by name.`
                      input_schema = NEW zcl_mcp2_schema_builder(
                        )->add_string( name = `name` required = abap_true
                        )->to_json( ) ) ).
ENDMETHOD.
```

Your v1 `handle_call_tool` body becomes `call_tool`, minus the unknown-name branch the base now
handles. Argument validation you wrote by hand against `zcl_mcp_schema_validator` can usually be
deleted — v2 validates advertised schemas before the handler runs, returning `isError` in both
eras. See [Tools](Tools.md).

### 3. Sessions and the raw HTTP objects are gone

v1 handed handlers a `server` struct containing `session_id`, `session_mode`, and live
`if_http_request` / `if_http_response` / `if_http_server` references. None of that exists in v2:

- **Session state** has no replacement. Continuation state for a multi-round-trip flow is
  offloaded to the client as an opaque `requestState` token ([Input required](InputRequired.md));
  long-running work goes to the [Tasks](Tasks.md) extension. Per-user state that outlives a
  request is your application's own table.
- **The HTTP objects** are deliberately not reachable — that isolation is what makes an ABAP
  Cloud port a factory change ([Platform abstraction](PlatformAbstraction.md)). What handlers
  legitimately needed from them is exposed as typed getters on the base class: client name and
  version, negotiated protocol, era, capabilities, log level, W3C trace context
  ([Server context](ServerContext.md)).
- `get_session_mode` and `handle_initialize` are gone. `initialize` is answered by the framework;
  only `get_name` and `get_version` are mandatory on your class.

If a v1 handler read `server-session_id` to key its own storage, key it by the authenticated user
instead — and never by a client-supplied label.

## Name mapping

Prefix `zcl_mcp_*` → `zcl_mcp2_*` holds almost everywhere. The exceptions:

| v1 | v2 | Note |
| --- | --- | --- |
| `zif_mcp_server` | `zif_mcp2_server` | One contract for both eras |
| `zcl_mcp_server_base` | `zcl_mcp2_server_base` | Or `zcl_mcp2_tool_server_base` for tool servers |
| `handle_call_tool` (CHANGING) | `call_tool` (RETURNING) | See above |
| `handle_list_tools` | `define_tools` | Declarative catalog |
| `handle_get_prompt`, `handle_resources_read`, … | `zif_mcp2_server~prompts_get`, `~resources_read`, … | Redefine the interface method directly |
| `handle_completions_complete` | `zif_mcp2_server~completions_complete` | |
| `handle_cancel_task` | Base-class `tasks/*` handling | Override only for custom semantics |
| `handle_initialize`, `get_session_mode` | — | Removed |
| `zcx_mcp_server` + `response-error` | `zcx_mcp2_error` | Typed `raise_*` helpers |
| `zcl_mcp_tasks` via `get_tasks( )` | `zcl_mcp2_tasks`; `start_task( )` on the base | Background mutators are **class** methods |
| `zcl_mcp_schema_builder` | `zcl_mcp2_schema_builder` | Fluent, chainable |
| `zcl_mcp_schema_builder_ddic` | `zcl_mcp2_schema_builder_ddic` | Now takes typed `overrides` |
| `zcl_mcp_schema_validator` | `zcl_mcp2_schema_validator` | Same subset; plus `validate_or_raise` |
| `zcl_mcp_http_handler` | `zcl_mcp2_http_handler` | New ICF node |
| `zmcp_ajson` | `zmcp2_ajson` | Vendored separately |

Full v2 inventory: [Class reference](Reference.md).

## Configuration mapping

| v1 | v2 |
| --- | --- |
| `zmcp_servers` | `zmcp2_servers` — same `AREA` / `SERVER` / `CLASS` idea |
| `zmcp_origins` | `zmcp2_origins` |
| `zmcp_config` | `zmcp2_config` — `CORS_MODE` only |
| `zmcp_tasks` | `zmcp2_tasks` |
| `zmcp_sessions` | **removed** — no sessions |
| `zmcp_req_nonces` | **removed** — no OAuth layer in v2 |
| `ZMCP_SRV` authorization object | **removed** — redefine `check_authorization` with your own object |
| `ZMCP_CLEAR_MCP_TASKS` | `ZMCP2_CLEAR_TASKS` |
| `ZMCP_CLEAR_MCP_SESSIONS`, `ZMCP_CLEAR_REQ_NONCES` | **removed** |

Rows are not migrated automatically — recreate them, or provision via abapGit table content
([Configuration](ConfigurationAndSecurity.md#provisioning-config-via-abapgit)).

## What v2 gains

Beyond the `2026-07-28` era itself: multi-round-trip [elicitation and sampling](InputRequired.md)
(v1 had neither), typed [content blocks and icons](Conversion.md) everywhere the spec allows them,
[header mirroring](Tools.md#header-mirroring-modern-era) for edge routing, per-request cache hints,
framework-level [input validation](Tools.md#input-validation), and a dispatch path that is fully
unit-testable without ICF.

## What v2 drops

OAuth support and the request-nonce table; sessions in every form; and the fixed `ZMCP_SRV`
authorization object (replaced by the `check_authorization` hook). Logging and roots are not implemented at all — both are deprecated in
`2026-07-28`, and a stateless server can never deliver logging notifications
([Protocol support](ProtocolSupport.md)).

## Suggested order

1. Install v2 alongside v1; create a **separate** ICF node (`/zmcp2`).
2. Port one small tool server. Start from [Getting started](GettingStarted.md), not from your v1
   class — the tool-catalog base changes the shape enough that transcribing is slower.
3. Move the tool bodies over, splitting `response-error` into `error_text` vs raised errors.
4. Replace hand-rolled argument validation with declared schemas.
5. Re-establish the access control `ZMCP_SRV` used to give you.
6. Test both eras — the [learning path](LearningPath.md#compatibility-branch) has a concrete
   compatibility exercise.
7. Repeat per server, then retire the v1 node when nothing points at it.
