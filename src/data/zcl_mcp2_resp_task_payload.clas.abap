"! <p class="shorttext synchronized">MCP2 task terminal payload</p>
"! Holds the final CallToolResult-shaped payload of a completed or failed task.
"! Returned by tasks/result (legacy) and embedded in tasks/get responses.
"! The persistence layer also serialises this to the PAYLOAD column.
CLASS zcl_mcp2_resp_task_payload DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    "! <p class="shorttext synchronized">Append a text content block</p>
    "! @parameter text | Plain text payload
    METHODS add_text
      IMPORTING !text TYPE string.

    "! <p class="shorttext synchronized">Set the structured result payload</p>
    "! @parameter content | JSON object conforming to the tool's output schema
    METHODS set_structured_content
      IMPORTING content TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Set the structured payload from ABAP data</p>
    "! Serializes any ABAP structure/table - no manual JSON.
    "! @parameter data                 | ABAP structure or table to serialize
    "! @parameter add_text             | Also add a text representation (default true)
    "! @raising   zcx_mcp2_ajson_error | Serialization failure
    METHODS set_structured_data
      IMPORTING !data    TYPE any
                add_text TYPE abap_bool DEFAULT abap_true
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Mark the result as an error outcome</p>
    "! @parameter flag | abap_true = error (default)
    METHODS set_is_error
      IMPORTING flag TYPE abap_bool DEFAULT abap_true.

    "! <p class="shorttext synchronized">Load a pre-built CallToolResult JSON</p>
    "! Used by the persistence layer. When set, to_json() returns this directly
    "! instead of building from the setters.
    "! @parameter json | Pre-built CallToolResult JSON
    METHODS set_from_json
      IMPORTING !json TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Annotate with the originating task id</p>
    "! Written to _meta under io.modelcontextprotocol/related-task.
    "! @parameter task_id              | 32-char uppercase hex UUID
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS set_related_task
      IMPORTING task_id TYPE sysuuid_c32
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Whether the payload is an error outcome</p>
    "! Used by the persistence layer to record the outcome.
    "! @parameter result | abap_true when marked as an error
    METHODS get_is_error
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA text_items         TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA structured_content TYPE REF TO zif_mcp2_ajson.
    DATA is_error           TYPE abap_bool.
    DATA prebuilt           TYPE REF TO zif_mcp2_ajson.
    DATA meta               TYPE REF TO zif_mcp2_ajson.

ENDCLASS.

CLASS zcl_mcp2_resp_task_payload IMPLEMENTATION.

  METHOD zif_mcp2_result~to_json.
    IF prebuilt IS BOUND.
      result = prebuilt.
      IF meta IS BOUND.
        result->set( iv_path = '/_meta' iv_val = meta ).
      ENDIF.
      RETURN.
    ENDIF.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/content' ).
    LOOP AT text_items INTO DATA(txt).
      DATA(idx) = sy-tabix.
      result->set_string( iv_path = |/content/{ idx }/type| iv_val = `text` ).
      result->set_string( iv_path = |/content/{ idx }/text| iv_val = txt ).
    ENDLOOP.
    IF structured_content IS BOUND.
      result->set( iv_path = '/structuredContent'
                   iv_val  = structured_content ).
    ENDIF.
    IF is_error = abap_true.
      result->set( iv_path         = '/isError'
                   iv_val          = abap_true
                   iv_ignore_empty = abap_false ).
    ENDIF.
    IF meta IS BOUND.
      result->set( iv_path = '/_meta' iv_val = meta ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
    result = 0.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    result = `private`.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    " Not a spec CacheableResult - never stamped with ttlMs/cacheScope.
  ENDMETHOD.

  METHOD add_text.
    APPEND text TO text_items.
  ENDMETHOD.

  METHOD set_structured_content.
    structured_content = content.
  ENDMETHOD.

  METHOD set_structured_data.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    json->set( iv_path = '/'
               iv_val  = data ).
    structured_content = json.
    IF add_text = abap_true.
      add_text( json->stringify( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD set_is_error.
    is_error = flag.
  ENDMETHOD.

  METHOD set_from_json.
    prebuilt = json.
  ENDMETHOD.

  METHOD set_related_task.
    IF meta IS NOT BOUND.
      IF prebuilt IS BOUND AND prebuilt->exists( '/_meta' ).
        meta = prebuilt->slice( '/_meta' ).
      ELSE.
        meta = zcl_mcp2_ajson=>create_empty( ).
      ENDIF.
    ENDIF.
    DATA(related) = zcl_mcp2_ajson=>create_empty( ).
    related->set_string( iv_path = '/taskId'
                         iv_val  = task_id ).
    " Literal '/' inside a member name is escaped as TAB (vendored-ajson
    " convention; there is no JSON-Pointer ~1 handling).
    meta->set( iv_path = '/io.modelcontextprotocol'
                         && cl_abap_char_utilities=>horizontal_tab
                         && 'related-task'
               iv_val  = related ).
  ENDMETHOD.

  METHOD get_is_error.
    result = is_error.
  ENDMETHOD.

ENDCLASS.
