"! <p class="shorttext synchronized">MCP2 legacy tasks/list response</p>
"! Returns a paginated list of tasks for the current user. Each entry is written
"! through the shared zcl_mcp2_task_util=>write_task_fields helper.
CLASS zcl_mcp2_resp_list_tasks_lgcy DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES: BEGIN OF task_entry,
             task_id      TYPE sysuuid_c32,
             status       TYPE string,
             status_msg   TYPE string,
             created_at   TYPE timestamp,
             last_updated TYPE timestamp,
             ttl_s        TYPE i,
             poll_ms      TYPE i,
           END OF task_entry.
    TYPES task_list TYPE STANDARD TABLE OF task_entry WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Append a task to the list</p>
    "! @parameter task_id      | 32-char uppercase hex UUID
    "! @parameter status       | Task status
    "! @parameter status_msg   | Optional status description
    "! @parameter created_at   | Creation UTC timestamp
    "! @parameter last_updated | Last-update UTC timestamp
    "! @parameter ttl_s        | TTL in seconds (0 = no expiry -> null on wire)
    "! @parameter poll_ms      | Recommended poll interval in milliseconds
    METHODS add_task
      IMPORTING task_id      TYPE sysuuid_c32
                !status      TYPE string
                status_msg   TYPE string    OPTIONAL
                created_at   TYPE timestamp OPTIONAL
                last_updated TYPE timestamp OPTIONAL
                ttl_s        TYPE i         OPTIONAL
                poll_ms      TYPE i         OPTIONAL.

    "! <p class="shorttext synchronized">Set the pagination cursor for the next page</p>
    "! @parameter cursor | Cursor token (empty = last page)
    METHODS set_next_cursor
      IMPORTING cursor TYPE string.

  PRIVATE SECTION.
    DATA tasks       TYPE task_list.
    DATA next_cursor TYPE string.

ENDCLASS.

CLASS zcl_mcp2_resp_list_tasks_lgcy IMPLEMENTATION.

  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/tasks' ).
    LOOP AT tasks ASSIGNING FIELD-SYMBOL(<t>).
      zcl_mcp2_task_util=>write_task_fields( json         = result
                                             prefix       = |/tasks/{ sy-tabix }|
                                             task_id      = <t>-task_id
                                             status       = <t>-status
                                             status_msg   = <t>-status_msg
                                             created_at   = <t>-created_at
                                             last_updated = <t>-last_updated
                                             ttl_s        = <t>-ttl_s
                                             poll_ms      = <t>-poll_ms ).
    ENDLOOP.
    IF next_cursor IS NOT INITIAL.
      result->set_string( iv_path = '/nextCursor'
                          iv_val  = next_cursor ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
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

  METHOD add_task.
    APPEND VALUE task_entry( task_id      = task_id
                             status       = status
                             status_msg   = status_msg
                             created_at   = created_at
                             last_updated = last_updated
                             ttl_s        = ttl_s
                             poll_ms      = poll_ms ) TO tasks.
  ENDMETHOD.

  METHOD set_next_cursor.
    next_cursor = cursor.
  ENDMETHOD.

ENDCLASS.
