"! <p class="shorttext synchronized">MCP2 task result (tools/call -> resultType=task)</p>
"! Return from a tools/call handler to indicate a background task was started.
"! The client uses taskId to poll via tasks/get until the task reaches a terminal state.
CLASS zcl_mcp2_resp_task DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    "! <p class="shorttext synchronized">Set the task id issued by the persistence layer</p>
    "! @parameter task_id | 32-char uppercase hex UUID
    METHODS set_task_id
      IMPORTING task_id TYPE sysuuid_c32.

    "! <p class="shorttext synchronized">Set the initial task status</p>
    "! Always 'working' at creation.
    "! @parameter status | Task status - see zif_mcp2_const=>task_statuses
    METHODS set_status
      IMPORTING !status TYPE string.

    "! <p class="shorttext synchronized">Set an optional human-readable status message</p>
    "! @parameter message | Short status description
    METHODS set_status_message
      IMPORTING !message TYPE string.

    "! <p class="shorttext synchronized">Set time-to-live in milliseconds (0 = no expiry)</p>
    "! @parameter ttl_ms | TTL in milliseconds
    METHODS set_ttl_ms
      IMPORTING ttl_ms TYPE i.

    "! <p class="shorttext synchronized">Set recommended client poll interval in ms</p>
    "! @parameter interval_ms | Poll interval in milliseconds
    METHODS set_poll_interval_ms
      IMPORTING interval_ms TYPE i.

    "! <p class="shorttext synchronized">Set creation / last-update timestamps</p>
    "! Both are required by the Task shape.
    "! @parameter created_at   | Creation UTC timestamp
    "! @parameter last_updated | Last-update UTC timestamp
    METHODS set_timestamps
      IMPORTING created_at   TYPE timestamp
                last_updated TYPE timestamp.

    "! <p class="shorttext synchronized">Set cache hints for the tools/call response</p>
    "! @parameter ttl_ms      | Cache TTL in milliseconds
    "! @parameter cache_scope | public or private
    METHODS set_cache
      IMPORTING ttl_ms      TYPE i
                cache_scope TYPE string.

  PRIVATE SECTION.
    DATA task_id        TYPE sysuuid_c32.
    DATA status         TYPE string.
    DATA status_message TYPE string.
    DATA ttl_ms         TYPE i.
    DATA poll_ms        TYPE i.
    DATA created_at     TYPE timestamp.
    DATA last_updated   TYPE timestamp.
    DATA cache_ttl      TYPE i.
    DATA cache_scope    TYPE string.

ENDCLASS.

CLASS zcl_mcp2_resp_task IMPLEMENTATION.

  METHOD zif_mcp2_result~to_json.
    " CreateTaskResult = Result & Task (flat): task fields at the result root.
    " resultType is stamped centrally by the modern dispatcher.
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
    IF ttl_ms > 0.
      result->set_integer( iv_path = '/ttlMs'
                           iv_val  = ttl_ms ).
    ELSE.
      result->set_null( '/ttlMs' ).
    ENDIF.
    IF poll_ms > 0.
      result->set_integer( iv_path = '/pollIntervalMs'
                           iv_val  = poll_ms ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-task.
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

  METHOD set_task_id.
    me->task_id = task_id.
  ENDMETHOD.

  METHOD set_status.
    me->status = status.
  ENDMETHOD.

  METHOD set_status_message.
    me->status_message = message.
  ENDMETHOD.

  METHOD set_ttl_ms.
    me->ttl_ms = ttl_ms.
  ENDMETHOD.

  METHOD set_poll_interval_ms.
    me->poll_ms = interval_ms.
  ENDMETHOD.

  METHOD set_timestamps.
    me->created_at   = created_at.
    me->last_updated = last_updated.
  ENDMETHOD.

  METHOD set_cache.
    cache_ttl        = ttl_ms.
    me->cache_scope  = cache_scope.
  ENDMETHOD.

ENDCLASS.
