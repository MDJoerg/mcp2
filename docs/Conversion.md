# Conversion conventions — data classes

## Decision

JSON↔ABAP conversion is **localized in each data class, field by field**. There is no central,
reflection-driven conversion engine. The only shared conversion code is:

- `zcl_mcp2_jsonrpc` — the JSON-RPC envelope (`jsonrpc`, `id`, `method`, `params`, `result`,
  `error`).
- the `zif_mcp2_result` envelope stamp — `resultType` / `ttlMs` / `cacheScope`, applied once by
  the dispatcher rather than by every handler.

### Why per-field, not a central mapper

The old SDK split conversion between (a) hand-written camelCase path strings in each class and
(b) a partly-adopted central ajson naming layer. The mix was the brittle part: two places to get
wrong, silent failures on typos, and `_set` boolean flags to distinguish "false" from "absent".

A fully automatic snake↔camel mapper was considered and rejected for this SDK: MCP shapes have
enough irregularities (`_meta`, `inputSchema` carrying raw JSON Schema, polymorphic content
blocks, optional-vs-absent semantics, `x-mcp-header` passthrough) that an automatic mapper needs
per-field overrides anyway. Keeping all of a message's conversion in one explicit place — its own
class — makes each class self-contained, greppable, and unit-testable in isolation. The cost is
boilerplate; the benefit is no hidden central coupling.

## Request classes (`zcl_mcp2_req_*`)

Parse inbound JSON explicitly.

- Constructor takes `json TYPE REF TO zif_mcp2_ajson` (the `params` slice).
- Read each field with the typed ajson getter and guard optionals with `exists( )`.
- Store into private attributes; expose typed getters (`get_name`, `has_arguments`,
  `get_arguments`, …).
- Delegate nested/optional sub-objects to their own data classes via `slice( )`.
- Never infer cross-request state — a request object reflects only its own payload.

```abap
" sketch — zcl_mcp2_req_call_tool
METHODS constructor IMPORTING json TYPE REF TO zif_mcp2_ajson
                    RAISING   zcx_mcp2_ajson_error.
" body: name = json->get_string( '/name' ).
"       IF json->exists( '/arguments' ). arguments = json->slice( '/arguments' ). ENDIF.
```

## Response / result classes (`zcl_mcp2_resp_*`)

Serialize outbound JSON explicitly and carry the result envelope.

- Implement `zif_mcp2_result`:
  - `to_json RETURNING REF TO zif_mcp2_ajson` — builds the result body with explicit per-field
    `set( )` calls using the literal camelCase paths the spec defines.
  - `result_type` / `ttl_ms` / `cache_scope` — envelope hints the dispatcher stamps. Default
    `result_type = complete`. Modern cacheable results get `ttlMs` and `cacheScope`; unset cache
    hints default to `ttlMs = 0`, `cacheScope = private`.
- Build fields with explicit paths (`result->set( '/content/1/type', 'text' )`), guarding
  optionals (`IF description IS NOT INITIAL.`).
- Raw JSON Schema fields (`inputSchema`, `outputSchema`, `structuredContent`) are grafted in as
  sub-`zif_mcp2_ajson` nodes, not stringified and re-parsed.

```abap
" sketch — zcl_mcp2_resp_call_tool implements zif_mcp2_result
METHOD zif_mcp2_result~to_json.
  result = zcl_mcp2_ajson=>create_empty( ).
  " content blocks, isError, optional structuredContent ...
ENDMETHOD.
METHOD zif_mcp2_result~result_type.   value = zif_mcp2_const=>result_types-complete. ENDMETHOD.
```

### Structured output from ABAP types

`zcl_mcp2_resp_call_tool=>structured_data( data )` creates a complete structured tool result.
For an existing response, `zcl_mcp2_resp_call_tool` and `zcl_mcp2_resp_task_payload` expose
`set_structured_data( data TYPE any )`.
Internally this calls `ajson->set( iv_path = '/' iv_val = data )`, which recursively serializes
any ABAP structure or table with **lowercase field names** (ajson default). An optional text
mirror (`add_text = abap_true`, the default) stringifies the resulting JSON and appends it as a
text content block — as recommended by the spec for clients that only consume `content`.

```abap
" no raw JSON needed — pass any ABAP structure
DATA: BEGIN OF payload,
        value TYPE i,
        label TYPE string,
      END OF payload.
payload-value = 42.  payload-label = `test`.
result = zcl_mcp2_resp_call_tool=>structured_data( payload ).
" → structuredContent: {"value":42,"label":"test"}
" → content: [{"type":"text","text":"{\"value\":42,\"label\":\"test\"}"}]
```

### Typed content blocks

All five spec `ContentBlock` kinds are constructible on `zcl_mcp2_resp_call_tool` without raw
JSON: `add_text` / `add_image` / `add_audio`, `add_resource` (embedded
`TextResourceContents` / `BlobResourceContents` — a non-initial `blob` selects the binary
variant) and `add_resource_link`. The shared structures live in `zif_mcp2_content`:
`annotations` (audience flags, `priority` + `priority_set`, `last_modified`),
`resource_contents` and `resource_link` (`size` + `size_set`). The `*_set` flags exist because
`0` is a meaningful spec value for `priority` and `size` — same convention as the tool
annotation hints.

