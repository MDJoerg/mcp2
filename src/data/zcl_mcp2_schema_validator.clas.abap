"! <p class="shorttext synchronized">MCP2 JSON Schema validator</p>
"! Validates a zif_mcp2_ajson instance against a JSON Schema.
"! Supports type, required, enum, pattern, additionalProperties,
"! length/range/item bounds, and nested objects/arrays.
CLASS zcl_mcp2_schema_validator DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Create a validator for a schema</p>
    "! @parameter schema               | JSON Schema to validate against
    "! @raising   zcx_mcp2_ajson_error | Schema parse failure
    METHODS constructor
      IMPORTING !schema TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate a JSON instance</p>
    "! Collects findings; retrieve them with get_errors.
    "! @parameter json                 | Instance to validate
    "! @parameter result               | abap_true when the instance is valid
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate
      IMPORTING !json         TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Accumulated validation error messages</p>
    "! @parameter result | Validation findings from the last validate call
    METHODS get_errors
      RETURNING VALUE(result) TYPE string_table.

    "! <p class="shorttext synchronized">Validate and raise InvalidParams on failure</p>
    "! Raises -32602 with all findings joined. Used by the legacy dispatcher for
    "! opt-in tools/call input validation (validate_tool_input).
    "! @parameter schema               | JSON Schema to validate against
    "! @parameter json                 | Instance to validate (unbound = empty object)
    "! @raising   zcx_mcp2_error       | Instance is invalid (InvalidParams)
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    CLASS-METHODS validate_or_raise
      IMPORTING !schema TYPE REF TO zif_mcp2_ajson
                !json   TYPE REF TO zif_mcp2_ajson OPTIONAL
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA schema       TYPE REF TO zif_mcp2_ajson.
    DATA error_list   TYPE string_table.

    "! <p class="shorttext synchronized">Record a validation finding</p>
    "! @parameter path    | JSON path of the offending node
    "! @parameter message | Human-readable finding
    METHODS add_error
      IMPORTING !path    TYPE string
                !message TYPE string.

    "! <p class="shorttext synchronized">Validate an object node</p>
    "! Checks required properties and validates each present property.
    "! @parameter schema_path          | Path of the object schema node
    "! @parameter json_path            | Path of the object in the instance
    "! @parameter json                 | Instance being validated
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_object
      IMPORTING schema_path TYPE string
                json_path   TYPE string
                !json       TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate a single property</p>
    "! Dispatches on the property's declared type.
    "! @parameter schema_path          | Path of the enclosing properties node
    "! @parameter json_path            | Path of the enclosing object in the instance
    "! @parameter property             | Property name to validate
    "! @parameter json                 | Instance being validated
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_property
      IMPORTING schema_path TYPE string
                json_path   TYPE string
                !property   TYPE string
                !json       TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate a string value</p>
    "! Checks enum, minLength and maxLength.
    "! @parameter schema_path          | Path of the string schema node
    "! @parameter json_path            | Path of the value in the instance
    "! @parameter json                 | Instance being validated
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_string
      IMPORTING schema_path TYPE string
                json_path   TYPE string
                !json       TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate a number value</p>
    "! Checks minimum and maximum.
    "! @parameter schema_path          | Path of the number schema node
    "! @parameter json_path            | Path of the value in the instance
    "! @parameter json                 | Instance being validated
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_number
      IMPORTING schema_path TYPE string
                json_path   TYPE string
                !json       TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate an integer value</p>
    "! Checks minimum and maximum.
    "! @parameter schema_path          | Path of the integer schema node
    "! @parameter json_path            | Path of the value in the instance
    "! @parameter json                 | Instance being validated
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_integer
      IMPORTING schema_path TYPE string
                json_path   TYPE string
                !json       TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate an array value</p>
    "! Checks minItems, maxItems and object item shape.
    "! @parameter schema_path          | Path of the array schema node
    "! @parameter json_path            | Path of the array in the instance
    "! @parameter json                 | Instance being validated
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_array
      IMPORTING schema_path TYPE string
                json_path   TYPE string
                !json       TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Safe exists check</p>
    "! Returns abap_false instead of raising on a JSON access error.
    "! @parameter json   | JSON document to probe
    "! @parameter path   | Path to test
    "! @parameter result | abap_true when the path exists
    METHODS property_exists
      IMPORTING !json       TYPE REF TO zif_mcp2_ajson
                !path       TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS escape_name
      IMPORTING name TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_mcp2_schema_validator IMPLEMENTATION.

  METHOD constructor.
    me->schema = schema.
  ENDMETHOD.

  METHOD validate.
    CLEAR error_list.
    IF json IS NOT BOUND.
      add_error( path = `/` message = `Input JSON is not bound` ) ##NO_TEXT.
      RETURN.
    ENDIF.
    IF schema IS NOT BOUND.
      add_error( path = `/` message = `Schema is not bound` ) ##NO_TEXT.
      RETURN.
    ENDIF.
    DATA(root_type) = schema->get_string( `/type` ).
    IF root_type <> `object`.
      add_error( path = `/` message = |Schema root must be of type object, found: { root_type }| ) ##NO_TEXT.
      result = abap_false.
      RETURN.
    ENDIF.
    IF json->get_node_type( `` ) <> zif_mcp2_ajson_types=>node_type-object.
      add_error( path = `/` message = |Expected object, got { json->get_node_type( `` ) }| ) ##NO_TEXT.
      result = abap_false.
      RETURN.
    ENDIF.

    validate_object( schema_path = ``
                     json_path   = ``
                     json        = json ).
    result = xsdbool( error_list IS INITIAL ).
  ENDMETHOD.

  METHOD get_errors.
    result = error_list.
  ENDMETHOD.

  METHOD validate_or_raise.
    DATA instance  TYPE REF TO zif_mcp2_ajson.
    DATA validator TYPE REF TO zcl_mcp2_schema_validator.
    DATA is_valid  TYPE abap_bool.
    DATA joined    TYPE string.

    instance = json.
    IF instance IS NOT BOUND.
      " parse (not create_empty) so the root is actually node_type-object -
      " create_empty()'s root has no node type until something is set on it.
      instance = zcl_mcp2_ajson=>parse( '{}' ).
    ENDIF.
    validator = NEW zcl_mcp2_schema_validator( schema ).
    is_valid = validator->validate( instance ).
    IF is_valid = abap_true.
      RETURN.
    ENDIF.
    joined = concat_lines_of( table = validator->get_errors( )
                              sep   = `; ` ).
    zcx_mcp2_error=>raise_invalid_params( |Invalid tool input: { joined }| ) ##NO_TEXT.
  ENDMETHOD.

  METHOD add_error.
    DATA(display_path) = COND string( WHEN path IS INITIAL THEN `/` ELSE path ).
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN display_path WITH `/`.
    APPEND |{ display_path }: { message }| TO error_list.
  ENDMETHOD.

  METHOD validate_object.
    " Check required properties exist.
    DATA(req_path) = |{ schema_path }/required|.
    IF property_exists( json = schema  path = req_path ).
      " Keep method-call results explicitly typed for ABAP 7.02 downport compatibility.
      DATA required TYPE string_table.
      required = schema->array_to_string_table( req_path ).
      LOOP AT required INTO DATA(req_prop).
        DATA(req_json_path) = |{ json_path }/{ escape_name( req_prop ) }|.
        IF property_exists( json = json  path = req_json_path ) = abap_false.
          add_error( path    = req_json_path
                     message = |Required property '{ req_prop }' is missing| ) ##NO_TEXT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    DATA(props_path) = |{ schema_path }/properties|.
    DATA props TYPE string_table.
    IF property_exists( json = schema path = props_path ).
      props = schema->members( props_path ).
    ENDIF.
    DATA(additional_path) = |{ schema_path }/additionalProperties|.
    IF property_exists( json = schema path = additional_path )
       AND schema->get_boolean( additional_path ) = abap_false.
      DATA instance_members TYPE string_table.
      instance_members = json->members( json_path ).
      LOOP AT instance_members INTO DATA(instance_member).
        IF NOT line_exists( props[ table_line = instance_member ] ).
          add_error( path    = |{ json_path }/{ escape_name( instance_member ) }|
                     message = |Additional property '{ instance_member }' is not allowed| ) ##NO_TEXT.
        ENDIF.
      ENDLOOP.
    ENDIF.
    LOOP AT props INTO DATA(prop).
      DATA(prop_json_path) = |{ json_path }/{ escape_name( prop ) }|.
      IF property_exists( json = json  path = prop_json_path ).
        validate_property( schema_path = props_path
                           json_path   = json_path
                           property    = prop
                           json        = json ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_property.
    DATA(prop_schema_path) = |{ schema_path }/{ escape_name( property ) }|.
    DATA(prop_json_path)   = |{ json_path }/{ escape_name( property ) }|.
    DATA(schema_type) = schema->get_string( |{ prop_schema_path }/type| ).

    CASE schema_type.
      WHEN `string`.
        IF json->get_node_type( prop_json_path ) <> `str`.
          add_error( path    = prop_json_path
                     message = |Expected string, got { json->get_node_type( prop_json_path ) }| ) ##NO_TEXT.
          RETURN.
        ENDIF.
        validate_string( schema_path = prop_schema_path
                         json_path   = prop_json_path
                         json        = json ).

      WHEN `number`.
        IF json->get_node_type( prop_json_path ) <> `num`.
          add_error( path    = prop_json_path
                     message = |Expected number, got { json->get_node_type( prop_json_path ) }| ) ##NO_TEXT.
          RETURN.
        ENDIF.
        validate_number( schema_path = prop_schema_path
                         json_path   = prop_json_path
                         json        = json ).

      WHEN `integer`.
        IF json->get_node_type( prop_json_path ) <> `num`.
          add_error( path    = prop_json_path
                     message = |Expected integer, got { json->get_node_type( prop_json_path ) }| ) ##NO_TEXT.
          RETURN.
        ENDIF.
        validate_integer( schema_path = prop_schema_path
                          json_path   = prop_json_path
                          json        = json ).

      WHEN `boolean`.
        IF json->get_node_type( prop_json_path ) <> `bool`.
          add_error( path    = prop_json_path
                     message = |Expected boolean, got { json->get_node_type( prop_json_path ) }| ) ##NO_TEXT.
        ENDIF.

      WHEN `object`.
        IF json->get_node_type( prop_json_path ) <> `object`.
          add_error( path    = prop_json_path
                     message = |Expected object, got { json->get_node_type( prop_json_path ) }| ) ##NO_TEXT.
          RETURN.
        ENDIF.
        validate_object( schema_path = prop_schema_path
                         json_path   = prop_json_path
                         json        = json ).

      WHEN `array`.
        IF json->get_node_type( prop_json_path ) <> `array`.
          add_error( path    = prop_json_path
                     message = |Expected array, got { json->get_node_type( prop_json_path ) }| ) ##NO_TEXT.
          RETURN.
        ENDIF.
        validate_array( schema_path = prop_schema_path
                        json_path   = prop_json_path
                        json        = json ).
    ENDCASE.
  ENDMETHOD.

  METHOD validate_string.
    DATA(val) = json->get_string( json_path ).
    DATA(vlen) = strlen( val ).

    " enum check
    DATA(enum_path) = |{ schema_path }/enum|.
    IF property_exists( json = schema  path = enum_path ).
      DATA allowed TYPE string_table.
      allowed = schema->array_to_string_table( enum_path ).
      " line_exists is a predicate function - it cannot be compared to abap_false.
      IF NOT line_exists( allowed[ table_line = val ] ).
        add_error( path    = json_path
                   message = |Value '{ val }' is not in enum| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    " minLength
    DATA(min_path) = |{ schema_path }/minLength|.
    IF property_exists( json = schema  path = min_path ).
      DATA(min_len) = schema->get_integer( min_path ).
      IF vlen < min_len.
        add_error( path    = json_path
                   message = |String length { vlen } is less than minLength { min_len }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    " maxLength
    DATA(max_path) = |{ schema_path }/maxLength|.
    IF property_exists( json = schema  path = max_path ).
      DATA(max_len) = schema->get_integer( max_path ).
      IF vlen > max_len.
        add_error( path    = json_path
                   message = |String length { vlen } exceeds maxLength { max_len }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    DATA(pattern_path) = |{ schema_path }/pattern|.
    IF property_exists( json = schema path = pattern_path ).
      DATA(pattern) = schema->get_string( pattern_path ).
      DATA match_offset TYPE i.
      DATA match_length TYPE i.
      TRY.
          FIND FIRST OCCURRENCE OF REGEX pattern IN val
            MATCH OFFSET match_offset MATCH LENGTH match_length.
          IF sy-subrc <> 0 OR match_offset <> 0 OR match_length <> strlen( val ).
            add_error( path = json_path message = |Value does not match pattern '{ pattern }'| ) ##NO_TEXT.
          ENDIF.
        CATCH cx_sy_regex.
          add_error( path = json_path message = |Schema contains invalid pattern '{ pattern }'| ) ##NO_TEXT.
      ENDTRY.
    ENDIF.
  ENDMETHOD.

  METHOD validate_number.
    DATA(val) = json->get_number( json_path ).

    DATA(min_path) = |{ schema_path }/minimum|.
    IF property_exists( json = schema  path = min_path ).
      DATA(min_val) = schema->get_number( min_path ).
      IF val < min_val.
        add_error( path    = json_path
                   message = |Value { val } is less than minimum { min_val }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    DATA(max_path) = |{ schema_path }/maximum|.
    IF property_exists( json = schema  path = max_path ).
      DATA(max_val) = schema->get_number( max_path ).
      IF val > max_val.
        add_error( path    = json_path
                   message = |Value { val } exceeds maximum { max_val }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD validate_integer.
    DATA(raw) = json->get_string( json_path ).
    FIND REGEX `^-?[0-9]+$` IN raw.
    IF sy-subrc <> 0.
      add_error( path = json_path message = |Expected integer, got { raw }| ) ##NO_TEXT.
      RETURN.
    ENDIF.
    " ajson's get_integer does a plain MOVE from the raw string, so an
    " out-of-range value raises the classic runtime error CONVT_OVERFLOW -
    " not a catchable exception class. Range-check via decfloat first.
    TRY.
        DATA(numeric) = CONV decfloat34( raw ).
      CATCH cx_sy_conversion_no_number cx_sy_conversion_overflow.
        add_error( path = json_path message = |Integer is outside the supported ABAP range: { raw }| ) ##NO_TEXT.
        RETURN.
    ENDTRY.
    IF numeric > 2147483647 OR numeric < -2147483648.
      add_error( path = json_path message = |Integer is outside the supported ABAP range: { raw }| ) ##NO_TEXT.
      RETURN.
    ENDIF.
    DATA val TYPE i.
    val = json->get_integer( json_path ).

    DATA(min_path) = |{ schema_path }/minimum|.
    IF property_exists( json = schema  path = min_path ).
      DATA(min_val) = schema->get_integer( min_path ).
      IF val < min_val.
        add_error( path    = json_path
                   message = |Value { val } is less than minimum { min_val }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    DATA(max_path) = |{ schema_path }/maximum|.
    IF property_exists( json = schema  path = max_path ).
      DATA(max_val) = schema->get_integer( max_path ).
      IF val > max_val.
        add_error( path    = json_path
                   message = |Value { val } exceeds maximum { max_val }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD validate_array.
    DATA(items_path) = |{ schema_path }/items|.
    DATA(items_type) = COND string(
      WHEN property_exists( json = schema  path = |{ items_path }/type| )
      THEN schema->get_string( |{ items_path }/type| )
      ELSE `` ).

    " Count items via members (numeric indices).
    DATA count TYPE i VALUE 0.
    DATA members TYPE string_table.
    TRY.
        members = json->members( json_path ).
        count   = lines( members ).
      CATCH zcx_mcp2_ajson_error.
        count = 0.
    ENDTRY.

    DATA(min_path) = |{ schema_path }/minItems|.
    IF property_exists( json = schema  path = min_path ).
      DATA(min_items) = schema->get_integer( min_path ).
      IF count < min_items.
        add_error( path    = json_path
                   message = |Array has { count } items, minItems is { min_items }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    DATA(max_path) = |{ schema_path }/maxItems|.
    IF property_exists( json = schema  path = max_path ).
      DATA(max_items) = schema->get_integer( max_path ).
      IF count > max_items.
        add_error( path    = json_path
                   message = |Array has { count } items, maxItems is { max_items }| ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    LOOP AT members INTO DATA(member_item).
      DATA(item_path) = |{ json_path }/{ member_item }|.
      CASE items_type.
        WHEN `object`.
          IF json->get_node_type( item_path ) <> `object`.
            add_error( path = item_path message = |Array item { member_item } expected object| ) ##NO_TEXT.
          ELSE.
            validate_object( schema_path = items_path json_path = item_path json = json ).
          ENDIF.
        WHEN `string`.
          IF json->get_node_type( item_path ) <> `str`.
            add_error( path = item_path message = |Array item { member_item } expected string| ) ##NO_TEXT.
          ELSE.
            validate_string( schema_path = items_path json_path = item_path json = json ).
          ENDIF.
        WHEN `integer`.
          IF json->get_node_type( item_path ) <> `num`.
            add_error( path = item_path message = |Array item { member_item } expected integer| ) ##NO_TEXT.
          ELSE.
            validate_integer( schema_path = items_path json_path = item_path json = json ).
          ENDIF.
        WHEN `number`.
          IF json->get_node_type( item_path ) <> `num`.
            add_error( path = item_path message = |Array item { member_item } expected number| ) ##NO_TEXT.
          ELSE.
            validate_number( schema_path = items_path json_path = item_path json = json ).
          ENDIF.
        WHEN `boolean`.
          IF json->get_node_type( item_path ) <> `bool`.
            add_error( path = item_path message = |Array item { member_item } expected boolean| ) ##NO_TEXT.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD property_exists.
    TRY.
        result = json->exists( path ).
      CATCH zcx_mcp2_ajson_error.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD escape_name.
    result = replace( val  = name
                      sub  = `/`
                      with = cl_abap_char_utilities=>horizontal_tab
                      occ  = 0 ).
  ENDMETHOD.

ENDCLASS.
