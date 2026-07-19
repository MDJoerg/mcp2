CLASS ltcl_req_cancel_task DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_valid_task_id   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_task_id FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_invalid_hex     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_meta_extracted  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_meta         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_req_cancel_task IMPLEMENTATION.

  METHOD test_valid_task_id.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899"}` ).
    DATA(req) = NEW zcl_mcp2_req_cancel_task( json ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = req->get_task_id( ) ).
  ENDMETHOD.

  METHOD test_missing_task_id.
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_cancel_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_invalid_hex.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"GGBBCCDDEEFF00112233445566778899"}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_cancel_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for non-hex char' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_meta_extracted.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899","_meta":{"x":"y"}}` ).
    DATA(req) = NEW zcl_mcp2_req_cancel_task( json ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
  ENDMETHOD.

  METHOD test_no_meta.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899"}` ).
    DATA(req) = NEW zcl_mcp2_req_cancel_task( json ).
    cl_abap_unit_assert=>assert_not_bound( req->get_meta( ) ).
  ENDMETHOD.

ENDCLASS.
