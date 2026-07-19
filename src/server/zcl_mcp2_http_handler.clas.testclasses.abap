CLASS ltcl_http_handler DEFINITION DEFERRED.
CLASS zcl_mcp2_http_handler DEFINITION LOCAL FRIENDS ltcl_http_handler.

CLASS ltcl_http_handler DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA handler TYPE REF TO zcl_mcp2_http_handler.

    METHODS setup.
    METHODS test_path_short            FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_path_with_prefix      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_path_invalid          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_classify_request      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_classify_notification FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_classify_batch        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_classify_parse_error  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_options_headers       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_http_headers_ok       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_http_headers_ct_bad   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_http_headers_accept_bad FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_http_headers_media_tokens FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_status_modern_404     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_status_legacy_200     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_method_not_allowed    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_cors_headers_set      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_cors_headers_no_origin FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_send_json_error       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_origin_allowed_empty  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_dispatch_req_legacy   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_dispatch_req_modern   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_mock_request DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_request.

    DATA headers  TYPE string_table.
    DATA hdr_vals TYPE string_table.
ENDCLASS.

CLASS ltcl_mock_request IMPLEMENTATION.
  METHOD zif_mcp2_http_request~get_method.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_path.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_body.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_origin.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header.
    DATA idx TYPE i.

    LOOP AT headers INTO DATA(h) WHERE table_line = name.
      idx = sy-tabix.
      READ TABLE hdr_vals INDEX idx INTO result.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header_names.
    result = headers.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_mock_response DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_response.

    DATA status       TYPE i.
    DATA content_type TYPE string.
    DATA body         TYPE string.
    DATA hdr_names    TYPE string_table.
    DATA hdr_vals     TYPE string_table.

    METHODS get_header
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string.
ENDCLASS.

CLASS ltcl_mock_response IMPLEMENTATION.
  METHOD zif_mcp2_http_response~set_status.
    status = code.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_header.
    APPEND name  TO hdr_names.
    APPEND value TO hdr_vals.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_content_type.
    me->content_type = content_type.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_body.
    me->body = body.
  ENDMETHOD.

  METHOD get_header.
    DATA idx TYPE i.
    LOOP AT hdr_names INTO DATA(h) WHERE table_line = name.
      idx = sy-tabix.
      READ TABLE hdr_vals INDEX idx INTO result.
      RETURN.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


"! Minimal server for dispatch_request's era-routing test - ping is served
"! by the legacy dispatcher but explicitly removed by the modern one, which
"! makes the two branches distinguishable without any DB dependency.
CLASS ltcl_dispatch_test_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name    REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.
ENDCLASS.

