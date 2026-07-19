"! <p class="shorttext synchronized">MCP2 legacy era dispatcher (2025-*)</p>
"! Routes initialize/ping and the standard method set for the 2025-* protocol
"! family. Does NOT stamp resultType - that field is modern-only.
"! The server context is populated before each handler call.
CLASS zcl_mcp2_dispatch_legacy DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Create a legacy dispatcher for a server</p>
    "! @parameter mcp_server | The SDK user's server implementation
    METHODS constructor
      IMPORTING mcp_server TYPE REF TO zif_mcp2_server.

    "! <p class="shorttext synchronized">Dispatch one legacy JSON-RPC request</p>
    "! Dispatch one JSON-RPC request and return the response struct.
    "! Never raises - all errors are converted to error-response structs.
    "! @parameter request | Parsed JSON-RPC request
    "! @parameter result  | JSON-RPC response (success or error)
    METHODS dispatch
      IMPORTING !request      TYPE zcl_mcp2_jsonrpc=>request
      RETURNING VALUE(result) TYPE zcl_mcp2_jsonrpc=>response.

  PRIVATE SECTION.
    DATA server TYPE REF TO zif_mcp2_server.

    "! <p class="shorttext synchronized">Handle ping (empty result)</p>
    "! @parameter result | Empty JSON object
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_ping
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle initialize (stateless handshake)</p>
    "! Negotiates the version and advertises capabilities; no session created.
    "! @parameter params | initialize params (protocolVersion, clientInfo, ...)
    "! @parameter result | initialize result
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_initialize
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tools/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tools_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tools/call</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tools_call
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle resources/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_resources_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle resources/read</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_resources_read
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle resources/templates/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_resources_tmpls
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle prompts/list</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_prompts_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle prompts/get</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_prompts_get
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle completion/complete</p>
    "! @parameter params | Request params slice
    "! @parameter result | Serialized result body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_completions
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/list (legacy)</p>
    "! @parameter params | Request params slice
    "! @parameter result | Task list body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_list
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/get (legacy)</p>
    "! @parameter params | Request params slice
    "! @parameter result | Task body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_get
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/result (legacy)</p>
    "! @parameter params | Request params slice
    "! @parameter result | Payload body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_result
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle tasks/cancel (legacy)</p>
    "! @parameter params | Request params slice
    "! @parameter result | Cancellation body
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS handle_tasks_cancel
      IMPORTING params        TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the advertised capabilities object</p>
    "! @parameter result | capabilities object reflecting supports_* flags
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_capabilities
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Populate the server context for the request</p>
    "! @parameter params | initialize params carrying client info/caps
    "! @parameter ver    | Negotiated protocol version
    METHODS set_legacy_context
      IMPORTING params TYPE REF TO zif_mcp2_ajson
                ver    TYPE string.

    "! <p class="shorttext synchronized">Stamp the minimal per-request context</p>
    "! Statelessly, only initialize carries client info - every other legacy
    "! request still gets era + the legacy baseline version so era checks and
    "! get_protocol_version work in any handler. initialize overwrites this
    "! with the negotiated values. For tools/call the per-request task opt-in
    "! (params.task) is recorded so client_supports_tasks( ) works in legacy.
    "! @parameter method | JSON-RPC method of the request
    "! @parameter params | Request params (optional _meta slice)
    METHODS stamp_request_context
      IMPORTING !method TYPE string
                params  TYPE REF TO zif_mcp2_ajson.

ENDCLASS.


