"! <p class="shorttext synchronized">MCP2 ICF HTTP handler</p>
CLASS zcl_mcp2_http_handler DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PRIVATE SECTION.
    TYPES: BEGIN OF http_check,
             ok      TYPE abap_bool,
             status  TYPE i,
             code    TYPE i,
             message TYPE string,
           END OF http_check.

    "! <p class="shorttext synchronized">Handle one wrapped HTTP request</p>
    "! Method gate, CORS, parse, dispatch and serialize. The transport-neutral
    "! entry point: nothing below here touches ICF.
    "! @parameter request  | Wrapped HTTP request
    "! @parameter response | Wrapped HTTP response to fill
    METHODS handle
      IMPORTING !request  TYPE REF TO zif_mcp2_http_request
                !response TYPE REF TO zif_mcp2_http_response.

    "! <p class="shorttext synchronized">Extract area + server from the request path</p>
    "! @parameter path   | Path info of the request
    "! @parameter area   | Resolved service area
    "! @parameter server | Resolved server name
    "! @parameter valid  | abap_true when the path matched the expected shape
    METHODS parse_mcp_path
      IMPORTING !path  TYPE string
      EXPORTING !area  TYPE string
                server TYPE string
                !valid TYPE abap_bool.

    "! <p class="shorttext synchronized">Classify a JSON-RPC body</p>
    "! Distinguishes a request, an (invalid) response, and a notification.
    "! @parameter json         | Raw request body
    "! @parameter has_request  | Body is a request (has id)
    "! @parameter has_response | Body is a client response (invalid here)
    "! @parameter has_notif    | Body is a notification (no id)
    "! @parameter parse_error  | Body is not syntactically valid JSON
    METHODS classify_message
      IMPORTING !json        TYPE string
      EXPORTING has_request  TYPE abap_bool
                has_response TYPE abap_bool
                has_notif    TYPE abap_bool
                parse_error  TYPE abap_bool.

    "! <p class="shorttext synchronized">Answer a CORS preflight (OPTIONS)</p>
    "! @parameter request  | Wrapped HTTP request
    "! @parameter response | Wrapped HTTP response to fill
    "! @parameter origin   | Request Origin header
    METHODS handle_options
      IMPORTING !request  TYPE REF TO zif_mcp2_http_request
                !response TYPE REF TO zif_mcp2_http_response
                origin    TYPE string.

    "! <p class="shorttext synchronized">Send 405 with Allow: POST, OPTIONS</p>
    "! @parameter response | Wrapped HTTP response to fill
    METHODS method_not_allowed
      IMPORTING !response TYPE REF TO zif_mcp2_http_response.

    "! <p class="shorttext synchronized">Validate modern Streamable HTTP media headers</p>
    "! @parameter request | Wrapped HTTP request
    "! @parameter result  | ok or transport-level JSON-RPC error details
    METHODS check_modern_http_headers
      IMPORTING !request      TYPE REF TO zif_mcp2_http_request
      RETURNING VALUE(result) TYPE http_check.

    "! <p class="shorttext synchronized">Whether a media-type token is present</p>
    "! Ignores parameters and surrounding space. Matching is exact:
    "! application/jsonp must not satisfy application/json.
    "! @parameter header     | Content-Type / Accept header value
    "! @parameter media_type | Media type to match
    "! @parameter result     | abap_true when the media type is present
    METHODS has_media_type
      IMPORTING !header     TYPE string
                media_type  TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the Origin is allowed for this server</p>
    "! @parameter origin | Request Origin header
    "! @parameter area   | Service area
    "! @parameter server | Server name
    "! @parameter result | abap_true when the origin passes the policy
    METHODS origin_allowed
      IMPORTING origin        TYPE string
                !area         TYPE string
                server        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Set CORS response headers for an allowed origin</p>
    "! @parameter response | Wrapped HTTP response to fill
    "! @parameter origin   | Allowed request origin to echo
    METHODS set_cors_headers
      IMPORTING !response TYPE REF TO zif_mcp2_http_response
                origin    TYPE string.

    "! <p class="shorttext synchronized">Route a parsed request to the era dispatcher</p>
    "! Selects legacy vs modern dispatch from the negotiated era.
    "! @parameter request     | Wrapped HTTP request (for header mirroring)
    "! @parameter mcp_server  | Resolved server implementation
    "! @parameter rpc_request | Parsed JSON-RPC request
    "! @parameter result      | JSON-RPC response
    METHODS dispatch_request
      IMPORTING !request      TYPE REF TO zif_mcp2_http_request
                mcp_server    TYPE REF TO zif_mcp2_server
                rpc_request   TYPE zcl_mcp2_jsonrpc=>request
      RETURNING VALUE(result) TYPE zcl_mcp2_jsonrpc=>response.

    "! <p class="shorttext synchronized">Map a JSON-RPC response to an HTTP status</p>
    "! @parameter response     | Wrapped HTTP response to fill
    "! @parameter rpc_response | JSON-RPC response carrying any error code
    "! @parameter era          | Negotiated era (affects method_not_found status)
    METHODS set_status_for_rpc
      IMPORTING !response    TYPE REF TO zif_mcp2_http_response
                rpc_response TYPE zcl_mcp2_jsonrpc=>response
                era          TYPE string OPTIONAL.

    "! <p class="shorttext synchronized">Write a JSON-RPC error body with an HTTP status</p>
    "! @parameter response | Wrapped HTTP response to fill
    "! @parameter code     | JSON-RPC error code
    "! @parameter message  | Error reason
    "! @parameter status   | HTTP status code
    METHODS send_json_error
      IMPORTING !response TYPE REF TO zif_mcp2_http_response
                !code     TYPE i
                !message  TYPE string
                !status   TYPE i.

