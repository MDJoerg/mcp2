"! <p class="shorttext synchronized">MCP2 tasks/get response (modern)</p>
"! Response for the modern tasks/get method. Carries the current task snapshot
"! and, when terminal, the embedded result or error.
CLASS zcl_mcp2_resp_task_get DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES: BEGIN OF input_request,
             request_key TYPE string,
             method      TYPE string,
             params      TYPE REF TO zif_mcp2_ajson,
           END OF input_request.
    TYPES input_requests TYPE STANDARD TABLE OF input_request WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Set the task snapshot fields</p>
    "! @parameter task_id          | 32-char uppercase hex UUID
    "! @parameter status           | Task status - see zif_mcp2_const=>task_statuses
    "! @parameter status_message   | Optional human-readable status description
    "! @parameter created_at       | Creation UTC timestamp (required by the Task shape)
    "! @parameter last_updated     | Last-update UTC timestamp (required by the Task shape)
    "! @parameter ttl_ms           | TTL in milliseconds (0 = no expiry)
    "! @parameter poll_interval_ms | Recommended client poll interval in milliseconds
    METHODS set_task
      IMPORTING task_id          TYPE sysuuid_c32
                !status          TYPE string
                status_message   TYPE string    OPTIONAL
                created_at       TYPE timestamp OPTIONAL
                last_updated     TYPE timestamp OPTIONAL
                ttl_ms           TYPE i         OPTIONAL
                poll_interval_ms TYPE i         OPTIONAL.

    "! <p class="shorttext synchronized">Set the terminal result payload (completed)</p>
    "! @parameter payload | CallToolResult-shaped JSON from the background worker
    METHODS set_result
      IMPORTING payload TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Set the task error (status = failed)</p>
    "! @parameter code    | JSON-RPC error code
    "! @parameter message | Error description
    "! @parameter data    | Optional error data
    METHODS set_error
      IMPORTING !code    TYPE i
                !message TYPE string
                !data    TYPE REF TO zif_mcp2_ajson OPTIONAL.

    "! <p class="shorttext synchronized">Describe a pending input request</p>
    "! @parameter request_key    | Key the client answers under
    "! @parameter method         | MCP method (e.g. elicitation/create)
    "! @parameter params         | Optional method params
    "! @raising   zcx_mcp2_error | request_key is empty or not path-safe
    METHODS add_input_request
      IMPORTING request_key TYPE string
                !method     TYPE string
                params      TYPE REF TO zif_mcp2_ajson OPTIONAL
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Set cache hints</p>
    "! @parameter ttl_ms      | Cache TTL in milliseconds
    "! @parameter cache_scope | public or private
    METHODS set_cache
      IMPORTING ttl_ms      TYPE i
                cache_scope TYPE string.

  PRIVATE SECTION.
    DATA task_id        TYPE sysuuid_c32.
    DATA status         TYPE string.
    DATA status_message TYPE string.
    DATA created_at     TYPE timestamp.
    DATA last_updated   TYPE timestamp.
    DATA ttl_ms_val     TYPE i.
    DATA poll_ms        TYPE i.
    DATA result_payload TYPE REF TO zif_mcp2_ajson.
    DATA error_code     TYPE i.
    DATA error_message  TYPE string.
    DATA error_data     TYPE REF TO zif_mcp2_ajson.
    DATA requests       TYPE input_requests.
    DATA cache_ttl      TYPE i.
    DATA cache_scope    TYPE string.

ENDCLASS.

CLASS zcl_mcp2_resp_task_get IMPLEMENTATION.

  METHOD zif_mcp2_result~to_json.
    " GetTaskResult = Result & DetailedTask (flat): task fields plus the
    " status-specific result / error / inputRequests all at the result root.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->set_string( iv_path = '/taskId'
                        iv_val  = task_id ).
    result->set_string( iv_path = '/status'
                        iv_val  = status ).
    IF status_message IS NOT INITIAL.
      result->set_string( iv_path = '/statusMessage'
                          iv_val  = status_message ).
    ENDIF.
    result->set_string( iv_path = '/createdAt'
                        iv_val  = zcl_mcp2_task_util=>ts_to_iso( created_at ) ).
    result->set_string( iv_path = '/lastUpdatedAt'
                        iv_val  = zcl_mcp2_task_util=>ts_to_iso( last_updated ) ).
    " ttlMs is required (number | null); 0 = unlimited -> null on the wire.
    IF ttl_ms_val > 0.
      result->set_integer( iv_path = '/ttlMs'
                           iv_val  = ttl_ms_val ).
    ELSE.
      result->set_null( '/ttlMs' ).
    ENDIF.
    IF poll_ms > 0.
      result->set_integer( iv_path = '/pollIntervalMs'
                           iv_val  = poll_ms ).
    ENDIF.

    IF result_payload IS BOUND.
      result->set( iv_path = '/result'
                   iv_val  = result_payload ).
    ENDIF.

    IF error_code <> 0 OR error_message IS NOT INITIAL.
      result->set_integer( iv_path = '/error/code'
                           iv_val  = error_code ).
      result->set_string( iv_path  = '/error/message'
                          iv_val   = error_message ).
      IF error_data IS BOUND.
        result->set( iv_path = '/error/data'
                     iv_val  = error_data ).
      ENDIF.
    ENDIF.

    IF requests IS NOT INITIAL.
      result->set( iv_path = '/inputRequests' iv_val = zcl_mcp2_ajson=>create_empty( ) ).
      LOOP AT requests ASSIGNING FIELD-SYMBOL(<r>).
        DATA(rp) = |/inputRequests/{ <r>-request_key }|.
        result->set_string( iv_path = |{ rp }/method|
                            iv_val  = <r>-method ).
        IF <r>-params IS BOUND.
          result->set( iv_path = |{ rp }/params|
                       iv_val  = <r>-params ).
        ELSE.
          " parse (not create_empty + set) so the grafted node is a real
          " empty object - create_empty()'s root has no node type at all,
          " and set() with an unbound-content graft produces no node.
          result->set( iv_path = |{ rp }/params| iv_val = zcl_mcp2_ajson=>parse( '{}' ) ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
    result = cache_ttl.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    result = cache_scope.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    " Not a spec CacheableResult - never stamped with ttlMs/cacheScope.
  ENDMETHOD.

  METHOD set_task.
    me->task_id        = task_id.
    me->status         = status.
    me->status_message = status_message.
    me->created_at     = created_at.
    me->last_updated   = last_updated.
    ttl_ms_val         = ttl_ms.
    poll_ms            = poll_interval_ms.
  ENDMETHOD.

  METHOD set_result.
    result_payload = payload.
  ENDMETHOD.

  METHOD set_error.
    error_code    = code.
    error_message = message.
    error_data    = data.
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

  METHOD set_cache.
    cache_ttl       = ttl_ms.
    me->cache_scope = cache_scope.
  ENDMETHOD.

ENDCLASS.
