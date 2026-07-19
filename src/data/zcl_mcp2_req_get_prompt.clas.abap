"! <p class="shorttext synchronized">MCP2 prompts/get request</p>
"! Supports MRTR the same way as tools/call.
CLASS zcl_mcp2_req_get_prompt DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF prompt_arg,
             name  TYPE string,
             value TYPE string,
           END OF prompt_arg.
    TYPES prompt_args TYPE STANDARD TABLE OF prompt_arg WITH KEY name.

    "! <p class="shorttext synchronized">Parse a prompts/get params object</p>
    "! @parameter json                 | The params slice of the JSON-RPC request
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    "! @raising   zcx_mcp2_error       | Missing/invalid required field
    METHODS constructor
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error
                zcx_mcp2_error.

    "! <p class="shorttext synchronized">Prompt name to retrieve</p>
    "! @parameter result | Prompt name
    METHODS get_name
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether arguments were supplied</p>
    "! @parameter result | abap_true when an arguments object is present
    METHODS has_arguments
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Prompt arguments as name/value pairs</p>
    "! @parameter result | Table of argument name/value pairs
    METHODS get_arguments
      RETURNING VALUE(result) TYPE prompt_args.

    "! <p class="shorttext synchronized">Whether a named argument is present</p>
    "! @parameter name   | Argument name
    "! @parameter result | abap_true when the argument exists
    METHODS has_arg
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Read a string argument by name</p>
    "! Returns an empty string when the argument is absent. Mirrors
    "! zcl_mcp2_req_call_tool=>get_arg_string for consistent ergonomics.
    "! @parameter name   | Argument name
    "! @parameter result | Argument value, empty when absent
    METHODS get_arg_string
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Read a string argument or a default</p>
    "! @parameter name          | Argument name
    "! @parameter default_value | Value returned when the argument is absent
    "! @parameter result        | Argument value, or default_value when absent
    METHODS get_arg_string_or
      IMPORTING !name         TYPE string
                default_value TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Read a required string argument</p>
    "! Raises InvalidParams when the argument is absent.
    "! @parameter name          | Argument name
    "! @parameter result        | Argument value
    "! @raising   zcx_mcp2_error | Argument is absent
    METHODS require_arg_string
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Whether this call is an MRTR retry</p>
    "! True when the client sent requestState and/or inputResponses - either
    "! marks the call as the retry leg of an input_required round-trip.
    "! @parameter result | abap_true when this is a retry leg
    METHODS is_retry
      RETURNING VALUE(result) TYPE abap_bool.

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

    "! <p class="shorttext synchronized">Typed reader for one MRTR input response (MRTR)</p>
    "! Mirrors zcl_mcp2_req_call_tool=>get_input_response.
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

    "! <p class="shorttext synchronized">The request _meta object</p>
    "! @parameter result | The _meta object, or unbound when absent
    METHODS get_meta
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

  PRIVATE SECTION.
    DATA name            TYPE string.
    DATA arguments       TYPE prompt_args.
    DATA args_set        TYPE abap_bool.
    DATA request_state   TYPE string.
    DATA retry           TYPE abap_bool.
    DATA input_responses TYPE REF TO zif_mcp2_ajson.
    DATA input_resp_set  TYPE abap_bool.
    DATA meta            TYPE REF TO zif_mcp2_ajson.

ENDCLASS.


CLASS zcl_mcp2_req_get_prompt IMPLEMENTATION.
  METHOD constructor.
    IF json->exists( '/name' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `prompts/get: name is required` ) ##NO_TEXT.
    ENDIF.
    IF json->get_node_type( '/name' ) <> zif_mcp2_ajson_types=>node_type-string.
      zcx_mcp2_error=>raise_invalid_params( `prompts/get: name must be a string` ) ##NO_TEXT.
    ENDIF.
    name = json->get_string( '/name' ).
    IF name IS INITIAL.
      zcx_mcp2_error=>raise_invalid_params( `prompts/get: name must not be empty` ) ##NO_TEXT.
    ENDIF.

    IF json->exists( '/arguments' ).
      IF json->get_node_type( '/arguments' )
         <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_invalid_params( `prompts/get: arguments must be an object` ) ##NO_TEXT.
      ENDIF.
      args_set = abap_true.
      DATA(args_node) = json->slice( '/arguments' ).
      " Keep method-call results explicitly typed for ABAP 7.02 downport compatibility.
      DATA members TYPE string_table.
      members = args_node->members( '/' ).
      LOOP AT members INTO DATA(member).
        IF args_node->get_node_type( |/{ member }| )
           <> zif_mcp2_ajson_types=>node_type-string.
          zcx_mcp2_error=>raise_invalid_params(
            |prompts/get: argument '{ member }' must be a string| ) ##NO_TEXT.
        ENDIF.
        APPEND VALUE #( name  = member
                        value = args_node->get_string( |/{ member }| ) ) TO arguments.
      ENDLOOP.
    ENDIF.

    IF json->exists( '/requestState' ).
      IF json->get_node_type( '/requestState' )
         <> zif_mcp2_ajson_types=>node_type-string.
        zcx_mcp2_error=>raise_invalid_params( `prompts/get: requestState must be a string` ) ##NO_TEXT.
      ENDIF.
      request_state = json->get_string( '/requestState' ).
      retry = abap_true.
    ENDIF.

    IF json->exists( '/inputResponses' ).
      IF json->get_node_type( '/inputResponses' )
         <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_invalid_params( `prompts/get: inputResponses must be an object` ) ##NO_TEXT.
      ENDIF.
      input_responses = json->slice( '/inputResponses' ).
      input_resp_set  = abap_true.
      retry           = abap_true.
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

  METHOD has_arg.
    result = xsdbool( line_exists( arguments[ name = name ] ) ).
  ENDMETHOD.

  METHOD get_arg_string.
    READ TABLE arguments WITH TABLE KEY name = name INTO DATA(arg).
    IF sy-subrc = 0.
      result = arg-value.
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
        |prompts/get: required argument '{ name }' is missing| ) ##NO_TEXT.
    ENDIF.
    result = get_arg_string( name ).
  ENDMETHOD.

  METHOD is_retry.
    result = retry.
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

  METHOD get_meta.
    result = meta.
  ENDMETHOD.

ENDCLASS.
