# Server identity and request context

`zcl_mcp2_server_base` does more than provide empty handlers. It gives every handler a typed,
per-request view of the client, protocol era, capabilities and common metadata. Use these helpers
instead of parsing `_meta` or remembering which protocol generation puts a value where.

## Advertise a useful server identity

Only `get_name` and `get_version` are mandatory. The optional identity methods make the server
much easier to recognize in client UIs:

```abap
METHOD zif_mcp2_server~get_title.
  result = `Sales Order Assistant`.
ENDMETHOD.

METHOD zif_mcp2_server~get_description.
  result = `Reads and explains sales orders from the production ERP system`.
ENDMETHOD.

METHOD zif_mcp2_server~get_website_url.
  result = `https://intranet.example.com/mcp/sales-orders`.
ENDMETHOD.

METHOD zif_mcp2_server~get_icons.
  result = VALUE #( ( src = `https://intranet.example.com/icons/orders.png`
                      mime_type = `image/png` ) ).
ENDMETHOD.

METHOD zif_mcp2_server~get_instructions.
  result = `Order numbers have ten digits. Never infer a missing order number.`.
ENDMETHOD.
```

`get_title`, `get_description`, `get_website_url` and `get_icons` populate `serverInfo` — a
top-level `initialize` result field in the legacy eras, and
`_meta["io.modelcontextprotocol/serverInfo"]` on every modern-era result since the 2026-07-16
schema change — see `ProtocolSupport.md`.
`get_instructions` is a server-wide hint to the client/model; keep security checks and business
rules in ABAP because clients are not required to enforce instructions.

## Identify the current client and protocol

The dispatcher installs fresh context before invoking a handler. These methods work in any
handler inherited from the base class:

```abap
DATA(client_name)    = get_client_name( ).
DATA(client_version) = get_client_version( ).
DATA(client_title)   = get_client_title( ).
DATA(protocol)       = get_protocol_version( ).

IF era_is_modern( ) = abap_true.
  " Modern-only behavior, if the business operation genuinely needs it
ENDIF.
```

Do not authorize by client name or version: both are client-supplied labels. Use the authenticated
ICF user and normal ABAP authorization checks for trust decisions.

For optional protocol features, prefer the purpose-specific helpers over version comparisons:

| Helper | True when |
| --- | --- |
| `client_supports_elicitation( )` | a modern client can render form elicitation |
| `client_supports_elicit_url( )` | a modern client explicitly supports URL elicitation |
| `client_supports_sampling( )` | a modern client declares sampling |
| `client_supports_tasks( )` | the current modern or legacy request can accept a task result |
| `supports_input_required( )` | the protocol era supports MRTR in general |
| `has_client_cap( key )` | the named top-level client capability exists |

For typed input requests, `can_request_input( input )` is safer and shorter than selecting the
individual capability check yourself. See [Input required](InputRequired.md).

## Logging and distributed tracing

Common `_meta` values have accessors that also handle keys containing `/` correctly:

```abap
DATA(log_level)   = get_log_level( ).
DATA(traceparent) = get_traceparent( ).
DATA(tracestate)  = get_tracestate( ).
DATA(custom)      = get_meta_string( `com.example/tenantHint` ).
```

The values are empty when absent. The SDK does not emit logging notifications or start tracing
spans; use these hints with your application log or tracing library. Treat custom metadata as
untrusted input. In particular, a tenant hint must not replace authorization derived from the
authenticated user.

## Cache discovery metadata

Modern `server/discover` is cacheable. If identity and capabilities only change when code is
transported, avoid repeated discovery work by overriding:

```abap
METHOD zif_mcp2_server~get_discover_cache.
  result-ttl_ms      = 3600000.
  result-cache_scope = zif_mcp2_const=>cache_scopes-private.
ENDMETHOD.
```

The default is `ttl_ms = 0` and `private`. Use `public` only if the discovered server description
is identical for all authenticated users. List responses for tools, resources and prompts have
their own `set_cache( )` method when implemented directly; the tool-catalog base intentionally
returns a conservative, uncached catalog.

## When raw context is appropriate

`zif_mcp2_server~get_context( )` exposes the parsed client info, capabilities and `_meta` ajson
objects. It is useful for a protocol extension that has no typed helper. Most application code
should use the accessors above: they preserve era compatibility and keep JSON path details out of
handlers. Context is request-local state on the server instance; do not retain its references for
background jobs. Pass only the explicitly validated values the job needs.