```abap
response->add_resource_link( VALUE #( uri      = `mcp2://files/report.pdf`
                                      name     = `report.pdf`
                                      size     = 1024
                                      size_set = abap_true
                                      annotations = VALUE #( audience_user = abap_true ) ) ).
```

### Icons

The spec `Icon` shape (`src` required; `mimeType`, `sizes`, `theme` optional) is the typed
structure `zif_mcp2_content=>icon`; `zif_mcp2_content=>icons` is the table. One emitter —
`zcl_mcp2_icons=>emit` — writes the array everywhere icons appear: `serverInfo`
(override `get_icons` on the server class; legacy `initialize` and modern `server/discover` both
carry it top-level, modern results additionally carry it in `_meta`), tools, prompts, resources,
resource templates
(each list entry struct has an `icons` field) and `resource_link` content blocks. Theme
values come from `zif_mcp2_const=>icon_themes`; empty optional fields are omitted from the
wire.

```abap
METHOD zif_mcp2_server~get_icons.
  result = VALUE #( ( src       = `https://example.com/icon.png`
                      mime_type = `image/png`
                      sizes     = VALUE #( ( `48x48` ) )
                      theme     = zif_mcp2_const=>icon_themes-light ) ).
ENDMETHOD.
```

## Input-request builders

The `InputRequired` / MRTR flow needs the server to declare what input it wants. Two builder
classes encapsulate this without exposing raw JSON:

| Class | Implements | Purpose |
| --- | --- | --- |
| `zcl_mcp2_input_elicitation` | `zif_mcp2_input_request` | Elicitation form or URL |
| `zcl_mcp2_input_sampling` | `zif_mcp2_input_request` | `sampling/createMessage` payload |

`zif_mcp2_input_request` exposes two methods: `get_method()` (the JSON-RPC method the client
must call) and `get_params()` (the JSON params). Both
`zcl_mcp2_resp_input_req->add_request( request_key, input )` and the static
`zcl_mcp2_tasks=>request_input( task_id, request_key, input )` accept any implementor, so adding
a future input type never touches those callers.

```abap
" fluent sampling builder
DATA(sampling) = NEW zcl_mcp2_input_sampling( )->set_max_tokens( 256
                   )->add_user_text( `Summarise this:` )->add_user_text( document_text ).
IF can_request_input( sampling ) = abap_true.
  result = input_required( request_key   = `summarise`
                           input         = sampling
                           request_state = `sampling-4711` ).
ENDIF.
```

`set_form` accepts only `zcl_mcp2_elicit_schema` — a flat builder covering the spec's
`PrimitiveSchemaDefinition` set (string with `title`/`format`/`default`/length bounds,
number/integer with bounds, boolean, single- and multi-select enums with optional display
titles). Nesting and `x-mcp-header` are unrepresentable, so a tool input schema can never be
reused as a `requestedSchema` by accident.

```abap
DATA(form) = NEW zcl_mcp2_elicit_schema(
  )->add_string( name = `email` format = zif_mcp2_const=>elicit_formats-email required = abap_true
  )->add_single_select_titled(
       name    = `env`
       options = VALUE #( ( value = `dev` title = `Development` )
                          ( value = `prod` title = `Production` ) ) ).
elicitation->set_form( message = `Where to?` requested_schema = form ).
```

## Era gating (one data-type set, two eras)

There is **one** set of data classes, modeled on `2025-11-25`. Era differences are handled by
emitting modern-only fields conditionally, driven by the era resolved in `zcl_mcp2_version` and
passed into the dispatcher:

| Field group | Legacy era | Modern era |
| --- | --- | --- |
| `resultType` | omitted | stamped on every modern result (`complete` / `input_required` / `task`) |
| `ttlMs`, `cacheScope` | omitted | always present where the result is cacheable |
| `_meta` passthrough | as received | as received |
| modern-only result fields | omitted | present |

Older clients ignore fields they do not understand, so emitting the `2025-11-25` shape to a
`2025-03-26` client is safe. The dispatcher applies the modern envelope stamp only for the modern
era, so handlers never branch on era for the envelope.

## Optional-vs-absent

Prefer **omitting** a key over emitting an empty/false value when the spec treats them
differently. Guard each optional `set( )` with an `IS NOT INITIAL` / `has_*` check. Where the
spec needs an explicit `false` that differs from "absent" (e.g. some tool annotation hints),
model the field with a tri-state (`has_x` + `x`) rather than relying on the initial value — but
keep that logic inside the owning class.

## Testing

Each data class ships a local test class (`ltcl_*`) that:

- for requests: parses representative JSON and asserts the getters,
- for results: builds the object via setters, calls `to_json`/`stringify`, and asserts the exact
  JSON (the pin that guards the per-field paths),
- covers both eras where the field set differs.
