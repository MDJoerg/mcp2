"! <p class="shorttext synchronized">MCP2 tasks/update request</p>
"! Modern-era MRTR continuation for a task in input_required state.
CLASS zcl_mcp2_req_update_task DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Parse a tasks/update params object</p>
    "! @parameter params               | Request params (taskId + inputResponses)
    "! @raising   zcx_mcp2_error       | Missing/invalid taskId or inputResponses
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS constructor
      IMPORTING params TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Task id being continued</p>
    "! @parameter result | Normalized 32-char task id
    METHODS get_task_id
      RETURNING VALUE(result) TYPE sysuuid_c32.

    "! <p class="shorttext synchronized">Client answers to the pending inputRequired</p>
    "! @parameter result | inputResponses object keyed by request key
    METHODS get_input_responses
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">The request _meta object</p>
    "! @parameter result | The _meta object, or unbound when absent
    METHODS get_meta
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

  PRIVATE SECTION.
    DATA task_id          TYPE sysuuid_c32.
    DATA input_responses  TYPE REF TO zif_mcp2_ajson.
    DATA meta             TYPE REF TO zif_mcp2_ajson.

ENDCLASS.

CLASS zcl_mcp2_req_update_task IMPLEMENTATION.
  METHOD constructor.
    IF params IS NOT BOUND OR params->exists( '/taskId' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `tasks/update requires taskId` ) ##NO_TEXT.
    ENDIF.
    IF params->get_node_type( '/taskId' ) <> zif_mcp2_ajson_types=>node_type-string.
      zcx_mcp2_error=>raise_invalid_params( `tasks/update taskId must be a string` ) ##NO_TEXT.
    ENDIF.
    task_id = zcl_mcp2_task_util=>normalize_task_id( params->get_string( '/taskId' ) ).

    IF params->exists( '/inputResponses' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `tasks/update requires inputResponses` ) ##NO_TEXT.
    ENDIF.
    IF params->get_node_type( '/inputResponses' )
       <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_invalid_params(
        `tasks/update inputResponses must be an object` ) ##NO_TEXT.
    ENDIF.
    input_responses = params->slice( '/inputResponses' ).

    IF params->exists( '/_meta' ).
      meta = params->slice( '/_meta' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_task_id.
    result = task_id.
  ENDMETHOD.

  METHOD get_input_responses.
    result = input_responses.
  ENDMETHOD.

  METHOD get_meta.
    result = meta.
  ENDMETHOD.
ENDCLASS.
