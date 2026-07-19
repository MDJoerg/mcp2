CLASS ltcl_req_get_task DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_valid_task_id          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_task_id        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_invalid_task_id_short  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_invalid_task_id_chars  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_uppercase_normalise    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_meta_extracted         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_unbound_params         FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_req_get_task IMPLEMENTATION.

  METHOD test_valid_task_id.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"aabbccddeeff00112233445566778899"}` ).
    DATA(req) = NEW zcl_mcp2_req_get_task( json ).
    cl_abap_unit_assert=>assert_equals( exp = `AABBCCDDEEFF00112233445566778899`
                                        act = req->get_task_id( ) ).
  ENDMETHOD.

  METHOD test_missing_task_id.
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_get_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for missing taskId' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_invalid_task_id_short.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"taskId":"tooshort"}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_get_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for short taskId' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_invalid_task_id_chars.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"zzbbccddeeff00112233445566778899"}` ).
    TRY.
        DATA(req) = NEW zcl_mcp2_req_get_task( json ).
        cl_abap_unit_assert=>fail( 'Expected error for non-hex taskId' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_uppercase_normalise.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"aabbccddeeff00112233445566778899"}` ).
    DATA(req) = NEW zcl_mcp2_req_get_task( json ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = req->get_task_id( ) ).
  ENDMETHOD.

  METHOD test_meta_extracted.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899","_meta":{"requestId":"r1"}}` ).
    DATA(req) = NEW zcl_mcp2_req_get_task( json ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `r1`
      act = req->get_meta( )->get_string( '/requestId' ) ).
  ENDMETHOD.

  METHOD test_unbound_params.
    DATA unbound TYPE REF TO zif_mcp2_ajson.
    TRY.
        DATA(req) = NEW zcl_mcp2_req_get_task( unbound ).
        cl_abap_unit_assert=>fail( 'Expected error for unbound params' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
