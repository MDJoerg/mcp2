CLASS ltcl_req_list_tasks DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_no_params        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_with_cursor      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_without_cursor   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_meta_extracted   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_unbound_params   FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_req_list_tasks IMPLEMENTATION.

  METHOD test_no_params.
    DATA unbound TYPE REF TO zif_mcp2_ajson.
    DATA(req) = NEW zcl_mcp2_req_list_tasks( unbound ).
    cl_abap_unit_assert=>assert_false( req->has_cursor( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `` act = req->get_cursor( ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_meta( ) ).
  ENDMETHOD.

  METHOD test_with_cursor.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"cursor":"tok_abc123"}` ).
    DATA(req) = NEW zcl_mcp2_req_list_tasks( json ).
    cl_abap_unit_assert=>assert_true( req->has_cursor( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `tok_abc123` act = req->get_cursor( ) ).
  ENDMETHOD.

  METHOD test_without_cursor.
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    DATA(req) = NEW zcl_mcp2_req_list_tasks( json ).
    cl_abap_unit_assert=>assert_false( req->has_cursor( ) ).
  ENDMETHOD.

  METHOD test_meta_extracted.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"_meta":{"traceId":"t1"}}` ).
    DATA(req) = NEW zcl_mcp2_req_list_tasks( json ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `t1`
      act = req->get_meta( )->get_string( '/traceId' ) ).
  ENDMETHOD.

  METHOD test_unbound_params.
    DATA unbound TYPE REF TO zif_mcp2_ajson.
    DATA(req) = NEW zcl_mcp2_req_list_tasks( unbound ).
    cl_abap_unit_assert=>assert_false( req->has_cursor( ) ).
  ENDMETHOD.

ENDCLASS.
