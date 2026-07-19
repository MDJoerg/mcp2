"! <p class="shorttext synchronized">MCP2 input_required result (MRTR)</p>
"! Return this from a handler instead of a complete result to ask the
"! client for more input. Set requestState to an opaque token the server
"! will receive back in the follow-up call; use inputRequests to describe
"! what input is needed (method + params per named key).
CLASS zcl_mcp2_resp_input_req DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES: BEGIN OF input_request,
             request_key TYPE string,
             method      TYPE string,
             params      TYPE REF TO zif_mcp2_ajson,
           END OF input_request.
    TYPES input_request_list TYPE STANDARD TABLE OF input_request WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Set the opaque continuation token (MRTR)</p>
    "! The client echoes this back on the follow-up request.
    "! @parameter state | Opaque request-state token
    "! @parameter self  | This instance, for chaining
    METHODS set_request_state
      IMPORTING !state      TYPE string
      RETURNING VALUE(self) TYPE REF TO zcl_mcp2_resp_input_req.

    "! <p class="shorttext synchronized">Describe one piece of required input (MRTR)</p>
    "! @parameter request_key | Server-chosen key the client answers under
    "! @parameter method      | Input method (sampling / elicitation)
    "! @parameter params      | Optional method-specific parameters
    "! @raising   zcx_mcp2_error | request_key is empty or not path-safe
    METHODS add_input_request
      IMPORTING request_key TYPE string
                !method     TYPE string
                params      TYPE REF TO zif_mcp2_ajson OPTIONAL
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Add a required input from a typed builder (MRTR)</p>
    "! Preferred over add_input_request - the builder supplies method + params.
    "! @parameter request_key | Server-chosen key the client answers under
    "! @parameter input       | Elicitation / sampling builder
    "! @parameter self        | This instance, for chaining
    "! @raising   zcx_mcp2_ajson_error | params build failure
    "! @raising   zcx_mcp2_error       | request_key is empty or not path-safe
    METHODS add_request
      IMPORTING request_key   TYPE string
                input         TYPE REF TO zif_mcp2_input_request
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_resp_input_req
      RAISING   zcx_mcp2_ajson_error
                zcx_mcp2_error.

  PRIVATE SECTION.
    DATA request_state TYPE string.
    DATA requests      TYPE input_request_list.

ENDCLASS.


CLASS zcl_mcp2_resp_input_req IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).

    IF request_state IS NOT INITIAL.
      result->set_string( iv_path = '/requestState'
                          iv_val  = request_state ).
    ENDIF.

    IF requests IS NOT INITIAL.
      result->set( iv_path = '/inputRequests'
                   iv_val  = zcl_mcp2_ajson=>create_empty( ) ).
      LOOP AT requests ASSIGNING FIELD-SYMBOL(<r>).
        DATA(rp) = |/inputRequests/{ <r>-request_key }|.
        result->set_string( iv_path = |{ rp }/method|
                            iv_val  = <r>-method ).
        IF <r>-params IS BOUND.
          result->set( iv_path = |{ rp }/params|
                       iv_val  = <r>-params ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-input_required.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
    result = 0.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    result = `private`.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    " Not a spec CacheableResult - never stamped with ttlMs/cacheScope.
  ENDMETHOD.

  METHOD set_request_state.
    request_state = state.
    self = me.
  ENDMETHOD.

  METHOD add_input_request.
    " Keys become ajson path segments - a '/' (or the tab escape) would
    " silently corrupt the inputRequests object.
    IF request_key IS INITIAL
       OR request_key CA '/'
       OR request_key CA cl_abap_char_utilities=>horizontal_tab.
      zcx_mcp2_error=>raise_internal(
        |Invalid input request key: '{ request_key }'| ) ##NO_TEXT.
    ENDIF.
    APPEND VALUE #( request_key = request_key
                    method      = method
                    params      = params ) TO requests.
  ENDMETHOD.

  METHOD add_request.
    add_input_request( request_key = request_key
                       method      = input->get_method( )
                       params      = input->get_params( ) ).
    self = me.
  ENDMETHOD.
ENDCLASS.
