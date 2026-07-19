"! <p class="shorttext synchronized">MCP2 JSON-RPC 2.0 envelope</p>
"! All methods are class-methods - no instance state.
"! Handles parse/serialize only; dispatching is in zcl_mcp2_dispatch_*.
"! Batches are not supported (removed from the MCP spec).
CLASS zcl_mcp2_jsonrpc DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF rpc_error,
             code    TYPE i,
             message TYPE string,
             data    TYPE REF TO zif_mcp2_ajson,
           END OF rpc_error.

    TYPES: BEGIN OF request,
             jsonrpc    TYPE string,
             method     TYPE string,
             params     TYPE REF TO zif_mcp2_ajson,
             id         TYPE string,
             id_present TYPE abap_bool,
             id_is_num  TYPE abap_bool,
           END OF request.

    TYPES: BEGIN OF response,
             jsonrpc    TYPE string,
             result     TYPE REF TO zif_mcp2_ajson,
             error      TYPE rpc_error,
             id         TYPE string,
             id_present TYPE abap_bool,
             id_is_null TYPE abap_bool,
             id_is_num  TYPE abap_bool,
             http_status TYPE i,
           END OF response.

    "! <p class="shorttext synchronized">Parse a JSON string into a request struct</p>
    "! Raises parse_error when the JSON is malformed and invalid_request when a
    "! required field is missing or has the wrong type.
    "! @parameter json           | Raw JSON-RPC request text
    "! @parameter result         | Parsed request struct
    "! @raising   zcx_mcp2_error | Malformed JSON or invalid request
    CLASS-METHODS parse_request
      IMPORTING !json         TYPE string
      RETURNING VALUE(result) TYPE request
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Serialize a response struct to JSON</p>
    "! @parameter response             | Response struct to serialize
    "! @parameter result               | JSON-RPC response text
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    CLASS-METHODS serialize_response
      IMPORTING !response     TYPE response
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build a success response</p>
    "! Copies the id (and its wire type) from the request.
    "! @parameter request     | Originating request
    "! @parameter result_json | Result payload placed under /result
    "! @parameter result      | Success response struct
    CLASS-METHODS build_success
      IMPORTING !request      TYPE request
                result_json   TYPE REF TO zif_mcp2_ajson OPTIONAL
      RETURNING VALUE(result) TYPE response.

    "! <p class="shorttext synchronized">Build an error response</p>
    "! Copies the id (and its wire type) from the request.
    "! @parameter request | Originating request
    "! @parameter code    | JSON-RPC error code
    "! @parameter message | Error message
    "! @parameter data    | Optional error data
    "! @parameter result  | Error response struct
    CLASS-METHODS build_error
      IMPORTING !request      TYPE request
                !code         TYPE i
                !message      TYPE string
                !data         TYPE REF TO zif_mcp2_ajson OPTIONAL
      RETURNING VALUE(result) TYPE response.

    "! <p class="shorttext synchronized">Build an error response from an exception</p>
    "! @parameter request | Originating request
    "! @parameter exc     | The protocol exception to render
    "! @parameter result  | Error response struct (with http_status)
    CLASS-METHODS build_from_exc
      IMPORTING !request      TYPE request
                exc           TYPE REF TO zcx_mcp2_error
      RETURNING VALUE(result) TYPE response.

    "! <p class="shorttext synchronized">Whether a request is a notification</p>
    "! Fire-and-forget requests carry no id field.
    "! @parameter request | Request to test
    "! @parameter result  | abap_true when the request has no id
    CLASS-METHODS is_notification
      IMPORTING !request      TYPE request
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! <p class="shorttext synchronized">Write an id preserving string vs numeric form</p>
    "! @parameter json_obj             | Target JSON object
    "! @parameter path                 | Path to write the id at
    "! @parameter id                   | id value as a string
    "! @parameter is_num               | abap_true to emit a JSON number, else a string
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    CLASS-METHODS write_id
      IMPORTING json_obj TYPE REF TO zif_mcp2_ajson
                !path    TYPE string
                !id      TYPE string
                is_num   TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Whether a JSON-RPC numeric id is an integer token</p>
    "! @parameter id     | Raw numeric id text
    "! @parameter result | abap_true when the token is an integer
    CLASS-METHODS is_integer_id
      IMPORTING !id           TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS zcl_mcp2_jsonrpc IMPLEMENTATION.
  METHOD parse_request.
    DATA json_obj TYPE REF TO zif_mcp2_ajson.

    TRY.
        json_obj = zcl_mcp2_ajson=>parse( json ).
      CATCH zcx_mcp2_ajson_error.
        zcx_mcp2_error=>raise_parse( ).
    ENDTRY.

    IF json_obj->get_node_type( '/' ) <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_invalid_req(
        `JSON-RPC request root must be an object` ) ##NO_TEXT.
    ENDIF.

    TRY.
        result-jsonrpc = json_obj->get_string( '/jsonrpc' ).
      CATCH zcx_mcp2_ajson_error.
        zcx_mcp2_error=>raise_invalid_req( `Missing jsonrpc field` ) ##NO_TEXT.
    ENDTRY.

    IF json_obj->get_node_type( '/jsonrpc' ) <> zif_mcp2_ajson_types=>node_type-string
       OR result-jsonrpc <> zif_mcp2_const=>jsonrpc_version.
      zcx_mcp2_error=>raise_invalid_req( |Invalid JSON-RPC version: { result-jsonrpc }| ) ##NO_TEXT.
    ENDIF.

    IF json_obj->exists( '/method' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_req( `Missing method field` ) ##NO_TEXT.
    ENDIF.

    IF json_obj->get_node_type( '/method' ) <> zif_mcp2_ajson_types=>node_type-string.
      zcx_mcp2_error=>raise_invalid_req( `JSON-RPC method must be a string` ) ##NO_TEXT.
    ENDIF.
    result-method = json_obj->get_string( '/method' ).
    IF result-method IS INITIAL.
      zcx_mcp2_error=>raise_invalid_req( `Empty method field` ) ##NO_TEXT.
    ENDIF.

    IF json_obj->exists( '/params' ).
      IF json_obj->get_node_type( '/params' ) <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_invalid_params(
          `JSON-RPC params must be an object when present` ) ##NO_TEXT.
      ENDIF.
      result-params = json_obj->slice( '/params' ).
    ELSE.
      result-params = zcl_mcp2_ajson=>create_empty( ).
    ENDIF.

    IF result-method = zif_mcp2_const=>methods-tools_call
       AND result-params->exists( '/arguments' )
       AND result-params->get_node_type( '/arguments' )
           <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_invalid_params(
        `tools/call arguments must be an object when present` ) ##NO_TEXT.
    ENDIF.

    result-id_present = xsdbool( json_obj->exists( '/id' ) ).
    IF result-id_present = abap_true.
      " Preserve the wire type: a string id must be echoed as a string and a
      " numeric id as a number, so the client can correlate the response.
      CASE json_obj->get_node_type( '/id' ).
        WHEN zif_mcp2_ajson_types=>node_type-number.
          result-id_is_num = abap_true.
          result-id        = json_obj->get_string( '/id' ).
          IF is_integer_id( result-id ) = abap_false.
            zcx_mcp2_error=>raise_invalid_req(
                `JSON-RPC id must be a string or integer (fractional numbers are not permitted)` ) ##NO_TEXT.
          ENDIF.
        WHEN zif_mcp2_ajson_types=>node_type-string.
          result-id        = json_obj->get_string( '/id' ).
        WHEN OTHERS.
          zcx_mcp2_error=>raise_invalid_req(
              `JSON-RPC id must be a string or integer (null and other types are not permitted)` ) ##NO_TEXT.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD serialize_response.
    DATA json_obj TYPE REF TO zif_mcp2_ajson.

    json_obj = zcl_mcp2_ajson=>create_empty( ).

    json_obj->set_string( iv_path = '/jsonrpc'
                          iv_val  = zif_mcp2_const=>jsonrpc_version ).

    IF response-error-code <> 0 OR response-error-message IS NOT INITIAL.
      json_obj->set_integer( iv_path = '/error/code'
                             iv_val  = response-error-code ).
      json_obj->set_string( iv_path = '/error/message'
                            iv_val  = response-error-message ).
      IF response-error-data IS BOUND.
        DATA(err_data_json) = response-error-data->stringify( ).
        json_obj->set( iv_path = '/error/data'
                       iv_val  = zcl_mcp2_ajson=>parse( err_data_json ) ).
      ENDIF.
    ELSEIF response-result IS BOUND.
      DATA(result_str) = response-result->stringify( ).
      json_obj->set( iv_path = '/result'
                     iv_val  = zcl_mcp2_ajson=>parse( result_str ) ).
    ELSE.
      json_obj->set( iv_path = '/result'
                     iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.

    " MCP TS SDK accepts absent, string, or number id - never null.
    IF response-id_present = abap_true AND response-id_is_null = abap_false.
      write_id( json_obj = json_obj
                path     = '/id'
                id       = response-id
                is_num   = response-id_is_num ).
    ENDIF.

    result = json_obj->stringify( ).
  ENDMETHOD.

  METHOD build_success.
    result-jsonrpc    = zif_mcp2_const=>jsonrpc_version.
    result-id         = request-id.
    result-id_present = request-id_present.
    result-id_is_num  = request-id_is_num.
    " parse_request rejects null ids; an empty string id is valid and must be echoed.
    result-id_is_null = abap_false.
    IF result_json IS SUPPLIED AND result_json IS BOUND.
      result-result = result_json.
    ENDIF.
  ENDMETHOD.

  METHOD build_error.
    result-jsonrpc    = zif_mcp2_const=>jsonrpc_version.
    result-id         = request-id.
    result-id_present = request-id_present.
    result-id_is_num  = request-id_is_num.
    " parse_request rejects null ids; an empty string id is valid and must be echoed.
    result-id_is_null = abap_false.
    result-error-code    = code.
    result-error-message = message.
    IF data IS SUPPLIED AND data IS BOUND.
      result-error-data = data.
    ENDIF.
  ENDMETHOD.

  METHOD build_from_exc.
    result = build_error( request = request
                          code    = exc->code
                          message = exc->reason
                          data    = exc->err_data ).
    result-http_status = exc->http_status.
  ENDMETHOD.

  METHOD is_notification.
    result = xsdbool( request-id_present = abap_false ).
  ENDMETHOD.

  METHOD write_id.
    " Echo the id with the exact wire type the client sent. Numeric ids are
    " written as a raw JSON number (node type 'num') straight from the original
    " text, so arbitrary-precision ids survive without an ABAP integer round-trip.
    IF is_num = abap_true.
      json_obj->set( iv_path      = path
                     iv_val       = id
                     iv_node_type = zif_mcp2_ajson_types=>node_type-number ).
    ELSE.
      json_obj->set_string( iv_path = path
                            iv_val  = id ).
    ENDIF.
  ENDMETHOD.

  METHOD is_integer_id.
    FIND REGEX '^-?[0-9]+$' IN id.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

ENDCLASS.
