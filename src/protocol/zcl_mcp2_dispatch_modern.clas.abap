"! <p class="shorttext synchronized">MCP2 modern era dispatcher (2026-07-28)</p>
"! Routes server/discover and the standard method set for 2026-07-28+.
"! Stamps resultType, ttlMs, cacheScope centrally from the zif_mcp2_result
"! returned by each handler - no envelope boilerplate in the server itself.
"! Validates _meta and mirrors headers for each request.
CLASS zcl_mcp2_dispatch_modern DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Create a modern dispatcher for a server</p>
    "! @parameter mcp_server | The SDK user's server implementation
    METHODS constructor
      IMPORTING mcp_server TYPE REF TO zif_mcp2_server.

    "! <p class="shorttext synchronized">Dispatch one modern JSON-RPC request</p>
    "! Dispatch one JSON-RPC request and return the response struct.
    "! Never raises - all errors are converted to error-response structs.
    "! @parameter request      | Parsed JSON-RPC request
    "! @parameter header_ver   | MCP-Protocol-Version header value (may be empty)
    "! @parameter http_request | Wrapped request; enables Mcp-Param-* validation
    "! @parameter result       | JSON-RPC response (success or error)
    METHODS dispatch
      IMPORTING !request      TYPE zcl_mcp2_jsonrpc=>request
                header_ver    TYPE string                       OPTIONAL
                http_request  TYPE REF TO zif_mcp2_http_request OPTIONAL
      RETURNING VALUE(result) TYPE zcl_mcp2_jsonrpc=>response.

  PRIVATE SECTION.
    DATA server TYPE REF TO zif_mcp2_server.

    TYPES: BEGIN OF param_header,
             property_path TYPE string,
             property_type TYPE string,
             header_suffix TYPE string,
             header_name   TYPE string,
           END OF param_header,
           param_headers TYPE STANDARD TABLE OF param_header WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Validate the modern request _meta block</p>
    "! Checks protocolVersion vs header, clientInfo and clientCapabilities.
    "! @parameter params     | Request params carrying _meta
    "! @parameter header_ver | MCP-Protocol-Version header value
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS validate_meta
      IMPORTING params     TYPE REF TO zif_mcp2_ajson
                header_ver TYPE string
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate mirrored Mcp-* headers against the body</p>
    "! Body is the source of truth; mismatched headers raise HeaderMismatch.
    "! @parameter request      | Parsed JSON-RPC request
    "! @parameter http_request | Wrapped request carrying the headers
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS validate_mirror_headers
      IMPORTING !request     TYPE zcl_mcp2_jsonrpc=>request
                http_request TYPE REF TO zif_mcp2_http_request
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    " Presence must be independent of the header value: an explicitly empty
    " mirrored header can validly mirror an empty string argument.
    METHODS has_header
      IMPORTING http_request TYPE REF TO zif_mcp2_http_request
                header_name  TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Handle server/discover</p>
    "! Server identity is not part of the discover body; the caller writes it
    "! into _meta via stamp_server_info, like on every other modern result.
    "! @parameter result | discover result (versions, caps, hints)
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_discover
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tools/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tools_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tools/call (with header mirroring)</p>
    "! @parameter params       | Request params slice
    "! @parameter http_request | Wrapped request for Mcp-Param-* validation
    "! @parameter result       | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tools_call
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
                http_request  TYPE REF TO zif_mcp2_http_request OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate Mcp-Param-* headers against arguments</p>
    "! Mirrors each x-mcp-header-annotated argument against its header.
    "! @parameter call_req             | Parsed tools/call request
    "! @parameter http_request         | Wrapped request carrying the headers
    "! @raising   zcx_mcp2_error       | Header/argument mismatch
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS validate_param_headers
      IMPORTING call_req     TYPE REF TO zcl_mcp2_req_call_tool
                http_request TYPE REF TO zif_mcp2_http_request
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Collect x-mcp-header annotations from a schema</p>
    "! Returns the top-level properties annotated for header mirroring.
    "! @parameter schema | Tool input schema
    "! @parameter result | Mirrorable properties with their header names/types
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS collect_param_headers
      IMPORTING !schema       TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE param_headers
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Collect x-mcp-header annotations recursively</p>
    "! Object properties may be nested; arrays remain unsupported for header mirroring.
    "! @parameter schema               | Tool input schema
    "! @parameter schema_path          | Current schema property path
    "! @parameter argument_path        | Matching argument path, without leading slash
    "! @parameter headers              | Accumulated mirrorable properties
    "! @parameter seen_headers         | Header names already seen (duplicate guard)
    "! @raising   zcx_mcp2_error       | Invalid or unsupported annotation
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS collect_param_headers_at
      IMPORTING !schema       TYPE REF TO zif_mcp2_ajson
                schema_path   TYPE string
                argument_path TYPE string
      CHANGING  headers       TYPE param_headers
                seen_headers  TYPE string_table
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Detect nested x-mcp-header annotations</p>
    "! True if an x-mcp-header sits at or below the given path.
    "! @parameter schema | Schema node to scan
    "! @parameter path   | Base path to scan from
    "! @parameter result | abap_true if a nested annotation exists
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS has_x_mcp_header_at_or_below
      IMPORTING !schema       TYPE REF TO zif_mcp2_ajson
                !path         TYPE string
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Validate a header-name suffix</p>
    "! @parameter suffix | The {Name} part of Mcp-Param-{Name}
    "! @parameter result | abap_true when the suffix is well-formed
    METHODS is_valid_header_suffix
      IMPORTING !suffix       TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Render a body argument as a header value</p>
    "! @parameter arguments | Tool arguments object
    "! @parameter path      | Path of the argument
    "! @parameter result    | Argument rendered as a string
    METHODS argument_to_header_value
      IMPORTING arguments     TYPE REF TO zif_mcp2_ajson
                !path         TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Normalize a received header value</p>
    "! Decodes =?base64?...?= encoded values and checks safety.
    "! @parameter header_name  | Header name (for error messages)
    "! @parameter header_value | Raw header value
    "! @parameter result       | Decoded, validated value
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    METHODS normalize_header_value
      IMPORTING header_name   TYPE string
                header_value  TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Reject unsafe / control characters in a header</p>
    "! @parameter header_name  | Header name (for error messages)
    "! @parameter header_value | Value to check
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    METHODS assert_header_value_safe
      IMPORTING header_name  TYPE string
                header_value TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Compare a mirrored header against the body</p>
    "! Type-aware: integers numerically, booleans lowercase, strings exact.
    "! @parameter header_name   | Header name (for error messages)
    "! @parameter header_value  | Header value
    "! @parameter body_value    | Corresponding body argument value
    "! @parameter property_type | JSON Schema type of the property
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    METHODS compare_param_header
      IMPORTING header_name   TYPE string
                header_value  TYPE string
                body_value    TYPE string
                property_type TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Assert integer text within JS safe-integer bounds</p>
    "! @parameter header_name | Header name (for error messages)
    "! @parameter value       | Integer text to validate
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    METHODS assert_safe_integer_text
      IMPORTING header_name TYPE string
                !value      TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Handle resources/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_resources_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle resources/read</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_resources_read
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle resources/templates/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_resources_tmpls
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle prompts/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_prompts_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle prompts/get (with header mirroring)</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_prompts_get
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle completion/complete</p>
    "! @parameter params | Request params slice
    "! @parameter result | Result object (envelope stamped by caller)
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_completions
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Stamp the modern result envelope</p>
    "! Serializes the result and adds resultType plus cache fields.
    "! Also enforces MRTR input_required capability rules centrally.
    "! @parameter mcp_result | The handler result
    "! @parameter method     | Dispatched method name (for MRTR enforcement)
    "! @parameter result     | Result JSON with the envelope stamped
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS stamp_result
      IMPORTING mcp_result    TYPE REF TO zif_mcp2_result
                !method       TYPE string OPTIONAL
                input_dependent TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Write ttlMs / cacheScope onto a result</p>
    "! @parameter json  | Target result JSON
    "! @parameter ttl   | Time-to-live in milliseconds
    "! @parameter scope | Cache scope (public / private)
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS stamp_cache_fields
      IMPORTING !json  TYPE REF TO zif_mcp2_ajson
                ttl    TYPE i
                !scope TYPE string
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Write server identity into _meta serverInfo</p>
    "! Servers SHOULD carry io.modelcontextprotocol/serverInfo in every modern
    "! result's _meta per the 2026-07-28 draft (ResultMetaObject); this is the
    "! single place that does so, for both discover and stamp_result.
    "! @parameter json | Target result JSON
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS stamp_server_info
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/get</p>
    "! @parameter params | Request params slice
    "! @parameter result | Task-get result
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_get
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/update</p>
    "! @parameter params | Request params slice
    "! @parameter result | Acknowledgement result
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_update
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/cancel</p>
    "! @parameter params | Request params slice
    "! @parameter result | Cancellation result
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_cancel
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Require the Tasks extension capability</p>
    "! Enforced for every modern tasks/* method.
    "! @raising zcx_mcp2_error | Client did not declare the Tasks extension
    METHODS require_tasks_capability
      RAISING zcx_mcp2_error.

    "! <p class="shorttext synchronized">Build the advertised capabilities object</p>
    "! @parameter result | capabilities object reflecting supports_* flags
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_capabilities
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Populate the server context from _meta</p>
    "! @parameter params | Request params carrying _meta
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS set_modern_context
      IMPORTING params TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_dispatch_modern IMPLEMENTATION.
  METHOD constructor.
    server = mcp_server.
  ENDMETHOD.

  METHOD dispatch.
    TRY.
        DATA result_json TYPE REF TO zif_mcp2_ajson.

        " All modern methods (including server/discover) require valid _meta.
        IF header_ver IS SUPPLIED.
          validate_meta( params     = request-params
                         header_ver = header_ver ).
        ELSE.
          validate_meta( params     = request-params
                         header_ver = `` ).
        ENDIF.
        IF http_request IS BOUND.
          validate_mirror_headers( request      = request
                                   http_request = http_request ).
        ENDIF.
        set_modern_context( request-params ).

        CASE request-method.
          WHEN zif_mcp2_const=>methods-server_discover.
            result_json = handle_discover( ).
            result_json->set_string( iv_path = '/resultType'
                                     iv_val  = zif_mcp2_const=>result_types-complete ).
            stamp_server_info( result_json ).
            DATA(discover_cache) = server->get_discover_cache( ).
            stamp_cache_fields( json  = result_json
                                ttl   = discover_cache-ttl_ms
                                scope = discover_cache-cache_scope ).

          WHEN zif_mcp2_const=>methods-tools_list.
            IF server->supports_tools( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result( mcp_result = handle_tools_list( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-tools_call.
            IF server->supports_tools( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result(
              mcp_result      = handle_tools_call( params       = request-params
                                                   http_request = http_request )
              method          = request-method
              input_dependent = xsdbool( request-params->exists( '/requestState' ) = abap_true
                                      OR request-params->exists( '/inputResponses' ) = abap_true ) ).

          WHEN zif_mcp2_const=>methods-resources_list.
            IF server->supports_resources( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result( mcp_result = handle_resources_list( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-resources_read.
            IF server->supports_resources( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result(
              mcp_result      = handle_resources_read( request-params )
              method          = request-method
              input_dependent = xsdbool( request-params->exists( '/requestState' ) = abap_true
                                      OR request-params->exists( '/inputResponses' ) = abap_true ) ).

          WHEN zif_mcp2_const=>methods-resources_tmpls_list.
            IF server->supports_resources( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result( mcp_result = handle_resources_tmpls( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-prompts_list.
            IF server->supports_prompts( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result( mcp_result = handle_prompts_list( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-prompts_get.
            IF server->supports_prompts( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result(
              mcp_result      = handle_prompts_get( request-params )
              method          = request-method
              input_dependent = xsdbool( request-params->exists( '/requestState' ) = abap_true
                                      OR request-params->exists( '/inputResponses' ) = abap_true ) ).

          WHEN zif_mcp2_const=>methods-completions.
            IF server->supports_completions( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = stamp_result( mcp_result = handle_completions( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-tasks_get.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            require_tasks_capability( ).
            result_json = stamp_result( mcp_result = handle_tasks_get( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-tasks_update.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            require_tasks_capability( ).
            result_json = stamp_result( mcp_result = handle_tasks_update( request-params )
                                        method     = request-method ).

          WHEN zif_mcp2_const=>methods-tasks_cancel.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            require_tasks_capability( ).
            result_json = stamp_result( mcp_result = handle_tasks_cancel( request-params )
                                        method     = request-method ).

          WHEN OTHERS.
            zcx_mcp2_error=>raise_method_not_found( request-method ).
        ENDCASE.

        result = zcl_mcp2_jsonrpc=>build_success( request     = request
                                                  result_json = result_json ).

      CATCH zcx_mcp2_error INTO DATA(proto_err).
        IF     request-method = zif_mcp2_const=>methods-resources_read
           AND proto_err->code = zif_mcp2_const=>error_codes-resource_not_found.
          " -32002 belongs to the latest legacy profile. The modern draft maps
          " an unknown resource to InvalidParams while retaining actionable data.
          DATA(modern_resource_err) = NEW zcx_mcp2_error(
            error_code = zif_mcp2_const=>error_codes-invalid_params
            error_msg  = proto_err->reason
            error_data = proto_err->err_data ).
          result = zcl_mcp2_jsonrpc=>build_from_exc( request = request
                                                     exc     = modern_resource_err ).
        ELSE.
          result = zcl_mcp2_jsonrpc=>build_from_exc( request = request
                                                     exc     = proto_err ).
        ENDIF.

      CATCH zcx_mcp2_ajson_error INTO DATA(json_err).
        result = zcl_mcp2_jsonrpc=>build_error( request = request
                                                code    = zif_mcp2_const=>error_codes-internal_error
                                                message = json_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD validate_meta.
    IF params IS NOT BOUND OR params->exists( '/_meta' ) = abap_false.
      zcx_mcp2_error=>raise_malformed_params( `Modern requests require params._meta` ) ##NO_TEXT.
    ENDIF.

    " Key names contain '/' so ajson paths use TAB as the in-name separator.
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(path_proto_ver)   = '/_meta/io.modelcontextprotocol' && tab && 'protocolVersion'.
    DATA(path_client_info) = '/_meta/io.modelcontextprotocol' && tab && 'clientInfo'.
    DATA(path_client_caps) = '/_meta/io.modelcontextprotocol' && tab && 'clientCapabilities'.

    DATA(meta_ver) = params->get_string( path_proto_ver ).
    IF meta_ver IS INITIAL.
      zcx_mcp2_error=>raise_malformed_params( `Modern requests require _meta protocolVersion` ) ##NO_TEXT.
    ENDIF.

    IF header_ver IS INITIAL.
      zcx_mcp2_error=>raise_header_mismatch( `MCP-Protocol-Version header is required` ) ##NO_TEXT.
    ENDIF.

    IF header_ver <> meta_ver.
      zcx_mcp2_error=>raise_header_mismatch(
          |MCP-Protocol-Version header '{ header_ver }' does not match _meta '{ meta_ver }'| ) ##NO_TEXT.
    ENDIF.

    " Compare first, then classify the selected version. This makes an
    " unsupported header/body pair a mismatch (-32020), while equal but
    " unsupported values remain -32022.
    IF zcl_mcp2_version=>is_modern( meta_ver ) = abap_false.
      zcx_mcp2_error=>raise_unsupported_ver( meta_ver ).
    ENDIF.

    " clientInfo is optional per the 2026-07-28 draft (clients SHOULD include it,
    " but MUST NOT be rejected for omitting it); when present it must still be
    " a well-formed Implementation (non-empty name and version).
    IF params->exists( path_client_info ) = abap_true.
      IF    params->get_node_type( path_client_info )
            <> zif_mcp2_ajson_types=>node_type-object
         OR params->get_string( |{ path_client_info }/name| )    IS INITIAL
         OR params->get_string( |{ path_client_info }/version| ) IS INITIAL.
        zcx_mcp2_error=>raise_malformed_params(
          `Modern _meta clientInfo, when present, must be an object with name and version` ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    IF    params->exists( path_client_caps ) = abap_false
       OR params->get_node_type( path_client_caps )
          <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_malformed_params( `Modern requests require _meta clientCapabilities object` ) ##NO_TEXT.
    ENDIF.

    DATA capability_names TYPE string_table.
    capability_names = params->members( path_client_caps ).
    LOOP AT capability_names INTO DATA(capability_name).
      DATA(capability_member_path) = capability_name.
      REPLACE ALL OCCURRENCES OF `/` IN capability_member_path
        WITH cl_abap_char_utilities=>horizontal_tab.
      IF params->get_node_type( |{ path_client_caps }/{ capability_member_path }| )
         <> zif_mcp2_ajson_types=>node_type-object.
        zcx_mcp2_error=>raise_malformed_params(
          |Modern client capability '{ capability_name }' must be an object| ) ##NO_TEXT.
      ENDIF.
    ENDLOOP.

    DATA(extensions_path) = |{ path_client_caps }/extensions|.
    IF     params->exists( extensions_path ) = abap_true
       AND params->get_node_type( extensions_path )
           <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_malformed_params( `Modern _meta clientCapabilities.extensions must be an object` ) ##NO_TEXT.
    ENDIF.
    IF params->exists( extensions_path ) = abap_true.
      DATA extension_names TYPE string_table.
      extension_names = params->members( extensions_path ).
      LOOP AT extension_names INTO DATA(extension_name).
        DATA(extension_member_path) = extension_name.
        REPLACE ALL OCCURRENCES OF `/` IN extension_member_path
          WITH cl_abap_char_utilities=>horizontal_tab.
        IF params->get_node_type( |{ extensions_path }/{ extension_member_path }| )
           <> zif_mcp2_ajson_types=>node_type-object.
          zcx_mcp2_error=>raise_malformed_params(
            |Modern client capability extension '{ extension_name }' must be an object| ) ##NO_TEXT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    DATA(path_log_level) = '/_meta/io.modelcontextprotocol' && tab && 'logLevel'.
    IF params->exists( path_log_level ) = abap_true.
      IF params->get_node_type( path_log_level )
         <> zif_mcp2_ajson_types=>node_type-string.
        zcx_mcp2_error=>raise_malformed_params( `Modern _meta logLevel must be a string` ) ##NO_TEXT.
      ENDIF.
      DATA(log_level) = params->get_string( path_log_level ).
      DATA(valid_log_level) = abap_false.
      CASE log_level.
        WHEN `debug` OR `info` OR `notice` OR `warning` OR `error`
          OR `critical` OR `alert` OR `emergency`.
          valid_log_level = abap_true.
      ENDCASE.
      IF valid_log_level = abap_false.
        zcx_mcp2_error=>raise_malformed_params(
          |Unknown io.modelcontextprotocol/logLevel '{ log_level }'| ) ##NO_TEXT.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD validate_mirror_headers.
    DATA(header_method) = http_request->get_header( zif_mcp2_const=>headers-method ).
    IF has_header( http_request = http_request
                   header_name  = zif_mcp2_const=>headers-method ) = abap_false.
      zcx_mcp2_error=>raise_header_mismatch( `Mcp-Method header is required` ) ##NO_TEXT.
    ENDIF.
    IF header_method <> request-method.
      zcx_mcp2_error=>raise_header_mismatch(
          |Mcp-Method header '{ header_method }' does not match method '{ request-method }'| ) ##NO_TEXT.
    ENDIF.

    " name_source names the body field the header has to carry. It is part of
    " every Mcp-Name error message: which field feeds the header differs per
    " method, and for tasks/* the rule lives in the Tasks extension rather than
    " the core transport document, so clients routinely miss it.
    DATA(expected_name) = ``.
    DATA(name_source)   = ``.
    DATA name_required TYPE abap_bool.
    CASE request-method.
      WHEN zif_mcp2_const=>methods-tools_call
        OR zif_mcp2_const=>methods-prompts_get.
        expected_name = request-params->get_string( '/name' ).
        name_source   = `params.name` ##NO_TEXT.
        name_required = abap_true.
      WHEN zif_mcp2_const=>methods-resources_read.
        expected_name = request-params->get_string( '/uri' ).
        name_source   = `params.uri` ##NO_TEXT.
        name_required = abap_true.
      WHEN zif_mcp2_const=>methods-tasks_get
        OR zif_mcp2_const=>methods-tasks_update
        OR zif_mcp2_const=>methods-tasks_cancel.
        " The Tasks extension mirrors params.taskId into Mcp-Name so
        " intermediaries can route by task affinity.
        " Compare the wire values before the request parser normalizes the UUID
        " for database lookup. Lowercase task ids are therefore valid when both
        " header and body use the same lowercase spelling.
        " Presence is NOT enforced here: the Tasks extension makes Mcp-Name a
        " client MUST for tasks/*, but neither it nor the core transport puts a
        " server under any duty to reject an absent one - the core "required
        " standard header missing" rule covers tools/call, prompts/get and
        " resources/read only. The stated purpose is routing affinity, and this
        " SDK serves every task from ZMCP2_TASKS, so any app server can answer
        " any tasks/* request. A header that IS sent must still match: a wrong
        " value is a genuine split-brain risk, an absent one is not.
        expected_name = request-params->get_string( '/taskId' ).
        name_source   = `params.taskId` ##NO_TEXT.
    ENDCASE.

    IF expected_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA(header_name) = http_request->get_header( zif_mcp2_const=>headers-name ).
    IF has_header( http_request = http_request
                   header_name  = zif_mcp2_const=>headers-name ) = abap_false.
      IF name_required = abap_true.
        zcx_mcp2_error=>raise_header_mismatch(
            |Mcp-Name header is required for { request-method } and must carry { name_source }| ) ##NO_TEXT.
      ENDIF.
      RETURN.
    ENDIF.
    DATA(decoded_name) = normalize_header_value(
        header_name  = zif_mcp2_const=>headers-name
        header_value = header_name ).
    IF decoded_name <> expected_name.
      zcx_mcp2_error=>raise_header_mismatch(
          |Mcp-Name header '{ header_name }' does not match { name_source } '{ expected_name }'| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD has_header.
    DATA names TYPE string_table.
    names = http_request->get_header_names( ).
    LOOP AT names INTO DATA(name).
      IF to_lower( name ) = to_lower( header_name ).
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD handle_discover.
    result = zcl_mcp2_ajson=>create_empty( ).

    " Server identity is not written here. The 2026-07-16 schema change moved
    " it out of the discover body into _meta.io.modelcontextprotocol/serverInfo
    " (ResultMetaObject), where stamp_server_info writes it for every modern
    " result, discover included.
    DATA(instructions) = server->get_instructions( ).
    IF instructions IS NOT INITIAL.
      result->set_string( iv_path = '/instructions'
                          iv_val  = instructions ).
    ENDIF.

    " Supported versions array
    result->touch_array( '/supportedVersions' ).
    result->push( iv_path = '/supportedVersions'
                  iv_val  = zif_mcp2_const=>protocol-v2026_07_28 ).
    result->push( iv_path = '/supportedVersions'
                  iv_val  = zif_mcp2_const=>protocol-v2025_11_25 ).
    result->push( iv_path = '/supportedVersions'
                  iv_val  = zif_mcp2_const=>protocol-v2025_06_18 ).
    result->push( iv_path = '/supportedVersions'
                  iv_val  = zif_mcp2_const=>protocol-v2025_03_26 ).

    result->set( iv_path = '/capabilities'
                 iv_val  = build_capabilities( ) ).
  ENDMETHOD.

  METHOD handle_tools_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_tools.

    req = NEW zcl_mcp2_req_list_tools( params ).
    result = server->tools_list( req ).
  ENDMETHOD.

  METHOD handle_tools_call.
    DATA req TYPE REF TO zcl_mcp2_req_call_tool.

    req = NEW zcl_mcp2_req_call_tool( params ).
    IF http_request IS BOUND.
      validate_param_headers( call_req     = req
                              http_request = http_request ).
    ENDIF.
    IF server->validate_tool_input( ) = abap_true.
      DATA(input_schema) = server->get_tool_schema( req->get_name( ) ).
      IF input_schema IS BOUND.
        " parse (not create_empty) so the fallback is actually node_type-object -
        " create_empty()'s root has no node type, which would make validate()
        " reject every argument-less call even against a schema with no
        " required properties.
        DATA(input_json) = COND #( WHEN req->has_arguments( ) = abap_true
                                   THEN req->get_arguments( )
                                   ELSE zcl_mcp2_ajson=>parse( '{}' ) ).
        DATA(validator) = NEW zcl_mcp2_schema_validator( input_schema ).
        IF validator->validate( input_json ) = abap_false.
          DATA(validation_msg) = concat_lines_of( table = validator->get_errors( )
                                                  sep   = `; ` ).
          result = zcl_mcp2_resp_call_tool=>error_text(
            |Invalid tool input: { validation_msg }| ) ##NO_TEXT.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.
    result = server->tools_call( req ).
  ENDMETHOD.

  METHOD validate_param_headers.
    DATA schema    TYPE REF TO zif_mcp2_ajson.
    DATA arguments TYPE REF TO zif_mcp2_ajson.
    DATA headers   TYPE param_headers.

    schema = server->get_tool_schema( call_req->get_name( ) ).
    IF schema IS INITIAL.
      RETURN.
    ENDIF.

    IF call_req->has_arguments( ) = abap_true.
      arguments = call_req->get_arguments( ).
    ENDIF.

    headers = collect_param_headers( schema ).

    LOOP AT headers INTO DATA(header_param).
      DATA(argument_path) = |/{ header_param-property_path }|.
      DATA(header_val) = http_request->get_header( header_param-header_name ).
      DATA(header_present) = has_header( http_request = http_request
                                         header_name  = header_param-header_name ).

      IF arguments IS NOT BOUND OR arguments->exists( argument_path ) = abap_false.
        IF header_present = abap_true.
          zcx_mcp2_error=>raise_header_mismatch(
              |{ header_param-header_name } supplied but argument { argument_path } is missing| ) ##NO_TEXT.
        ENDIF.
        CONTINUE.
      ENDIF.

      " Null argument values are not mirrored as headers.
      IF arguments->get_node_type( argument_path ) = zif_mcp2_ajson_types=>node_type-null.
        IF header_present = abap_true.
          zcx_mcp2_error=>raise_header_mismatch(
              |{ header_param-header_name } supplied but argument { argument_path } is null| ) ##NO_TEXT.
        ENDIF.
        CONTINUE.
      ENDIF.

      IF header_present = abap_false.
        zcx_mcp2_error=>raise_header_mismatch( |Missing { header_param-header_name } header| ) ##NO_TEXT.
      ENDIF.

      DATA(body_val) = argument_to_header_value( arguments = arguments
                                                 path      = argument_path ).

      compare_param_header( header_name   = header_param-header_name
                            header_value  = header_val
                            body_value    = body_val
                            property_type = header_param-property_type ).
    ENDLOOP.
  ENDMETHOD.

  METHOD collect_param_headers.
    DATA members        TYPE string_table.
    DATA seen_headers   TYPE string_table.

    IF schema IS NOT BOUND.
      RETURN.
    ENDIF.

    " Annotations must be statically reachable through a pure properties
    " chain; one hidden in a $defs/definitions subschema (reachable only via
    " $ref) makes the tool definition invalid - conforming clients drop the
    " tool, so reject the call instead of silently ignoring the annotation.
    DATA(defs_containers) = VALUE string_table( ( `$defs` ) ( `definitions` ) ).
    LOOP AT defs_containers INTO DATA(defs_kw).
      IF schema->exists( |/{ defs_kw }| ) = abap_true.
        " Keep method-call results explicitly typed for ABAP 7.02 downport compatibility.
        DATA defs_members TYPE string_table.
        defs_members = schema->members( |/{ defs_kw }| ).
        LOOP AT defs_members INTO DATA(defs_member).
          IF has_x_mcp_header_at_or_below( schema = schema
                                           path   = |/{ defs_kw }/{ defs_member }| ) = abap_true.
            zcx_mcp2_error=>raise_invalid_params(
                |x-mcp-header annotations under { defs_kw } are not supported: /{ defs_kw }/{ defs_member }| ) ##NO_TEXT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    IF schema->exists( '/properties' ) = abap_false.
      RETURN.
    ENDIF.

    members = schema->members( '/properties' ).
    LOOP AT members INTO DATA(property).
      DATA(property_path) = |/properties/{ property }|.
      collect_param_headers_at( EXPORTING schema        = schema
                                          schema_path   = property_path
                                          argument_path = property
                                CHANGING  headers       = result
                                          seen_headers  = seen_headers ).
    ENDLOOP.
  ENDMETHOD.

  METHOD collect_param_headers_at.
    IF schema IS NOT BOUND.
      RETURN.
    ENDIF.

    IF     schema->exists( |{ schema_path }/items| ) = abap_true
         AND has_x_mcp_header_at_or_below( schema = schema
                                           path   = |{ schema_path }/items| ) = abap_true.
        zcx_mcp2_error=>raise_invalid_params(
            |x-mcp-header annotations under arrays are not supported: { schema_path }/items| ) ##NO_TEXT.
    ENDIF.

    IF schema->exists( |{ schema_path }/x-mcp-header| ) = abap_true.
      IF schema->get_node_type( |{ schema_path }/x-mcp-header| ) <> zif_mcp2_ajson_types=>node_type-string.
        zcx_mcp2_error=>raise_invalid_params(
            |x-mcp-header must be a string: { schema_path }| ) ##NO_TEXT.
      ENDIF.
      DATA(header_suffix) = schema->get_string( |{ schema_path }/x-mcp-header| ).
      IF header_suffix IS INITIAL.
        zcx_mcp2_error=>raise_invalid_params(
            |x-mcp-header must be a non-empty string: { schema_path }| ) ##NO_TEXT.
      ENDIF.

      DATA(property_type) = schema->get_string( |{ schema_path }/type| ).
      IF property_type <> 'string' AND property_type <> 'integer' AND property_type <> 'boolean'.
        zcx_mcp2_error=>raise_invalid_params(
            |x-mcp-header is not allowed on { property_type } property { argument_path }| ) ##NO_TEXT.
      ENDIF.

      IF is_valid_header_suffix( header_suffix ) = abap_false.
        zcx_mcp2_error=>raise_invalid_params(
            |Invalid x-mcp-header value for { argument_path }: { header_suffix }| ) ##NO_TEXT.
      ENDIF.

      DATA(header_key) = to_lower( header_suffix ).
      IF line_exists( seen_headers[ table_line = header_key ] ).
        zcx_mcp2_error=>raise_invalid_params( |Duplicate x-mcp-header value: { header_suffix }| ) ##NO_TEXT.
      ENDIF.
      APPEND header_key TO seen_headers.

      APPEND VALUE #( property_path = argument_path
                      property_type = property_type
                      header_suffix = header_suffix
                      header_name   = |Mcp-Param-{ header_suffix }| ) TO headers ##NO_TEXT.
    ENDIF.

    IF schema->exists( |{ schema_path }/properties| ) = abap_true.
      DATA nested_members TYPE string_table.
      nested_members = schema->members( |{ schema_path }/properties| ).
      LOOP AT nested_members INTO DATA(nested_property).
        collect_param_headers_at(
          EXPORTING schema        = schema
                    schema_path   = |{ schema_path }/properties/{ nested_property }|
                    argument_path = |{ argument_path }/{ nested_property }|
          CHANGING  headers       = headers
                    seen_headers  = seen_headers ).
      ENDLOOP.
    ENDIF.

    " Reject x-mcp-header annotations hidden inside schema composition keywords -
    " their semantics are undefined and clients conforming to the draft would reject
    " the tool definition.
    " Single-schema keywords: the path is itself a schema object.
    DATA(single_compos_kws) = VALUE string_table( ( `not` ) ( `if` ) ( `then` ) ( `else` ) ).
    LOOP AT single_compos_kws INTO DATA(single_ckw).
      IF     schema->exists( |{ schema_path }/{ single_ckw }| ) = abap_true
         AND has_x_mcp_header_at_or_below( schema = schema
                                           path   = |{ schema_path }/{ single_ckw }| ) = abap_true.
        zcx_mcp2_error=>raise_invalid_params(
            |x-mcp-header annotations under { single_ckw } are not supported: { schema_path }/{ single_ckw }| ) ##NO_TEXT.
      ENDIF.
    ENDLOOP.
    " Array-schema keywords: the path is a JSON array - iterate its elements.
    DATA(array_compos_kws) = VALUE string_table( ( `oneOf` ) ( `anyOf` ) ( `allOf` ) ).
    LOOP AT array_compos_kws INTO DATA(array_ckw).
      IF schema->exists( |{ schema_path }/{ array_ckw }| ) = abap_true.
        DATA ckw_members TYPE string_table.
        ckw_members = schema->members( |{ schema_path }/{ array_ckw }| ).
        LOOP AT ckw_members INTO DATA(ckw_idx).
          IF has_x_mcp_header_at_or_below( schema = schema
                                           path   = |{ schema_path }/{ array_ckw }/{ ckw_idx }| ) = abap_true.
            zcx_mcp2_error=>raise_invalid_params(
                |x-mcp-header annotations under { array_ckw } are not supported: { schema_path }/{ array_ckw }| ) ##NO_TEXT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD has_x_mcp_header_at_or_below.
    IF schema IS NOT BOUND.
      RETURN.
    ENDIF.

    IF schema->exists( |{ path }/x-mcp-header| ) = abap_true.
      result = abap_true.
      RETURN.
    ENDIF.

    IF schema->exists( |{ path }/properties| ) = abap_true.
      DATA members TYPE string_table.
      members = schema->members( |{ path }/properties| ).
      LOOP AT members INTO DATA(member).
        IF has_x_mcp_header_at_or_below( schema = schema
                                         path   = |{ path }/properties/{ member }| ) = abap_true.
          result = abap_true.
          RETURN.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF     schema->exists( |{ path }/items| ) = abap_true
       AND has_x_mcp_header_at_or_below( schema = schema
                                         path   = |{ path }/items| ) = abap_true.
      result = abap_true.
      RETURN.
    ENDIF.

    " Check single-schema composition keywords (not, if, then, else)
    DATA(single_compos) = VALUE string_table( ( `not` ) ( `if` ) ( `then` ) ( `else` ) ).
    LOOP AT single_compos INTO DATA(single_kw).
      IF     schema->exists( |{ path }/{ single_kw }| ) = abap_true
         AND has_x_mcp_header_at_or_below( schema = schema
                                           path   = |{ path }/{ single_kw }| ) = abap_true.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

    " Check array-schema composition keywords (oneOf, anyOf, allOf)
    DATA(array_compos) = VALUE string_table( ( `oneOf` ) ( `anyOf` ) ( `allOf` ) ).
    LOOP AT array_compos INTO DATA(array_kw).
      IF schema->exists( |{ path }/{ array_kw }| ) = abap_true.
        DATA compos_sub TYPE string_table.
        compos_sub = schema->members( |{ path }/{ array_kw }| ).
        LOOP AT compos_sub INTO DATA(sub_idx).
          IF has_x_mcp_header_at_or_below( schema = schema
                                           path   = |{ path }/{ array_kw }/{ sub_idx }| ) = abap_true.
            result = abap_true.
            RETURN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_valid_header_suffix.
    DATA allowed TYPE string VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&''*+-.^_`|~' ##NO_TEXT.

    result = abap_false.
    IF suffix IS INITIAL.
      RETURN.
    ENDIF.

    IF suffix CO allowed.
      result = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD argument_to_header_value.
    CASE arguments->get_node_type( path ).
      WHEN 'bool'.
        IF arguments->get_boolean( path ) = abap_true.
          result = `true`.
        ELSE.
          result = `false`.
        ENDIF.
      WHEN OTHERS.
        result = arguments->get_string( path ).
    ENDCASE.
  ENDMETHOD.

  METHOD normalize_header_value.
    result = header_value.
    DATA(value_len) = strlen( header_value ).
    DATA(decoded_from_base64) = abap_false.

    IF value_len >= 11.
      DATA(end_offset) = value_len - 2.
      IF     header_value(9)            = `=?base64?`
         AND header_value+end_offset(2) = `?=`.
        DATA(encoded_len) = value_len - 11.
        DATA(encoded) = header_value+9(encoded_len).

        IF encoded IS INITIAL OR encoded CN `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=` ##NO_TEXT.
          zcx_mcp2_error=>raise_header_mismatch( |Invalid { header_name } base64 value| ) ##NO_TEXT.
        ENDIF.

        DATA decoded TYPE xstring.
        CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
          EXPORTING  input    = encoded
                     unescape = ``
          IMPORTING  output   = decoded
          EXCEPTIONS failed   = 1
                     OTHERS   = 2.
        IF sy-subrc <> 0.
          zcx_mcp2_error=>raise_header_mismatch( |Invalid { header_name } base64 value| ) ##NO_TEXT.
        ENDIF.

        TRY.
            result = cl_abap_codepage=>convert_from( decoded ).
            decoded_from_base64 = abap_true.
          CATCH cx_root.
            zcx_mcp2_error=>raise_header_mismatch( |Invalid { header_name } base64 text| ) ##NO_TEXT.
        ENDTRY.
      ENDIF.
    ENDIF.

    " No other encoding exists: a value without the base64 sentinel is a
    " literal (SEP-2243). In particular there is no percent-encoding - a
    " header value containing %XX must compare byte-for-byte with the body.
    IF decoded_from_base64 = abap_false.
      assert_header_value_safe( header_name  = header_name
                                header_value = result ).
    ENDIF.
  ENDMETHOD.

  METHOD assert_header_value_safe.
    " Plain (non-base64) header values must contain only printable ASCII (0x20-0x7E)
    " and HTAB (0x09) per RFC 9110. Other control characters, DEL, non-ASCII, and
    " leading/trailing whitespace are disallowed - clients must base64-encode those.
    IF header_value IS INITIAL.
      RETURN.
    ENDIF.

    DATA(htab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(allowed) = ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'
                 && '`abcdefghijklmnopqrstuvwxyz{|}~'
                 && htab ##NO_TEXT.

    IF header_value CN allowed.
      zcx_mcp2_error=>raise_header_mismatch( |Invalid characters in { header_name }| ) ##NO_TEXT.
    ENDIF.

    DATA(first_char) = header_value(1).
    DATA(last_pos)   = strlen( header_value ) - 1.
    DATA(last_char)  = header_value+last_pos(1).
    IF first_char = ' ' OR first_char = htab
    OR last_char  = ' ' OR last_char  = htab.
      zcx_mcp2_error=>raise_header_mismatch( |Leading/trailing whitespace in { header_name }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD compare_param_header.
    DATA(normalized_header) = normalize_header_value( header_name  = header_name
                                                      header_value = header_value ).

    CASE property_type.
      WHEN `integer`.
        assert_safe_integer_text( header_name = header_name
                                  value       = normalized_header ).
        assert_safe_integer_text( header_name = header_name
                                  value       = body_value ).

        DATA(header_number) = CONV decfloat34( normalized_header ).
        DATA(body_number) = CONV decfloat34( body_value ).
        IF header_number <> body_number.
          zcx_mcp2_error=>raise_header_mismatch( |{ header_name } mismatch: { normalized_header } <> { body_value }| ).
        ENDIF.

      WHEN `boolean`.
        IF normalized_header <> `true` AND normalized_header <> `false`.
          zcx_mcp2_error=>raise_header_mismatch( |Invalid boolean value in { header_name }| ) ##NO_TEXT.
        ENDIF.
        IF normalized_header <> body_value.
          zcx_mcp2_error=>raise_header_mismatch( |{ header_name } mismatch: { normalized_header } <> { body_value }| ).
        ENDIF.

      WHEN OTHERS.
        IF normalized_header <> body_value.
          zcx_mcp2_error=>raise_header_mismatch( |{ header_name } mismatch: { normalized_header } <> { body_value }| ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD assert_safe_integer_text.
    CONSTANTS max_safe TYPE decfloat34 VALUE '9007199254740991'.
    CONSTANTS min_safe TYPE decfloat34 VALUE '-9007199254740991'.

    IF value IS INITIAL.
      zcx_mcp2_error=>raise_header_mismatch( |Invalid integer value in { header_name }| ) ##NO_TEXT.
    ENDIF.

    " The transport asks servers to compare integer headers numerically
    " (42.0 == 42), so tolerate an all-zero fractional part before comparing.
    FIND REGEX `^-?[0-9]+(\.0+)?$` IN value.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_header_mismatch( |Invalid integer value in { header_name }| ) ##NO_TEXT.
    ENDIF.

    TRY.
        DATA(numeric_value) = CONV decfloat34( value ).
      CATCH cx_root.
        zcx_mcp2_error=>raise_header_mismatch( |Invalid integer value in { header_name }| ) ##NO_TEXT.
    ENDTRY.

    IF numeric_value > max_safe OR numeric_value < min_safe.
      zcx_mcp2_error=>raise_header_mismatch( |Unsafe integer value in { header_name }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD handle_resources_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_resources.

    req = NEW zcl_mcp2_req_list_resources( params ).
    result = server->resources_list( req ).
  ENDMETHOD.

  METHOD handle_resources_read.
    DATA req TYPE REF TO zcl_mcp2_req_read_resource.

    req = NEW zcl_mcp2_req_read_resource( params ).
    result = server->resources_read( req ).
  ENDMETHOD.

  METHOD handle_resources_tmpls.
    DATA req TYPE REF TO zcl_mcp2_req_list_res_tmpls.

    req = NEW zcl_mcp2_req_list_res_tmpls( params ).
    result = server->resources_tmpls_list( req ).
  ENDMETHOD.

  METHOD handle_prompts_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_prompts.

    req = NEW zcl_mcp2_req_list_prompts( params ).
    result = server->prompts_list( req ).
  ENDMETHOD.

  METHOD handle_prompts_get.
    DATA req TYPE REF TO zcl_mcp2_req_get_prompt.

    req = NEW zcl_mcp2_req_get_prompt( params ).
    result = server->prompts_get( req ).
  ENDMETHOD.

  METHOD handle_completions.
    DATA req TYPE REF TO zcl_mcp2_req_complete.

    req = NEW zcl_mcp2_req_complete( params ).
    result = server->completions_complete( req ).
  ENDMETHOD.

  METHOD stamp_result.
    result = mcp_result->to_json( ).

    DATA(rtype) = mcp_result->result_type( ).
    IF rtype IS NOT INITIAL.
      result->set_string( iv_path = '/resultType'
                          iv_val  = rtype ).
    ELSE.
      result->set_string( iv_path = '/resultType'
                          iv_val  = zif_mcp2_const=>result_types-complete ).
    ENDIF.

    stamp_server_info( result ).

    " Central enforcement: a task result requires the client to have declared the extension.
    IF rtype = zif_mcp2_const=>result_types-task.
      DATA(ctx) = server->get_context( ).
      DATA(has_ext) = abap_false.
      IF ctx-client_caps IS BOUND.
        DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
        DATA(task_ext_path) = '/extensions/io.modelcontextprotocol' && tab && 'tasks'.
        has_ext = xsdbool(
             ctx-client_caps->exists( task_ext_path ) = abap_true
         AND ctx-client_caps->get_node_type( task_ext_path )
             = zif_mcp2_ajson_types=>node_type-object ).
      ENDIF.
      IF has_ext = abap_false.
        " data.requiredCapabilities is a ClientCapabilities-shaped object, not
        " a string list. Build it by parsing literal JSON so the slash-bearing
        " extension key survives without ajson tab escaping.
        zcx_mcp2_error=>raise_missing_cap(
          `extensions/io.modelcontextprotocol/tasks` ).
      ENDIF.
    ENDIF.

    " Central enforcement: input_required is only valid from tools/call, prompts/get,
    " and resources/read; and each inputRequests method must map to a declared client capability.
    IF rtype = zif_mcp2_const=>result_types-input_required.
      IF     method <> zif_mcp2_const=>methods-tools_call
         AND method <> zif_mcp2_const=>methods-prompts_get
         AND method <> zif_mcp2_const=>methods-resources_read.
        RAISE EXCEPTION NEW zcx_mcp2_error(
          error_code = zif_mcp2_const=>error_codes-internal_error
          error_msg  = |input_required is not valid for { method }| ) ##NO_TEXT.
      ENDIF.

      DATA(has_request_state) = xsdbool(
           result->exists( '/requestState' ) = abap_true
       AND result->get_string( '/requestState' ) IS NOT INITIAL ).
      DATA(has_input_requests) = abap_false.
      IF result->exists( '/inputRequests' ) = abap_true.
        has_input_requests = xsdbool( lines( result->members( '/inputRequests' ) ) > 0 ).
        DATA(ir_ctx) = server->get_context( ).
        DATA input_request_keys TYPE string_table.
        input_request_keys = result->members( '/inputRequests' ).
        DATA ir_key TYPE string.
        LOOP AT input_request_keys INTO ir_key.
          DATA(ir_method) = result->get_string( |/inputRequests/{ ir_key }/method| ).
          DATA(ir_slash)  = find( val = ir_method sub = `/` ).
          IF ir_slash <= 0.
            zcx_mcp2_error=>raise_missing_cap( ir_method ).
          ENDIF.
          DATA(ir_cap)     = ir_method(ir_slash).
          DATA(ir_has_cap) = abap_false.
          IF ir_ctx-client_caps IS BOUND.
            ir_has_cap = ir_ctx-client_caps->exists( '/' && ir_cap ).
          ENDIF.
          IF ir_has_cap = abap_false.
            zcx_mcp2_error=>raise_missing_cap( ir_cap ).
          ENDIF.
          DATA(ir_mode_path) = |/inputRequests/{ ir_key }/params/mode|.
          IF ir_method = zif_mcp2_const=>methods-elicitation_create.
            DATA(ir_elicit_cap) = |/{ zif_mcp2_const=>client_caps-elicitation }|.
            DATA(ir_mode) = COND string( WHEN result->exists( ir_mode_path ) = abap_true
                                         THEN result->get_string( ir_mode_path )
                                         ELSE zif_mcp2_const=>elicit_modes-form ).
            IF ir_mode = zif_mcp2_const=>elicit_modes-url.
              " URL mode is never implicit - the client must declare elicitation.url.
              DATA(ir_has_url_cap) = abap_false.
              IF ir_ctx-client_caps IS BOUND.
                ir_has_url_cap = ir_ctx-client_caps->exists( |{ ir_elicit_cap }/url| ).
              ENDIF.
              IF ir_has_url_cap = abap_false.
                zcx_mcp2_error=>raise_missing_cap( `elicitation/url` ).
              ENDIF.
            ELSE.
              " Form mode (explicit or default): supported when the client declared
              " elicitation/form, or a bare elicitation object (neither form nor url
              " subkey) which the spec treats as form-only. Mirrors the base-class
              " client_supports_elicitation( ) rule.
              DATA(ir_has_form_cap) = abap_false.
              IF ir_ctx-client_caps IS BOUND.
                ir_has_form_cap = xsdbool(
                     ir_ctx-client_caps->exists( |{ ir_elicit_cap }/form| ) = abap_true
                  OR (     ir_ctx-client_caps->exists( |{ ir_elicit_cap }/form| ) = abap_false
                       AND ir_ctx-client_caps->exists( |{ ir_elicit_cap }/url| )  = abap_false ) ).
              ENDIF.
              IF ir_has_form_cap = abap_false.
                zcx_mcp2_error=>raise_missing_cap( `elicitation/form` ).
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

      IF has_request_state = abap_false AND has_input_requests = abap_false.
        RAISE EXCEPTION NEW zcx_mcp2_error(
          error_code = zif_mcp2_const=>error_codes-internal_error
          error_msg  = `input_required requires inputRequests or requestState` ) ##NO_TEXT.
      ENDIF.
    ENDIF.

    IF mcp_result->is_cacheable( ) = abap_true.
      IF input_dependent = abap_true.
        stamp_cache_fields( json  = result
                            ttl   = 0
                            scope = zif_mcp2_const=>cache_scopes-private ).
      ELSE.
        stamp_cache_fields( json  = result
                            ttl   = mcp_result->ttl_ms( )
                            scope = mcp_result->cache_scope( ) ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD stamp_cache_fields.
    DATA safe_ttl TYPE i.

    safe_ttl = ttl.
    IF safe_ttl < 0.
      safe_ttl = 0.
    ENDIF.

    json->set_integer( iv_path = '/ttlMs'
                       iv_val  = safe_ttl ).
    IF    scope = zif_mcp2_const=>cache_scopes-public
       OR scope = zif_mcp2_const=>cache_scopes-private.
      json->set_string( iv_path = '/cacheScope'
                        iv_val  = scope ).
    ELSE.
      json->set_string( iv_path = '/cacheScope'
                        iv_val  = zif_mcp2_const=>cache_scopes-private ).
    ENDIF.
  ENDMETHOD.

  METHOD stamp_server_info.
    DATA(tab)  = cl_abap_char_utilities=>horizontal_tab.
    DATA(path) = '/_meta/io.modelcontextprotocol' && tab && 'serverInfo'.

    json->set_string( iv_path = |{ path }/name|
                      iv_val  = server->get_name( ) ).
    json->set_string( iv_path = |{ path }/version|
                      iv_val  = server->get_version( ) ).
    DATA(title) = server->get_title( ).
    IF title IS NOT INITIAL.
      json->set_string( iv_path = |{ path }/title|
                        iv_val  = title ).
    ENDIF.
    DATA(description) = server->get_description( ).
    IF description IS NOT INITIAL.
      json->set_string( iv_path = |{ path }/description|
                        iv_val  = description ).
    ENDIF.
    DATA(website_url) = server->get_website_url( ).
    IF website_url IS NOT INITIAL.
      json->set_string( iv_path = |{ path }/websiteUrl|
                        iv_val  = website_url ).
    ENDIF.
    zcl_mcp2_icons=>emit( json  = json
                          path  = |{ path }/icons|
                          icons = server->get_icons( ) ).
  ENDMETHOD.

  METHOD handle_tasks_get.
    DATA req TYPE REF TO zcl_mcp2_req_get_task.

    req = NEW zcl_mcp2_req_get_task( params ).
    result = server->tasks_get( req ).
  ENDMETHOD.

  METHOD handle_tasks_update.
    DATA req TYPE REF TO zcl_mcp2_req_update_task.

    req = NEW zcl_mcp2_req_update_task( params ).
    result = server->tasks_update( req ).
  ENDMETHOD.

  METHOD handle_tasks_cancel.
    DATA req TYPE REF TO zcl_mcp2_req_cancel_task.

    req = NEW zcl_mcp2_req_cancel_task( params ).
    result = server->tasks_cancel( req ).
  ENDMETHOD.

  METHOD require_tasks_capability.
    DATA(ctx) = server->get_context( ).
    DATA(has_tasks) = abap_false.
    IF ctx-client_caps IS BOUND.
      DATA(tasks_path) = '/extensions/io.modelcontextprotocol'
        && cl_abap_char_utilities=>horizontal_tab && 'tasks'.
      has_tasks = xsdbool(
           ctx-client_caps->exists( tasks_path ) = abap_true
       AND ctx-client_caps->get_node_type( tasks_path )
           = zif_mcp2_ajson_types=>node_type-object ).
    ENDIF.
    IF has_tasks = abap_false.
      zcx_mcp2_error=>raise_missing_cap(
        `extensions/io.modelcontextprotocol/tasks` ).
    ENDIF.
  ENDMETHOD.

  METHOD build_capabilities.
    result = zcl_mcp2_ajson=>parse( '{}' ).
    IF server->supports_tools( ) = abap_true.
      result->set( iv_path = '/tools'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.
    IF server->supports_resources( ) = abap_true.
      result->set( iv_path = '/resources'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.
    IF server->supports_prompts( ) = abap_true.
      result->set( iv_path = '/prompts'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.
    IF server->supports_completions( ) = abap_true.
      result->set( iv_path = '/completions'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.
    IF server->supports_tasks( ) = abap_true.
      result->set(
        iv_path = '/extensions/io.modelcontextprotocol'
                  && cl_abap_char_utilities=>horizontal_tab
                  && 'tasks'
        iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD set_modern_context.
    DATA ctx TYPE zif_mcp2_server=>context.
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(path_proto_ver)   = '/_meta/io.modelcontextprotocol' && tab && 'protocolVersion'.
    DATA(path_client_info) = '/_meta/io.modelcontextprotocol' && tab && 'clientInfo'.
    DATA(path_client_caps) = '/_meta/io.modelcontextprotocol' && tab && 'clientCapabilities'.

    ctx-era = zif_mcp2_const=>eras-modern.

    IF params->exists( path_proto_ver ).
      ctx-protocol_ver = params->get_string( path_proto_ver ).
    ELSE.
      ctx-protocol_ver = zif_mcp2_const=>protocol-v2026_07_28.
    ENDIF.

    IF params->exists( path_client_info ).
      ctx-client_info    = params->slice( path_client_info ).
      ctx-client-name    = params->get_string( |{ path_client_info }/name| ).
      ctx-client-version = params->get_string( |{ path_client_info }/version| ).
      ctx-client-title   = params->get_string( |{ path_client_info }/title| ).
    ENDIF.

    IF params->exists( path_client_caps ).
      ctx-client_caps = params->slice( path_client_caps ).
    ENDIF.

    IF params->exists( '/_meta' ).
      ctx-meta = params->slice( '/_meta' ).
    ENDIF.

    server->set_context( ctx ).
  ENDMETHOD.
ENDCLASS.
