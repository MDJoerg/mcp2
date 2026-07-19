"! <p class="shorttext synchronized">MCP2 JSON Schema builder</p>
"! Fluent builder for JSON Schema objects used as tool input/output schemas.
"! All mutating methods return self for chaining.
"! Nested objects/arrays are opened with begin_object/begin_array and closed
"! with end_object/end_array; the root holds an active_builder pointer so
"! callers can keep calling on any reference and hit the right node.
CLASS zcl_mcp2_schema_builder DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES enum_values TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Create an empty object schema</p>
    "! @raising zcx_mcp2_ajson_error | JSON init failure
    METHODS constructor
      IMPORTING additional_properties TYPE abap_bool DEFAULT abap_true
      RAISING zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a string property</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter enum                 | Allowed values when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_length           | Minimum length when supplied
    "! @parameter max_length           | Maximum length when supplied
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_string
      IMPORTING !name         TYPE string
                !title        TYPE string        OPTIONAL
                description   TYPE string       OPTIONAL
                !enum         TYPE enum_values   OPTIONAL
                !default      TYPE string        OPTIONAL
                required      TYPE abap_bool     DEFAULT abap_false
                min_length    TYPE i             OPTIONAL
                max_length    TYPE i             OPTIONAL
                pattern       TYPE string        OPTIONAL
                x_mcp_header  TYPE string        OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a number (float) property</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter minimum              | Lower bound when supplied
    "! @parameter maximum              | Upper bound when supplied
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_number
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                !default      TYPE f        OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                minimum       TYPE f        OPTIONAL
                maximum       TYPE f        OPTIONAL
                x_mcp_header  TYPE string   OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add an integer property</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter minimum              | Lower bound when supplied
    "! @parameter maximum              | Upper bound when supplied
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_integer
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                !default      TYPE i        OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                minimum       TYPE i        OPTIONAL
                maximum       TYPE i        OPTIONAL
                x_mcp_header  TYPE string   OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add a boolean property</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_boolean
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                !default      TYPE abap_bool OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                x_mcp_header  TYPE string   OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Open a nested object property</p>
    "! Call end_object to close it.
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter self                 | The nested object builder
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS begin_object
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                additional_properties TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Close the current nested object</p>
    "! @parameter self                 | The parent builder
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS end_object
      RETURNING VALUE(self) TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Open an array property</p>
    "! Adds a single object items node. Call end_array to close it.
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum item count when supplied
    "! @parameter max_items            | Maximum item count when supplied
    "! @parameter self                 | The array items builder
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS begin_array
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                min_items     TYPE i        OPTIONAL
                max_items     TYPE i        OPTIONAL
                additional_properties TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add an array of string values</p>
    "! For arrays of objects use begin_array / end_array instead.
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum element count when supplied
    "! @parameter max_items            | Maximum element count when supplied
    "! @parameter item_pattern         | ABAP POSIX pattern each element must match
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_string_array
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                min_items     TYPE i        OPTIONAL
                max_items     TYPE i        OPTIONAL
                item_pattern  TYPE string   OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add an array of integer values</p>
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum element count when supplied
    "! @parameter max_items            | Maximum element count when supplied
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_integer_array
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                min_items     TYPE i        OPTIONAL
                max_items     TYPE i        OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add an array of decimal-number values</p>
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum element count when supplied
    "! @parameter max_items            | Maximum element count when supplied
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_number_array
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                min_items     TYPE i        OPTIONAL
                max_items     TYPE i        OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add an array of boolean values</p>
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum element count when supplied
    "! @parameter max_items            | Maximum element count when supplied
    "! @parameter self                 | This builder, for chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_boolean_array
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool DEFAULT abap_false
                min_items     TYPE i        OPTIONAL
                max_items     TYPE i        OPTIONAL
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Close the current array</p>
    "! @parameter self                 | The parent builder
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS end_array
      RETURNING VALUE(self) TYPE REF TO zcl_mcp2_schema_builder
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Finalize and return the JSON Schema object</p>
    "! @parameter result               | The built JSON Schema
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS to_json
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA schema           TYPE REF TO zcl_mcp2_ajson.
    DATA current_path     TYPE string.
    DATA parent_builder   TYPE REF TO zcl_mcp2_schema_builder.
    DATA node_type        TYPE string.
    DATA root_builder     TYPE REF TO zcl_mcp2_schema_builder.
    DATA active_builder   TYPE REF TO zcl_mcp2_schema_builder.
    DATA required_props   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA property_names   TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Currently active nested builder</p>
    "! Returns self when the root node is the active one.
    "! @parameter result | The active builder
    METHODS get_active_builder
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_schema_builder.

    "! <p class="shorttext synchronized">Properties path for a property name</p>
    "! @parameter name   | Property name
    "! @parameter result | The /properties/... path for the property
    METHODS property_path
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS escape_name
      IMPORTING name TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Write the common property head</p>
    "! Emits type, description and x-mcp-header, and tracks the required flag.
    "! @parameter name                 | Property name
    "! @parameter json_type            | JSON schema type
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_property
      IMPORTING !name         TYPE string
                json_type     TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool
                x_mcp_header  TYPE string   OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Internal add_string with supplied flags</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter enum                 | Allowed values when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_length           | Minimum length when supplied
    "! @parameter max_length           | Maximum length when supplied
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter min_length_sup       | Whether min_length was supplied
    "! @parameter max_length_sup       | Whether max_length was supplied
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS _add_string
      IMPORTING !name           TYPE string
                !title          TYPE string   OPTIONAL
                description     TYPE string   OPTIONAL
                !enum           TYPE enum_values OPTIONAL
                !default        TYPE string   OPTIONAL
                required        TYPE abap_bool
                min_length      TYPE i        OPTIONAL
                max_length      TYPE i        OPTIONAL
                pattern         TYPE string   OPTIONAL
                x_mcp_header    TYPE string   OPTIONAL
                min_length_sup  TYPE abap_bool
                max_length_sup  TYPE abap_bool
                default_sup     TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Internal add_number with supplied flags</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter minimum              | Lower bound when supplied
    "! @parameter maximum              | Upper bound when supplied
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter minimum_sup          | Whether minimum was supplied
    "! @parameter maximum_sup          | Whether maximum was supplied
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS _add_number
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                !default      TYPE f        OPTIONAL
                required      TYPE abap_bool
                minimum       TYPE f        OPTIONAL
                maximum       TYPE f        OPTIONAL
                x_mcp_header  TYPE string   OPTIONAL
                minimum_sup   TYPE abap_bool
                maximum_sup   TYPE abap_bool
                default_sup   TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Internal add_integer with supplied flags</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter minimum              | Lower bound when supplied
    "! @parameter maximum              | Upper bound when supplied
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter minimum_sup          | Whether minimum was supplied
    "! @parameter maximum_sup          | Whether maximum was supplied
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS _add_integer
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                !default      TYPE i        OPTIONAL
                required      TYPE abap_bool
                minimum       TYPE i        OPTIONAL
                maximum       TYPE i        OPTIONAL
                x_mcp_header  TYPE string   OPTIONAL
                minimum_sup   TYPE abap_bool
                maximum_sup   TYPE abap_bool
                default_sup   TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Internal add_boolean with supplied flags</p>
    "! @parameter name                 | Property name
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter default              | Prefilled value when supplied
    "! @parameter required             | Add to the schema's required list
    "! @parameter x_mcp_header         | x-mcp-header annotation value
    "! @parameter default_sup          | Whether default was supplied
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS _add_boolean
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                !default      TYPE abap_bool OPTIONAL
                required      TYPE abap_bool
                x_mcp_header  TYPE string   OPTIONAL
                default_sup   TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Internal begin_array with supplied flags</p>
    "! @parameter name                 | Property name
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum item count when supplied
    "! @parameter max_items            | Maximum item count when supplied
    "! @parameter min_items_sup        | Whether min_items was supplied
    "! @parameter max_items_sup        | Whether max_items was supplied
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS _begin_array
      IMPORTING !name         TYPE string
                !title        TYPE string   OPTIONAL
                description   TYPE string   OPTIONAL
                required      TYPE abap_bool
                min_items     TYPE i        OPTIONAL
                max_items     TYPE i        OPTIONAL
                min_items_sup TYPE abap_bool
                max_items_sup TYPE abap_bool
                additional_properties TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Internal array-of-primitives with supplied flags</p>
    "! Shared by add_string_array / add_integer_array / add_number_array /
    "! add_boolean_array; item_pattern applies to string items only.
    "! @parameter name                 | Property name
    "! @parameter item_type            | JSON schema type of the elements
    "! @parameter title                | Display title
    "! @parameter description          | Property description
    "! @parameter required             | Add to the schema's required list
    "! @parameter min_items            | Minimum element count when supplied
    "! @parameter max_items            | Maximum element count when supplied
    "! @parameter item_pattern         | Element pattern (string items only)
    "! @parameter min_items_sup        | Whether min_items was supplied
    "! @parameter max_items_sup        | Whether max_items was supplied
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS _add_prim_array
      IMPORTING !name         TYPE string
                item_type     TYPE string
                !title        TYPE string OPTIONAL
                description   TYPE string OPTIONAL
                required      TYPE abap_bool
                min_items     TYPE i OPTIONAL
                max_items     TYPE i OPTIONAL
                item_pattern  TYPE string OPTIONAL
                min_items_sup TYPE abap_bool
                max_items_sup TYPE abap_bool
      RAISING zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Flush tracked required props to the node</p>
    "! @raising zcx_mcp2_ajson_error | JSON build failure
    METHODS flush_required
      RAISING zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_schema_builder IMPLEMENTATION.

  METHOD constructor.
    schema = zcl_mcp2_ajson=>create_empty( ).
    schema->set_string( iv_path = '/type'
                        iv_val  = `object` ).
    IF additional_properties = abap_false.
      schema->set( iv_path         = '/additionalProperties'
                   iv_val          = abap_false
                   iv_ignore_empty = abap_false ).
    ENDIF.
    node_type     = `object`.
    root_builder  = me.
    active_builder = me.
  ENDMETHOD.

  METHOD get_active_builder.
    IF me = root_builder AND active_builder IS BOUND AND active_builder <> me.
      result = active_builder.
    ELSE.
      result = me.
    ENDIF.
  ENDMETHOD.

  METHOD property_path.
    DATA(escaped_name) = escape_name( name ).
    IF current_path IS INITIAL.
      result = |/properties/{ escaped_name }|.
    ELSE.
      result = |{ current_path }/properties/{ escaped_name }|.
    ENDIF.
  ENDMETHOD.

  METHOD escape_name.
    result = replace( val  = name
                      sub  = `/`
                      with = cl_abap_char_utilities=>horizontal_tab
                      occ  = 0 ).
  ENDMETHOD.

  METHOD add_property.
    IF name IS INITIAL.
      zcx_mcp2_ajson_error=>raise( `Schema property name must not be empty` ) ##NO_TEXT.
    ENDIF.
    IF line_exists( property_names[ table_line = name ] ).
      zcx_mcp2_ajson_error=>raise( |Duplicate schema property: { name }| ) ##NO_TEXT.
    ENDIF.
    APPEND name TO property_names.
    DATA(path) = property_path( name ).
    schema->set_string( iv_path = |{ path }/type|
                        iv_val  = json_type ).
    IF title IS NOT INITIAL.
      schema->set_string( iv_path = |{ path }/title|
                          iv_val  = title ).
    ENDIF.
    IF description IS NOT INITIAL.
      schema->set_string( iv_path = |{ path }/description|
                          iv_val  = description ).
    ENDIF.
    IF x_mcp_header IS NOT INITIAL.
      schema->set_string( iv_path = |{ path }/x-mcp-header|
                          iv_val  = x_mcp_header ).
    ENDIF.
    IF required = abap_true.
      APPEND name TO required_props.
    ENDIF.
  ENDMETHOD.

  METHOD add_string.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_string(
               name           = name
               title          = title
               description    = description
               enum           = enum
               default        = default
               required       = required
               min_length     = min_length
               max_length     = max_length
               pattern        = pattern
               x_mcp_header   = x_mcp_header
               min_length_sup = xsdbool( min_length IS SUPPLIED )
               max_length_sup = xsdbool( max_length IS SUPPLIED )
               default_sup    = xsdbool( default IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_string( name           = name
                 title          = title
                 description    = description
                 enum           = enum
                 default        = default
                 required       = required
                 min_length     = min_length
                 max_length     = max_length
                 pattern        = pattern
                 x_mcp_header   = x_mcp_header
                 min_length_sup = xsdbool( min_length IS SUPPLIED )
                 max_length_sup = xsdbool( max_length IS SUPPLIED )
                 default_sup    = xsdbool( default IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD _add_string.
    IF min_length_sup = abap_true AND min_length < 0.
      zcx_mcp2_ajson_error=>raise( |minLength must not be negative: { min_length }| ) ##NO_TEXT.
    ENDIF.
    IF max_length_sup = abap_true AND max_length < 0.
      zcx_mcp2_ajson_error=>raise( |maxLength must not be negative: { max_length }| ) ##NO_TEXT.
    ENDIF.
    IF min_length_sup = abap_true AND max_length_sup = abap_true AND min_length > max_length.
      zcx_mcp2_ajson_error=>raise( `minLength must not exceed maxLength` ) ##NO_TEXT.
    ENDIF.
    add_property( name        = name
                  json_type   = `string`
                  title       = title
                  description = description
                  required    = required
                  x_mcp_header = x_mcp_header ).
    DATA(path) = property_path( name ).
    " ignore_empty = false so an explicitly supplied empty default survives.
    IF default_sup = abap_true.
      schema->set( iv_path         = |{ path }/default|
                   iv_val          = default
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF enum IS NOT INITIAL.
      schema->touch_array( |{ path }/enum| ).
      DATA(idx) = 0.
      LOOP AT enum INTO DATA(val).
        idx = idx + 1.
        schema->set( iv_path = |{ path }/enum/{ idx }|
                     iv_val  = val ).
      ENDLOOP.
    ENDIF.
    IF min_length_sup = abap_true.
      schema->set_integer( iv_path = |{ path }/minLength|
                           iv_val  = min_length ).
    ENDIF.
    IF max_length_sup = abap_true.
      schema->set_integer( iv_path = |{ path }/maxLength|
                           iv_val  = max_length ).
    ENDIF.
    IF pattern IS NOT INITIAL.
      schema->set_string( iv_path = |{ path }/pattern|
                          iv_val  = pattern ).
    ENDIF.
  ENDMETHOD.

  METHOD add_number.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_number(
               name        = name
               title       = title
               description = description
               default     = default
               required    = required
               minimum     = minimum
               maximum     = maximum
               x_mcp_header = x_mcp_header
               minimum_sup = xsdbool( minimum IS SUPPLIED )
               maximum_sup = xsdbool( maximum IS SUPPLIED )
               default_sup = xsdbool( default IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_number( name        = name
                 title       = title
                 description = description
                 default     = default
                 required    = required
                 minimum     = minimum
                 maximum     = maximum
                 x_mcp_header = x_mcp_header
                 minimum_sup = xsdbool( minimum IS SUPPLIED )
                 maximum_sup = xsdbool( maximum IS SUPPLIED )
                 default_sup = xsdbool( default IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD _add_number.
    IF minimum_sup = abap_true AND maximum_sup = abap_true AND minimum > maximum.
      zcx_mcp2_ajson_error=>raise( `minimum must not exceed maximum` ) ##NO_TEXT.
    ENDIF.
    add_property( name        = name
                  json_type   = `number`
                  title       = title
                  description = description
                  required    = required
                  x_mcp_header = x_mcp_header ).
    DATA(path) = property_path( name ).
    " ignore_empty = false so an explicitly supplied default of 0 survives.
    IF default_sup = abap_true.
      schema->set( iv_path         = |{ path }/default|
                   iv_val          = default
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF minimum_sup = abap_true.
      schema->set( iv_path         = |{ path }/minimum|
                   iv_val          = minimum
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF maximum_sup = abap_true.
      schema->set( iv_path         = |{ path }/maximum|
                   iv_val          = maximum
                   iv_ignore_empty = abap_false ).
    ENDIF.
  ENDMETHOD.

  METHOD add_integer.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_integer(
               name        = name
               title       = title
               description = description
               default     = default
               required    = required
               minimum     = minimum
               maximum     = maximum
               x_mcp_header = x_mcp_header
               minimum_sup = xsdbool( minimum IS SUPPLIED )
               maximum_sup = xsdbool( maximum IS SUPPLIED )
               default_sup = xsdbool( default IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_integer( name        = name
                  title       = title
                  description = description
                  default     = default
                  required    = required
                  minimum     = minimum
                  maximum     = maximum
                  x_mcp_header = x_mcp_header
                  minimum_sup = xsdbool( minimum IS SUPPLIED )
                  maximum_sup = xsdbool( maximum IS SUPPLIED )
                  default_sup = xsdbool( default IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD _add_integer.
    IF minimum_sup = abap_true AND maximum_sup = abap_true AND minimum > maximum.
      zcx_mcp2_ajson_error=>raise( `minimum must not exceed maximum` ) ##NO_TEXT.
    ENDIF.
    add_property( name        = name
                  json_type   = `integer`
                  title       = title
                  description = description
                  required    = required
                  x_mcp_header = x_mcp_header ).
    DATA(path) = property_path( name ).
    " ignore_empty = false so an explicitly supplied default of 0 survives.
    IF default_sup = abap_true.
      schema->set( iv_path         = |{ path }/default|
                   iv_val          = default
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF minimum_sup = abap_true.
      schema->set( iv_path         = |{ path }/minimum|
                   iv_val          = minimum
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF maximum_sup = abap_true.
      schema->set( iv_path         = |{ path }/maximum|
                   iv_val          = maximum
                   iv_ignore_empty = abap_false ).
    ENDIF.
  ENDMETHOD.

  METHOD add_boolean.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_boolean( name        = name
                             title       = title
                             description = description
                             default     = default
                             required    = required
                             x_mcp_header = x_mcp_header
                             default_sup = xsdbool( default IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_boolean( name        = name
                  title       = title
                  description = description
                  default     = default
                  required    = required
                  x_mcp_header = x_mcp_header
                  default_sup = xsdbool( default IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD _add_boolean.
    add_property( name        = name
                  json_type   = `boolean`
                  title       = title
                  description = description
                  required    = required
                  x_mcp_header = x_mcp_header ).
    " ignore_empty = false so an explicitly supplied default of false survives.
    IF default_sup = abap_true.
      schema->set( iv_path         = |{ property_path( name ) }/default|
                   iv_val          = default
                   iv_ignore_empty = abap_false ).
    ENDIF.
  ENDMETHOD.

  METHOD begin_object.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      self = builder->begin_object( name        = name
                                    title       = title
                                    description = description
                                    required    = required
                                    additional_properties = additional_properties ).
      RETURN.
    ENDIF.

    add_property( name        = name
                  json_type   = `object`
                  title       = title
                  description = description
                  required    = required ).

    DATA(path) = property_path( name ).
    IF additional_properties = abap_false.
      schema->set( iv_path         = |{ path }/additionalProperties|
                   iv_val          = abap_false
                   iv_ignore_empty = abap_false ).
    ENDIF.
    DATA child TYPE REF TO zcl_mcp2_schema_builder.
    child = NEW zcl_mcp2_schema_builder( ).
    child->schema         = schema.
    child->current_path   = path.
    child->parent_builder = me.
    child->node_type      = `object`.
    child->root_builder   = root_builder.

    root_builder->active_builder = child.
    self = child.
  ENDMETHOD.

  METHOD end_object.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      self = builder->end_object( ).
      RETURN.
    ENDIF.
    IF parent_builder IS NOT BOUND OR node_type <> `object`.
      zcx_mcp2_ajson_error=>raise( `end_object called outside a nested object` ) ##NO_TEXT.
    ENDIF.
    flush_required( ).
    root_builder->active_builder = parent_builder.
    self = parent_builder.
  ENDMETHOD.

  METHOD begin_array.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_begin_array(
               name         = name
               title        = title
               description  = description
               required     = required
               min_items    = min_items
               max_items    = max_items
               min_items_sup = xsdbool( min_items IS SUPPLIED )
               max_items_sup = xsdbool( max_items IS SUPPLIED )
               additional_properties = additional_properties ).
      self = root_builder->active_builder.
      RETURN.
    ENDIF.
    _begin_array( name         = name
                  title        = title
                  description  = description
                  required     = required
                  min_items    = min_items
                  max_items    = max_items
                  min_items_sup = xsdbool( min_items IS SUPPLIED )
                  max_items_sup = xsdbool( max_items IS SUPPLIED )
                  additional_properties = additional_properties ).
    self = root_builder->active_builder.
  ENDMETHOD.

  METHOD _begin_array.
    IF min_items_sup = abap_true AND min_items < 0.
      zcx_mcp2_ajson_error=>raise( |minItems must not be negative: { min_items }| ) ##NO_TEXT.
    ENDIF.
    IF max_items_sup = abap_true AND max_items < 0.
      zcx_mcp2_ajson_error=>raise( |maxItems must not be negative: { max_items }| ) ##NO_TEXT.
    ENDIF.
    IF min_items_sup = abap_true AND max_items_sup = abap_true AND min_items > max_items.
      zcx_mcp2_ajson_error=>raise( `minItems must not exceed maxItems` ) ##NO_TEXT.
    ENDIF.
    add_property( name        = name
                  json_type   = `array`
                  title       = title
                  description = description
                  required    = required ).
    DATA(path) = property_path( name ).
    IF min_items_sup = abap_true.
      schema->set_integer( iv_path = |{ path }/minItems|
                           iv_val  = min_items ).
    ENDIF.
    IF max_items_sup = abap_true.
      schema->set_integer( iv_path = |{ path }/maxItems|
                           iv_val  = max_items ).
    ENDIF.
    schema->set_string( iv_path = |{ path }/items/type|
                        iv_val  = `object` ).
    IF additional_properties = abap_false.
      schema->set( iv_path         = |{ path }/items/additionalProperties|
                   iv_val          = abap_false
                   iv_ignore_empty = abap_false ).
    ENDIF.

    DATA child TYPE REF TO zcl_mcp2_schema_builder.
    child = NEW zcl_mcp2_schema_builder( ).
    child->schema         = schema.
    child->current_path   = |{ path }/items|.
    child->parent_builder = me.
    child->node_type      = `array`.
    child->root_builder   = root_builder.

    root_builder->active_builder = child.
  ENDMETHOD.

  METHOD end_array.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      self = builder->end_array( ).
      RETURN.
    ENDIF.
    IF parent_builder IS NOT BOUND OR node_type <> `array`.
      zcx_mcp2_ajson_error=>raise( `end_array called outside an array` ) ##NO_TEXT.
    ENDIF.
    flush_required( ).
    root_builder->active_builder = parent_builder.
    self = parent_builder.
  ENDMETHOD.

  METHOD flush_required.
    IF required_props IS INITIAL.
      RETURN.
    ENDIF.
    DATA base TYPE string.
    IF current_path IS INITIAL.
      base = ``.
    ELSE.
      base = current_path.
    ENDIF.
    schema->touch_array( |{ base }/required| ).
    DATA idx TYPE i VALUE 0.
    LOOP AT required_props INTO DATA(prop).
      idx = idx + 1.
      schema->set( iv_path = |{ base }/required/{ idx }|
                   iv_val  = prop ).
    ENDLOOP.
    CLEAR required_props.
  ENDMETHOD.

  METHOD to_json.
    IF root_builder->active_builder <> root_builder.
      zcx_mcp2_ajson_error=>raise( `Cannot finalize schema with an unclosed object or array` ) ##NO_TEXT.
    ENDIF.
    root_builder->flush_required( ).
    result = schema.
  ENDMETHOD.

  METHOD add_string_array.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_prim_array( name          = name
                                item_type     = `string`
                                title         = title
                                description   = description
                                required      = required
                                min_items     = min_items
                                max_items     = max_items
                                item_pattern  = item_pattern
                                min_items_sup = xsdbool( min_items IS SUPPLIED )
                                max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_prim_array( name          = name
                     item_type     = `string`
                     title         = title
                     description   = description
                     required      = required
                     min_items     = min_items
                     max_items     = max_items
                     item_pattern  = item_pattern
                     min_items_sup = xsdbool( min_items IS SUPPLIED )
                     max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD add_integer_array.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_prim_array( name          = name
                                item_type     = `integer`
                                title         = title
                                description   = description
                                required      = required
                                min_items     = min_items
                                max_items     = max_items
                                min_items_sup = xsdbool( min_items IS SUPPLIED )
                                max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_prim_array( name          = name
                     item_type     = `integer`
                     title         = title
                     description   = description
                     required      = required
                     min_items     = min_items
                     max_items     = max_items
                     min_items_sup = xsdbool( min_items IS SUPPLIED )
                     max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD add_number_array.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_prim_array( name          = name
                                item_type     = `number`
                                title         = title
                                description   = description
                                required      = required
                                min_items     = min_items
                                max_items     = max_items
                                min_items_sup = xsdbool( min_items IS SUPPLIED )
                                max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_prim_array( name          = name
                     item_type     = `number`
                     title         = title
                     description   = description
                     required      = required
                     min_items     = min_items
                     max_items     = max_items
                     min_items_sup = xsdbool( min_items IS SUPPLIED )
                     max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD add_boolean_array.
    DATA(builder) = get_active_builder( ).
    IF builder <> me.
      builder->_add_prim_array( name          = name
                                item_type     = `boolean`
                                title         = title
                                description   = description
                                required      = required
                                min_items     = min_items
                                max_items     = max_items
                                min_items_sup = xsdbool( min_items IS SUPPLIED )
                                max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
      self = builder.
      RETURN.
    ENDIF.
    _add_prim_array( name          = name
                     item_type     = `boolean`
                     title         = title
                     description   = description
                     required      = required
                     min_items     = min_items
                     max_items     = max_items
                     min_items_sup = xsdbool( min_items IS SUPPLIED )
                     max_items_sup = xsdbool( max_items IS SUPPLIED ) ).
    self = me.
  ENDMETHOD.

  METHOD _add_prim_array.
    IF min_items_sup = abap_true AND min_items < 0.
      zcx_mcp2_ajson_error=>raise( |minItems must not be negative: { min_items }| ) ##NO_TEXT.
    ENDIF.
    IF max_items_sup = abap_true AND max_items < 0.
      zcx_mcp2_ajson_error=>raise( |maxItems must not be negative: { max_items }| ) ##NO_TEXT.
    ENDIF.
    IF min_items_sup = abap_true AND max_items_sup = abap_true AND min_items > max_items.
      zcx_mcp2_ajson_error=>raise( `minItems must not exceed maxItems` ) ##NO_TEXT.
    ENDIF.
    add_property( name        = name
                  json_type   = `array`
                  title       = title
                  description = description
                  required    = required ).
    DATA(path) = property_path( name ).
    schema->set_string( iv_path = |{ path }/items/type| iv_val = item_type ).
    IF min_items_sup = abap_true.
      schema->set_integer( iv_path = |{ path }/minItems| iv_val = min_items ).
    ENDIF.
    IF max_items_sup = abap_true.
      schema->set_integer( iv_path = |{ path }/maxItems| iv_val = max_items ).
    ENDIF.
    " Patterns constrain string elements only; ignored for other item types.
    IF item_pattern IS NOT INITIAL AND item_type = `string`.
      schema->set_string( iv_path = |{ path }/items/pattern| iv_val = item_pattern ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
