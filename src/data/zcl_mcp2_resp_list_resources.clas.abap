"! <p class="shorttext synchronized">MCP2 resources/list response</p>
CLASS zcl_mcp2_resp_list_resources DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES: BEGIN OF resource,
             uri         TYPE string,
             name        TYPE string,
             title       TYPE string,
             description TYPE string,
             mime_type   TYPE string,
             icons       TYPE zif_mcp2_content=>icons,
           END OF resource.
    TYPES resource_list TYPE STANDARD TABLE OF resource WITH KEY uri.

    "! <p class="shorttext synchronized">Append a resource entry</p>
    "! @parameter entry | Resource uri, name, title, description, MIME type
    METHODS add_resource
      IMPORTING !entry TYPE resource.

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
    DATA resources   TYPE resource_list.
    DATA next_cursor TYPE string.
    DATA ttl         TYPE i.
    DATA scope       TYPE string.

ENDCLASS.


CLASS zcl_mcp2_resp_list_resources IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/resources' ).
    LOOP AT resources ASSIGNING FIELD-SYMBOL(<r>).
      DATA(p) = |/resources/{ sy-tabix }|.
      result->set_string( iv_path = |{ p }/uri|
                          iv_val  = <r>-uri ).
      IF <r>-name IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/name|
                            iv_val  = <r>-name ).
      ENDIF.
      IF <r>-title IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/title|
                            iv_val  = <r>-title ).
      ENDIF.
      IF <r>-description IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/description|
                            iv_val  = <r>-description ).
      ENDIF.
      IF <r>-mime_type IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/mimeType|
                            iv_val  = <r>-mime_type ).
      ENDIF.
      zcl_mcp2_icons=>emit( json  = result
                            path  = |{ p }/icons|
                            icons = <r>-icons ).
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

  METHOD add_resource.
    APPEND entry TO resources.
  ENDMETHOD.

  METHOD set_next_cursor.
    next_cursor = cursor.
  ENDMETHOD.

  METHOD set_cache.
    ttl = ttl_ms.
    scope = cache_scope.
  ENDMETHOD.
ENDCLASS.
