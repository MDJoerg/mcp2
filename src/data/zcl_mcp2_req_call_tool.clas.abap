"! <p class="shorttext synchronized">MCP2 tools/call request</p>
"! Supports MRTR: if requestState is present the call is a retry after
"! an input_required round-trip. inputResponses carries the client answers.
CLASS zcl_mcp2_req_call_tool DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    " Return types for the array-argument readers.
    TYPES integer_table TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES number_table  TYPE STANDARD TABLE OF decfloat34 WITH EMPTY KEY.
    TYPES boolean_table TYPE STANDARD TABLE OF abap_bool WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Parse a tools/call params object</p>
    "! @parameter json                 | The params slice of the JSON-RPC request
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    "! @raising   zcx_mcp2_error       | Missing/invalid required field
    METHODS constructor
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error
                zcx_mcp2_error.

    "! <p class="shorttext synchronized">Tool name to invoke</p>
    "! @parameter result | Tool name
    METHODS get_name
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether arguments were supplied</p>
    "! @parameter result | abap_true when an arguments object is present
    METHODS has_arguments
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Tool arguments object</p>
    "! @parameter result | Arguments object, or unbound when absent
    METHODS get_arguments
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Whether this call is an MRTR retry</p>
    "! True when the client sent requestState and/or inputResponses - either
    "! marks the call as the retry leg of an input_required round-trip.
    "! @parameter result | abap_true when this is a retry leg
    METHODS is_retry
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the call is task-augmented (legacy)</p>
    "! True when the request carried the 2025-11-25 per-request task opt-in
    "! (params.task). Legacy clients must opt in before a handler may return a
    "! task result; prefer the era-aware client_supports_tasks( ) on the base.
    "! @parameter result | abap_true when params.task was present
    METHODS has_task_request
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Requested task TTL in milliseconds (legacy)</p>
    "! The optional params.task.ttl from a task-augmented legacy call.
    "! Returns 0 when absent; servers MAY override the requested value.
    "! @parameter result | Requested TTL in ms, 0 when absent
    METHODS get_task_ttl_ms
      RETURNING VALUE(result) TYPE i.

    "! <p class="shorttext synchronized">Opaque continuation token (MRTR)</p>
    "! @parameter result | requestState token, empty when absent
    METHODS get_request_state
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether inputResponses were supplied (MRTR)</p>
    "! @parameter result | abap_true when inputResponses is present
    METHODS has_input_responses
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Client answers to a prior inputRequired (MRTR)</p>
    "! @parameter result | inputResponses object, or unbound when absent
    METHODS get_input_responses
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">The request _meta object</p>
    "! @parameter result | The _meta object, or unbound when absent
    METHODS get_meta
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Whether a named argument is present</p>
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | abap_true when the argument exists
    METHODS has_arg
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Read a string argument by name</p>
    "! Returns an empty string when arguments or the field are absent.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Argument value, empty when absent
    METHODS get_arg_string
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Read a string argument or a default</p>
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter default_value | Value returned when the argument is absent
    "! @parameter result        | Argument value, or default_value when absent
    METHODS get_arg_string_or
      IMPORTING !name         TYPE string
                default_value TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Read a required string argument</p>
    "! Raises InvalidParams when the argument is absent.
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter result        | Argument value
    "! @raising   zcx_mcp2_error | Argument is absent
    METHODS require_arg_string
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Read an integer argument by name</p>
    "! Returns 0 when arguments or the field are absent.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Argument value, 0 when absent
    METHODS get_arg_integer
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE i.

    "! <p class="shorttext synchronized">Read an integer argument or a default</p>
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter default_value | Value returned when the argument is absent
    "! @parameter result        | Argument value, or default_value when absent
    METHODS get_arg_integer_or
      IMPORTING !name         TYPE string
                default_value TYPE i
      RETURNING VALUE(result) TYPE i.

    "! <p class="shorttext synchronized">Read a required integer argument</p>
    "! Raises InvalidParams when the argument is absent.
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter result        | Argument value
    "! @raising   zcx_mcp2_error | Argument is absent
    METHODS require_arg_integer
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Read a decimal-number argument by name</p>
    "! Reads JSON number values only - returns 0 when the argument is absent
    "! or carries any other node type, including a numeric string such as
    "! "12.75". Converts from the raw JSON literal, so decimal fractions are
    "! not rounded through a binary float.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Argument value, 0 when absent or not a JSON number
    METHODS get_arg_number
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE decfloat34.

    "! <p class="shorttext synchronized">Read a decimal-number argument or a default</p>
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter default_value | Value returned when the argument is absent
    "! @parameter result        | Argument value, or default_value when absent
    METHODS get_arg_number_or
      IMPORTING !name         TYPE string
                default_value TYPE decfloat34
      RETURNING VALUE(result) TYPE decfloat34.

    "! <p class="shorttext synchronized">Read a required decimal-number argument</p>
    "! Raises InvalidParams when the argument is absent.
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter result        | Argument value
    "! @raising   zcx_mcp2_error | Argument is absent
    METHODS require_arg_number
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE decfloat34
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Read a boolean argument by name</p>
    "! Returns abap_false when arguments or the field are absent.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Argument value, abap_false when absent
    METHODS get_arg_boolean
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Read a boolean argument or a default</p>
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter default_value | Value returned when the argument is absent
    "! @parameter result        | Argument value, or default_value when absent
    METHODS get_arg_boolean_or
      IMPORTING !name         TYPE string
                default_value TYPE abap_bool
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Read a required boolean argument</p>
    "! Raises InvalidParams when the argument is absent.
    "! @parameter name          | Argument name (no leading slash)
    "! @parameter result        | Argument value
    "! @raising   zcx_mcp2_error | Argument is absent
    METHODS require_arg_boolean
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Read a string-array argument by name</p>
    "! Returns an empty table when the argument is absent. Element values are
    "! read as strings; for arrays of objects use get_arg_json or bind_arguments.
    "! @parameter name                 | Argument name (no leading slash)
    "! @parameter result               | Element values, empty when absent
    "! @raising   zcx_mcp2_ajson_error | Argument is not an array
    METHODS get_arg_string_table
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string_table
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Read an integer-array argument by name</p>
    "! Returns an empty table when the argument is absent or is not an array.
    "! An element that is not a JSON number contributes 0.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Element values, empty when absent
    METHODS get_arg_integer_table
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE integer_table.

    "! <p class="shorttext synchronized">Read a decimal-array argument by name</p>
    "! Returns an empty table when the argument is absent or is not an array.
    "! Elements are converted from their raw JSON literals, so decimals are not
    "! rounded through a binary float; a non-number element contributes 0.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Element values, empty when absent
    METHODS get_arg_number_table
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE number_table.

    "! <p class="shorttext synchronized">Read a boolean-array argument by name</p>
    "! Returns an empty table when the argument is absent or is not an array.
    "! An element that is not a JSON boolean contributes abap_false.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Element values, empty when absent
    METHODS get_arg_boolean_table
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE boolean_table.

    "! <p class="shorttext synchronized">Read one raw argument node by name</p>
    "! Returns initial when the argument is absent.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Raw argument node, or unbound when absent
    METHODS get_arg_json
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Marshal all arguments into an ABAP structure</p>
    "! Corresponding fields only - unmapped JSON members are ignored. When no
    "! arguments were supplied the target is left unchanged.
    "! @parameter target               | Receiving structure (matched by field name)
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS bind_arguments
      CHANGING !target TYPE any
      RAISING  zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Typed reader for one MRTR input response (MRTR)</p>
    "! Slices inputResponses/&lt;key&gt; and wraps it in an elicitation result reader.
    "! @parameter key                  | The input-request key the client answered under
    "! @parameter result               | Reader over the client's answer for that key
    "! @raising   zcx_mcp2_error       | Missing key or invalid response
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS get_input_response
      IMPORTING !key          TYPE string
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_elicit_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Non-raising reader for one MRTR input response</p>
    "! Returns unbound when the key was not answered; a present but malformed
    "! answer still raises, as get_input_response does.
    "! @parameter key                  | The input-request key the client answered under
    "! @parameter result               | Reader over the answer, or unbound when absent
    "! @raising   zcx_mcp2_error       | Present answer is invalid
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS try_get_input_response
      IMPORTING !key          TYPE string
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_elicit_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    "! <p class="shorttext synchronized">Member names of an array argument</p>
    "! Empty when the argument is absent or is not an array, so the typed
    "! array readers all degrade to an empty table.
    "! @parameter name   | Argument name (no leading slash)
    "! @parameter result | Array member names, empty when not an array
    METHODS array_members
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string_table.

    DATA name            TYPE string.
    DATA arguments       TYPE REF TO zif_mcp2_ajson.
    DATA args_set        TYPE abap_bool.
    DATA request_state   TYPE string.
    DATA retry           TYPE abap_bool.
    DATA input_responses TYPE REF TO zif_mcp2_ajson.
    DATA input_resp_set  TYPE abap_bool.
    DATA meta            TYPE REF TO zif_mcp2_ajson.
    DATA task_req        TYPE abap_bool.
    DATA task_ttl_ms     TYPE i.

