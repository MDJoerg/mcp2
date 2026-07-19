"! <p class="shorttext synchronized">MCP2 resources/read response</p>
CLASS zcl_mcp2_resp_read_resource DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    "! <p class="shorttext synchronized">Append a text resource-contents block</p>
    "! @parameter uri                  | Resource URI
    "! @parameter text                 | Text payload
    "! @parameter mime_type            | Optional MIME type
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_text_content
      IMPORTING uri       TYPE string
                !text     TYPE string
                mime_type TYPE string OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append a binary (blob) resource-contents block</p>
    "! @parameter uri                  | Resource URI
    "! @parameter blob                 | Base64-encoded binary payload
    "! @parameter mime_type            | Optional MIME type
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_blob_content
      IMPORTING uri       TYPE string
                !blob     TYPE string
                mime_type TYPE string OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Set modern cache hints (ttlMs / cacheScope)</p>
    "! @parameter ttl_ms      | Time-to-live in milliseconds
    "! @parameter cache_scope | public or private (see zif_mcp2_const)
    METHODS set_cache
      IMPORTING ttl_ms      TYPE i
                cache_scope TYPE string.

  PRIVATE SECTION.
    DATA content TYPE STANDARD TABLE OF REF TO zif_mcp2_ajson WITH EMPTY KEY.
    DATA ttl     TYPE i.
    DATA scope   TYPE string.

ENDCLASS.


CLASS zcl_mcp2_resp_read_resource IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/contents' ).
    LOOP AT content ASSIGNING FIELD-SYMBOL(<c>).
      result->set( iv_path = |/contents/{ sy-tabix }|
                   iv_val  = <c> ).
    ENDLOOP.
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

  METHOD add_text_content.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/uri'
                       iv_val  = uri ).
    block->set_string( iv_path = '/text'
                       iv_val  = text ).
    IF mime_type IS SUPPLIED AND mime_type IS NOT INITIAL.
      block->set_string( iv_path = '/mimeType'
                         iv_val  = mime_type ).
    ENDIF.
    APPEND block TO content.
  ENDMETHOD.

  METHOD add_blob_content.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/uri'
                       iv_val  = uri ).
    block->set_string( iv_path = '/blob'
                       iv_val  = blob ).
    IF mime_type IS SUPPLIED AND mime_type IS NOT INITIAL.
      block->set_string( iv_path = '/mimeType'
                         iv_val  = mime_type ).
    ENDIF.
    APPEND block TO content.
  ENDMETHOD.

  METHOD set_cache.
    ttl = ttl_ms.
    scope = cache_scope.
  ENDMETHOD.
ENDCLASS.
