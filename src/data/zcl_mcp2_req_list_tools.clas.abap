"! <p class="shorttext synchronized">MCP2 tools/list request</p>
CLASS zcl_mcp2_req_list_tools DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Parse a list params object</p>
    "! @parameter json                 | The params slice of the JSON-RPC request
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS constructor
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Pagination cursor (empty when absent)</p>
    "! @parameter result | Opaque pagination cursor
    METHODS get_cursor
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether a pagination cursor was supplied</p>
    "! @parameter result | abap_true when a cursor is present
    METHODS has_cursor
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">The request _meta object</p>
    "! @parameter result | The _meta object, or unbound when absent
    METHODS get_meta
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

  PRIVATE SECTION.
    DATA cursor     TYPE string.
    DATA cursor_set TYPE abap_bool.
    DATA meta       TYPE REF TO zif_mcp2_ajson.

ENDCLASS.


CLASS zcl_mcp2_req_list_tools IMPLEMENTATION.
  METHOD constructor.
    IF json->exists( '/cursor' ).
      cursor     = json->get_string( '/cursor' ).
      cursor_set = abap_true.
    ENDIF.
    IF json->exists( '/_meta' ).
      meta = json->slice( '/_meta' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_cursor.
    result = cursor.
  ENDMETHOD.

  METHOD has_cursor.
    result = cursor_set.
  ENDMETHOD.

  METHOD get_meta.
    result = meta.
  ENDMETHOD.
ENDCLASS.
