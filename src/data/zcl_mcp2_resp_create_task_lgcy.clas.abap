"! <p class="shorttext synchronized">MCP2 legacy create-task response</p>
"! Response for a legacy tools/call that created a background task. Identical to
"! the root task shape but nested under /task. Extends zcl_mcp2_resp_get_task_lgcy
"! and only overrides the JSON prefix.
CLASS zcl_mcp2_resp_create_task_lgcy DEFINITION PUBLIC
  INHERITING FROM zcl_mcp2_resp_get_task_lgcy FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_result~to_json     REDEFINITION.
    METHODS zif_mcp2_result~result_type REDEFINITION.

ENDCLASS.

CLASS zcl_mcp2_resp_create_task_lgcy IMPLEMENTATION.

  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_task_util=>write_task_fields( json         = result
                                           prefix       = `/task`
                                           task_id      = task_id
                                           status       = status
                                           status_msg   = status_msg
                                           created_at   = created_at
                                           last_updated = last_updated
                                           ttl_s        = ttl_s
                                           poll_ms      = poll_ms ).
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    " Identifies this as a create-task result for the legacy dispatcher's
    " params.task opt-in gate. The legacy era never emits resultType on the
    " wire - this value is only read by the framework.
    result = zif_mcp2_const=>result_types-task.
  ENDMETHOD.

ENDCLASS.
