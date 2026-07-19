"! <p class="shorttext synchronized">MCP2 icon-array JSON emitter</p>
"! Shared emitter for the spec Icon[] shape (serverInfo, tools, prompts,
"! resources, resource templates, resource links).
CLASS zcl_mcp2_icons DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Emit an icons array at the given path</p>
    "! Emits nothing when the icon table is empty; per icon only the filled
    "! optional fields (mimeType, sizes, theme) are written.
    "! @parameter json                 | Target JSON document
    "! @parameter path                 | Array path, e.g. `/serverInfo/icons`
    "! @parameter icons                | Typed icon entries
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    CLASS-METHODS emit
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
                !path TYPE string
                icons TYPE zif_mcp2_content=>icons
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_icons IMPLEMENTATION.
  METHOD emit.
    IF icons IS INITIAL.
      RETURN.
    ENDIF.

    json->touch_array( path ).
    LOOP AT icons ASSIGNING FIELD-SYMBOL(<i>).
      DATA(p) = |{ path }/{ sy-tabix }|.
      json->set_string( iv_path = |{ p }/src|
                        iv_val  = <i>-src ).
      IF <i>-mime_type IS NOT INITIAL.
        json->set_string( iv_path = |{ p }/mimeType|
                          iv_val  = <i>-mime_type ).
      ENDIF.
      IF <i>-theme IS NOT INITIAL.
        json->set_string( iv_path = |{ p }/theme|
                          iv_val  = <i>-theme ).
      ENDIF.
      IF <i>-sizes IS NOT INITIAL.
        json->touch_array( |{ p }/sizes| ).
        LOOP AT <i>-sizes INTO DATA(size).
          json->set_string( iv_path = |{ p }/sizes/{ sy-tabix }|
                            iv_val  = size ).
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
