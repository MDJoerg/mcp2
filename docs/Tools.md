# Tools

Tools are functions that MCP clients (and the models behind them) call on your server.
For tool-focused servers, inherit from `zcl_mcp2_tool_server_base` and implement two protected
methods:

| Method | Purpose |
| --- | --- |
| `define_tools` | Declare names, descriptions, schemas, icons, annotations and task support once |
| `call_tool` | Execute one declared tool call and return content |

The base derives `supports_tools`, `tools_list`, `get_tool_schema`, and default input validation
from the catalog. Calls for undeclared tool names are rejected before `call_tool` runs.

## Declaring tools — `define_tools`

```abap
METHOD define_tools.
  result = VALUE #( (
      name          = `create_order`
      title         = `Create Order`
      description   = `Creates a sales order and returns its number.`
      input_schema  = build_order_schema( )
      output_schema = build_order_result_schema( )
      icons         = VALUE #( ( src = `https://example.com/order.png` mime_type = `image/png` ) )
      annotations   = VALUE #( read_only_hint = abap_false
                               destructive_hint = abap_false destructive_hint_set = abap_true
                               idempotent_hint = abap_true ) ) ).
ENDMETHOD.
```

- `input_schema` / `output_schema` are ajson documents — build them with the
  [schema builders](Schemas.md); when `input_schema` is omitted the SDK emits the open
  object schema `{"type":"object"}`.
- **Annotations** are behavior hints. `destructiveHint` and `openWorldHint` default to
  *true* in the spec, so an explicit `false` needs the paired `*_set = abap_true` flag.
- **Pagination**: call `set_next_cursor( 'my-cursor' )` on the response; the cursor comes
  back on the next request via `request->has_cursor( )` / `get_cursor( )`. Reject unknown
  cursors with `zcx_mcp2_error=>raise_invalid_params( )`.
- **Caching (modern era)**: `set_cache( ttl_ms = 60000 cache_scope = zif_mcp2_const=>cache_scopes-public )`
  is available when you implement `tools_list` directly on `zcl_mcp2_server_base`. The catalog
  base intentionally uses the default no-cache list response.

## Handling calls — `call_tool`

`zcl_mcp2_req_call_tool` gives you typed access to the arguments:

```abap
METHOD call_tool.
  CASE request->get_name( ).
    WHEN `create_order`.
      " Individual typed getters ...
      DATA(customer) = request->require_arg_string( `customer` ).
      DATA(quantity) = request->require_arg_integer( `quantity` ).
      DATA(express)  = request->get_arg_boolean_or( name = `express` default_value = abap_false ).

      " ... or bind the whole argument object onto an ABAP structure
      DATA: BEGIN OF order_args,
              customer TYPE string,
              quantity TYPE i,
              express  TYPE abap_bool,
            END OF order_args.
      request->bind_arguments( CHANGING target = order_args ).

      result = zcl_mcp2_resp_call_tool=>text( |Order created for { customer }.| ).

    WHEN OTHERS.
      " Not reached for undeclared names when using zcl_mcp2_tool_server_base.
      zcx_mcp2_error=>raise_invalid_params( |Unknown tool: { request->get_name( ) }| ).
  ENDCASE.
ENDMETHOD.
```

Tool names appear in both `define_tools` and `call_tool` — keep them in a shared private
constants block (`CONSTANTS: BEGIN OF tool_names, …`) so the catalog and the dispatch cannot
drift apart. The demo servers model this pattern.

For optional arguments, the null-safe `get_arg_string/integer/number/boolean` methods return ABAP
initial values when absent, while `get_arg_string_or/integer_or/number_or/boolean_or` let you
supply an explicit fallback. For required arguments, use
`require_arg_string/integer/number/boolean`; absent values raise `-32602 InvalidParams`.
`has_arg( name )` distinguishes "absent" from "initial".

`get_arg_number` returns `decfloat34` and converts from the raw JSON literal, so decimals are
not rounded through a binary float — use it for prices, rates and quantities rather than reading
a float. It reads JSON **number** nodes only: a numeric string like `"12.75"` yields 0 rather
than being coerced, because a declared schema would have rejected it as the wrong type.

Arrays of primitives have matching readers: `get_arg_string_table`, `get_arg_integer_table`,
`get_arg_number_table` and `get_arg_boolean_table`. Each returns an empty table when the
argument is absent or is not an array, and an element of the wrong JSON type contributes the
ABAP initial value rather than raising. For arrays of objects use `get_arg_json( name )`, which
returns one raw argument node, or `bind_arguments`. `has_arguments( )` / `get_arguments( )`
expose the whole raw ajson object when you need it.

## Content blocks

For common results, use the static factories:

```abap
result = zcl_mcp2_resp_call_tool=>text( `plain text` ).
result = zcl_mcp2_resp_call_tool=>error_text( `Customer 4711 does not exist.` ).

