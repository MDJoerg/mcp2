CLASS ltcl_req_list_resources DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_no_cursor   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_cursor FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_meta     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_meta   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_req_list_resources IMPLEMENTATION.
  METHOD test_no_cursor.
    DATA(req) = NEW zcl_mcp2_req_list_resources( zcl_mcp2_ajson=>parse( `{}` ) ).
    cl_abap_unit_assert=>assert_false( req->has_cursor( ) ).
    cl_abap_unit_assert=>assert_initial( req->get_cursor( ) ).
  ENDMETHOD.

  METHOD test_with_cursor.
    DATA(req) = NEW zcl_mcp2_req_list_resources( zcl_mcp2_ajson=>parse( `{"cursor":"tok1"}` ) ).
    cl_abap_unit_assert=>assert_true( req->has_cursor( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `tok1`
                                        act = req->get_cursor( ) ).
  ENDMETHOD.

  METHOD test_no_meta.
    DATA(req) = NEW zcl_mcp2_req_list_resources( zcl_mcp2_ajson=>parse( `{}` ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_meta( ) ).
  ENDMETHOD.

  METHOD test_with_meta.
    DATA(req) = NEW zcl_mcp2_req_list_resources( zcl_mcp2_ajson=>parse( `{"_meta":{"token":"abc"}}` ) ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `abc`
                                        act = req->get_meta( )->get_string( '/token' ) ).
  ENDMETHOD.
ENDCLASS.
