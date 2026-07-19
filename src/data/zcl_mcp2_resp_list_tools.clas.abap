"! <p class="shorttext synchronized">MCP2 tools/list response</p>
CLASS zcl_mcp2_resp_list_tools DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    " destructive_hint and open_world_hint default to true in the spec.
    " Use the *_set flag to emit an explicit false override.
    TYPES: BEGIN OF tool_annotations,
             title                TYPE string,
             read_only_hint       TYPE abap_bool,
             destructive_hint     TYPE abap_bool,
             destructive_hint_set TYPE abap_bool,
             idempotent_hint      TYPE abap_bool,
             open_world_hint      TYPE abap_bool,
             open_world_hint_set  TYPE abap_bool,
           END OF tool_annotations.

    " task_support: legacy (2025-11-25) tool-level task negotiation, emitted as
    " execution.taskSupport (values in zif_mcp2_const=>task_support). Omitted
    " when initial, which legacy clients read as "forbidden". The modern tasks
    " extension is server-directed and ignores the field.
    TYPES: BEGIN OF tool,
             name          TYPE string,
             description   TYPE string,
             title         TYPE string,
             input_schema  TYPE REF TO zif_mcp2_ajson,
             output_schema TYPE REF TO zif_mcp2_ajson,
             icons         TYPE zif_mcp2_content=>icons,
             annotations   TYPE tool_annotations,
             task_support  TYPE string,
           END OF tool.
    TYPES tool_list TYPE STANDARD TABLE OF tool WITH KEY name.

    "! <p class="shorttext synchronized">Append a tool definition</p>
    "! @parameter entry | Tool name, schemas, icons and annotation hints
    METHODS add_tool
      IMPORTING !entry TYPE tool.

    "! <p class="shorttext synchronized">Set the pagination next-cursor</p>
    "! @parameter cursor | Opaque cursor for the next page
    METHODS set_next_cursor
      IMPORTING !cursor TYPE string.

    "! <p class="shorttext synchronized">Set modern cache hints (ttlMs / cacheScope)</p>
    "! @parameter ttl_ms      | Time-to-live in milliseconds
    "! @parameter cache_scope | public or private (see zif_mcp2_const)
    METHODS set_cache
      IMPORTING ttl_ms      TYPE i
                cache_scope TYPE string.

  PRIVATE SECTION.
    DATA tools       TYPE tool_list.
    DATA next_cursor TYPE string.
    DATA ttl         TYPE i.
    DATA scope       TYPE string.

    "! <p class="shorttext synchronized">Emit tri-state tool annotation hints</p>
    "! Writes only the hints that differ from their spec defaults.
    "! @parameter json                 | Target JSON document
    "! @parameter path                 | Base path of the tool's annotations object
    "! @parameter ann                  | Annotation values plus their *_set overrides
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS emit_tool_annotations
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
                !path TYPE string
                ann   TYPE tool_annotations
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_resp_list_tools IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/tools' ).

    LOOP AT tools ASSIGNING FIELD-SYMBOL(<t>).
      DATA(p) = |/tools/{ sy-tabix }|.
      result->set_string( iv_path = |{ p }/name|
                          iv_val  = <t>-name ).
      IF <t>-description IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/description|
                            iv_val  = <t>-description ).
      ENDIF.
      IF <t>-title IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/title|
                            iv_val  = <t>-title ).
      ENDIF.
      IF <t>-input_schema IS BOUND.
        result->set( iv_path = |{ p }/inputSchema|
                     iv_val  = <t>-input_schema ).
      ELSE.
        result->set_string( iv_path = |{ p }/inputSchema/type|
                            iv_val  = `object` ).
      ENDIF.
      IF <t>-output_schema IS BOUND.
        result->set( iv_path = |{ p }/outputSchema|
                     iv_val  = <t>-output_schema ).
      ENDIF.
      zcl_mcp2_icons=>emit( json  = result
                            path  = |{ p }/icons|
                            icons = <t>-icons ).
      emit_tool_annotations( json = result
                             path = p
                             ann  = <t>-annotations ).
      IF <t>-task_support IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/execution/taskSupport|
                            iv_val  = <t>-task_support ).
      ENDIF.
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
    result = ttl.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    result = scope.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    result = abap_true.
  ENDMETHOD.

  METHOD add_tool.
    APPEND entry TO tools.
  ENDMETHOD.

  METHOD set_next_cursor.
    next_cursor = cursor.
  ENDMETHOD.

  METHOD set_cache.
    ttl   = ttl_ms.
    scope = cache_scope.
  ENDMETHOD.

  METHOD emit_tool_annotations.
    DATA(a) = ann.
    IF     a-title                IS INITIAL
       AND a-read_only_hint        = abap_false
       AND a-destructive_hint_set  = abap_false
       AND a-destructive_hint      = abap_false
       AND a-idempotent_hint       = abap_false
       AND a-open_world_hint_set   = abap_false
       AND a-open_world_hint       = abap_false.
      RETURN.
    ENDIF.
    DATA(ap) = |{ path }/annotations|.
    IF a-title IS NOT INITIAL.
      json->set_string( iv_path = |{ ap }/title|
                        iv_val  = a-title ).
    ENDIF.
    IF a-read_only_hint = abap_true.
      json->set( iv_path = |{ ap }/readOnlyHint|
                 iv_val  = abap_true ).
    ENDIF.
    " destructiveHint: spec default true - emit only when explicitly false
    " (iv_ignore_empty would swallow the abap_false value entirely)
    IF a-destructive_hint_set = abap_true AND a-destructive_hint = abap_false.
      json->set( iv_path         = |{ ap }/destructiveHint|
                 iv_val          = abap_false
                 iv_ignore_empty = abap_false ).
    ELSEIF a-destructive_hint_set = abap_false AND a-destructive_hint = abap_true.
      json->set( iv_path = |{ ap }/destructiveHint|
                 iv_val  = abap_true ).
    ENDIF.
    IF a-idempotent_hint = abap_true.
      json->set( iv_path = |{ ap }/idempotentHint|
                 iv_val  = abap_true ).
    ENDIF.
    " openWorldHint: spec default true - emit only when explicitly false
    " (iv_ignore_empty would swallow the abap_false value entirely)
    IF a-open_world_hint_set = abap_true AND a-open_world_hint = abap_false.
      json->set( iv_path         = |{ ap }/openWorldHint|
                 iv_val          = abap_false
                 iv_ignore_empty = abap_false ).
    ELSEIF a-open_world_hint_set = abap_false AND a-open_world_hint = abap_true.
      json->set( iv_path = |{ ap }/openWorldHint|
                 iv_val  = abap_true ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
