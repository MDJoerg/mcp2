"! <p class="shorttext synchronized">MCP2 prompts/list response</p>
CLASS zcl_mcp2_resp_list_prompts DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES: BEGIN OF prompt_arg_def,
             name        TYPE string,
             description TYPE string,
             required    TYPE abap_bool,
           END OF prompt_arg_def.
    TYPES arg_def_list TYPE STANDARD TABLE OF prompt_arg_def WITH KEY name.

    TYPES: BEGIN OF prompt,
             name        TYPE string,
             description TYPE string,
             title       TYPE string,
             icons       TYPE zif_mcp2_content=>icons,
             arguments   TYPE arg_def_list,
           END OF prompt.
    TYPES prompt_list TYPE STANDARD TABLE OF prompt WITH KEY name.

    "! <p class="shorttext synchronized">Append a prompt definition</p>
    "! @parameter entry | Prompt name, description, title and argument defs
    METHODS add_prompt
      IMPORTING !entry TYPE prompt.

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
    DATA prompts     TYPE prompt_list.
    DATA next_cursor TYPE string.
    DATA ttl         TYPE i.
    DATA scope       TYPE string.

ENDCLASS.


CLASS zcl_mcp2_resp_list_prompts IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/prompts' ).
    LOOP AT prompts ASSIGNING FIELD-SYMBOL(<p>).
      DATA(pp) = |/prompts/{ sy-tabix }|.
      result->set_string( iv_path = |{ pp }/name|
                          iv_val  = <p>-name ).
      IF <p>-description IS NOT INITIAL.
        result->set_string( iv_path = |{ pp }/description|
                            iv_val  = <p>-description ).
      ENDIF.
      IF <p>-title IS NOT INITIAL.
        result->set_string( iv_path = |{ pp }/title|
                            iv_val  = <p>-title ).
      ENDIF.
      zcl_mcp2_icons=>emit( json  = result
                            path  = |{ pp }/icons|
                            icons = <p>-icons ).
      IF <p>-arguments IS INITIAL.
        CONTINUE.
      ENDIF.

      result->touch_array( |{ pp }/arguments| ).
      LOOP AT <p>-arguments ASSIGNING FIELD-SYMBOL(<a>).
        DATA(ap) = |{ pp }/arguments/{ sy-tabix }|.
        result->set_string( iv_path = |{ ap }/name|
                            iv_val  = <a>-name ).
        IF <a>-description IS NOT INITIAL.
          result->set_string( iv_path = |{ ap }/description|
                              iv_val  = <a>-description ).
        ENDIF.
        IF <a>-required = abap_true.
          result->set( iv_path = |{ ap }/required|
                       iv_val  = abap_true ).
        ENDIF.
      ENDLOOP.
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

  METHOD add_prompt.
    APPEND entry TO prompts.
  ENDMETHOD.

  METHOD set_next_cursor.
    next_cursor = cursor.
  ENDMETHOD.

  METHOD set_cache.
    ttl = ttl_ms.
    scope = cache_scope.
  ENDMETHOD.
ENDCLASS.
