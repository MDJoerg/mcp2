"! <p class="shorttext synchronized">MCP2 legacy task response (root shape)</p>
"! Serves the legacy tasks/get and tasks/cancel responses, which carry the task
"! header fields at the JSON root. Also the base for the nested create-task shape.
"! Field writing and timestamp formatting are delegated to zcl_mcp2_task_util.
CLASS zcl_mcp2_resp_get_task_lgcy DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    "! <p class="shorttext synchronized">Set the legacy task header fields</p>
    "! @parameter task_id      | 32-char uppercase hex UUID
    "! @parameter status       | Task status
    "! @parameter status_msg   | Optional human-readable status description
    "! @parameter created_at   | Creation UTC timestamp
    "! @parameter last_updated | Last-update UTC timestamp
    "! @parameter ttl_s        | TTL in seconds (0 = no expiry -> null on wire)
    "! @parameter poll_ms      | Recommended poll interval in milliseconds
    METHODS set_task
      IMPORTING task_id      TYPE sysuuid_c32
                !status      TYPE string
                status_msg   TYPE string    OPTIONAL
                created_at   TYPE timestamp OPTIONAL
                last_updated TYPE timestamp OPTIONAL
                ttl_s        TYPE i         OPTIONAL
                poll_ms      TYPE i         OPTIONAL.

  PROTECTED SECTION.
    DATA task_id      TYPE sysuuid_c32.
    DATA status       TYPE string.
    DATA status_msg   TYPE string.
    DATA created_at   TYPE timestamp.
    DATA last_updated TYPE timestamp.
    DATA ttl_s        TYPE i.
    DATA poll_ms      TYPE i.

ENDCLASS.

CLASS zcl_mcp2_resp_get_task_lgcy IMPLEMENTATION.

  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_task_util=>write_task_fields( json         = result
                                           prefix       = ``
                                           task_id      = task_id
                                           status       = status
                                           status_msg   = status_msg
                                           created_at   = created_at
                                           last_updated = last_updated
                                           ttl_s        = ttl_s
                                           poll_ms      = poll_ms ).
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

  METHOD set_task.
    me->task_id      = task_id.
    me->status       = status.
    me->status_msg   = status_msg.
    me->created_at   = created_at.
    me->last_updated = last_updated.
    me->ttl_s        = ttl_s.
    me->poll_ms      = poll_ms.
  ENDMETHOD.

ENDCLASS.
