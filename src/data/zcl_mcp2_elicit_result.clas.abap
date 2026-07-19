"! <p class="shorttext synchronized">MCP2 elicitation response reader</p>
"! Parses the client's answer to an elicitation/create request.
"! Construct with the ajson slice for the specific input-response key,
"! then use is_accept/is_decline/is_cancel and the typed getters.
CLASS zcl_mcp2_elicit_result DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Parse an elicitation response object</p>
    "! Wraps the {action, content?} object returned by the client.
    "! @parameter json                 | The elicitation response object (action + optional content)
    "! @raising   zcx_mcp2_error       | Missing or invalid action field
    "! @raising   zcx_mcp2_ajson_error | JSON parse failure
    METHODS constructor
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Raw action string (accept/decline/cancel)</p>
    "! @parameter result | Raw action string
    METHODS get_action
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether the user accepted (action = accept)</p>
    "! @parameter result | abap_true when action = accept
    METHODS is_accept
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the user declined (action = decline)</p>
    "! @parameter result | abap_true when action = decline
    METHODS is_decline
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether the user cancelled (action = cancel)</p>
    "! @parameter result | abap_true when action = cancel
    METHODS is_cancel
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether a content object is present</p>
    "! @parameter result | abap_true when the response includes content
    METHODS has_content
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">The content object (empty ajson when absent)</p>
    "! @parameter result | Content object; empty ajson when no content was sent
    METHODS get_content
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Read a string field from content</p>
    "! @parameter name                 | Field name (no leading slash)
    "! @parameter result               | Field value
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS get_string
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Read a boolean field from content</p>
    "! @parameter name                 | Field name (no leading slash)
    "! @parameter result               | Field value
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS get_boolean
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Read an integer field from content</p>
    "! @parameter name                 | Field name (no leading slash)
    "! @parameter result               | Field value
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    METHODS get_integer
      IMPORTING !name         TYPE string
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA action      TYPE string.
    DATA has_content_flag TYPE abap_bool.
    DATA content     TYPE REF TO zif_mcp2_ajson.

ENDCLASS.


CLASS zcl_mcp2_elicit_result IMPLEMENTATION.

  METHOD constructor.
    IF json IS NOT BOUND.
      zcx_mcp2_error=>raise_invalid_params( `Elicitation result JSON is required` ) ##NO_TEXT.
    ENDIF.

    IF json->exists( '/action' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `Elicitation result requires action field` ) ##NO_TEXT.
    ENDIF.

    action = json->get_string( '/action' ).
    IF    action <> zif_mcp2_const=>elicit_actions-accept
      AND action <> zif_mcp2_const=>elicit_actions-decline
      AND action <> zif_mcp2_const=>elicit_actions-cancel.
      zcx_mcp2_error=>raise_invalid_params(
          |Invalid elicitation action: { action }| ) ##NO_TEXT.
    ENDIF.

    IF json->exists( '/content' ) = abap_true.
      has_content_flag = abap_true.
      content          = json->slice( '/content' ).
    ELSE.
      has_content_flag = abap_false.
      content          = zcl_mcp2_ajson=>create_empty( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_action.
    result = action.
  ENDMETHOD.

  METHOD is_accept.
    result = xsdbool( action = zif_mcp2_const=>elicit_actions-accept ).
  ENDMETHOD.

  METHOD is_decline.
    result = xsdbool( action = zif_mcp2_const=>elicit_actions-decline ).
  ENDMETHOD.

  METHOD is_cancel.
    result = xsdbool( action = zif_mcp2_const=>elicit_actions-cancel ).
  ENDMETHOD.

  METHOD has_content.
    result = has_content_flag.
  ENDMETHOD.

  METHOD get_content.
    result = content.
  ENDMETHOD.

  METHOD get_string.
    result = content->get_string( |/{ name }| ).
  ENDMETHOD.

  METHOD get_boolean.
    result = content->get_boolean( |/{ name }| ).
  ENDMETHOD.

  METHOD get_integer.
    result = content->get_integer( |/{ name }| ).
  ENDMETHOD.

ENDCLASS.