CLASS zcl_mcp2_dispatch_legacy IMPLEMENTATION.
  METHOD constructor.
    server = mcp_server.
  ENDMETHOD.

  METHOD dispatch.
    TRY.
        DATA result_json TYPE REF TO zif_mcp2_ajson.

        stamp_request_context( method = request-method
                               params = request-params ).

        CASE request-method.
          WHEN zif_mcp2_const=>methods-ping.
            result_json = handle_ping( ).

          WHEN zif_mcp2_const=>methods-initialize.
            result_json = handle_initialize( request-params ).

          WHEN zif_mcp2_const=>methods-tools_list.
            IF server->supports_tools( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_tools_list( request-params ).

          WHEN zif_mcp2_const=>methods-tools_call.
            IF server->supports_tools( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_tools_call( request-params ).

          WHEN zif_mcp2_const=>methods-resources_list.
            IF server->supports_resources( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_resources_list( request-params ).

          WHEN zif_mcp2_const=>methods-resources_read.
            IF server->supports_resources( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_resources_read( request-params ).

          WHEN zif_mcp2_const=>methods-resources_tmpls_list.
            IF server->supports_resources( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_resources_tmpls( request-params ).

          WHEN zif_mcp2_const=>methods-prompts_list.
            IF server->supports_prompts( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_prompts_list( request-params ).

          WHEN zif_mcp2_const=>methods-prompts_get.
            IF server->supports_prompts( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_prompts_get( request-params ).

          WHEN zif_mcp2_const=>methods-completions.
            IF server->supports_completions( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_completions( request-params ).

          WHEN zif_mcp2_const=>methods-tasks_list.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_tasks_list( request-params ).

          WHEN zif_mcp2_const=>methods-tasks_get.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_tasks_get( request-params ).

          WHEN zif_mcp2_const=>methods-tasks_result.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_tasks_result( request-params ).

          WHEN zif_mcp2_const=>methods-tasks_cancel.
            IF server->supports_tasks( ) = abap_false.
              zcx_mcp2_error=>raise_method_not_found( request-method ).
            ENDIF.
            result_json = handle_tasks_cancel( request-params ).

          WHEN zif_mcp2_const=>methods-tasks_update.
            zcx_mcp2_error=>raise_invalid_req( `tasks/update is only available to modern clients` ) ##NO_TEXT.

          WHEN OTHERS.
            zcx_mcp2_error=>raise_method_not_found( request-method ).
        ENDCASE.

        result = zcl_mcp2_jsonrpc=>build_success( request     = request
                                                  result_json = result_json ).

      CATCH zcx_mcp2_error INTO DATA(proto_err).
        result = zcl_mcp2_jsonrpc=>build_from_exc( request = request
                                                   exc     = proto_err ).

      CATCH zcx_mcp2_ajson_error INTO DATA(json_err).
        result = zcl_mcp2_jsonrpc=>build_error( request = request
                                                code    = zif_mcp2_const=>error_codes-internal_error
                                                message = json_err->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD handle_ping.
    result = zcl_mcp2_ajson=>parse( '{}' ).
  ENDMETHOD.

  METHOD handle_initialize.
    " Extract client-proposed version and negotiate.
    DATA(client_ver) = params->get_string( '/protocolVersion' ).
    DATA(agreed_ver) = zcl_mcp2_version=>negotiate_legacy( client_ver ).

    IF    params->exists( '/clientInfo' )              = abap_false
       OR params->get_node_type( '/clientInfo' )      <> zif_mcp2_ajson_types=>node_type-object
       OR params->get_string( '/clientInfo/name' )    IS INITIAL
       OR params->get_string( '/clientInfo/version' ) IS INITIAL.
      zcx_mcp2_error=>raise_invalid_params( `initialize requires clientInfo with name and version` ) ##NO_TEXT.
    ENDIF.

    IF    params->exists( '/capabilities' )         = abap_false
       OR params->get_node_type( '/capabilities' ) <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_invalid_params( `initialize requires capabilities object` ) ##NO_TEXT.
    ENDIF.

    " Build server context so handlers can inspect capabilities.
    set_legacy_context( params = params
                        ver    = agreed_ver ).

    " Build the initialize response.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->set_string( iv_path = '/protocolVersion'
                        iv_val  = agreed_ver ).
    result->set_string( iv_path = '/serverInfo/name'
                        iv_val  = server->get_name( ) ).
    result->set_string( iv_path = '/serverInfo/version'
                        iv_val  = server->get_version( ) ).
    " Optional Implementation fields (title since 2025-06-18,
    " description/websiteUrl/icons part of the 2025-11-25 baseline shape).
    DATA(title) = server->get_title( ).
    IF title IS NOT INITIAL.
      result->set_string( iv_path = '/serverInfo/title'
                          iv_val  = title ).
    ENDIF.
    DATA(description) = server->get_description( ).
    IF description IS NOT INITIAL.
      result->set_string( iv_path = '/serverInfo/description'
                          iv_val  = description ).
    ENDIF.
    DATA(website_url) = server->get_website_url( ).
    IF website_url IS NOT INITIAL.
      result->set_string( iv_path = '/serverInfo/websiteUrl'
                          iv_val  = website_url ).
    ENDIF.
    zcl_mcp2_icons=>emit( json  = result
                          path  = '/serverInfo/icons'
                          icons = server->get_icons( ) ).

    DATA(instructions) = server->get_instructions( ).
    IF instructions IS NOT INITIAL.
      result->set_string( iv_path = '/instructions'
                          iv_val  = instructions ).
    ENDIF.

    DATA(caps) = build_capabilities( ).
    result->set( iv_path = '/capabilities'
                 iv_val  = caps ).
  ENDMETHOD.

  METHOD handle_tools_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_tools.

    req = NEW zcl_mcp2_req_list_tools( params ).
    DATA(mcp_result) = server->tools_list( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_tools_call.
    DATA req TYPE REF TO zcl_mcp2_req_call_tool.

    req = NEW zcl_mcp2_req_call_tool( params ).
    IF server->validate_tool_input( ) = abap_true.
      DATA(input_schema) = server->get_tool_schema( req->get_name( ) ).
      IF input_schema IS BOUND.
        DATA(input_json) = COND #( WHEN req->has_arguments( ) = abap_true
                                   THEN req->get_arguments( )
                                   ELSE zcl_mcp2_ajson=>parse( '{}' ) ).
        DATA(validator) = NEW zcl_mcp2_schema_validator( input_schema ).
        IF validator->validate( input_json ) = abap_false.
          DATA(validation_msg) = concat_lines_of( table = validator->get_errors( )
                                                  sep   = `; ` ).
          DATA(validation_result) = zcl_mcp2_resp_call_tool=>error_text(
            |Invalid tool input: { validation_msg }| ) ##NO_TEXT.
          result = validation_result->zif_mcp2_result~to_json( ).
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.
    DATA(mcp_result) = server->tools_call( req ).
    IF mcp_result->result_type( ) = zif_mcp2_const=>result_types-input_required.
      zcx_mcp2_error=>raise_invalid_req(
          `inputRequired is not answerable on the stateless legacy transport;` &&
          ` gate the call behind supports_input_required()` ) ##NO_TEXT.
    ENDIF.
    " 2025-11-25 tasks: a CreateTaskResult may only answer a task-augmented
    " request (params.task). Protect non-opted-in legacy clients from a shape
    " they cannot parse; handlers gate with client_supports_tasks( ) to fall
    " back to a synchronous result instead.
    IF     mcp_result->result_type( ) = zif_mcp2_const=>result_types-task
       AND req->has_task_request( )   = abap_false.
      zcx_mcp2_error=>raise_invalid_req(
          `Task results require the legacy per-request opt-in (params.task);` &&
          ` gate the call behind client_supports_tasks()` ) ##NO_TEXT.
    ENDIF.
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_resources_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_resources.

    req = NEW zcl_mcp2_req_list_resources( params ).
    DATA(mcp_result) = server->resources_list( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_resources_read.
    DATA req TYPE REF TO zcl_mcp2_req_read_resource.

    req = NEW zcl_mcp2_req_read_resource( params ).
    DATA(mcp_result) = server->resources_read( req ).
    IF mcp_result->result_type( ) = zif_mcp2_const=>result_types-input_required.
      zcx_mcp2_error=>raise_invalid_req(
          `inputRequired is not answerable on the stateless legacy transport;` &&
          ` gate the call behind supports_input_required()` ) ##NO_TEXT.
    ENDIF.
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_resources_tmpls.
    DATA req TYPE REF TO zcl_mcp2_req_list_res_tmpls.

    req = NEW zcl_mcp2_req_list_res_tmpls( params ).
    DATA(mcp_result) = server->resources_tmpls_list( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_prompts_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_prompts.

    req = NEW zcl_mcp2_req_list_prompts( params ).
    DATA(mcp_result) = server->prompts_list( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_prompts_get.
    DATA req TYPE REF TO zcl_mcp2_req_get_prompt.

    req = NEW zcl_mcp2_req_get_prompt( params ).
    DATA(mcp_result) = server->prompts_get( req ).
    IF mcp_result->result_type( ) = zif_mcp2_const=>result_types-input_required.
      zcx_mcp2_error=>raise_invalid_req(
          `inputRequired is not answerable on the stateless legacy transport;` &&
          ` gate the call behind supports_input_required()` ) ##NO_TEXT.
    ENDIF.
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_completions.
    DATA req TYPE REF TO zcl_mcp2_req_complete.

    req = NEW zcl_mcp2_req_complete( params ).
    DATA(mcp_result) = server->completions_complete( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_tasks_list.
    DATA req TYPE REF TO zcl_mcp2_req_list_tasks.

    req = NEW zcl_mcp2_req_list_tasks( params ).
    DATA(mcp_result) = server->tasks_list( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_tasks_get.
    DATA req TYPE REF TO zcl_mcp2_req_get_task.

    req = NEW zcl_mcp2_req_get_task( params ).
    DATA(mcp_result) = server->tasks_get( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_tasks_result.
    DATA req TYPE REF TO zcl_mcp2_req_get_task_payload.

    req = NEW zcl_mcp2_req_get_task_payload( params ).
    DATA(mcp_result) = server->tasks_result( req ).
    result = mcp_result->to_json( ).
  ENDMETHOD.

  METHOD handle_tasks_cancel.
    DATA req TYPE REF TO zcl_mcp2_req_cancel_task.

    req = NEW zcl_mcp2_req_cancel_task( params ).
    DATA(mcp_result) = server->tasks_cancel( req ).
    result = mcp_result->to_json( ).
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
    " 2025-11-25 tasks capability shape: tasks.{list,cancel,requests.tools.call}.
    " (The draft's capabilities.extensions key does not exist in the legacy era.)
    IF server->supports_tasks( ) = abap_true.
      result->set( iv_path = '/tasks/list'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
      result->set( iv_path = '/tasks/cancel'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
      result->set( iv_path = '/tasks/requests/tools/call'
                   iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD stamp_request_context.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era          = zif_mcp2_const=>eras-legacy.
    ctx-protocol_ver = zif_mcp2_const=>protocol-latest_legacy.
    IF params IS BOUND AND params->exists( '/_meta' ).
      ctx-meta = params->slice( '/_meta' ).
    ENDIF.
    IF     method = zif_mcp2_const=>methods-tools_call
       AND params IS BOUND
       AND params->exists( '/task' ).
      ctx-task_requested = abap_true.
    ENDIF.
    server->set_context( ctx ).
  ENDMETHOD.

  METHOD set_legacy_context.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era = zif_mcp2_const=>eras-legacy.
    ctx-protocol_ver = ver.
    IF params->exists( '/clientInfo' ).
      ctx-client_info = params->slice( '/clientInfo' ).
      ctx-client-name    = params->get_string( '/clientInfo/name' ).
      ctx-client-version = params->get_string( '/clientInfo/version' ).
      ctx-client-title   = params->get_string( '/clientInfo/title' ).
    ENDIF.
    IF params->exists( '/capabilities' ).
      ctx-client_caps = params->slice( '/capabilities' ).
    ENDIF.
    server->set_context( ctx ).
  ENDMETHOD.
ENDCLASS.
