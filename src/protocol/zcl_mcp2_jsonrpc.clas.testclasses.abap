CLASS ltcl_jsonrpc DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_parse_valid       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_parse_no_id       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_parse_numeric_id  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_parse_wrong_ver   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_parse_no_method   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_parse_malformed   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_is_notification   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_serialize_success FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_serialize_error   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_serialize_no_id   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_build_from_exc    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_id_string_stays_str FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_id_numeric_stays_num FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_id_big_numeric_kept FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_parse_null_id     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_empty_string_id    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_fractional_id_bad  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_root_must_be_object FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_method_must_be_string FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_params_must_be_object FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_args_object FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_jsonrpc IMPLEMENTATION.
  METHOD test_parse_valid.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"tools/list","id":"1","params":{}}` ).
    cl_abap_unit_assert=>assert_equals( exp = `tools/list`
                                        act = req-method ).
    cl_abap_unit_assert=>assert_equals( exp = `1`
                                        act = req-id ).
    cl_abap_unit_assert=>assert_true( req-id_present ).
  ENDMETHOD.

  METHOD test_parse_no_id.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"tools/list"}` ).
    cl_abap_unit_assert=>assert_equals( exp = `tools/list`
                                        act = req-method ).
    cl_abap_unit_assert=>assert_false( req-id_present ).
    cl_abap_unit_assert=>assert_initial( req-id ).
  ENDMETHOD.

  METHOD test_parse_numeric_id.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":42}` ).
    cl_abap_unit_assert=>assert_equals( exp = `42`
                                        act = req-id ).
    cl_abap_unit_assert=>assert_true( req-id_present ).
  ENDMETHOD.

  METHOD test_parse_wrong_ver.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"1.0","method":"ping","id":"1"}` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_parse_no_method.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","id":"1"}` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_parse_malformed.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request( `not json` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-parse_error
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_is_notification.
    DATA(notif) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping"}` ).
    cl_abap_unit_assert=>assert_true( zcl_mcp2_jsonrpc=>is_notification( notif ) ).

    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":"1"}` ).
    cl_abap_unit_assert=>assert_false( zcl_mcp2_jsonrpc=>is_notification( req ) ).
  ENDMETHOD.

  METHOD test_serialize_success.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":"1"}` ).
    DATA(resp) = zcl_mcp2_jsonrpc=>build_success( request = req ).
    DATA(json) = zcl_mcp2_jsonrpc=>serialize_response( resp ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( json ).
    cl_abap_unit_assert=>assert_equals( exp = `2.0`
                                        act = parsed->get_string( '/jsonrpc' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1`
                                        act = parsed->get_string( '/id' ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/result' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/error' ) ).
  ENDMETHOD.

  METHOD test_serialize_error.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":"1"}` ).
    DATA(resp) = zcl_mcp2_jsonrpc=>build_error( request = req
                                                code    = zif_mcp2_const=>error_codes-method_not_found
                                                message = `Method not found: ping` ).
    DATA(json) = zcl_mcp2_jsonrpc=>serialize_response( resp ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( json ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = parsed->get_integer( '/error/code' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/result' ) ).
  ENDMETHOD.

  METHOD test_serialize_no_id.
    " Error responses for notifications should not include an id.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-id_present = abap_false.
    DATA(resp) = zcl_mcp2_jsonrpc=>build_error( request = req
                                                code    = zif_mcp2_const=>error_codes-parse_error
                                                message = `Parse error` ).
    DATA(json) = zcl_mcp2_jsonrpc=>serialize_response( resp ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( json ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/id' ) ).
  ENDMETHOD.

  METHOD test_build_from_exc.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"tools/call","id":"99"}` ).
    TRY.
        zcx_mcp2_error=>raise_method_not_found( `tools/call` ).
      CATCH zcx_mcp2_error INTO DATA(exc).
    ENDTRY.

    DATA(resp) = zcl_mcp2_jsonrpc=>build_from_exc( request = req
                                                   exc     = exc ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = `99`
                                        act = resp-id ).
  ENDMETHOD.

  METHOD test_id_string_stays_str.
    " A numeric-looking string id must be echoed as a JSON string, not a number.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":"123"}` ).
    cl_abap_unit_assert=>assert_false( req-id_is_num ).

    DATA(parsed) = zcl_mcp2_ajson=>parse(
      zcl_mcp2_jsonrpc=>serialize_response( zcl_mcp2_jsonrpc=>build_success( req ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-string
                                        act = parsed->get_node_type( '/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `123`
                                        act = parsed->get_string( '/id' ) ).
  ENDMETHOD.

  METHOD test_id_numeric_stays_num.
    " A numeric id must be echoed as a JSON number.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":42}` ).
    cl_abap_unit_assert=>assert_true( req-id_is_num ).

    DATA(parsed) = zcl_mcp2_ajson=>parse(
      zcl_mcp2_jsonrpc=>serialize_response( zcl_mcp2_jsonrpc=>build_success( req ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-number
                                        act = parsed->get_node_type( '/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = parsed->get_integer( '/id' ) ).
  ENDMETHOD.

  METHOD test_id_big_numeric_kept.
    " A numeric id beyond 32-bit range survives as a number at full precision -
    " the old CONV i path would have overflowed and flipped it to a string.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request(
      `{"jsonrpc":"2.0","method":"ping","id":9007199254740991}` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse(
      zcl_mcp2_jsonrpc=>serialize_response( zcl_mcp2_jsonrpc=>build_success( req ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-number
                                        act = parsed->get_node_type( '/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `9007199254740991`
                                        act = parsed->get_string( '/id' ) ).
  ENDMETHOD.

  METHOD test_parse_null_id.
    " A null id is neither a string nor an integer - reject as invalid request.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":null}` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_empty_string_id.
    DATA(req) = zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":""}` ).
    cl_abap_unit_assert=>assert_true( req-id_present ).
    cl_abap_unit_assert=>assert_initial( req-id ).

    DATA(parsed) = zcl_mcp2_ajson=>parse(
      zcl_mcp2_jsonrpc=>serialize_response( zcl_mcp2_jsonrpc=>build_success( req ) ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-string
                                        act = parsed->get_node_type( '/id' ) ).
    cl_abap_unit_assert=>assert_initial( parsed->get_string( '/id' ) ).
  ENDMETHOD.

  METHOD test_fractional_id_bad.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request( `{"jsonrpc":"2.0","method":"ping","id":1.5}` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_root_must_be_object.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request( `[]` ).
        cl_abap_unit_assert=>fail( `Expected invalid request` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_request
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_method_must_be_string.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request(
          `{"jsonrpc":"2.0","method":7,"id":"1"}` ).
        cl_abap_unit_assert=>fail( `Expected invalid request` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_request
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_params_must_be_object.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request(
          `{"jsonrpc":"2.0","method":"ping","params":[]}` ).
        cl_abap_unit_assert=>fail( `Expected invalid params` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_args_object.
    TRY.
        zcl_mcp2_jsonrpc=>parse_request(
          `{"jsonrpc":"2.0","method":"tools/call","params":{"arguments":[]}}` ).
        cl_abap_unit_assert=>fail( `Expected invalid params` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
