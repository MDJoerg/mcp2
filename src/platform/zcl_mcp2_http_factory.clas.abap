"! <p class="shorttext synchronized">MCP2 HTTP wrapper factory (7.5x)</p>
"! The single place in the codebase that knows about ICF. ZCL_MCP2_HTTP_HANDLER
"! calls this factory once per request to wrap IF_HTTP_REQUEST / IF_HTTP_RESPONSE
"! into ZIF_MCP2_HTTP_REQUEST / ZIF_MCP2_HTTP_RESPONSE. Everything below the
"! handler uses only the interfaces.
"!
"! When ABAP Cloud support is added, this factory is the only class that changes.
CLASS zcl_mcp2_http_factory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Wrap an ICF request</p>
    "! @parameter icf_request | ICF request object
    "! @parameter result      | Transport-neutral request wrapper
    CLASS-METHODS create_request
      IMPORTING icf_request   TYPE REF TO if_http_request
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_http_request.

    "! <p class="shorttext synchronized">Wrap an ICF response</p>
    "! @parameter icf_response | ICF response object
    "! @parameter result       | Transport-neutral response wrapper
    CLASS-METHODS create_response
      IMPORTING icf_response  TYPE REF TO if_http_response
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_http_response.

ENDCLASS.


CLASS zcl_mcp2_http_factory IMPLEMENTATION.
  METHOD create_request.
    result = zcl_mcp2_http_req_icf=>create( icf_request ).
  ENDMETHOD.

  METHOD create_response.
    result = zcl_mcp2_http_resp_icf=>create( icf_response ).
  ENDMETHOD.

ENDCLASS.