ENDCLASS.


CLASS zcl_mcp2_req_call_tool IMPLEMENTATION.
  METHOD constructor.
    IF json->exists( '/name' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `tools/call: name is required` ) ##NO_TEXT.
    ENDIF.
    IF json->get_node_type( '/name' ) <> zif_mcp2_ajson_types=>node_type-string.
      zcx_mcp2_error=>raise_invalid_params( `tools/call: name must be a string` ) ##NO_TEXT.
    ENDIF.
    name = json->get_string( '/name' ).
    IF name IS INITIAL.
      zcx_mcp2_error=>raise_invalid_params( `tools/call: name must not be empty` ) ##NO_TEXT.
    ENDIF.

    IF json->exists( '/arguments' ).
      IF json->get_node_type( '/arguments' )
         <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_invalid_params( `tools/call: arguments must be an object` ) ##NO_TEXT.
      ENDIF.
      arguments = json->slice( '/arguments' ).
      args_set  = abap_true.
    ENDIF.

    IF json->exists( '/requestState' ).
      IF json->get_node_type( '/requestState' )
         <> zif_mcp2_ajson_types=>node_type-string.
        zcx_mcp2_error=>raise_invalid_params( `tools/call: requestState must be a string` ) ##NO_TEXT.
      ENDIF.
      request_state = json->get_string( '/requestState' ).
      retry = abap_true.
    ENDIF.

    IF json->exists( '/inputResponses' ).
      IF json->get_node_type( '/inputResponses' )
         <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_invalid_params( `tools/call: inputResponses must be an object` ) ##NO_TEXT.
      ENDIF.
      input_responses = json->slice( '/inputResponses' ).
      input_resp_set  = abap_true.
      retry           = abap_true.
    ENDIF.

    " Legacy (2025-11-25) per-request task opt-in: params.task with optional ttl (ms).
    IF json->exists( '/task' ).
      task_req = abap_true.
      IF json->exists( '/task/ttl' ).
        IF json->get_node_type( '/task/ttl' )
           <> zif_mcp2_ajson_types=>node_type-number.
          zcx_mcp2_error=>raise_invalid_params(
            `tools/call: task.ttl must be a non-negative integer` ) ##NO_TEXT.
        ENDIF.
        task_ttl_ms = zcl_mcp2_task_util=>parse_milliseconds(
          json->get( '/task/ttl' ) ).
      ENDIF.
    ENDIF.

    IF json->exists( '/_meta' ).
      meta = json->slice( '/_meta' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_name.
    result = name.
  ENDMETHOD.

  METHOD has_arguments.
    result = args_set.
  ENDMETHOD.

  METHOD get_arguments.
    result = arguments.
  ENDMETHOD.

  METHOD is_retry.
    result = retry.
  ENDMETHOD.

  METHOD has_task_request.
    result = task_req.
  ENDMETHOD.

  METHOD get_task_ttl_ms.
    result = task_ttl_ms.
  ENDMETHOD.

  METHOD get_request_state.
    result = request_state.
  ENDMETHOD.

  METHOD has_input_responses.
    result = input_resp_set.
  ENDMETHOD.

  METHOD get_input_responses.
    result = input_responses.
  ENDMETHOD.

  METHOD get_meta.
    result = meta.
  ENDMETHOD.

  METHOD has_arg.
    IF arguments IS BOUND.
      result = arguments->exists( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_string.
    IF arguments IS BOUND.
      result = arguments->get_string( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_string_or.
    IF has_arg( name ) = abap_true.
      result = get_arg_string( name ).
    ELSE.
      result = default_value.
    ENDIF.
  ENDMETHOD.

  METHOD require_arg_string.
    IF has_arg( name ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params(
        |tools/call: required argument '{ name }' is missing| ) ##NO_TEXT.
    ENDIF.
    result = get_arg_string( name ).
  ENDMETHOD.

  METHOD get_arg_integer.
    IF arguments IS BOUND.
      result = arguments->get_integer( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_integer_or.
    IF has_arg( name ) = abap_true.
      result = get_arg_integer( name ).
    ELSE.
      result = default_value.
    ENDIF.
  ENDMETHOD.

  METHOD require_arg_integer.
    IF has_arg( name ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params(
        |tools/call: required argument '{ name }' is missing| ) ##NO_TEXT.
    ENDIF.
    result = get_arg_integer( name ).
  ENDMETHOD.

  METHOD get_arg_number.
    IF arguments IS BOUND
       AND arguments->get_node_type( |/{ name }| ) = zif_mcp2_ajson_types=>node_type-number.
      " Convert from the raw JSON literal rather than ajson's binary float
      " getter, so decimals reach the handler unrounded. Restricting this to
      " number nodes means the literal is parser-guaranteed numeric, so no
      " conversion guard is needed.
      result = arguments->get( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_number_or.
    IF has_arg( name ) = abap_true.
      result = get_arg_number( name ).
    ELSE.
      result = default_value.
    ENDIF.
  ENDMETHOD.

  METHOD require_arg_number.
    IF has_arg( name ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params(
        |tools/call: required argument '{ name }' is missing| ) ##NO_TEXT.
    ENDIF.
    result = get_arg_number( name ).
  ENDMETHOD.

  METHOD get_arg_string_table.
    IF has_arg( name ) = abap_true.
      result = arguments->array_to_string_table( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_integer_table.
    " Explicitly typed: string_table returns are not inferrable by the
    " downport tooling.
    DATA members TYPE string_table.
    members = array_members( name ).
    LOOP AT members INTO DATA(member).
      APPEND arguments->get_integer( |/{ name }/{ member }| ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_arg_number_table.
    DATA num TYPE decfloat34.
    " Explicitly typed: string_table returns are not inferrable by the
    " downport tooling.
    DATA members TYPE string_table.
    members = array_members( name ).
    LOOP AT members INTO DATA(member).
      DATA(item_path) = |/{ name }/{ member }|.
      CLEAR num.
      " Same rule as get_arg_number: convert from the raw literal, and only
      " for real JSON numbers.
      IF arguments->get_node_type( item_path ) = zif_mcp2_ajson_types=>node_type-number.
        num = arguments->get( item_path ).
      ENDIF.
      APPEND num TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_arg_boolean_table.
    " Explicitly typed: string_table returns are not inferrable by the
    " downport tooling.
    DATA members TYPE string_table.
    members = array_members( name ).
    LOOP AT members INTO DATA(member).
      APPEND arguments->get_boolean( |/{ name }/{ member }| ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD array_members.
    IF arguments IS BOUND
       AND arguments->get_node_type( |/{ name }| ) = zif_mcp2_ajson_types=>node_type-array.
      result = arguments->members( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_boolean.
    IF arguments IS BOUND.
      result = arguments->get_boolean( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_arg_boolean_or.
    IF has_arg( name ) = abap_true.
      result = get_arg_boolean( name ).
    ELSE.
      result = default_value.
    ENDIF.
  ENDMETHOD.

  METHOD require_arg_boolean.
    IF has_arg( name ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params(
        |tools/call: required argument '{ name }' is missing| ) ##NO_TEXT.
    ENDIF.
    result = get_arg_boolean( name ).
  ENDMETHOD.

  METHOD get_arg_json.
    IF has_arg( name ) = abap_true.
      result = arguments->slice( |/{ name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD bind_arguments.
    IF arguments IS BOUND.
      arguments->to_abap( EXPORTING iv_corresponding = abap_true
                          IMPORTING ev_container     = target ).
    ENDIF.
  ENDMETHOD.

  METHOD get_input_response.
    IF input_responses IS NOT BOUND OR input_responses->exists( |/{ key }| ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params(
        |No input response for key { key }| ) ##NO_TEXT.
    ENDIF.
    result = NEW zcl_mcp2_elicit_result( input_responses->slice( |/{ key }| ) ).
  ENDMETHOD.

  METHOD try_get_input_response.
    IF input_responses IS NOT BOUND OR input_responses->exists( |/{ key }| ) = abap_false.
      RETURN.
    ENDIF.
    result = get_input_response( key ).
  ENDMETHOD.

ENDCLASS.
