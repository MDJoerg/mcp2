"! <p class="shorttext synchronized">MCP2 HTTP response - ICF 7.5x impl</p>
"! Wraps IF_HTTP_RESPONSE into ZIF_MCP2_HTTP_RESPONSE. Only ZCL_MCP2_HTTP_FACTORY
"! instantiates this class; all other code uses the interface.
CLASS zcl_mcp2_http_resp_icf DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_response.

    "! <p class="shorttext synchronized">Wrap an ICF response</p>
    "! @parameter icf_response | The classic ICF response object
    "! @parameter result       | The transport-neutral wrapper
    CLASS-METHODS create
      IMPORTING icf_response  TYPE REF TO if_http_response
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_http_response.

  PRIVATE SECTION.
    DATA icf_response TYPE REF TO if_http_response.
ENDCLASS.


CLASS zcl_mcp2_http_resp_icf IMPLEMENTATION.
  METHOD create.
    DATA instance TYPE REF TO zcl_mcp2_http_resp_icf.

    instance = NEW #( ).
    instance->icf_response = icf_response.
    result = instance.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_status.
    icf_response->set_status( code   = code
                              reason = '' ).
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_header.
    icf_response->set_header_field( name  = name
                                    value = value ).
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_content_type.
    icf_response->set_content_type( content_type ).
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_body.
    icf_response->set_cdata( body ).
  ENDMETHOD.

ENDCLASS.
