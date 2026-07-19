"! <p class="shorttext synchronized">MCP2 tasks/result request (legacy)</p>
"! Legacy-era request to retrieve the terminal result payload of a completed task.
CLASS zcl_mcp2_req_get_task_payload DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Parse a tasks/result params object</p>
    "! @parameter params               | Request params containing taskId
    "! @raising   zcx_mcp2_error       | Missing or invalid taskId
    "! @raising   zcx_mcp2_ajson_error | JSON parse failure
    METHODS constructor
      IMPORTING params TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Task id whose result is requested</p>
    "! @parameter result | Normalized 32-char task id
    METHODS get_task_id
      RETURNING VALUE(result) TYPE sysuuid_c32.

    "! <p class="shorttext synchronized">The request _meta object</p>
    "! @parameter result | The _meta object, or unbound when absent
    METHODS get_meta
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

  PRIVATE SECTION.
    DATA task_id TYPE sysuuid_c32.
    DATA meta    TYPE REF TO zif_mcp2_ajson.

ENDCLASS.

CLASS zcl_mcp2_req_get_task_payload IMPLEMENTATION.
  METHOD constructor.
    IF params IS NOT BOUND OR params->exists( '/taskId' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `tasks/result requires taskId` ) ##NO_TEXT.
    ENDIF.
    task_id = zcl_mcp2_task_util=>normalize_task_id( params->get_string( '/taskId' ) ).
    IF params->exists( '/_meta' ).
      meta = params->slice( '/_meta' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_task_id.
    result = task_id.
  ENDMETHOD.

  METHOD get_meta.
    result = meta.
  ENDMETHOD.
ENDCLASS.
