"! <p class="shorttext synchronized">MCP2 completion/complete request</p>
CLASS zcl_mcp2_req_complete DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF ref_type,
                 prompt   TYPE string VALUE `ref/prompt`,
                 resource TYPE string VALUE `ref/resource`,
               END OF ref_type.

    "! <p class="shorttext synchronized">Parse a completion/complete params object</p>
    "! @parameter json                 | The params slice of the JSON-RPC request
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    "! @raising   zcx_mcp2_error       | Missing/invalid required field
    METHODS constructor
      IMPORTING !json TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error
                zcx_mcp2_error.

    "! <p class="shorttext synchronized">Reference kind: ref/prompt or ref/resource</p>
    "! @parameter result | ref/prompt or ref/resource
    METHODS get_ref_type
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Prompt name (only when ref/prompt)</p>
    "! @parameter result | Prompt name, empty for ref/resource
    METHODS get_ref_name
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Resource URI (only when ref/resource)</p>
    "! @parameter result | Resource URI, empty for ref/prompt
    METHODS get_ref_uri
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Name of the argument being completed</p>
    "! @parameter result | Argument name
    METHODS get_argument_name
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Partial value typed so far</p>
    "! @parameter result | Partial argument value
    METHODS get_argument_value
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether resolved-argument context was supplied</p>
    "! @parameter result | abap_true when context is present
    METHODS has_context
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Previously-resolved argument context object</p>
    "! @parameter result | Context object, or unbound when absent
    METHODS get_context_json
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">The request _meta object</p>
    "! @parameter result | The _meta object, or unbound when absent
    METHODS get_meta
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson.

  PRIVATE SECTION.
    DATA ref_type_val    TYPE string.
    DATA ref_name        TYPE string.
    DATA ref_uri         TYPE string.
    DATA argument_name   TYPE string.
    DATA argument_value  TYPE string.
    DATA context_present TYPE abap_bool.
    DATA context_json    TYPE REF TO zif_mcp2_ajson.
    DATA meta            TYPE REF TO zif_mcp2_ajson.

ENDCLASS.


CLASS zcl_mcp2_req_complete IMPLEMENTATION.
  METHOD constructor.
    IF json->exists( '/ref/type' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `completion/complete: ref.type is required` ) ##NO_TEXT.
    ENDIF.
    ref_type_val = json->get_string( '/ref/type' ).

    CASE ref_type_val.
      WHEN ref_type-prompt.
        IF json->exists( '/ref/name' ) = abap_false.
          zcx_mcp2_error=>raise_invalid_params( `completion/complete: ref.name required for ref/prompt` ) ##NO_TEXT.
        ENDIF.
        ref_name = json->get_string( '/ref/name' ).
      WHEN ref_type-resource.
        IF json->exists( '/ref/uri' ) = abap_false.
          zcx_mcp2_error=>raise_invalid_params( `completion/complete: ref.uri required for ref/resource` ) ##NO_TEXT.
        ENDIF.
        ref_uri = json->get_string( '/ref/uri' ).
      WHEN OTHERS.
        zcx_mcp2_error=>raise_invalid_params( |completion/complete: unknown ref.type '{ ref_type_val }'| ) ##NO_TEXT.
    ENDCASE.

    IF json->exists( '/argument/name' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `completion/complete: argument.name is required` ) ##NO_TEXT.
    ENDIF.
    argument_name = json->get_string( '/argument/name' ).

    IF json->exists( '/argument/value' ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params( `completion/complete: argument.value is required` ) ##NO_TEXT.
    ENDIF.
    argument_value = json->get_string( '/argument/value' ).

    IF json->exists( '/context' ).
      context_present = abap_true.
      context_json    = json->slice( '/context' ).
    ENDIF.

    IF json->exists( '/_meta' ).
      meta = json->slice( '/_meta' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_ref_type.
    result = ref_type_val.
  ENDMETHOD.

  METHOD get_ref_name.
    result = ref_name.
  ENDMETHOD.

  METHOD get_ref_uri.
    result = ref_uri.
  ENDMETHOD.

  METHOD get_argument_name.
    result = argument_name.
  ENDMETHOD.

  METHOD get_argument_value.
    result = argument_value.
  ENDMETHOD.

  METHOD has_context.
    result = context_present.
  ENDMETHOD.

  METHOD get_context_json.
    result = context_json.
  ENDMETHOD.

  METHOD get_meta.
    result = meta.
  ENDMETHOD.

ENDCLASS.
