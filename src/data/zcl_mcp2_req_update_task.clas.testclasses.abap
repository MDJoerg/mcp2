CLASS ltcl_req_update_task DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_valid_with_responses   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_task_id        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_missing_input_responses FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_invalid_task_id        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_meta_present           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_meta_absent            FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_invalid_field_types     FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_req_update_task IMPLEMENTATION.
  METHOD test_invalid_field_types.
    DATA cases TYPE string_table.
    cases = VALUE #(
      ( `{"taskId":7,"inputResponses":{}}` )
      ( `{"taskId":"AABBCCDDEEFF00112233445566778899","inputResponses":[]}` ) ).
    LOOP AT cases INTO DATA(json_text).
      TRY.
          NEW zcl_mcp2_req_update_task( zcl_mcp2_ajson=>parse( json_text ) ).
          cl_abap_unit_assert=>fail( `Expected invalid field type` ).
        CATCH zcx_mcp2_error INTO DATA(err).
          cl_abap_unit_assert=>assert_equals(
            exp = zif_mcp2_const=>error_codes-invalid_params act = err->code ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD test_valid_with_responses.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899","inputResponses":{"approval":{"action":"accept"}}}` ).
    DATA(req) = NEW zcl_mcp2_req_update_task( json ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = req->get_task_id( ) ).
    cl_abap_unit_assert=>assert_bound( req->get_input_responses( ) ).
  ENDMETHOD.

  METHOD test_missing_task_id.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"inputResponses":{"x":{}}}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_update_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for missing taskId' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_input_responses.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899"}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_update_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for missing inputResponses' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_invalid_task_id.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"short","inputResponses":{}}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_update_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for short taskId' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_meta_present.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899","inputResponses":{},"_meta":{"trace":"abc"}}` ).
    DATA(req) = NEW zcl_mcp2_req_update_task( json ).
    DATA(meta) = req->get_meta( ).
    cl_abap_unit_assert=>assert_bound( meta ).
    cl_abap_unit_assert=>assert_equals( exp = `abc`
                                        act = meta->get_string( '/trace' ) ).
  ENDMETHOD.

  METHOD test_meta_absent.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899","inputResponses":{}}` ).
    DATA(req) = NEW zcl_mcp2_req_update_task( json ).
    cl_abap_unit_assert=>assert_not_bound( req->get_meta( ) ).
  ENDMETHOD.

ENDCLASS.
