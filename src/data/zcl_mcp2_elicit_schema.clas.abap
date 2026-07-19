"! <p class="shorttext synchronized">MCP2 elicitation form schema builder</p>
"! Fluent builder for the requestedSchema of a form-mode elicitation. The
"! spec restricts these schemas to a flat object of primitive properties
"! (PrimitiveSchemaDefinition) - this builder makes non-flat schemas
"! unrepresentable, unlike the general zcl_mcp2_schema_builder, which allows
"! nesting and x-mcp-header annotations that are invalid here.
"! All mutating methods return self for chaining; feed the builder into
"! zcl_mcp2_input_elicitation->set_form.
CLASS zcl_mcp2_elicit_schema DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES enum_values TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    " One selectable option with a display label (TitledSelect variants).
    TYPES: BEGIN OF enum_option,
             value TYPE string,
             title TYPE string,
           END OF enum_option.
    TYPES enum_options TYPE STANDARD TABLE OF enum_option WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Create an empty flat object schema</p>
    "! @raising zcx_mcp2_ajson_error | JSON init failure
    METHODS constructor
      RAISING zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a free-text property (StringSchema)</p>
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter format               | date / date-time / email / uri (zif_mcp2_const=>elicit_formats)
    "! @parameter default              | Prefilled value
    "! @parameter min_length           | Minimum length when supplied
    "! @parameter max_length           | Maximum length when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_string
      IMPORTING !name        TYPE string
                !title       TYPE string    OPTIONAL
                !description TYPE string    OPTIONAL
                !format      TYPE string    OPTIONAL
                !default     TYPE string    OPTIONAL
                min_length   TYPE i         OPTIONAL
                max_length   TYPE i         OPTIONAL
                !required    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a decimal-number property (NumberSchema)</p>
    "! minimum / maximum / default are emitted when supplied (0 included).
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter minimum              | Lower bound when supplied
    "! @parameter maximum              | Upper bound when supplied
    "! @parameter default              | Prefilled value when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_number
      IMPORTING !name        TYPE string
                !title       TYPE string    OPTIONAL
                !description TYPE string    OPTIONAL
                !minimum     TYPE f         OPTIONAL
                !maximum     TYPE f         OPTIONAL
                !default     TYPE f         OPTIONAL
                !required    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add an integer property (NumberSchema)</p>
    "! minimum / maximum / default are emitted when supplied (0 included).
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter minimum              | Lower bound when supplied
    "! @parameter maximum              | Upper bound when supplied
    "! @parameter default              | Prefilled value when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_integer
      IMPORTING !name        TYPE string
                !title       TYPE string    OPTIONAL
                !description TYPE string    OPTIONAL
                !minimum     TYPE i         OPTIONAL
                !maximum     TYPE i         OPTIONAL
                !default     TYPE i         OPTIONAL
                !required    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a yes/no property (BooleanSchema)</p>
    "! default is emitted when supplied (abap_false included).
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter default              | Preselected value when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_boolean
      IMPORTING !name        TYPE string
                !title       TYPE string    OPTIONAL
                !description TYPE string    OPTIONAL
                !default     TYPE abap_bool OPTIONAL
                !required    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a single-select choice</p>
    "! Spec UntitledSingleSelectEnumSchema.
    "! @parameter name                 | Property name
    "! @parameter values               | Selectable values
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter default              | Preselected value
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_single_select
      IMPORTING !name        TYPE string
                !values      TYPE enum_values
                !title       TYPE string    OPTIONAL
                !description TYPE string    OPTIONAL
                !default     TYPE string    OPTIONAL
                !required    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a titled single-select choice</p>
    "! Display labels per option (spec TitledSingleSelectEnumSchema, oneOf const/title pairs).
    "! @parameter name                 | Property name
    "! @parameter options              | value + display title per option
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter default              | Preselected value
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_single_select_titled
      IMPORTING !name        TYPE string
                !options     TYPE enum_options
                !title       TYPE string    OPTIONAL
                !description TYPE string    OPTIONAL
                !default     TYPE string    OPTIONAL
                !required    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a multi-select choice</p>
    "! Spec UntitledMultiSelectEnumSchema. min_items / max_items are emitted when supplied.
    "! @parameter name                 | Property name
    "! @parameter values               | Selectable values
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter defaults             | Preselected values
    "! @parameter min_items            | Minimum selections when supplied
    "! @parameter max_items            | Maximum selections when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_multi_select
      IMPORTING !name        TYPE string
                !values      TYPE enum_values
                !title       TYPE string      OPTIONAL
                !description TYPE string      OPTIONAL
                defaults     TYPE enum_values OPTIONAL
                min_items    TYPE i           OPTIONAL
                max_items    TYPE i           OPTIONAL
                !required    TYPE abap_bool   DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a titled multi-select choice</p>
    "! Display labels per option (spec TitledMultiSelectEnumSchema, items.anyOf const/title pairs).
    "! @parameter name                 | Property name
    "! @parameter options              | value + display title per option
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter defaults             | Preselected values
    "! @parameter min_items            | Minimum selections when supplied
    "! @parameter max_items            | Maximum selections when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_multi_select_titled
      IMPORTING !name        TYPE string
                !options     TYPE enum_options
                !title       TYPE string      OPTIONAL
                !description TYPE string      OPTIONAL
                defaults     TYPE enum_values OPTIONAL
                min_items    TYPE i           OPTIONAL
                max_items    TYPE i           OPTIONAL
                !required    TYPE abap_bool   DEFAULT abap_false
      RETURNING VALUE(self)  TYPE REF TO zcl_mcp2_elicit_schema
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Finalize and return the flat schema object</p>
    "! @parameter result               | {"type":"object","properties":{...},"required":[...]}
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS to_json
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA schema         TYPE REF TO zif_mcp2_ajson.
    DATA required_props TYPE string_table.

    "! <p class="shorttext synchronized">Write the common property head</p>
    "! Emits type/title/description and tracks the required flag.
    "! @parameter name                 | Property name
    "! @parameter json_type            | JSON schema type (string/number/...)
    "! @parameter title                | Display title
    "! @parameter description          | Explanation shown to the user
    "! @parameter required             | Add to the schema's required list
    "! @parameter result               | Base path of the new property node
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_property
      IMPORTING !name       TYPE string
                json_type   TYPE string
                title       TYPE string
                description TYPE string
                required    TYPE abap_bool
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_elicit_schema IMPLEMENTATION.
  METHOD constructor.
    " parse (not create_empty + set) so /properties exists as an empty object
    " node even when no field is ever added - grafting an empty ajson via
    " set( ) produces no node at all.
    schema = zcl_mcp2_ajson=>parse( '{"type":"object","properties":{}}' ).
  ENDMETHOD.

  METHOD add_property.
    result = |/properties/{ name }|.
    schema->set_string( iv_path = |{ result }/type|
                        iv_val  = json_type ).
    IF title IS NOT INITIAL.
      schema->set_string( iv_path = |{ result }/title|
                          iv_val  = title ).
    ENDIF.
    IF description IS NOT INITIAL.
      schema->set_string( iv_path = |{ result }/description|
                          iv_val  = description ).
    ENDIF.
    IF required = abap_true.
      APPEND name TO required_props.
    ENDIF.
  ENDMETHOD.

  METHOD add_string.
    DATA(p) = add_property( name        = name
                            json_type   = `string`
                            title       = title
                            description = description
                            required    = required ).
    IF format IS NOT INITIAL.
      schema->set_string( iv_path = |{ p }/format|
                          iv_val  = format ).
    ENDIF.
    IF default IS SUPPLIED.
      schema->set_string( iv_path = |{ p }/default|
                          iv_val  = default ).
    ENDIF.
    IF min_length IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/minLength|
                           iv_val  = min_length ).
    ENDIF.
    IF max_length IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/maxLength|
                           iv_val  = max_length ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_number.
    DATA(p) = add_property( name        = name
                            json_type   = `number`
                            title       = title
                            description = description
                            required    = required ).
    IF minimum IS SUPPLIED.
      schema->set( iv_path         = |{ p }/minimum|
                   iv_val          = minimum
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF maximum IS SUPPLIED.
      schema->set( iv_path         = |{ p }/maximum|
                   iv_val          = maximum
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF default IS SUPPLIED.
      schema->set( iv_path         = |{ p }/default|
                   iv_val          = default
                   iv_ignore_empty = abap_false ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_integer.
    DATA(p) = add_property( name        = name
                            json_type   = `integer`
                            title       = title
                            description = description
                            required    = required ).
    IF minimum IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/minimum|
                           iv_val  = minimum ).
    ENDIF.
    IF maximum IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/maximum|
                           iv_val  = maximum ).
    ENDIF.
    IF default IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/default|
                           iv_val  = default ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_boolean.
    DATA(p) = add_property( name        = name
                            json_type   = `boolean`
                            title       = title
                            description = description
                            required    = required ).
    IF default IS SUPPLIED.
      schema->set( iv_path         = |{ p }/default|
                   iv_val          = default
                   iv_ignore_empty = abap_false ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_single_select.
    DATA(p) = add_property( name        = name
                            json_type   = `string`
                            title       = title
                            description = description
                            required    = required ).
    schema->touch_array( |{ p }/enum| ).
    LOOP AT values INTO DATA(value).
      schema->set_string( iv_path = |{ p }/enum/{ sy-tabix }|
                          iv_val  = value ).
    ENDLOOP.
    IF default IS SUPPLIED.
      schema->set_string( iv_path = |{ p }/default|
                          iv_val  = default ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_single_select_titled.
    DATA(p) = add_property( name        = name
                            json_type   = `string`
                            title       = title
                            description = description
                            required    = required ).
    schema->touch_array( |{ p }/oneOf| ).
    LOOP AT options INTO DATA(option).
      DATA(op) = |{ p }/oneOf/{ sy-tabix }|.
      schema->set_string( iv_path = |{ op }/const|
                          iv_val  = option-value ).
      schema->set_string( iv_path = |{ op }/title|
                          iv_val  = option-title ).
    ENDLOOP.
    IF default IS SUPPLIED.
      schema->set_string( iv_path = |{ p }/default|
                          iv_val  = default ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_multi_select.
    DATA(p) = add_property( name        = name
                            json_type   = `array`
                            title       = title
                            description = description
                            required    = required ).
    schema->set_string( iv_path = |{ p }/items/type|
                        iv_val  = `string` ).
    schema->touch_array( |{ p }/items/enum| ).
    LOOP AT values INTO DATA(value).
      schema->set_string( iv_path = |{ p }/items/enum/{ sy-tabix }|
                          iv_val  = value ).
    ENDLOOP.
    IF defaults IS NOT INITIAL.
      schema->touch_array( |{ p }/default| ).
      LOOP AT defaults INTO DATA(default_value).
        schema->set_string( iv_path = |{ p }/default/{ sy-tabix }|
                            iv_val  = default_value ).
      ENDLOOP.
    ENDIF.
    IF min_items IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/minItems|
                           iv_val  = min_items ).
    ENDIF.
    IF max_items IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/maxItems|
                           iv_val  = max_items ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD add_multi_select_titled.
    DATA(p) = add_property( name        = name
                            json_type   = `array`
                            title       = title
                            description = description
                            required    = required ).
    schema->touch_array( |{ p }/items/anyOf| ).
    LOOP AT options INTO DATA(option).
      DATA(op) = |{ p }/items/anyOf/{ sy-tabix }|.
      schema->set_string( iv_path = |{ op }/const|
                          iv_val  = option-value ).
      schema->set_string( iv_path = |{ op }/title|
                          iv_val  = option-title ).
    ENDLOOP.
    IF defaults IS NOT INITIAL.
      schema->touch_array( |{ p }/default| ).
      LOOP AT defaults INTO DATA(default_value).
        schema->set_string( iv_path = |{ p }/default/{ sy-tabix }|
                            iv_val  = default_value ).
      ENDLOOP.
    ENDIF.
    IF min_items IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/minItems|
                           iv_val  = min_items ).
    ENDIF.
    IF max_items IS SUPPLIED.
      schema->set_integer( iv_path = |{ p }/maxItems|
                           iv_val  = max_items ).
    ENDIF.
    self = me.
  ENDMETHOD.

  METHOD to_json.
    IF required_props IS NOT INITIAL.
      schema->set( iv_path = '/required'
                   iv_val  = required_props ).
    ENDIF.
    result = schema.
  ENDMETHOD.
ENDCLASS.
