"! <p class="shorttext synchronized">MCP2 resources/read request</p>
"! Supports MRTR the same way as tools/call - resources/read is one of the
"! three methods that may answer with an input_required result.
CLASS zcl_mcp2_req_read_resource DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Parse a resources/read params object</p>
    "! @parameter json                 | The params slice of the JSON-RPC request
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    "! @raising   zcx_mcp2_error       | Missing/invalid required field
    METHODS constructor
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error
                zcx_mcp2_error.

    "! <p class="shorttext synchronized">URI of the resource to read</p>
    "! @parameter result | Resource URI
    METHODS get_uri
      RETURNING VALUE(result) TYPE string.

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
    DATA uri             TYPE string.
    DATA meta            TYPE REF TO zif_mcp2_ajson.
    DATA request_state   TYPE string.
    DATA retry           TYPE abap_bool.
    DATA input_responses TYPE REF TO zif_mcp2_ajson.
    DATA input_resp_set  TYPE abap_bool.

ENDCLASS.


CLASS zcl_mcp2_req_read_resource IMPLEMENTATION.
  METHOD constructor.
    IF json->exists( '/uri' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `resources/read: uri is required` ) ##NO_TEXT.
    ENDIF.
    IF json->get_node_type( '/uri' ) <> zif_mcp2_ajson_types=>node_type-string.
      zcx_mcp2_error=>raise_invalid_params( `resources/read: uri must be a string` ) ##NO_TEXT.
    ENDIF.
    uri = json->get_string( '/uri' ).
    IF uri IS INITIAL.
      zcx_mcp2_error=>raise_invalid_params( `resources/read: uri must not be empty` ) ##NO_TEXT.
    ENDIF.

    IF json->exists( '/requestState' ).
      IF json->get_node_type( '/requestState' )
         <> zif_mcp2_ajson_types=>node_type-string.
        zcx_mcp2_error=>raise_invalid_params( `resources/read: requestState must be a string` ) ##NO_TEXT.
      ENDIF.
      request_state = json->get_string( '/requestState' ).
      retry = abap_true.
    ENDIF.

    IF json->exists( '/inputResponses' ).
      IF json->get_node_type( '/inputResponses' )
         <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_invalid_params( `resources/read: inputResponses must be an object` ) ##NO_TEXT.
      ENDIF.
      input_responses = json->slice( '/inputResponses' ).
      input_resp_set  = abap_true.
      retry           = abap_true.
    ENDIF.

    IF json->exists( '/_meta' ).
      meta = json->slice( '/_meta' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_uri.
    result = uri.
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
