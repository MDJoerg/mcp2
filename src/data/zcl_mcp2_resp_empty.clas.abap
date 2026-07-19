"! <p class="shorttext synchronized">MCP2 empty complete result</p>
"! Used by acknowledgement methods whose modern result is only the envelope
"! resultType=complete.
CLASS zcl_mcp2_resp_empty DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

ENDCLASS.


CLASS zcl_mcp2_resp_empty IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
  ENDMETHOD.
ENDCLASS.
