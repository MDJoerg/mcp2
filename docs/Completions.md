# Completions

`completion/complete` autocompletes prompt arguments and resource-template variables while
the user types. Enable with `supports_completions` returning `abap_true` and redefine
`completions_complete`.

## Request

`zcl_mcp2_req_complete` tells you what is being completed:

- `get_ref_type( )` — `ref/prompt` or `ref/resource` (constants in
  `zcl_mcp2_req_complete=>ref_type`)
- `get_ref_name( )` — prompt name (for `ref/prompt`)
- `get_ref_uri( )` — resource template URI (for `ref/resource`)
- `get_argument_name( )` / `get_argument_value( )` — the argument being typed and its
  current partial value
- `has_context( )` / `get_context_json( )` — previously-resolved arguments
  (`2025-06-18`+), so completions can depend on other fields

## Response

```abap
METHOD zif_mcp2_server~completions_complete.
  DATA(response) = NEW zcl_mcp2_resp_complete( ).

  IF     request->get_ref_type( )      = zcl_mcp2_req_complete=>ref_type-prompt
     AND request->get_ref_name( )      = `explain_order`
     AND request->get_argument_name( ) = `number`.

    SELECT vbeln FROM vbak
      WHERE vbeln LIKE @( |{ request->get_argument_value( ) }%| )
      ORDER BY vbeln
      INTO TABLE @DATA(orders)
      UP TO 10 ROWS.
    LOOP AT orders INTO DATA(order).
      response->add_value( CONV string( order ) ).
    ENDLOOP.
    response->set_total( lines( orders ) ).
    response->set_has_more( abap_false ).
  ENDIF.

  result = response.
ENDMETHOD.
```

- `add_value( )` appends one suggestion (spec caps the list at 100);
  `set_values( )` replaces the whole list.
- `set_total( )` — total number of matches (may exceed what you return).
- `set_has_more( )` — whether more matches exist beyond the returned page.

An empty response (no values) is a valid "no suggestions" answer.

## Return whole values, never the typed text plus a suffix

The client **replaces** the argument with the value it receives; it does not append to what the
user typed. So each value must be the complete argument, and `get_argument_value( )` is a *filter*
input, not a prefix to build on:

```abap
" WRONG - typing "A" then yields "AAda"
response->add_value( |{ request->get_argument_value( ) }Ada| ).

" RIGHT - offer the whole candidate, filtered by what was typed
IF to_upper( candidate ) CP |{ to_upper( request->get_argument_value( ) ) }*|.
  response->add_value( candidate ).
ENDIF.
```

The SQL example above already does this correctly: `LIKE '{value}%'` selects whole `vbeln` values
that begin with the typed text. `ZCL_MCP2_DEMO_BASIC.completions_complete` shows the same rule
against an in-memory candidate list, including the empty-prefix case (offer everything) and the
no-match case (return nothing rather than inventing a value).