CLASS ltcl_dispatch_test_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `DispatchReqServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_http_handler IMPLEMENTATION.
  METHOD setup.
    handler = NEW zcl_mcp2_http_handler( ).
  ENDMETHOD.

  METHOD test_path_short.
    DATA area   TYPE string.
    DATA server TYPE string.
    DATA valid  TYPE abap_bool.

    handler->parse_mcp_path( EXPORTING path   = '/demo/basic'
                             IMPORTING area   = area
                                       server = server
                                       valid  = valid ).

    cl_abap_unit_assert=>assert_true( valid ).
    cl_abap_unit_assert=>assert_equals( exp = `demo`
                                        act = area ).
    cl_abap_unit_assert=>assert_equals( exp = `basic`
                                        act = server ).
  ENDMETHOD.

  METHOD test_path_with_prefix.
    DATA area   TYPE string.
    DATA server TYPE string.
    DATA valid  TYPE abap_bool.

    handler->parse_mcp_path( EXPORTING path   = '/mcp/demo/basic/'
                             IMPORTING area   = area
                                       server = server
                                       valid  = valid ).

    cl_abap_unit_assert=>assert_true( valid ).
    cl_abap_unit_assert=>assert_equals( exp = `demo`
                                        act = area ).
    cl_abap_unit_assert=>assert_equals( exp = `basic`
                                        act = server ).
  ENDMETHOD.

  METHOD test_path_invalid.
    DATA area   TYPE string.
    DATA server TYPE string.
    DATA valid  TYPE abap_bool.

    handler->parse_mcp_path( EXPORTING path   = '/mcp/demo/basic/extra'
                             IMPORTING area   = area
                                       server = server
                                       valid  = valid ).

    cl_abap_unit_assert=>assert_false( valid ).
  ENDMETHOD.

  METHOD test_classify_request.
    DATA has_request  TYPE abap_bool.
    DATA has_response TYPE abap_bool.
    DATA has_notif    TYPE abap_bool.

    handler->classify_message( EXPORTING json         = `{"jsonrpc":"2.0","method":"ping","id":1}`
                               IMPORTING has_request  = has_request
                                         has_response = has_response
                                         has_notif    = has_notif ).

    cl_abap_unit_assert=>assert_true( has_request ).
    cl_abap_unit_assert=>assert_false( has_response ).
    cl_abap_unit_assert=>assert_false( has_notif ).
  ENDMETHOD.

  METHOD test_classify_notification.
    DATA has_request  TYPE abap_bool.
    DATA has_response TYPE abap_bool.
    DATA has_notif    TYPE abap_bool.

    handler->classify_message( EXPORTING json         = `{"jsonrpc":"2.0","method":"ping"}`
                               IMPORTING has_request  = has_request
                                         has_response = has_response
                                         has_notif    = has_notif ).

    cl_abap_unit_assert=>assert_false( has_request ).
    cl_abap_unit_assert=>assert_false( has_response ).
    cl_abap_unit_assert=>assert_true( has_notif ).
  ENDMETHOD.

  METHOD test_classify_batch.
    DATA has_request  TYPE abap_bool.
    DATA has_response TYPE abap_bool.
    DATA has_notif    TYPE abap_bool.
    DATA parse_error  TYPE abap_bool.

    handler->classify_message( EXPORTING json         = `[{"jsonrpc":"2.0","method":"ping","id":1}]`
                               IMPORTING has_request  = has_request
                                         has_response = has_response
                                         has_notif    = has_notif
                                         parse_error  = parse_error ).

    cl_abap_unit_assert=>assert_false( has_request ).
    cl_abap_unit_assert=>assert_false( has_response ).
    cl_abap_unit_assert=>assert_false( has_notif ).
    cl_abap_unit_assert=>assert_false( parse_error ).
  ENDMETHOD.

  METHOD test_classify_parse_error.
    DATA has_request  TYPE abap_bool.
    DATA has_response TYPE abap_bool.
    DATA has_notif    TYPE abap_bool.
    DATA parse_error  TYPE abap_bool.

    handler->classify_message( EXPORTING json         = `not-json{{{`
                               IMPORTING has_request  = has_request
                                         has_response = has_response
                                         has_notif    = has_notif
                                         parse_error  = parse_error ).

    cl_abap_unit_assert=>assert_false( has_request ).
    cl_abap_unit_assert=>assert_false( has_response ).
    cl_abap_unit_assert=>assert_false( has_notif ).
    cl_abap_unit_assert=>assert_true( parse_error ).
  ENDMETHOD.

  METHOD test_options_headers.
    DATA request  TYPE REF TO ltcl_mock_request.
    DATA response TYPE REF TO ltcl_mock_response.

    request = NEW #( ).
    response = NEW #( ).
    APPEND `Access-Control-Request-Headers` TO request->headers.
    APPEND `content-type, mcp-param-tenant` TO request->hdr_vals.

    handler->handle_options( request  = request
                             response = response
                             origin   = `https://example.test` ).

    DATA(allow_headers) = response->get_header( `Access-Control-Allow-Headers` ).
    cl_abap_unit_assert=>assert_equals( exp = 204
                                        act = response->status ).
    cl_abap_unit_assert=>assert_true( xsdbool( allow_headers CS `MCP-Protocol-Version` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( allow_headers CS `mcp-param-tenant` ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( allow_headers CS `Mcp-Param-*` ) ).
  ENDMETHOD.

  METHOD test_http_headers_ok.
    DATA request TYPE REF TO ltcl_mock_request.
    request = NEW #( ).
    APPEND `Content-Type` TO request->headers.
    APPEND `application/json; charset=utf-8` TO request->hdr_vals.
    APPEND `Accept` TO request->headers.
    APPEND `application/json, text/event-stream` TO request->hdr_vals.

    DATA(check) = handler->check_modern_http_headers( request ).
    cl_abap_unit_assert=>assert_true( check-ok ).
  ENDMETHOD.

  METHOD test_http_headers_ct_bad.
    DATA request TYPE REF TO ltcl_mock_request.
    request = NEW #( ).
    APPEND `Content-Type` TO request->headers.
    APPEND `text/plain` TO request->hdr_vals.
    APPEND `Accept` TO request->headers.
    APPEND `application/json, text/event-stream` TO request->hdr_vals.

    DATA(check) = handler->check_modern_http_headers( request ).
    cl_abap_unit_assert=>assert_false( check-ok ).
    cl_abap_unit_assert=>assert_equals( exp = 415
                                        act = check-status ).
  ENDMETHOD.

  METHOD test_http_headers_accept_bad.
    DATA request TYPE REF TO ltcl_mock_request.
    request = NEW #( ).
    APPEND `Content-Type` TO request->headers.
    APPEND `application/json` TO request->hdr_vals.
    APPEND `Accept` TO request->headers.
    APPEND `application/json` TO request->hdr_vals.

    DATA(check) = handler->check_modern_http_headers( request ).
    cl_abap_unit_assert=>assert_false( check-ok ).
    cl_abap_unit_assert=>assert_equals( exp = 406
                                        act = check-status ).
  ENDMETHOD.

  METHOD test_http_headers_media_tokens.
    DATA request TYPE REF TO ltcl_mock_request.
    request = NEW #( ).
    APPEND `Content-Type` TO request->headers.
    APPEND `application/jsonp` TO request->hdr_vals.
    APPEND `Accept` TO request->headers.
    APPEND `application/jsonish, text/event-streaming` TO request->hdr_vals.

    DATA(check) = handler->check_modern_http_headers( request ).
    cl_abap_unit_assert=>assert_false( check-ok ).
    cl_abap_unit_assert=>assert_equals( exp = 415
                                        act = check-status ).

    CLEAR request->headers.
    CLEAR request->hdr_vals.
    APPEND `Content-Type` TO request->headers.
    APPEND `application/json; charset=utf-8` TO request->hdr_vals.
    APPEND `Accept` TO request->headers.
    APPEND `application/json; q=1, text/event-stream; q=0.5` TO request->hdr_vals.
    check = handler->check_modern_http_headers( request ).
    cl_abap_unit_assert=>assert_true( check-ok ).
  ENDMETHOD.

  METHOD test_status_modern_404.
    DATA response TYPE REF TO ltcl_mock_response.
    DATA rpc_response TYPE zcl_mcp2_jsonrpc=>response.
    response = NEW #( ).
    rpc_response-error-code = zif_mcp2_const=>error_codes-method_not_found.

    handler->set_status_for_rpc( response     = response
                                 rpc_response = rpc_response
                                 era          = zif_mcp2_const=>eras-modern ).

    cl_abap_unit_assert=>assert_equals( exp = 404
                                        act = response->status ).
  ENDMETHOD.

  METHOD test_status_legacy_200.
    DATA response TYPE REF TO ltcl_mock_response.
    DATA rpc_response TYPE zcl_mcp2_jsonrpc=>response.
    response = NEW #( ).
    rpc_response-error-code = zif_mcp2_const=>error_codes-method_not_found.

    handler->set_status_for_rpc( response     = response
                                 rpc_response = rpc_response
                                 era          = zif_mcp2_const=>eras-legacy ).

    cl_abap_unit_assert=>assert_equals( exp = 200
                                        act = response->status ).
  ENDMETHOD.

  METHOD test_method_not_allowed.
    DATA response TYPE REF TO ltcl_mock_response.
    response = NEW #( ).

    handler->method_not_allowed( response ).

    cl_abap_unit_assert=>assert_equals( exp = 405
                                        act = response->status ).
    cl_abap_unit_assert=>assert_equals( exp = `POST, OPTIONS`
                                        act = response->get_header( `Allow` ) ).
  ENDMETHOD.

  METHOD test_cors_headers_set.
    DATA response TYPE REF TO ltcl_mock_response.
    response = NEW #( ).

    handler->set_cors_headers( response = response
                               origin   = `https://example.com` ).

    cl_abap_unit_assert=>assert_equals( exp = `https://example.com`
                                        act = response->get_header( `Access-Control-Allow-Origin` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Origin`
                                        act = response->get_header( `Vary` ) ).
  ENDMETHOD.

  METHOD test_cors_headers_no_origin.
    DATA response TYPE REF TO ltcl_mock_response.
    response = NEW #( ).

    handler->set_cors_headers( response = response
                               origin   = `` ).

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( response->hdr_names ) ).
  ENDMETHOD.

  METHOD test_send_json_error.
    DATA response TYPE REF TO ltcl_mock_response.
    response = NEW #( ).

    handler->send_json_error( response = response
                              code     = zif_mcp2_const=>error_codes-invalid_request
                              message  = `bad request`
                              status   = 400 ).

    cl_abap_unit_assert=>assert_equals( exp = 400
                                        act = response->status ).
    cl_abap_unit_assert=>assert_equals( exp = `application/json`
                                        act = response->content_type ).
    DATA(json) = zcl_mcp2_ajson=>parse( response->body ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                        act = json->get_integer( '/error/code' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `bad request`
                                        act = json->get_string( '/error/message' ) ).
  ENDMETHOD.

  METHOD test_origin_allowed_empty.
    " No Origin header is always allowed (same-origin/non-browser request) -
    " this branch returns before ever touching zcl_mcp2_config, so it is the
    " only origin_allowed( ) outcome that is deterministic without control
    " over the target system's zmcp2_config/zmcp2_origins content.
    cl_abap_unit_assert=>assert_true(
      handler->origin_allowed( origin = ``
                               area   = `__mcp2_unit_missing_area__`
                               server = `__mcp2_unit_missing_server__` ) ).
  ENDMETHOD.

  METHOD test_dispatch_req_legacy.
    " ping is served by the legacy dispatcher.
    DATA rpc_req TYPE zcl_mcp2_jsonrpc=>request.
    rpc_req-jsonrpc    = `2.0`.
    rpc_req-method     = zif_mcp2_const=>methods-ping.
    rpc_req-id         = `1`.
    rpc_req-id_present = abap_true.
    rpc_req-params     = zcl_mcp2_ajson=>parse( `{}` ).

    DATA(request) = NEW ltcl_mock_request( ).
    DATA(resp) = handler->dispatch_request( request     = request
                                            mcp_server  = NEW ltcl_dispatch_test_server( )
                                            rpc_request = rpc_req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_dispatch_req_modern.
    " ping was removed from the modern vocabulary.
    DATA rpc_req TYPE zcl_mcp2_jsonrpc=>request.

    rpc_req-jsonrpc    = `2.0`.
    rpc_req-method     = zif_mcp2_const=>methods-ping.
    rpc_req-id         = `1`.
    rpc_req-id_present = abap_true.
    rpc_req-params     = zcl_mcp2_ajson=>parse(
                             |\{"_meta":\{"io.modelcontextprotocol/protocolVersion":"2026-07-28",| &&
                             |"io.modelcontextprotocol/clientInfo":\{"name":"Unit","version":"1"\},| &&
                             |"io.modelcontextprotocol/clientCapabilities":\{\}\}\}| ).

    DATA(request) = NEW ltcl_mock_request( ).
    APPEND zif_mcp2_const=>headers-protocol_version TO request->headers.
    APPEND zif_mcp2_const=>protocol-v2026_07_28 TO request->hdr_vals.
    APPEND zif_mcp2_const=>headers-method TO request->headers.
    APPEND zif_mcp2_const=>methods-ping TO request->hdr_vals.
    DATA(resp) = handler->dispatch_request( request     = request
                                            mcp_server  = NEW ltcl_dispatch_test_server( )
                                            rpc_request = rpc_req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
  ENDMETHOD.

ENDCLASS.
