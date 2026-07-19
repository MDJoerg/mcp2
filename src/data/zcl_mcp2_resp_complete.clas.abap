"! <p class="shorttext synchronized">MCP2 completion/complete response</p>
CLASS zcl_mcp2_resp_complete DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    TYPES values TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! <p class="shorttext synchronized">Append a single completion candidate</p>
    "! @parameter value | Completion candidate value
    METHODS add_value
      IMPORTING !value TYPE string.

    "! <p class="shorttext synchronized">Set all completion candidates at once</p>
    "! @parameter values | Completion candidate values (max 100 per spec)
    METHODS set_values
      IMPORTING !values TYPE values.

    "! <p class="shorttext synchronized">Set the total number of matches</p>
    "! @parameter count | Total available matches
    METHODS set_total
      IMPORTING !count TYPE i.

    "! <p class="shorttext synchronized">Flag that more matches exist beyond those returned</p>
    "! @parameter flag | abap_true when more candidates are available
    METHODS set_has_more
      IMPORTING flag TYPE abap_bool.

  PRIVATE SECTION.
    DATA vals         TYPE values.
    DATA total        TYPE i.
    DATA has_more     TYPE abap_bool.
    DATA has_more_set TYPE abap_bool.

ENDCLASS.


CLASS zcl_mcp2_resp_complete IMPLEMENTATION.
  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/completion/values' ).
    LOOP AT vals INTO DATA(v).
      result->set( iv_path = |/completion/values/{ sy-tabix }|
                   iv_val  = v ).
    ENDLOOP.
    IF total > 0.
      result->set_integer( iv_path = '/completion/total'
                           iv_val  = total ).
    ENDIF.
    IF has_more_set = abap_true.
      result->set( iv_path         = '/completion/hasMore'
                   iv_val          = has_more
                   iv_ignore_empty = abap_false ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
    " CompleteResult is not a CacheableResult in the spec - no cache hints.
    result = 0.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    " CompleteResult is not a CacheableResult in the spec - no cache hints.
    result = ``.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    " Not a spec CacheableResult - never stamped with ttlMs/cacheScope.
  ENDMETHOD.

  METHOD add_value.
    APPEND value TO vals.
  ENDMETHOD.

  METHOD set_values.
    vals = values.
  ENDMETHOD.

  METHOD set_total.
    total = count.
  ENDMETHOD.

  METHOD set_has_more.
    has_more = flag.
    has_more_set = abap_true.
  ENDMETHOD.
ENDCLASS.
