"! <p class="shorttext synchronized">MCP2 resources/templates/list response</p>
CLASS zcl_mcp2_resp_list_res_tmpls DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES: BEGIN OF template,
             uri_template TYPE string,
             name         TYPE string,
             title        TYPE string,
             description  TYPE string,
             mime_type    TYPE string,
             icons        TYPE zif_mcp2_content=>icons,
           END OF template.
    TYPES template_list TYPE STANDARD TABLE OF template WITH KEY uri_template.

    "! <p class="shorttext synchronized">Append a resource-template entry</p>
    "! @parameter entry | URI template, name, title, description, MIME type
    METHODS add_template
      IMPORTING !entry TYPE template.

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
    DATA templates   TYPE template_list.
    DATA next_cursor TYPE string.
    DATA ttl         TYPE i.
    DATA scope       TYPE string.

ENDCLASS.


CLASS zcl_mcp2_resp_list_res_tmpls IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/resourceTemplates' ).
    LOOP AT templates ASSIGNING FIELD-SYMBOL(<t>).
      DATA(p) = |/resourceTemplates/{ sy-tabix }|.
      result->set_string( iv_path = |{ p }/uriTemplate|
                          iv_val  = <t>-uri_template ).
      IF <t>-name IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/name|
                            iv_val  = <t>-name ).
      ENDIF.
      IF <t>-title IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/title|
                            iv_val  = <t>-title ).
      ENDIF.
      IF <t>-description IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/description|
                            iv_val  = <t>-description ).
      ENDIF.
      IF <t>-mime_type IS NOT INITIAL.
        result->set_string( iv_path = |{ p }/mimeType|
                            iv_val  = <t>-mime_type ).
      ENDIF.
      zcl_mcp2_icons=>emit( json  = result
                            path  = |{ p }/icons|
                            icons = <t>-icons ).
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

  METHOD add_template.
    APPEND entry TO templates.
  ENDMETHOD.

  METHOD set_next_cursor.
    next_cursor = cursor.
  ENDMETHOD.

  METHOD set_cache.
    ttl = ttl_ms.
    scope = cache_scope.
  ENDMETHOD.
ENDCLASS.
