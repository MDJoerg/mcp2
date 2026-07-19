"! <p class="shorttext synchronized">MCP2 prompts/get response</p>
CLASS zcl_mcp2_resp_get_prompt DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    "! <p class="shorttext synchronized">Append a user-role text message</p>
    "! @parameter text                 | Message text
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_user_text
      IMPORTING !text TYPE string
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append an assistant-role text message</p>
    "! @parameter text                 | Message text
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_assistant_text
      IMPORTING !text TYPE string
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append a message with a pre-built content node</p>
    "! Add a message with a pre-built content node (e.g. image, resource).
    "! @parameter role    | Message role (user / assistant)
    "! @parameter content | Pre-built content node
    METHODS add_message
      IMPORTING role    TYPE string
                content TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Set the prompt description</p>
    "! @parameter text | Description text
    METHODS set_description
      IMPORTING !text TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF message,
             role    TYPE string,
             content TYPE REF TO zif_mcp2_ajson,
           END OF message.

    DATA messages    TYPE STANDARD TABLE OF message WITH EMPTY KEY.
    DATA description TYPE string.

ENDCLASS.


CLASS zcl_mcp2_resp_get_prompt IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    IF description IS NOT INITIAL.
      result->set_string( iv_path = '/description'
                          iv_val  = description ).
    ENDIF.
    result->touch_array( '/messages' ).
    LOOP AT messages ASSIGNING FIELD-SYMBOL(<m>).
      DATA(mp) = |/messages/{ sy-tabix }|.
      result->set_string( iv_path = |{ mp }/role|
                          iv_val  = <m>-role ).
      result->set( iv_path = |{ mp }/content|
                   iv_val  = <m>-content ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
    " GetPromptResult is not a CacheableResult in the spec - no cache hints.
    result = 0.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    " GetPromptResult is not a CacheableResult in the spec - no cache hints.
    result = ``.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    " Not a spec CacheableResult - never stamped with ttlMs/cacheScope.
  ENDMETHOD.

  METHOD add_user_text.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `text` ).
    block->set_string( iv_path = '/text'
                       iv_val  = text ).
    APPEND VALUE #( role    = `user`
                    content = block ) TO messages.
  ENDMETHOD.

  METHOD add_assistant_text.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `text` ).
    block->set_string( iv_path = '/text'
                       iv_val  = text ).
    APPEND VALUE #( role    = `assistant`
                    content = block ) TO messages.
  ENDMETHOD.

  METHOD add_message.
    APPEND VALUE #( role    = role
                    content = content ) TO messages.
  ENDMETHOD.

  METHOD set_description.
    description = text.
  ENDMETHOD.
ENDCLASS.
