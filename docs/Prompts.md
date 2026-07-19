# Prompts

Prompts are reusable message templates the user picks in the client UI (often as slash
commands). Enable them with `supports_prompts` returning `abap_true` and redefine:

| Method | Purpose |
| --- | --- |
| `prompts_list` | Advertise prompts and their argument definitions |
| `prompts_get` | Expand one prompt into concrete messages |

## Listing — `prompts_list`

```abap
METHOD zif_mcp2_server~prompts_list.
  DATA(response) = NEW zcl_mcp2_resp_list_prompts( ).
  response->add_prompt( VALUE #(
      name        = `explain_order`
      title       = `Explain Order`
      description = `Explains a sales order in plain language`
      arguments   = VALUE #(
          ( name = `number` description = `Order number` required = abap_true )
          ( name = `style`  description = `concise or detailed` ) ) ) ).
  result = response.
ENDMETHOD.
```

Prompt entries also take `icons`. Pagination (`set_next_cursor`) and modern cache hints
(`set_cache`) behave as for tools.

## Expanding — `prompts_get`

```abap
METHOD zif_mcp2_server~prompts_get.
  IF request->get_name( ) <> `explain_order`.
    zcx_mcp2_error=>raise_invalid_params( |Unknown prompt: { request->get_name( ) }| ).
  ENDIF.

  DATA(order_number) = request->require_arg_string( `number` ).
  DATA(style) = request->get_arg_string_or( name = `style` default_value = `concise` ).

  DATA(response) = NEW zcl_mcp2_resp_get_prompt( ).
  response->set_description( `Order explanation request` ).
  response->add_user_text( |Explain sales order { order_number } in a { style } style.| ).
  result = response.
ENDMETHOD.
```

- `add_user_text( )` / `add_assistant_text( )` for text messages;
  `add_message( role = ... content = ... )` accepts a prebuilt content node (image,
  embedded resource, …).
- The request offers string argument accessors matching tools: `has_arg( )`,
  `get_arg_string( )`, `get_arg_string_or( )`, `require_arg_string( )`,
  `has_arguments( )` / `get_arguments( )`.
- Argument values are always strings on the wire (spec rule) — convert in the handler.

## Interactive prompts (modern era)

In the modern era `prompts_get` may return an inputRequired result instead of messages —
for example to elicit a missing argument — and complete on the client's retry. The flow,
including the mandatory era/capability gating, is described in
[Input required](InputRequired.md); the MRTR request accessors (`is_retry`,
`get_request_state`, `get_input_response`) exist on the prompt request exactly as on the
tool request.

Pair prompt arguments with [Completions](Completions.md) for autocompletion while the
user types.
