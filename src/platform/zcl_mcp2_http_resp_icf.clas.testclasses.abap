"! Only the release-independent wrapping contract is exercised here: the
"! get_*/set_* delegation methods dispatch straight to the real ICF object
"! (IF_HTTP_RESPONSE), which is not constructible in the Phase-5 JS-transpiled
"! test runtime (standalone CL_HTTP_RESPONSE relies on a kernel SYSTEM-CALL) -
"! see ZCL_MCP2_DDIC_75's test file for the same constraint. create() itself
"! never dereferences its input, so an unbound reference is enough to prove
"! the wrapping happens.
CLASS ltcl_http_resp_icf DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS test_create_wraps FOR TESTING.

ENDCLASS.

CLASS ltcl_http_resp_icf IMPLEMENTATION.
  METHOD test_create_wraps.
    DATA icf_response TYPE REF TO if_http_response.
    DATA(result) = zcl_mcp2_http_resp_icf=>create( icf_response ).
    cl_abap_unit_assert=>assert_bound( result ).
  ENDMETHOD.
ENDCLASS.
