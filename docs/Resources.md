# Resources

Resources expose readable content — files, database records, generated documents — that
clients can list and fetch. Enable them with `supports_resources` returning `abap_true`
and redefine up to three handlers:

| Method | Purpose |
| --- | --- |
| `resources_list` | Advertise concrete resources |
| `resources_read` | Return the contents of one URI |
| `resources_tmpls_list` | Advertise URI templates (RFC 6570) for parameterized resources |

## Listing — `resources_list`

```abap
METHOD zif_mcp2_server~resources_list.
  DATA(response) = NEW zcl_mcp2_resp_list_resources( ).
  response->add_resource( VALUE #( uri         = `mcp2://orders/4500001234`
                                   name        = `order-4500001234`
                                   title       = `Sales Order 4500001234`
                                   description = `Order header and items`
                                   mime_type   = `application/json`
                                   icons       = VALUE #( ( src = `https://example.com/doc.png` ) ) ) ).
  result = response.
ENDMETHOD.
```

Pagination and modern cache hints work exactly as for tools: `set_next_cursor( )`,
`set_cache( )`, and `request->has_cursor( )` / `get_cursor( )` on the request.

## Reading — `resources_read`

```abap
METHOD zif_mcp2_server~resources_read.
  CASE request->get_uri( ).
    WHEN `mcp2://orders/4500001234`.
      DATA(response) = NEW zcl_mcp2_resp_read_resource( ).
      response->add_text_content( uri       = request->get_uri( )
                                  text      = `{"order":"4500001234","items":3}`
                                  mime_type = `application/json` ).
      result = response.
    WHEN OTHERS.
      zcx_mcp2_error=>raise_resource_not_found( request->get_uri( ) ).
  ENDCASE.
ENDMETHOD.
```

- Answer unknown URIs with `zcx_mcp2_error=>raise_resource_not_found( uri )`. The dispatcher
  preserves legacy `-32002 ResourceNotFound` and maps the same era-neutral handler signal to
  modern `-32602`; both carry the URI in `error.data.uri`.
- `add_text_content( uri, text, mime_type )` — text contents
- `add_blob_content( uri, blob, mime_type )` — base64 binary contents
- A read result may carry multiple contents entries (e.g. a directory URI returning
  several files).

## Templates — `resources_tmpls_list`

Templates advertise URI patterns the client can expand itself:

```abap
response->add_template( VALUE #( uri_template = `mcp2://orders/{number}`
                                 name         = `order-by-number`
                                 title        = `Sales order by number`
                                 mime_type    = `application/json` ) ).
```

The expanded URI arrives at `resources_read` like any other; parse it there. Pair
templates with [Completions](Completions.md) to autocomplete the `{number}` argument.

## Interactive reads (modern era)

`resources_read` may return an inputRequired result when a read needs consent or another client
action. Its request has the same `is_retry`, `get_request_state`, `has_input_responses`,
`get_input_response` and `try_get_input_response` helpers as a tool call. Gate the first response
with `can_request_input( )`; the complete two-round-trip pattern is in
[Input required](InputRequired.md). Do not use elicitation as a substitute for an ABAP
authorization check.

## What is not supported

`resources/subscribe` / `unsubscribe` and `notifications/resources/*` need a server→client
channel that a stateless server does not have. The capability is advertised as
`resources: {}` (no `subscribe`), so conforming clients will not attempt it; calls answer
`method_not_found`.