ENDCLASS.


CLASS zcl_mcp2_http_handler IMPLEMENTATION.
  METHOD if_http_extension~handle_request.
    DATA request  TYPE REF TO zif_mcp2_http_request.
    DATA response TYPE REF TO zif_mcp2_http_response.

    request = zcl_mcp2_http_factory=>create_request( server->request ).
    response = zcl_mcp2_http_factory=>create_response( server->response ).
    handle( request  = request
            response = response ).
  ENDMETHOD.

  METHOD handle.
    DATA area        TYPE string.
    DATA server_name TYPE string.
    DATA valid       TYPE abap_bool.

    response->set_header( name  = 'Cache-Control'
                          value = 'no-store' ) ##NO_TEXT.
    response->set_content_type( 'application/json' ).

    DATA(origin) = request->get_origin( ).
    DATA(method) = to_upper( request->get_method( ) ).

    parse_mcp_path( EXPORTING path   = request->get_path( )
                    IMPORTING area   = area
                              server = server_name
                              valid  = valid ).

    IF valid = abap_false.
      send_json_error( response = response
                       code     = zif_mcp2_const=>error_codes-invalid_request
                       message  = `Invalid MCP endpoint path`
                       status   = 404 ) ##NO_TEXT.
      RETURN.
    ENDIF.

    IF method = 'OPTIONS'.
      IF origin_allowed( origin = origin
                         area   = area
                         server = server_name ) = abap_false.
        send_json_error( response = response
                         code     = zif_mcp2_const=>error_codes-invalid_request
                         message  = `Origin is not allowed`
                         status   = 403 ) ##NO_TEXT.
        RETURN.
      ENDIF.
      handle_options( request  = request
                      response = response
                      origin   = origin ).
      RETURN.
    ENDIF.

    IF method <> 'POST'.
      method_not_allowed( response ).
      RETURN.
    ENDIF.

    IF origin_allowed( origin = origin
                       area   = area
                       server = server_name ) = abap_false.
      send_json_error( response = response
                       code     = zif_mcp2_const=>error_codes-invalid_request
                       message  = `Origin is not allowed`
                       status   = 403 ) ##NO_TEXT.
      RETURN.
    ENDIF.
    set_cors_headers( response = response
                      origin   = origin ).

    DATA mcp_server TYPE REF TO zif_mcp2_server.
    TRY.
        mcp_server = zcl_mcp2_server_factory=>get_server( area   = area
                                                          server = server_name ).
      CATCH zcx_mcp2_error.
        " Registered but broken (bad class name / missing interface): a server
        " problem, not an unknown endpoint. Keep implementation details out of
        " the public response; the factory exception remains available to a
        " server-side debugger or log integration.
        send_json_error( response = response
                         code     = zif_mcp2_const=>error_codes-internal_error
                         message  = `MCP server configuration error`
                         status   = 500 ) ##NO_TEXT.
        RETURN.
    ENDTRY.
    IF mcp_server IS NOT BOUND.
      send_json_error( response = response
                       code     = zif_mcp2_const=>error_codes-method_not_found
                       message  = `MCP server not found`
                       status   = 404 ) ##NO_TEXT.
      RETURN.
    ENDIF.

    " Endpoint authorization, before the body is even parsed, so a denied
    " caller reaches no handler at all - not initialize, not server/discover.
    " Default grants access; servers redefine check_authorization to add their
    " own AUTHORITY-CHECK. The reason is never echoed back.
    IF mcp_server->check_authorization( area   = area
                                        server = server_name ) = abap_false.
      send_json_error( response = response
                       code     = zif_mcp2_const=>error_codes-invalid_request
                       message  = `Not authorized for this MCP server`
                       status   = 403 ) ##NO_TEXT.
      RETURN.
    ENDIF.

    DATA body TYPE string.
    body = request->get_body( ).

    DATA has_request  TYPE abap_bool.
    DATA has_response TYPE abap_bool.
    DATA has_notif    TYPE abap_bool.
    DATA parse_error  TYPE abap_bool.
    classify_message( EXPORTING json         = body
                      IMPORTING has_request  = has_request
                                has_response = has_response
                                has_notif    = has_notif
                                parse_error  = parse_error ).

    IF parse_error = abap_true.
      send_json_error( response = response
                       code     = zif_mcp2_const=>error_codes-parse_error
                       message  = `Parse error`
                       status   = 400 ) ##NO_TEXT.
      RETURN.
    ENDIF.

    IF has_response = abap_true OR ( has_request = abap_false AND has_notif = abap_false ).
      send_json_error( response = response
                       code     = zif_mcp2_const=>error_codes-invalid_request
                       message  = `Client body must be one JSON-RPC request or notification`
                       status   = 400 ) ##NO_TEXT.
      RETURN.
    ENDIF.

    DATA rpc_request TYPE zcl_mcp2_jsonrpc=>request.
    TRY.
        rpc_request = zcl_mcp2_jsonrpc=>parse_request( body ).
      CATCH zcx_mcp2_error INTO DATA(parse_err).
        send_json_error( response = response
                         code     = parse_err->code
                         message  = parse_err->reason
                         status   = 400 ).
        RETURN.
    ENDTRY.

    IF zcl_mcp2_jsonrpc=>is_notification( rpc_request ) = abap_true.
      response->set_status( 202 ).
      response->set_body( `` ).
      RETURN.
    ENDIF.

    DATA header_ver TYPE string.
    DATA era        TYPE string.
    header_ver = request->get_header( zif_mcp2_const=>headers-protocol_version ).

    DATA rpc_response TYPE zcl_mcp2_jsonrpc=>response.
    TRY.
        era = zcl_mcp2_version=>detect_era( method     = rpc_request-method
                                            params     = rpc_request-params
                                            header_ver = header_ver ).
      CATCH zcx_mcp2_error INTO DATA(era_err).
        rpc_response = zcl_mcp2_jsonrpc=>build_from_exc( request = rpc_request
                                                         exc     = era_err ).
        set_status_for_rpc( response     = response
                            rpc_response = rpc_response ).
        TRY.
            response->set_body( zcl_mcp2_jsonrpc=>serialize_response( rpc_response ) ).
          CATCH zcx_mcp2_ajson_error INTO DATA(era_json_err).
            send_json_error( response = response
                             code     = zif_mcp2_const=>error_codes-internal_error
                             message  = era_json_err->get_text( )
                             status   = 500 ).
        ENDTRY.
        RETURN.
    ENDTRY.

    IF era = zif_mcp2_const=>eras-modern.
      DATA(modern_http) = check_modern_http_headers( request ).
      IF modern_http-ok = abap_false.
        rpc_response = zcl_mcp2_jsonrpc=>build_error( request = rpc_request
                                                      code    = modern_http-code
                                                      message = modern_http-message ).
        response->set_status( modern_http-status ).
        TRY.
            response->set_body( zcl_mcp2_jsonrpc=>serialize_response( rpc_response ) ).
          CATCH zcx_mcp2_ajson_error INTO DATA(http_json_err).
            send_json_error( response = response
                             code     = zif_mcp2_const=>error_codes-internal_error
                             message  = http_json_err->get_text( )
                             status   = 500 ).
        ENDTRY.
        RETURN.
      ENDIF.
    ENDIF.

    rpc_response = dispatch_request( request     = request
                                     mcp_server  = mcp_server
                                     rpc_request = rpc_request ).
    set_status_for_rpc( response     = response
                        rpc_response = rpc_response
                        era          = era ).

    TRY.
        response->set_body( zcl_mcp2_jsonrpc=>serialize_response( rpc_response ) ).
      CATCH zcx_mcp2_ajson_error INTO DATA(json_err).
        send_json_error( response = response
                         code     = zif_mcp2_const=>error_codes-internal_error
                         message  = json_err->get_text( )
                         status   = 500 ).
    ENDTRY.
  ENDMETHOD.

  METHOD parse_mcp_path.
    DATA parts TYPE string_table.

    SPLIT path AT '/' INTO TABLE parts.
    DELETE parts WHERE table_line IS INITIAL.

    CLEAR: area,
           server.
    valid = abap_false.

    CASE lines( parts ).
      WHEN 2.
        READ TABLE parts INDEX 1 INTO area.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        READ TABLE parts INDEX 2 INTO server.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
      WHEN 3.
        " Keep this declaration explicit for ABAP 7.02 downport compatibility.
        DATA prefix TYPE string.
        READ TABLE parts INDEX 1 INTO prefix.
        IF sy-subrc <> 0 OR prefix <> 'mcp'.
          RETURN.
        ENDIF.
        READ TABLE parts INDEX 2 INTO area.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        READ TABLE parts INDEX 3 INTO server.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    valid = xsdbool( area IS NOT INITIAL AND server IS NOT INITIAL ).
  ENDMETHOD.

  METHOD classify_message.
    CLEAR: has_request,
           has_response,
           has_notif,
           parse_error.

    TRY.
        DATA(json_obj) = zcl_mcp2_ajson=>parse( json ).
        IF json_obj->get_node_type( '/' ) = 'array'.
          RETURN.
        ENDIF.
        IF json_obj->exists( '/method' ) = abap_true.
          IF json_obj->exists( '/id' ) = abap_true.
            has_request = abap_true.
          ELSE.
            has_notif = abap_true.
          ENDIF.
        ENDIF.
        IF json_obj->exists( '/result' ) = abap_true OR json_obj->exists( '/error' ) = abap_true.
          has_response = abap_true.
        ENDIF.
      CATCH zcx_mcp2_ajson_error.
        parse_error = abap_true.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD handle_options.
    DATA allow_headers     TYPE string VALUE `Content-Type, Authorization, MCP-Protocol-Version, Mcp-Method, Mcp-Name` ##NO_TEXT.
    DATA requested_headers TYPE string_table.

    SPLIT request->get_header( `Access-Control-Request-Headers` )
          AT `,` INTO TABLE requested_headers ##NO_TEXT.
    LOOP AT requested_headers INTO DATA(requested_header).
      CONDENSE requested_header.
      IF to_lower( requested_header ) CP `mcp-param-*`.
        allow_headers = |{ allow_headers }, { requested_header }|.
      ENDIF.
    ENDLOOP.

    response->set_status( 204 ).
    response->set_header( name  = 'Allow'
                          value = 'POST, OPTIONS' ) ##NO_TEXT.
    response->set_header( name  = 'Access-Control-Allow-Methods'
                          value = 'POST, OPTIONS' ) ##NO_TEXT.
    response->set_header( name  = 'Access-Control-Allow-Headers'
                          value = allow_headers ) ##NO_TEXT.
    response->set_header( name  = 'Access-Control-Max-Age'
                          value = '600' ) ##NO_TEXT.
    set_cors_headers( response = response
                      origin   = origin ).
    response->set_body( `` ).
  ENDMETHOD.

  METHOD method_not_allowed.
    response->set_status( 405 ).
    response->set_header( name  = 'Allow'
                          value = 'POST, OPTIONS' ) ##NO_TEXT.
    response->set_body( `` ).
  ENDMETHOD.

  METHOD check_modern_http_headers.
    result-ok = abap_true.

    DATA(content_type) = request->get_header( 'Content-Type' ) ##NO_TEXT.
    IF    content_type CS `,`
       OR has_media_type( header     = content_type
                          media_type = `application/json` ) = abap_false.
      result-ok      = abap_false.
      result-status  = 415.
      result-code    = zif_mcp2_const=>error_codes-invalid_request.
      result-message = `Modern Streamable HTTP requests require Content-Type application/json` ##NO_TEXT.
      RETURN.
    ENDIF.

    DATA(accept) = request->get_header( 'Accept' ) ##NO_TEXT.
    IF    has_media_type( header     = accept
                          media_type = `application/json` ) = abap_false
       OR has_media_type( header     = accept
                          media_type = `text/event-stream` ) = abap_false.
      result-ok      = abap_false.
      result-status  = 406.
      result-code    = zif_mcp2_const=>error_codes-invalid_request.
      result-message = `Modern Streamable HTTP requests require Accept application/json and text/event-stream` ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD has_media_type.
    DATA tokens TYPE string_table.
    DATA header_lower TYPE string.
    DATA wanted TYPE string.
    DATA token_type TYPE string.
    DATA parameters TYPE string.

    header_lower = to_lower( header ).
    wanted = to_lower( media_type ).
    SPLIT header_lower AT `,` INTO TABLE tokens.
    LOOP AT tokens INTO DATA(token).
      CLEAR: token_type, parameters.
      SPLIT token AT `;` INTO token_type parameters.
      CONDENSE token_type.
      IF token_type = wanted.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD origin_allowed.
    result = abap_true.
    IF origin IS INITIAL.
      RETURN.
    ENDIF.

    DATA(config) = NEW zcl_mcp2_config( area_name   = area
                                        server_name = server ).
    DATA(cors_mode) = config->get_cors_mode( ).
    IF cors_mode = zcl_mcp2_config=>cors_mode_ignore.
      RETURN.
    ENDIF.

    IF     cors_mode <> zcl_mcp2_config=>cors_mode_check
       AND cors_mode <> zcl_mcp2_config=>cors_mode_enforce.
      result = abap_false.
      RETURN.
    ENDIF.

    " Origins are scheme://host[:port]; scheme and host are case-insensitive
    " (RFC 6454), and the DDIC field may have upper-cased configured values.
    DATA(origins)      = config->get_allowed_origins( ).
    DATA(origin_upper) = to_upper( origin ).
    LOOP AT origins INTO DATA(allowed).
      IF allowed = `*` OR to_upper( allowed ) = origin_upper.
        RETURN.
      ENDIF.
    ENDLOOP.

    result = abap_false.
  ENDMETHOD.

  METHOD set_cors_headers.
    IF origin IS INITIAL.
      RETURN.
    ENDIF.
    response->set_header( name  = 'Access-Control-Allow-Origin'
                          value = origin ) ##NO_TEXT.
    response->set_header( name  = 'Vary'
                          value = 'Origin' ) ##NO_TEXT.
  ENDMETHOD.

  METHOD dispatch_request.
    DATA header_ver TYPE string.

    header_ver = request->get_header( zif_mcp2_const=>headers-protocol_version ).

    TRY.
        DATA(era) = zcl_mcp2_version=>detect_era( method     = rpc_request-method
                                                  params     = rpc_request-params
                                                  header_ver = header_ver ).
        IF era = zcl_mcp2_version=>era_modern.
          DATA(modern) = NEW zcl_mcp2_dispatch_modern( mcp_server ).
          result = modern->dispatch( request      = rpc_request
                                     header_ver   = header_ver
                                     http_request = request ).
        ELSE.
          DATA(legacy) = NEW zcl_mcp2_dispatch_legacy( mcp_server ).
          result = legacy->dispatch( rpc_request ).
        ENDIF.
      CATCH zcx_mcp2_error INTO DATA(proto_err).
        result = zcl_mcp2_jsonrpc=>build_from_exc( request = rpc_request
                                                   exc     = proto_err ).
    ENDTRY.
  ENDMETHOD.

  METHOD set_status_for_rpc.
    IF rpc_response-http_status > 0.
      response->set_status( rpc_response-http_status ).
      RETURN.
    ENDIF.

    CASE rpc_response-error-code.
      WHEN zif_mcp2_const=>error_codes-header_mismatch
        OR zif_mcp2_const=>error_codes-missing_client_cap
        OR zif_mcp2_const=>error_codes-unsupported_version.
        response->set_status( 400 ).
      WHEN zif_mcp2_const=>error_codes-method_not_found.
        IF era = zif_mcp2_const=>eras-modern.
          response->set_status( 404 ).
        ELSE.
          response->set_status( 200 ).
        ENDIF.
      WHEN OTHERS.
        response->set_status( 200 ).
    ENDCASE.
  ENDMETHOD.

  METHOD send_json_error.
    DATA empty_req    TYPE zcl_mcp2_jsonrpc=>request.
    DATA rpc_response TYPE zcl_mcp2_jsonrpc=>response.

    response->set_status( status ).
    response->set_content_type( 'application/json' ).
    rpc_response = zcl_mcp2_jsonrpc=>build_error( request = empty_req
                                                  code    = code
                                                  message = message ).

    TRY.
        response->set_body( zcl_mcp2_jsonrpc=>serialize_response( rpc_response ) ).
      CATCH zcx_mcp2_ajson_error.
        response->set_body( `{"jsonrpc":"2.0","error":{"code":-32603,"message":"Internal error"}}` ) ##NO_TEXT.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
