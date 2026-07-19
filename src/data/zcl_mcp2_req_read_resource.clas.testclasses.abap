CLASS ltcl_req_read_resource DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_valid_uri   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_uri FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_empty_uri   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_meta     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_meta   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_retry  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_retry    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_try_input_response FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_invalid_field_types FOR TESTING RAISING zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_req_read_resource IMPLEMENTATION.
  METHOD test_invalid_field_types.
    DATA cases TYPE string_table.
    cases = VALUE #( ( `{"uri":7}` )
                     ( `{"uri":"file:///x","requestState":7}` )
                     ( `{"uri":"file:///x","inputResponses":[]}` ) ).
    LOOP AT cases INTO DATA(json_text).
      TRY.
          NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( json_text ) ).
          cl_abap_unit_assert=>fail( `Expected invalid field type` ).
        CATCH zcx_mcp2_error INTO DATA(err).
          cl_abap_unit_assert=>assert_equals(
            exp = zif_mcp2_const=>error_codes-invalid_params act = err->code ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD test_valid_uri.
    DATA(req) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( `{"uri":"file:///data/doc.txt"}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///data/doc.txt`
                                        act = req->get_uri( ) ).
  ENDMETHOD.

  METHOD test_missing_uri.
    TRY.
        NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( `{}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_empty_uri.
    TRY.
        NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( `{"uri":""}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_no_meta.
    DATA(req) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( `{"uri":"file:///x"}` ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_meta( ) ).
  ENDMETHOD.

  METHOD test_with_meta.
    DATA(req) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( `{"uri":"file:///x","_meta":{"token":"abc"}}` ) ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `abc`
                                        act = req->get_meta( )->get_string( '/token' ) ).
  ENDMETHOD.

  METHOD test_mrtr_retry.
    " resources/read is MRTR-capable: the retry leg carries requestState
    " and/or inputResponses, same accessors as tools/call.
    DATA(req) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse(
        `{"uri":"file:///x","requestState":"st1",` &&
        `"inputResponses":{"q1":{"action":"accept","content":{"v":"yes"}}}}` ) ).
    cl_abap_unit_assert=>assert_true( req->is_retry( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `st1`
                                        act = req->get_request_state( ) ).
    cl_abap_unit_assert=>assert_true( req->has_input_responses( ) ).
    DATA(answer) = req->get_input_response( `q1` ).
    cl_abap_unit_assert=>assert_true( answer->is_accept( ) ).

    " inputResponses without requestState still counts as a retry
    DATA(req2) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse(
        `{"uri":"file:///x","inputResponses":{"q1":{"action":"decline"}}}` ) ).
    cl_abap_unit_assert=>assert_true( req2->is_retry( ) ).
  ENDMETHOD.

  METHOD test_no_retry.
    DATA(req) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse( `{"uri":"file:///x"}` ) ).
    cl_abap_unit_assert=>assert_false( req->is_retry( ) ).
    cl_abap_unit_assert=>assert_false( req->has_input_responses( ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_input_responses( ) ).
  ENDMETHOD.

  METHOD test_try_input_response.
    DATA(req) = NEW zcl_mcp2_req_read_resource( zcl_mcp2_ajson=>parse(
      `{"uri":"file:///x","inputResponses":{"approval":{"action":"accept"}}}` ) ).

    cl_abap_unit_assert=>assert_not_bound(
      req->try_get_input_response( `missing` ) ).

    DATA(elicit) = req->try_get_input_response( `approval` ).
    cl_abap_unit_assert=>assert_bound( elicit ).
    cl_abap_unit_assert=>assert_true( elicit->is_accept( ) ).
  ENDMETHOD.
ENDCLASS.