DATA: BEGIN OF order_result,
        order_number TYPE string,
        items        TYPE i,
      END OF order_result.
order_result-order_number = `4500001234`.
order_result-items        = 3.

result = zcl_mcp2_resp_call_tool=>structured_data( order_result ).
```

For multi-block responses, annotations, and resource links, create an instance and append the
blocks you need. `zcl_mcp2_resp_call_tool` builds every spec `ContentBlock` kind without raw
JSON:

```abap
response->add_text( text = `plain text`
                    annotations = VALUE #( audience_user = abap_true
                                           priority = '0.8' priority_set = abap_true ) ).
response->add_image( data = base64_png  mime_type = `image/png` ).
response->add_audio( data = base64_wav  mime_type = `audio/wav` ).

" Embedded resource - non-initial blob selects the binary variant
response->add_resource( resource = VALUE #( uri = `mcp2://files/note.txt`
                                            text = `inline content`
                                            mime_type = `text/plain` ) ).

" Resource link - a pointer the client may resources/read later
response->add_resource_link( VALUE #( uri  = `mcp2://files/report.pdf`
                                      name = `report.pdf`
                                      mime_type = `application/pdf`
                                      size = 1024  size_set = abap_true ) ).
```

Annotations (`zif_mcp2_content=>annotations`) carry audience flags, a `priority`
(0..1 — set `priority_set` because 0 is meaningful) and `last_modified`. Resource links
also take `icons`.

## Errors: `isError` vs protocol errors

Business failures the model should see and self-correct belong **inside** the result:

```abap
result = zcl_mcp2_resp_call_tool=>error_text( `Customer 4711 does not exist.` ).
```

Protocol-level failures such as an unknown tool are exceptions:
`zcx_mcp2_error=>raise_invalid_params( )`. When you use `zcl_mcp2_tool_server_base`, unknown
tool names are handled by the base. Invalid tool arguments that the model can self-correct
should be returned as `isError = true`.

## Structured output

Declare an `output_schema` in `tools_list` and return typed data:

```abap
DATA: BEGIN OF order_result,
        order_number TYPE string,
        items        TYPE i,
      END OF order_result.
order_result-order_number = `4500001234`.
order_result-items        = 3.

result = zcl_mcp2_resp_call_tool=>structured_data( order_result ).  " lowercase JSON field names
```

`structured_data` / `set_structured_data` serialize any ABAP structure via ajson and
(optionally) mirror a text block for older clients; `structured_json` /
`set_structured_content` take a prebuilt ajson document.
When you advertise an `output_schema`, the structured content you return must conform to it;
the SDK does not validate output schemas for you.

## Input validation

`zcl_mcp2_tool_server_base` enables framework validation by default. The dispatcher checks
`tools/call` arguments against the declared `input_schema` **before** your handler runs. In
both eras, schema violations become an `isError` tool result. Structurally malformed calls remain
`-32602`.

```abap
METHODS tool_input_validation_enabled REDEFINITION.
...
METHOD tool_input_validation_enabled.
  result = abap_false.
ENDMETHOD.
```

Redefine this only when handlers deliberately validate themselves. Tools without a schema are
not validated. See [Schemas](Schemas.md#validator) for what the validator enforces.

`tool_input_validation_enabled` is the override for `zcl_mcp2_tool_server_base` (it feeds the
base's `validate_tool_input`). A server built directly on `zcl_mcp2_server_base` instead
redefines `validate_tool_input` itself and supplies `get_tool_schema`.

## Header mirroring (modern era)

String/integer/boolean schema properties may declare an `x-mcp-header` annotation (via the
schema builder's `x_mcp_header` parameter). The property may be top-level or nested through
object `properties`; arrays and composition keywords are not mirrorable. Modern clients then
mirror the argument value into an `Mcp-Param-{Name}` HTTP header, and the dispatcher verifies
header and body match before your handler runs (mismatch → `-32020`, HTTP 400). This lets edge
infrastructure route/inspect calls without parsing JSON bodies. With `zcl_mcp2_tool_server_base`,
the schema comes from `define_tools`.

Header names must be case-insensitively unique per tool — reference clients exclude tools
with conflicting declarations from `tools/list`.

## Long-running work

Return a task instead of a result — see [Tasks](Tasks.md). Gate with the era-aware
`client_supports_tasks( )` and advertise per-tool task capability via the `task_support`
field of the catalog entry (`zif_mcp2_const=>task_support-optional` / `required` / `forbidden`,
emitted as the legacy `execution.taskSupport`). When the tool needs to ask
the user something first, return an inputRequired result — see
[Input required](InputRequired.md).
