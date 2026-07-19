CLASS ltcl_req_complete DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_prompt_ref        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_ref      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_unknown_ref       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_ref       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_context      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_arg_name  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_arg_value FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_ref_name  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_ref_uri   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_meta         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_context        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_req_complete IMPLEMENTATION.
  METHOD test_prompt_ref.
    DATA(req) = NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse( |\{"ref":\{"type":"ref/prompt","name":"greet"\},| &&
                                                                  |"argument":\{"name":"lang","value":"d"\}\}| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `ref/prompt`
                                        act = req->get_ref_type( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `greet`
                                        act = req->get_ref_name( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `lang`
                                        act = req->get_argument_name( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `d`
                                        act = req->get_argument_value( ) ).
    cl_abap_unit_assert=>assert_false( req->has_context( ) ).
  ENDMETHOD.

  METHOD test_resource_ref.
    DATA(req) = NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse(
                                               |\{"ref":\{"type":"ref/resource","uri":"file:///a"\},| &&
                                               |"argument":\{"name":"p","value":"x"\}\}| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `ref/resource`
                                        act = req->get_ref_type( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///a`
                                        act = req->get_ref_uri( ) ).
  ENDMETHOD.

  METHOD test_unknown_ref.
    TRY.
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse(
                                       `{"ref":{"type":"ref/unknown"},"argument":{"name":"x","value":"y"}}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_ref.
    TRY.
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse( `{"argument":{"name":"x","value":"y"}}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_with_context.
    DATA(req) = NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse( |\{"ref":\{"type":"ref/prompt","name":"p"\},| &&
                                                                  |"argument":\{"name":"a","value":"v"\},| &&
                                                                  |"context":\{"arguments":\{"prev":"done"\}\}\}| ) ).
    cl_abap_unit_assert=>assert_true( req->has_context( ) ).
    cl_abap_unit_assert=>assert_bound( req->get_context_json( ) ).
  ENDMETHOD.

  METHOD test_missing_arg_name.
    TRY.
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse( `{"ref":{"type":"ref/prompt","name":"p"}}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_arg_value.
    TRY.
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse(
                                       `{"ref":{"type":"ref/prompt","name":"p"},"argument":{"name":"x"}}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_ref_name.
    TRY.
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse(
                                       `{"ref":{"type":"ref/prompt"},"argument":{"name":"x","value":"y"}}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_ref_uri.
    TRY.
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse(
                                       `{"ref":{"type":"ref/resource"},"argument":{"name":"x","value":"y"}}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_with_meta.
    DATA(req) = NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse( |\{"ref":\{"type":"ref/prompt","name":"p"\},| &&
                                                                  |"argument":\{"name":"a","value":"v"\},| &&
                                                                  |"_meta":\{"token":"abc"\}\}| ) ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `abc`
                                        act = req->get_meta( )->get_string( '/token' ) ).
  ENDMETHOD.

  METHOD test_no_context.
    DATA(req) = NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse(
                                               `{"ref":{"type":"ref/prompt","name":"p"},"argument":{"name":"a","value":"v"}}` ) ).
    cl_abap_unit_assert=>assert_false( req->has_context( ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_context_json( ) ).
  ENDMETHOD.
ENDCLASS.
