"! Tests for the platform abstraction. These tests use local mock implementations
"! of ZIF_MCP2_HTTP_REQUEST / ZIF_MCP2_HTTP_RESPONSE to verify that the interfaces
"! work correctly without requiring ICF. They also serve as a template for how
"! tests in the protocol core should mock the HTTP layer.
CLASS ltcl_mock_request DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_request.

    DATA method   TYPE string.
    DATA path     TYPE string.
    DATA body     TYPE string.
    DATA origin   TYPE string.
    DATA headers  TYPE string_table.
    DATA hdr_vals TYPE string_table.

ENDCLASS.

CLASS ltcl_mock_request IMPLEMENTATION.
  METHOD zif_mcp2_http_request~get_method.
    result = method.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_path.
    result = path.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_body.
    result = body.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_origin.
    result = origin.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header.
    DATA idx TYPE i.

    LOOP AT headers INTO DATA(h) WHERE table_line = name.
      idx = sy-tabix.
      READ TABLE hdr_vals INDEX idx INTO result. "#EC CI_SUBRC
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header_names.
    result = headers.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_mock_response DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_response.

    DATA status       TYPE i.
    DATA content_type TYPE string.
    DATA body         TYPE string.
    DATA hdr_names    TYPE string_table.
    DATA hdr_vals     TYPE string_table.

ENDCLASS.

CLASS ltcl_mock_response IMPLEMENTATION.
  METHOD zif_mcp2_http_response~set_status.
    status = code.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_content_type.
    me->content_type = content_type.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_body.
    me->body = body.
  ENDMETHOD.

  METHOD zif_mcp2_http_response~set_header.
    APPEND name  TO hdr_names.
    APPEND value TO hdr_vals.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_platform DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS test_mock_request  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mock_response FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_platform IMPLEMENTATION.
  METHOD test_mock_request.
    DATA req TYPE REF TO ltcl_mock_request.

    req = NEW #( ).
    req->method = 'POST'.
    req->path   = '/mcp/main/my-server'.
    req->body   = '{"jsonrpc":"2.0"}' ##NO_TEXT.
    req->origin = 'https://example.com' ##NO_TEXT.
    APPEND 'Content-Type' TO req->headers.
    APPEND 'application/json' TO req->hdr_vals.

    DATA request TYPE REF TO zif_mcp2_http_request.
    request = req.

    cl_abap_unit_assert=>assert_equals( exp = 'POST'
                                        act = request->get_method( ) ).
    cl_abap_unit_assert=>assert_equals( exp = '/mcp/main/my-server'
                                        act = request->get_path( ) ).
    cl_abap_unit_assert=>assert_equals( exp = '{"jsonrpc":"2.0"}'
                                        act = request->get_body( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'https://example.com'
                                        act = request->get_origin( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'application/json'
                                        act = request->get_header( 'Content-Type' ) ).

    DATA names TYPE string_table.
    names = request->get_header_names( ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( names ) ).
  ENDMETHOD.

  METHOD test_mock_response.
    DATA resp TYPE REF TO ltcl_mock_response.

    resp = NEW #( ).

    DATA response TYPE REF TO zif_mcp2_http_response.
    response = resp.

    response->set_status( 200 ).
    response->set_content_type( 'application/json' ).
    response->set_body( '{}' ).
    response->set_header( name  = 'Allow'
                          value = 'POST, OPTIONS' ).

    cl_abap_unit_assert=>assert_equals( exp = 200
                                        act = resp->status ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( resp->hdr_names ) ).
  ENDMETHOD.
ENDCLASS.


"! Tests for ZCL_MCP2_HTTP_FACTORY itself. create_request/create_response only
"! store the ICF reference they are given - they never dereference it - so an
"! unbound IF_HTTP_REQUEST/IF_HTTP_RESPONSE is enough to prove the wrapping
"! happens without needing a live ICF request/response.
CLASS ltcl_http_factory DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS test_create_request_wraps  FOR TESTING.
    METHODS test_create_response_wraps FOR TESTING.

ENDCLASS.

CLASS ltcl_http_factory IMPLEMENTATION.
  METHOD test_create_request_wraps.
    DATA icf_request TYPE REF TO if_http_request.
    DATA(result) = zcl_mcp2_http_factory=>create_request( icf_request ).
    cl_abap_unit_assert=>assert_bound( result ).
  ENDMETHOD.

  METHOD test_create_response_wraps.
    DATA icf_response TYPE REF TO if_http_response.
    DATA(result) = zcl_mcp2_http_factory=>create_response( icf_response ).
    cl_abap_unit_assert=>assert_bound( result ).
  ENDMETHOD.
ENDCLASS.
