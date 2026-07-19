CLASS ltcl_req_get_prompt DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_name_only          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_arguments     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_retry         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_retry_resp_only    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_name       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_empty_name         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_meta          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_input_responses FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_try_input_response FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_get_arg_string     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_string_default FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_required_arg_string FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_required_arg_missing FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_invalid_field_types FOR TESTING RAISING zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_req_get_prompt IMPLEMENTATION.
  METHOD test_invalid_field_types.
    DATA cases TYPE string_table.
    cases = VALUE #( ( `{"name":7}` )
                     ( `{"name":"p","arguments":{"count":1}}` )
                     ( `{"name":"p","requestState":7}` )
                     ( `{"name":"p","inputResponses":[]}` ) ).
    LOOP AT cases INTO DATA(json_text).
      TRY.
          NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( json_text ) ).
          cl_abap_unit_assert=>fail( `Expected invalid field type` ).
        CATCH zcx_mcp2_error INTO DATA(err).
          cl_abap_unit_assert=>assert_equals(
            exp = zif_mcp2_const=>error_codes-invalid_params act = err->code ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD test_name_only.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet"}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `greet`
                                        act = req->get_name( ) ).
    cl_abap_unit_assert=>assert_false( req->has_arguments( ) ).
    cl_abap_unit_assert=>assert_false( req->is_retry( ) ).
  ENDMETHOD.

  METHOD test_with_arguments.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet","arguments":{"lang":"de"}}` ) ).
    cl_abap_unit_assert=>assert_true( req->has_arguments( ) ).
    DATA(args) = req->get_arguments( ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( args ) ).
    cl_abap_unit_assert=>assert_equals( exp = `de`
                                        act = args[ 1 ]-value ).
  ENDMETHOD.

  METHOD test_get_arg_string.
    " Typed getter parity with zcl_mcp2_req_call_tool=>get_arg_string.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet","arguments":{"lang":"de"}}` ) ).
    cl_abap_unit_assert=>assert_true( req->has_arg( `lang` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `de`
                                        act = req->get_arg_string( `lang` ) ).
    cl_abap_unit_assert=>assert_false( req->has_arg( `missing` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_string( `missing` ) ).
  ENDMETHOD.

  METHOD test_arg_string_default.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet","arguments":{"lang":"de"}}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `de`
                                        act = req->get_arg_string_or( name = `lang` default_value = `en` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `en`
                                        act = req->get_arg_string_or( name = `missing` default_value = `en` ) ).
  ENDMETHOD.

  METHOD test_required_arg_string.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet","arguments":{"lang":"de"}}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `de`
                                        act = req->require_arg_string( `lang` ) ).
  ENDMETHOD.

  METHOD test_required_arg_missing.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet","arguments":{"lang":"de"}}` ) ).
    TRY.
        req->require_arg_string( `missing` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_mrtr_retry.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse(
                                                 `{"name":"form","requestState":"st2","inputResponses":{"f1":"val"}}` ) ).
    cl_abap_unit_assert=>assert_true( req->is_retry( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `st2`
                                        act = req->get_request_state( ) ).
  ENDMETHOD.

  METHOD test_retry_resp_only.
    " inputResponses without requestState still counts as an MRTR retry.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse(
                                                 `{"name":"form","inputResponses":{"f1":"val"}}` ) ).
    cl_abap_unit_assert=>assert_true( req->is_retry( ) ).
    cl_abap_unit_assert=>assert_true( req->has_input_responses( ) ).
    cl_abap_unit_assert=>assert_initial( req->get_request_state( ) ).
  ENDMETHOD.

  METHOD test_missing_name.
    TRY.
        NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_empty_name.
    TRY.
        NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":""}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_with_meta.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet","_meta":{"token":"abc"}}` ) ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `abc`
                                        act = req->get_meta( )->get_string( '/token' ) ).
  ENDMETHOD.

  METHOD test_no_input_responses.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse( `{"name":"greet"}` ) ).
    cl_abap_unit_assert=>assert_false( req->has_input_responses( ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_input_responses( ) ).
  ENDMETHOD.

  METHOD test_try_input_response.
    DATA(req) = NEW zcl_mcp2_req_get_prompt( zcl_mcp2_ajson=>parse(
      `{"name":"greet","inputResponses":{"approval":{"action":"accept"}}}` ) ).

    cl_abap_unit_assert=>assert_not_bound(
      req->try_get_input_response( `missing` ) ).

    DATA(elicit) = req->try_get_input_response( `approval` ).
    cl_abap_unit_assert=>assert_bound( elicit ).
    cl_abap_unit_assert=>assert_true( elicit->is_accept( ) ).
  ENDMETHOD.
ENDCLASS.
