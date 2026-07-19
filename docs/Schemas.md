# Schemas

The SDK provides typed builders for the JSON Schema shapes most ABAP servers need, plus a
small validator for tool input. The validator is not a full JSON Schema 2020-12 engine.

| Class | Builds | Used for |
| --- | --- | --- |
| `zcl_mcp2_schema_builder` | Common JSON Schema object shapes (nested objects/arrays) | Tool `inputSchema` / `outputSchema` |
| `zcl_mcp2_schema_builder_ddic` | JSON Schema derived from a DDIC structure | Tool schemas from existing types |
| `zcl_mcp2_elicit_schema` | Flat elicitation form schema (spec `PrimitiveSchemaDefinition`) | `requestedSchema` in [elicitation](InputRequired.md) |
| `zcl_mcp2_schema_validator` | — | Validating instances against a schema |

## Tool schemas — `zcl_mcp2_schema_builder`

All `add_*` methods return the builder for chaining:

```abap
DATA(schema) = NEW zcl_mcp2_schema_builder(
    )->add_string(  name = `customer` title = `Customer` description = `Customer id`
                    required = abap_true x_mcp_header = `Customer`
    )->add_integer( name = `quantity` minimum = 1 maximum = 100 default = 1
    )->add_boolean( name = `express` default = abap_false
    )->add_number(  name = `discount` minimum = '0.0' maximum = '0.5' ).

" Nested structures
schema->begin_object( name = `address` required = abap_true
    )->add_string( name = `city` required = abap_true
    )->add_string( name = `zip`
    )->end_object( ).

schema->begin_array( name = `tags` )->add_string( name = `tag` )->end_array( ).

DATA(json) = schema->to_json( ).
```

- Every `add_*`, `begin_object` and `begin_array` takes an optional `title` — a display
  label clients render instead of the raw property name.
- The scalar methods take an optional `default`. It is emitted whenever supplied, including
  `0`, `abap_false` and the empty string; omit the parameter to leave the key out entirely.
- `add_string` also takes `enum`, `min_length` / `max_length`, and an ABAP POSIX
  `pattern`. Patterns are matched against the complete string. `enum` is string-only.
- **Arrays of primitives**: `add_string_array`, `add_integer_array`, `add_number_array` and
  `add_boolean_array` model homogeneous arrays of scalar values, with optional
  `min_items` / `max_items` (and `item_pattern` for strings). `begin_array` continues to
  model arrays of objects.
- Objects accept `additional_properties = abap_false` in the constructor,
  `begin_object`, and `begin_array`. Objects remain open by default for compatibility.
- `x_mcp_header` annotates a string/integer/boolean property for modern
  [header mirroring](Tools.md#header-mirroring-modern-era). Nested object properties are
  supported; arrays and composition keywords are not mirrorable.

## DDIC-derived schemas — `zcl_mcp2_schema_builder_ddic`

Derive the schema from an existing dictionary structure — field names lowercase, DDIC
texts as descriptions, lengths as constraints:

```abap
DATA(schema) = NEW zcl_mcp2_schema_builder_ddic(
    structure_name = `ZMY_ORDER_INPUT`
    )->to_json( ).
```

Per-field `overrides` refine names, descriptions, and required flags where the dictionary
defaults don't fit. Pairs naturally with `bind_arguments`, which maps the call arguments
back onto the same structure.

```abap
DATA(overrides) = VALUE zcl_mcp2_schema_builder_ddic=>field_overrides(
  ( field_path = `vbeln`       name = `order_number`
    description = `Ten-digit sales order number` required = abap_true )
  ( field_path = `partner.name1` name = `customer_name` ) ).

DATA(schema) = NEW zcl_mcp2_schema_builder_ddic(
    structure_name = `ZMY_ORDER_INPUT`
    overrides      = overrides
    )->to_json( ).
```

`field_path` uses lowercase JSON property paths joined with `.` for nested structures. If you
rename a parent property, child paths use that renamed parent. A leaf-only path such as `name1`
also acts as a fallback match, but a full path avoids ambiguity. Domain fixed values become string
enums, and date/time/numeric-text fields retain their ABAP wire representation with a format hint
and a pattern constraint. Set `required_is_set = abap_true` when explicitly making a
normally-required field optional. DDIC table types currently produce an array of string items; model complex
table rows explicitly with the general builder.

## Elicitation form schemas — `zcl_mcp2_elicit_schema`

Elicitation requests use a deliberately restricted, **flat** schema vocabulary that
clients can render as a form. Never reuse a tool input schema here — build a dedicated
form:

```abap
DATA(form) = NEW zcl_mcp2_elicit_schema(
    )->add_string(  name = `reason` title = `Reason` required = abap_true
                    format = zif_mcp2_const=>elicit_formats-email
    )->add_integer( name = `amount` minimum = 1 default = 1
    )->add_number(  name = `budget` minimum = '0.0'
    )->add_boolean( name = `urgent` default = abap_false
    )->add_single_select(  name = `plant` values = VALUE #( ( `1000` ) ( `2000` ) )
    )->add_multi_select(   name = `channels`
                           values = VALUE #( ( `mail` ) ( `sms` ) ) ).
```

- String `format`: `date`, `date-time`, `email`, `uri` (`zif_mcp2_const=>elicit_formats`).
- `add_single_select_titled` / `add_multi_select_titled` take value+title pairs and emit
  the titled spec variants (`oneOf` const/title, `items.anyOf`).
- Defaults, `minimum`/`maximum`, `min_items`/`max_items` are emitted whenever supplied —
  including 0/false.

## <a name="validator"></a>Validation — `zcl_mcp2_schema_validator`

Validates an ajson instance against the supported subset of schemas built with the general
builder. Supports `type`, `required`, `enum`, ABAP POSIX `pattern`, boolean
`additionalProperties`, `minLength`/`maxLength`, `minimum`/`maximum`, homogeneous primitive
array items, and nested objects/arrays.

```abap
DATA(validator) = NEW zcl_mcp2_schema_validator( schema ).
IF validator->validate( instance ) = abap_false.
  DATA(errors) = validator->get_errors( ).   " table of path + message strings
ENDIF.

" One-liner that raises -32602 with all messages joined:
zcl_mcp2_schema_validator=>validate_or_raise( schema = schema json = instance ).
```

The catalog base enables [tool input validation](Tools.md#input-validation) by default. Both
dispatchers use the same validator and convert advertised-schema failures to `isError` tool
results, so handlers behind them can trust the argument shapes.

This is an ABAP-oriented schema profile rather than a standards-complete validator. Regex
syntax follows the ABAP runtime and not JSON Schema's ECMAScript dialect. The validator
intentionally does not implement JSON Schema dialect negotiation, `$schema`,
`$ref`, composition keywords (`oneOf`, `anyOf`, `allOf`), or the full 2020-12 vocabulary. If a
server advertises schemas using those features, validate them in the handler or a dedicated
validator before trusting the input.
