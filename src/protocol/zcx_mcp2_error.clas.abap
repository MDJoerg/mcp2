"! <p class="shorttext synchronized">MCP2 protocol error</p>
"! Carries a JSON-RPC error code, a human-readable reason, and optional
"! structured data. Static raise_* methods cover every spec error code so
"! callers never hard-code magic numbers.
CLASS zcx_mcp2_error DEFINITION
  PUBLIC FINAL
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA code        TYPE i          READ-ONLY.
    DATA reason      TYPE string     READ-ONLY.
    DATA err_data    TYPE REF TO zif_mcp2_ajson READ-ONLY.
    DATA http_status TYPE i          READ-ONLY.

    "! <p class="shorttext synchronized">Create a protocol error</p>
    "! @parameter error_code | JSON-RPC error code (see zif_mcp2_const)
    "! @parameter error_msg  | Human-readable reason
    "! @parameter error_data | Optional structured error data
    METHODS constructor
      IMPORTING
        error_code  TYPE i
        error_msg   TYPE string
        error_data  TYPE REF TO zif_mcp2_ajson OPTIONAL
        http_status TYPE i OPTIONAL.

    METHODS get_text REDEFINITION.

    "! <p class="shorttext synchronized">Raise -32700 ParseError</p>
    "! @raising zcx_mcp2_error | Always
    CLASS-METHODS raise_parse
      RAISING zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32600 InvalidRequest</p>
    "! @parameter message | Reason
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_invalid_req
      IMPORTING message TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32601 MethodNotFound</p>
    "! @parameter method | The unknown method name
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_method_not_found
      IMPORTING method TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32602 InvalidParams</p>
    "! @parameter message | Reason
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_invalid_params
      IMPORTING message TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32602 InvalidParams with HTTP 400</p>
    "! @parameter message | Reason
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_malformed_params
      IMPORTING message TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32603 InternalError</p>
    "! @parameter message | Reason
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_internal
      IMPORTING message TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise legacy -32002 ResourceNotFound</p>
    "! Handlers use this era-neutral signal for an unknown URI. The modern
    "! dispatcher converts it to -32602 while the legacy dispatcher preserves it.
    "! @parameter uri | The unknown resource URI
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_resource_not_found
      IMPORTING uri TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32020 HeaderMismatch (modern)</p>
    "! @parameter message | Reason
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_header_mismatch
      IMPORTING message TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32021 MissingRequiredClientCapability</p>
    "! @parameter capability | The capability the client did not declare
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_missing_cap
      IMPORTING capability TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Raise -32022 UnsupportedProtocolVersion</p>
    "! @parameter version | The unsupported protocol version
    "! @raising   zcx_mcp2_error | Always
    CLASS-METHODS raise_unsupported_ver
      IMPORTING version TYPE string
      RAISING   zcx_mcp2_error.

ENDCLASS.


CLASS zcx_mcp2_error IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    code        = error_code.
    reason      = error_msg.
    err_data    = error_data.
    me->http_status = http_status.
  ENDMETHOD.


  METHOD get_text.

    result = |[{ code }] { reason }|.

  ENDMETHOD.


  METHOD raise_parse.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-parse_error
      error_msg  = `Parse error` ) ##NO_TEXT.
  ENDMETHOD.


  METHOD raise_invalid_req.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-invalid_request
      error_msg  = message ).
  ENDMETHOD.


  METHOD raise_method_not_found.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-method_not_found
      error_msg  = |Method not found: { method }| ) ##NO_TEXT.
  ENDMETHOD.


  METHOD raise_invalid_params.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-invalid_params
      error_msg  = message ).
  ENDMETHOD.


  METHOD raise_malformed_params.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code  = zif_mcp2_const=>error_codes-invalid_params
      error_msg   = message
      http_status = 400 ).
  ENDMETHOD.


  METHOD raise_internal.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-internal_error
      error_msg  = message ).
  ENDMETHOD.


  METHOD raise_resource_not_found.
    " The spec's ResourceNotFound error carries the requested URI in data.uri.
    DATA err_data TYPE REF TO zif_mcp2_ajson.
    TRY.
        err_data = zcl_mcp2_ajson=>create_empty( ).
        err_data->set_string( iv_path = '/uri'
                              iv_val  = uri ).
      CATCH zcx_mcp2_ajson_error.
        CLEAR err_data.
    ENDTRY.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-resource_not_found
      error_msg  = |Resource not found: { uri }|
      error_data = err_data ) ##NO_TEXT.
  ENDMETHOD.


  METHOD raise_header_mismatch.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-header_mismatch
      error_msg  = message ).
  ENDMETHOD.


  METHOD raise_missing_cap.
    " data.requiredCapabilities is a ClientCapabilities-shaped object per the
    " MissingRequiredClientCapabilityError schema, not a bare string.
    DATA err_data TYPE REF TO zif_mcp2_ajson.
    TRY.
        err_data = zcl_mcp2_ajson=>parse( '{"requiredCapabilities":{}}' ).
        DATA cap_path TYPE string.
        cap_path = `/requiredCapabilities`.
        DATA segments TYPE string_table.
        SPLIT capability AT `/` INTO TABLE segments.
        LOOP AT segments INTO DATA(segment).
          IF segment IS INITIAL.
            CONTINUE.
          ENDIF.
          " The extension name contains a literal slash in a JSON member
          " name. ajson uses TAB as its path escape for that one case.
          DATA task_segment TYPE string.
          READ TABLE segments WITH KEY table_line = `tasks` INTO task_segment.
          IF sy-subrc = 0
             AND segment = `io.modelcontextprotocol`
             AND task_segment = `tasks`.
            cap_path = |{ cap_path }/io.modelcontextprotocol|
                       && cl_abap_char_utilities=>horizontal_tab
                       && `tasks`.
            EXIT.
          ENDIF.
          cap_path = |{ cap_path }/{ segment }|.
        ENDLOOP.
        err_data->set( iv_path = cap_path
                       iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
      CATCH zcx_mcp2_ajson_error.
        CLEAR err_data.
    ENDTRY.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-missing_client_cap
      error_msg  = |Missing client capability: { capability }|
      error_data = err_data ) ##NO_TEXT.
  ENDMETHOD.


  METHOD raise_unsupported_ver.
    DATA err_data TYPE REF TO zif_mcp2_ajson.
    TRY.
        err_data = zcl_mcp2_ajson=>create_empty( ).
        err_data->set_string( iv_path = '/requested' iv_val = version ).
        err_data->touch_array( '/supported' ).
        err_data->push( iv_path = '/supported' iv_val = zif_mcp2_const=>protocol-v2025_03_26 ).
        err_data->push( iv_path = '/supported' iv_val = zif_mcp2_const=>protocol-v2025_06_18 ).
        err_data->push( iv_path = '/supported' iv_val = zif_mcp2_const=>protocol-v2025_11_25 ).
        err_data->push( iv_path = '/supported' iv_val = zif_mcp2_const=>protocol-v2026_07_28 ).
      CATCH zcx_mcp2_ajson_error.
        CLEAR err_data.
    ENDTRY.
    RAISE EXCEPTION NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-unsupported_version
      error_msg  = |Unsupported protocol version: { version }|
      error_data = err_data ) ##NO_TEXT.
  ENDMETHOD.

ENDCLASS.
