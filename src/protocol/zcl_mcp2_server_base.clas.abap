"! <p class="shorttext synchronized">MCP2 server base class</p>
"! Abstract base for MCP servers.
"! Subclasses must implement get_name and get_version.
"! Override capability flags and handler methods for each feature supported.
"! All handlers default to raising method_not_found; override only what you need.
CLASS zcl_mcp2_server_base DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Identity is deliberately abstract: a server silently shipping under a
    " placeholder name/version is a bug waiting to happen.
    INTERFACES zif_mcp2_server ABSTRACT METHODS get_name get_version.

    "! <p class="shorttext synchronized">Whether the client has a named capability</p>
    "! Checks a key in clientCapabilities.
    "! @parameter capability | Capability key
    "! @parameter result     | abap_true when the client declared it
    METHODS has_client_cap
      IMPORTING capability    TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Client name from clientInfo.name</p>
    "! @parameter result | Client name
    METHODS get_client_name
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Client version from clientInfo.version</p>
    "! @parameter result | Client version
    METHODS get_client_version
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Client title from clientInfo.title</p>
    "! Optional; may be initial.
    "! @parameter result | Client title, or empty
    METHODS get_client_title
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether the request is the modern era</p>
    "! Modern era is 2026-07-28+.
    "! @parameter result | abap_true for the modern era
    METHODS era_is_modern
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the client answers MRTR input</p>
    "! Only true in the modern era; always false for legacy clients.
    "! @parameter result | abap_true when inputRequired round-trips are possible
    METHODS supports_input_required
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the client supports form elicitation</p>
    "! Modern era only. The elicitation capability declares its modes: a bare
    "! object means form mode implicitly; explicit subkeys enumerate the modes.
    "! @parameter result | abap_true when form-mode elicitation is supported
    METHODS client_supports_elicitation
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the client supports URL elicitation</p>
    "! Modern era only. URL mode is never implicit - the client must declare
    "! elicitation.url. Check before building a set_url input request.
    "! @parameter result | abap_true when URL-mode elicitation is supported
    METHODS client_supports_elicit_url
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the client can receive a task</p>
    "! Era-aware: modern era checks the declared io.modelcontextprotocol/tasks
    "! extension in clientCapabilities.extensions; legacy era (2025-11-25) checks
    "! whether the current tools/call carried the per-request task opt-in
    "! (params.task). Gate start_task( ) with this to fall back to a synchronous
    "! result when the client cannot handle a task.
    "! @parameter result | abap_true when the client can take a task result
    METHODS client_supports_tasks
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the client supports sampling</p>
    "! Modern era only. Check before returning a sampling/createMessage input
    "! request, else the framework rejects the result with -32021
    "! MissingRequiredClientCapability.
    "! Note: the Sampling feature is deprecated as of 2026-07-28 (SEP-2577) with
    "! a >=12-month removal window; prefer direct LLM provider integration for
    "! new designs where feasible.
    "! @parameter result | abap_true when the sampling capability was declared
    METHODS client_supports_sampling
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Negotiated protocol version</p>
    "! For the current request (e.g. 2026-07-28).
    "! @parameter result | Negotiated protocol version
    METHODS get_protocol_version
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Read a string from request _meta by key</p>
    "! Keys containing '/' (e.g. io.modelcontextprotocol/logLevel) are handled
    "! transparently - no ajson path escaping needed by the caller.
    "! Returns empty when _meta or the key is absent.
    "! @parameter key    | Literal _meta key
    "! @parameter result | Value, or empty when absent
    METHODS get_meta_string
      IMPORTING !key          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Per-request log level from _meta</p>
    "! From io.modelcontextprotocol/logLevel. Empty when the client did not opt
    "! in to log messages; the stateless runtime cannot emit notifications/message
    "! either way - use this to adjust the verbosity of your own logging.
    "! @parameter result | Log level, or empty
    METHODS get_log_level
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">W3C Trace Context traceparent from _meta</p>
    "! @parameter result | traceparent, or empty
    METHODS get_traceparent
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">W3C Trace Context tracestate from _meta</p>
    "! @parameter result | tracestate, or empty
    METHODS get_tracestate
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Task-store area key</p>
    "! Used when constructing the task store (default: server name). Override to
    "! scope tasks to a logical application area.
    "! @parameter result | Area key
    METHODS get_task_area
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Task-store server key</p>
    "! Used when constructing the task store (default: server name). Override to
    "! provide a more specific server identifier.
    "! @parameter result | Server key
    METHODS get_task_server
      RETURNING VALUE(result) TYPE string.

  PROTECTED SECTION.
    " A freshly started task: the id for the background unit plus the
    " era-appropriate create-task result to return from the handler.
    TYPES: BEGIN OF task_start,
             task_id TYPE sysuuid_c32,
             result  TYPE REF TO zif_mcp2_result,
           END OF task_start.

    "! <p class="shorttext synchronized">The task store scoped to this server</p>
    "! Lazily constructed from get_task_area( ) / get_task_server( ). Use it in
    "! handlers instead of instantiating zcl_mcp2_tasks by hand.
    "! @parameter result | The scoped task store
    METHODS get_tasks
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_tasks.

    "! <p class="shorttext synchronized">Start a background task (one call)</p>
    "! Persists a 'working' row in the scoped task store and builds the
    "! era-appropriate create-task result: the modern resultType=task shape or
    "! the legacy nested CreateTaskResult. Use the returned task_id to hand the
    "! work to a background unit and to complete/fail the task later.
    "! The dispatchers protect the wire when the client cannot take a task:
    "! modern -32021 without the declared tasks extension, legacy -32600
    "! without the per-request params.task opt-in. Gate with the era-aware
    "! client_supports_tasks( ) to fall back to a synchronous result instead.
    "! @parameter poll_ms        | Recommended client poll interval (ms)
    "! @parameter ttl_s          | Task row time-to-live in seconds (0 = none)
    "! @parameter status_message | Optional initial human-readable status
    "! @parameter result         | task_id + era-appropriate handler result
    "! @raising   zcx_mcp2_error | Task row creation failed
    METHODS start_task
      IMPORTING poll_ms        TYPE i DEFAULT 5000
                ttl_s          TYPE i DEFAULT 0
                status_message TYPE string OPTIONAL
      RETURNING VALUE(result)  TYPE task_start
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Era-appropriate create-task result from a row</p>
    "! Modern: zcl_mcp2_resp_task (resultType=task). Legacy (or no context):
    "! zcl_mcp2_resp_create_task_lgcy (nested task with timestamps).
    "! @parameter row    | The persisted task row
    "! @parameter result | Result object for the current era
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    METHODS build_task_result
      IMPORTING !row          TYPE zcl_mcp2_tasks=>task_row
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">True when the client can answer this MRTR input</p>
    "! Inspects the typed input request: form elicitation requires
    "! client_supports_elicitation( ), URL elicitation requires
    "! client_supports_elicit_url( ), and sampling requires
    "! client_supports_sampling( ).
    "! @parameter input                | Typed input request builder
    "! @parameter result               | True when safe to return as input_required
    "! @raising   zcx_mcp2_ajson_error | Input params build failure
    METHODS can_request_input
      IMPORTING input         TYPE REF TO zif_mcp2_input_request
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build a single-input MRTR response</p>
    "! Use can_request_input( ) first when you want to fall back instead of
    "! relying on dispatcher capability errors.
    "! @parameter request_key          | Server-chosen key the client answers under
    "! @parameter input                | Typed elicitation / sampling builder
    "! @parameter request_state        | Optional opaque continuation token
    "! @parameter result               | input_required response
    "! @raising   zcx_mcp2_ajson_error | Input params build failure
    "! @raising   zcx_mcp2_error       | Invalid request key
    METHODS input_required
      IMPORTING request_key          TYPE string
                input                TYPE REF TO zif_mcp2_input_request
                request_state        TYPE string OPTIONAL
      RETURNING VALUE(result)        TYPE REF TO zcl_mcp2_resp_input_req
      RAISING   zcx_mcp2_ajson_error
                zcx_mcp2_error.

  PRIVATE SECTION.
    DATA context       TYPE zif_mcp2_server=>context.
    DATA tasks_inst    TYPE REF TO zcl_mcp2_tasks.

    "! <p class="shorttext synchronized">Row TTL (seconds) to milliseconds</p>
    "! Rejects values beyond the representable 4-byte millisecond bound.
    "! @parameter ttl_s  | TTL in seconds
    "! @parameter result | TTL in milliseconds, clamped to max int4
    "! @raising zcx_mcp2_error | Protocol error returned to the client
    METHODS ttl_s_to_ms
      IMPORTING ttl_s         TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_mcp2_error.

