"! <p class="shorttext synchronized">MCP2 HTTP request - ICF 7.5x impl</p>
"! Wraps IF_HTTP_REQUEST into ZIF_MCP2_HTTP_REQUEST. Only ZCL_MCP2_HTTP_FACTORY
"! instantiates this class; all other code uses the interface.
CLASS zcl_mcp2_http_req_icf DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_request.

    "! <p class="shorttext synchronized">Wrap an ICF request</p>
    "! @parameter icf_request | The classic ICF request object
    "! @parameter result      | The transport-neutral wrapper
    CLASS-METHODS create
      IMPORTING icf_request   TYPE REF TO if_http_request
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_http_request.

  PRIVATE SECTION.
    DATA icf_request TYPE REF TO if_http_request.
ENDCLASS.


CLASS zcl_mcp2_http_req_icf IMPLEMENTATION.
  METHOD create.
    DATA instance TYPE REF TO zcl_mcp2_http_req_icf.

    instance = NEW #( ).
    instance->icf_request = icf_request.
    result = instance.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_method.
    result = icf_request->get_method( ).
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header.
    result = icf_request->get_header_field( name ).
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header_names.
    DATA fields TYPE tihttpnvp.

    icf_request->get_header_fields( CHANGING fields = fields ).
    LOOP AT fields INTO DATA(field).
      APPEND field-name TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_path.
    result = icf_request->get_header_field( '~path_info' ).
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_body.
    result = icf_request->get_cdata( ).
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_origin.
    result = icf_request->get_header_field( 'origin' ).
  ENDMETHOD.
ENDCLASS.