ENDCLASS.


CLASS zcl_mcp2_server_base IMPLEMENTATION.
  METHOD zif_mcp2_server~get_instructions.
    " Default: no instructions. Override to provide a system prompt hint.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_title.
    " Default: no display title. Override for a human-readable serverInfo.title.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_description.
    " Default: no description. Override to describe the server's purpose.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_website_url.
    " Default: no website. Override to link documentation.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_icons.
    " Default: no icons. Override to advertise serverInfo.icons.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_discover_cache.
    " Conservative default: immediately stale, never shared.
    result-ttl_ms      = 0.
    result-cache_scope = zif_mcp2_const=>cache_scopes-private.
  ENDMETHOD.

  METHOD zif_mcp2_server~set_context.
    context = ctx.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_context.
    result = context.
  ENDMETHOD.

  METHOD zif_mcp2_server~check_authorization.
    " Allow by default: ICF logon and S_ICF already gate the node. This hook
    " exists to separate audiences across servers under one node; the SDK
    " deliberately ships no authorization object - see
    " ConfigurationAndSecurity.md.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_resources.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_prompts.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_completions.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_list.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-tools_list ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-tools_call ).
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_list.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-resources_list ).
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_read.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-resources_read ).
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_tmpls_list.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-resources_tmpls_list ).
  ENDMETHOD.

  METHOD zif_mcp2_server~prompts_list.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-prompts_list ).
  ENDMETHOD.

  METHOD zif_mcp2_server~prompts_get.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-prompts_get ).
  ENDMETHOD.

  METHOD zif_mcp2_server~completions_complete.
    zcx_mcp2_error=>raise_method_not_found( zif_mcp2_const=>methods-completions ).
  ENDMETHOD.

  METHOD zif_mcp2_server~get_tool_schema.
    " Default: return initial - no schema means no header-mirroring validation.
  ENDMETHOD.

  METHOD zif_mcp2_server~validate_tool_input.
    " Default: off - handlers validate themselves via the typed getters.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tasks.
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_get.
    DATA(row) = get_tasks( )->get( request->get_task_id( ) ).
    zcl_mcp2_task_util=>validate_ttl_s( row-ttl_s ).
    IF era_is_modern( ).
      " Modern: rich shape that embeds the terminal result payload inline.
      DATA(resp_m) = NEW zcl_mcp2_resp_task_get( ).
      resp_m->set_task( task_id          = row-task_id
                        status           = row-status
                        status_message   = row-status_message
                        created_at       = row-created_at
                        last_updated     = row-last_updated
                        ttl_ms           = ttl_s_to_ms( row-ttl_s )
                        poll_interval_ms = row-poll_ms ).
      CASE row-status.
        WHEN zif_mcp2_const=>task_statuses-completed.
          DATA(payload_json) = get_tasks( )->get_payload( request->get_task_id( ) ).
          resp_m->set_result( payload_json ).
        WHEN zif_mcp2_const=>task_statuses-failed.
          " Surface the code stored by zcl_mcp2_tasks=>fail; tasks failed via
          " complete( ) with an isError payload have no stored code.
          resp_m->set_error( code    = COND #( WHEN row-error_code <> 0
                                               THEN row-error_code
                                               ELSE -32603 )
                             message = row-status_message ).
        WHEN zif_mcp2_const=>task_statuses-input_required.
          DATA(input_json) = get_tasks( )->get_payload( request->get_task_id( ) ).
          IF     input_json->exists( '/inputRequests' ) = abap_true
             AND input_json->get_node_type( '/inputRequests' )
                 = zif_mcp2_ajson_types=>node_type-object.
            DATA input_keys TYPE string_table.
            input_keys = input_json->members( '/inputRequests' ).
            LOOP AT input_keys INTO DATA(input_key).
              DATA(input_method) = input_json->get_string(
                |/inputRequests/{ input_key }/method| ).
              IF input_method IS INITIAL.
                zcx_mcp2_error=>raise_internal(
                  |Task { row-task_id } has an invalid input_required payload| ) ##NO_TEXT.
              ENDIF.
              DATA input_params TYPE REF TO zif_mcp2_ajson.
              IF input_json->exists( |/inputRequests/{ input_key }/params| ) = abap_true.
                input_params = input_json->slice( |/inputRequests/{ input_key }/params| ).
              ELSE.
                CLEAR input_params.
              ENDIF.
              resp_m->add_input_request( request_key = input_key
                                         method      = input_method
                                         params      = input_params ).
            ENDLOOP.
          ELSEIF input_json->exists( '/requestKey' ) = abap_true.
            " Compatibility with input_required rows written before keyed
            " inputRequests persistence was introduced.
            DATA(old_input_key) = input_json->get_string( '/requestKey' ).
            DATA(old_input_method) = input_json->get_string( '/method' ).
            IF old_input_key IS INITIAL OR old_input_method IS INITIAL.
              zcx_mcp2_error=>raise_internal(
                |Task { row-task_id } has an invalid input_required payload| ) ##NO_TEXT.
            ENDIF.
            DATA old_input_params TYPE REF TO zif_mcp2_ajson.
            IF input_json->exists( '/params' ) = abap_true.
              old_input_params = input_json->slice( '/params' ).
            ENDIF.
            resp_m->add_input_request( request_key = old_input_key
                                       method      = old_input_method
                                       params      = old_input_params ).
          ELSE.
            zcx_mcp2_error=>raise_internal(
              |Task { row-task_id } has an invalid input_required payload| ) ##NO_TEXT.
          ENDIF.
      ENDCASE.
      result = resp_m.
    ELSE.
      " Legacy: task header at root level; the payload is fetched via tasks/result.
      DATA(resp_l) = NEW zcl_mcp2_resp_get_task_lgcy( ).
      resp_l->set_task( task_id      = row-task_id
                        status       = row-status
                        status_msg   = row-status_message
                        created_at   = row-created_at
                        last_updated = row-last_updated
                        ttl_s        = row-ttl_s
                        poll_ms      = row-poll_ms ).
      result = resp_l.
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_update.
    DATA(consume) = zcl_mcp2_tasks=>consume_update(
      task_id         = request->get_task_id( )
      input_responses = request->get_input_responses( ) ) ##NEEDED.
    result = NEW zcl_mcp2_resp_empty( ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_cancel.
    IF era_is_modern( ).
      " Modern: cancellation is cooperative and eventually consistent - ack with
      " an empty complete result. A task already in a terminal state (the work
      " finished before the cancel arrived) is acked as-is, not errored; only an
      " unknown taskId surfaces an error (via the user-scoped get).
      DATA(cancel_row) = get_tasks( )->get( request->get_task_id( ) ).
      IF     cancel_row-status <> zif_mcp2_const=>task_statuses-completed
         AND cancel_row-status <> zif_mcp2_const=>task_statuses-failed
         AND cancel_row-status <> zif_mcp2_const=>task_statuses-cancelled.
        zcl_mcp2_tasks=>cancel( request->get_task_id( ) ).
      ENDIF.
      result = NEW zcl_mcp2_resp_empty( ).
    ELSE.
      " Legacy 2025-11-25: cancelling a task already in any terminal state
      " (including cancelled) is -32602.
      DATA(row) = get_tasks( )->get( request->get_task_id( ) ).
      IF    row-status = zif_mcp2_const=>task_statuses-completed
         OR row-status = zif_mcp2_const=>task_statuses-failed
         OR row-status = zif_mcp2_const=>task_statuses-cancelled.
        zcx_mcp2_error=>raise_invalid_params(
          |Cannot cancel task: already in terminal status '{ row-status }'| ) ##NO_TEXT.
      ENDIF.
      zcl_mcp2_tasks=>cancel( request->get_task_id( ) ).
      row = get_tasks( )->get( request->get_task_id( ) ).
      DATA(resp_l) = NEW zcl_mcp2_resp_get_task_lgcy( ).
      resp_l->set_task( task_id      = row-task_id
                        status       = row-status
                        status_msg   = row-status_message
                        created_at   = row-created_at
                        last_updated = row-last_updated
                        ttl_s        = row-ttl_s
                        poll_ms      = row-poll_ms ).
      result = resp_l.
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_list.
    DATA(list) = get_tasks( )->list(
      COND string( WHEN request->has_cursor( )
                   THEN request->get_cursor( ) ) ).
    DATA(resp) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    LOOP AT list-rows ASSIGNING FIELD-SYMBOL(<r>).
      zcl_mcp2_task_util=>validate_ttl_s( <r>-ttl_s ).
      resp->add_task( task_id      = <r>-task_id
                      status       = <r>-status
                      status_msg   = <r>-status_message
                      created_at   = <r>-created_at
                      last_updated = <r>-last_updated
                      ttl_s        = <r>-ttl_s
                      poll_ms      = <r>-poll_ms ).
    ENDLOOP.
    IF list-next_cursor IS NOT INITIAL.
      resp->set_next_cursor( list-next_cursor ).
    ENDIF.
    result = resp.
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_result.
    " 2025-11-25: tasks/result returns exactly what the underlying request
    " would have returned. Stored payloads (completed, or failed via an
    " isError result) are returned as-is; tasks failed via fail( ) re-raise
    " the stored JSON-RPC error. Blocking on non-terminal tasks is impossible
    " statelessly - clients keep polling tasks/get instead.
    DATA(row) = get_tasks( )->get( request->get_task_id( ) ).
    CASE row-status.
      WHEN zif_mcp2_const=>task_statuses-working
        OR zif_mcp2_const=>task_statuses-input_required.
        zcx_mcp2_error=>raise_invalid_req(
          |Task { row-task_id } has not reached a terminal state;| &&
          ` this stateless server cannot block - poll tasks/get` ) ##NO_TEXT.
      WHEN zif_mcp2_const=>task_statuses-cancelled.
        zcx_mcp2_error=>raise_invalid_params(
          |Task { row-task_id } was cancelled before completion| ) ##NO_TEXT.
      WHEN zif_mcp2_const=>task_statuses-failed.
        IF row-error_code <> 0.
          " Keep exception construction procedural for ABAP 7.02 downport compatibility.
          DATA error_message TYPE string.
          IF row-status_message IS NOT INITIAL.
            error_message = row-status_message.
          ELSE.
            error_message = `Task failed`  ##NO_TEXT.
          ENDIF.
          RAISE EXCEPTION NEW zcx_mcp2_error(
            error_code = row-error_code
            error_msg  = error_message ).
        ENDIF.
        " Failed via complete( ) with an isError payload: fall through and
        " return the stored CallToolResult, as the original call would have.
    ENDCASE.
    DATA(payload_json) = get_tasks( )->get_payload( request->get_task_id( ) ).
    DATA(resp) = NEW zcl_mcp2_resp_task_payload( ).
    resp->set_from_json( payload_json ).
    " 2025-11-25: tasks/result MUST carry the related-task _meta annotation,
    " since the payload itself has no task id.
    resp->set_related_task( row-task_id ).
    result = resp.
  ENDMETHOD.

  METHOD has_client_cap.
    IF context-client_caps IS NOT BOUND.
      RETURN.
    ENDIF.
    result = xsdbool( context-client_caps->exists( |/{ capability }| ) ).
  ENDMETHOD.

  METHOD get_client_name.
    result = context-client-name.
  ENDMETHOD.

  METHOD get_client_version.
    result = context-client-version.
  ENDMETHOD.

  METHOD get_client_title.
    result = context-client-title.
  ENDMETHOD.

  METHOD era_is_modern.
    result = xsdbool( context-era = zif_mcp2_const=>eras-modern ).
  ENDMETHOD.

  METHOD supports_input_required.
    result = era_is_modern( ).
  ENDMETHOD.

  METHOD client_supports_elicitation.
    IF era_is_modern( ) = abap_false OR context-client_caps IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(cap_path) = |/{ zif_mcp2_const=>client_caps-elicitation }|.
    IF context-client_caps->exists( cap_path ) = abap_false.
      RETURN.
    ENDIF.
    " Form mode: declared explicitly, or implicit when no mode subkey is named.
    result = xsdbool(    context-client_caps->exists( |{ cap_path }/form| ) = abap_true
                      OR (     context-client_caps->exists( |{ cap_path }/form| ) = abap_false
                           AND context-client_caps->exists( |{ cap_path }/url| )  = abap_false ) ).
  ENDMETHOD.

  METHOD client_supports_elicit_url.
    IF era_is_modern( ) = abap_false OR context-client_caps IS NOT BOUND.
      RETURN.
    ENDIF.
    result = context-client_caps->exists(
      |/{ zif_mcp2_const=>client_caps-elicitation }/url| ).
  ENDMETHOD.

  METHOD client_supports_sampling.
    IF era_is_modern( ) = abap_false.
      RETURN.
    ENDIF.
    result = has_client_cap( zif_mcp2_const=>client_caps-sampling ).
  ENDMETHOD.

  METHOD get_protocol_version.
    result = context-protocol_ver.
  ENDMETHOD.

  METHOD get_meta_string.
    IF context-meta IS NOT BOUND.
      RETURN.
    ENDIF.
    " ajson separates path segments with '/'; literal slashes inside a member
    " name are represented by TAB (vendored-ajson convention).
    DATA(escaped) = replace( val  = key
                             sub  = '/'
                             with = cl_abap_char_utilities=>horizontal_tab
                             occ  = 0 ).
    result = context-meta->get_string( |/{ escaped }| ).
  ENDMETHOD.

  METHOD get_log_level.
    result = get_meta_string( zif_mcp2_const=>meta_keys-log_level ).
  ENDMETHOD.

  METHOD get_traceparent.
    result = get_meta_string( `traceparent` ).
  ENDMETHOD.

  METHOD get_tracestate.
    result = get_meta_string( `tracestate` ).
  ENDMETHOD.

  METHOD client_supports_tasks.
    " Legacy era: capabilities are unknown statelessly; the per-request
    " params.task opt-in (2025-11-25) is the reliable signal instead.
    IF era_is_modern( ) = abap_false.
      result = context-task_requested.
      RETURN.
    ENDIF.
    IF context-client_caps IS NOT BOUND.
      RETURN.
    ENDIF.
    result = context-client_caps->exists(
      '/extensions/io.modelcontextprotocol'
      && cl_abap_char_utilities=>horizontal_tab
      && 'tasks' ).
  ENDMETHOD.

  METHOD get_task_area.
    result = zif_mcp2_server~get_name( ).
  ENDMETHOD.

  METHOD get_task_server.
    result = zif_mcp2_server~get_name( ).
  ENDMETHOD.

  METHOD get_tasks.
    IF tasks_inst IS NOT BOUND.
      tasks_inst = NEW zcl_mcp2_tasks( area   = get_task_area( )
                                       server = get_task_server( ) ).
    ENDIF.
    result = tasks_inst.
  ENDMETHOD.

  METHOD start_task.
    IF poll_ms < 0.
      zcx_mcp2_error=>raise_invalid_params(
        `Task poll interval must not be negative` ) ##NO_TEXT.
    ENDIF.
    zcl_mcp2_task_util=>validate_ttl_s( ttl_s ).
    DATA(store) = get_tasks( ).
    result-task_id = store->create_task( poll_ms        = poll_ms
                                         ttl_s          = ttl_s
                                         status_message = status_message
                                         protocol_era   = COND #( WHEN era_is_modern( ) = abap_true
                                                                  THEN zif_mcp2_const=>eras-modern
                                                                  ELSE zif_mcp2_const=>eras-legacy ) ).
    result-result = build_task_result( store->get( result-task_id ) ).
  ENDMETHOD.

  METHOD ttl_s_to_ms.
    result = zcl_mcp2_task_util=>ttl_s_to_ms( ttl_s ).
  ENDMETHOD.

  METHOD build_task_result.
    zcl_mcp2_task_util=>validate_ttl_s( row-ttl_s ).
    IF era_is_modern( ).
      DATA(modern) = NEW zcl_mcp2_resp_task( ).
      modern->set_task_id( row-task_id ).
      modern->set_status( row-status ).
      IF row-status_message IS NOT INITIAL.
        modern->set_status_message( row-status_message ).
      ENDIF.
      modern->set_timestamps( created_at   = row-created_at
                              last_updated = row-last_updated ).
      modern->set_ttl_ms( ttl_s_to_ms( row-ttl_s ) ).
      modern->set_poll_interval_ms( row-poll_ms ).
      result = modern.
    ELSE.
      DATA(legacy) = NEW zcl_mcp2_resp_create_task_lgcy( ).
      legacy->set_task( task_id      = row-task_id
                        status       = row-status
                        status_msg   = row-status_message
                        created_at   = row-created_at
                        last_updated = row-last_updated
                        ttl_s        = row-ttl_s
                        poll_ms      = row-poll_ms ).
      result = legacy.
    ENDIF.
  ENDMETHOD.

  METHOD can_request_input.
    IF input IS NOT BOUND OR supports_input_required( ) = abap_false.
      RETURN.
    ENDIF.

    CASE input->get_method( ).
      WHEN zif_mcp2_const=>methods-elicitation_create.
        DATA(params) = input->get_params( ).
        DATA(mode) = params->get_string( '/mode' ).
        IF mode = zif_mcp2_const=>elicit_modes-url.
          result = client_supports_elicit_url( ).
        ELSE.
          result = client_supports_elicitation( ).
        ENDIF.

      WHEN zif_mcp2_const=>methods-sampling_create.
        result = client_supports_sampling( ).
    ENDCASE.
  ENDMETHOD.

  METHOD input_required.
    result = NEW zcl_mcp2_resp_input_req( ).
    IF request_state IS NOT INITIAL.
      result->set_request_state( request_state ).
    ENDIF.
    result->add_request( request_key = request_key
                         input       = input ).
  ENDMETHOD.

ENDCLASS.
