CLASS ltcl_req_call_tool DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_name_only          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_arguments     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_retry         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_retry_resp_only    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_task_opt_in        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_task_opt_in     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_name       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_empty_name         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_meta          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_input_responses FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_typed_arg_getters  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_getters_absent FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_getters_default FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_required_args      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_required_arg_missing FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_get_arg_json       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_bind_arguments     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_get_input_response FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_try_input_resp     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_resp_missing FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_invalid_field_types FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_arg_number         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_number_absent  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_number_bad     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_string_table   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_typed_tables   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_tables_absent  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_arg_tables_bad     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_req_call_tool IMPLEMENTATION.
  METHOD test_invalid_field_types.
    DATA cases TYPE string_table.
    cases = VALUE #( ( `{"name":7}` )
                     ( `{"name":"t","arguments":[]}` )
                     ( `{"name":"t","requestState":7}` )
                     ( `{"name":"t","inputResponses":false}` ) ).
    LOOP AT cases INTO DATA(json_text).
      TRY.
          NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( json_text ) ).
          cl_abap_unit_assert=>fail( `Expected invalid field type` ).
        CATCH zcx_mcp2_error INTO DATA(err).
          cl_abap_unit_assert=>assert_equals(
            exp = zif_mcp2_const=>error_codes-invalid_params act = err->code ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD test_name_only.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"my_tool"}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `my_tool`
                                        act = req->get_name( ) ).
    cl_abap_unit_assert=>assert_false( req->has_arguments( ) ).
    cl_abap_unit_assert=>assert_false( req->is_retry( ) ).
  ENDMETHOD.

  METHOD test_with_arguments.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"calc","arguments":{"x":1,"y":2}}` ) ).
    cl_abap_unit_assert=>assert_true( req->has_arguments( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1`
                                        act = req->get_arguments( )->get_string( '/x' ) ).
  ENDMETHOD.

  METHOD test_mrtr_retry.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
                                                `{"name":"ask","requestState":"state1","inputResponses":{"q1":"yes"}}` ) ).
    cl_abap_unit_assert=>assert_true( req->is_retry( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `state1`
                                        act = req->get_request_state( ) ).
    cl_abap_unit_assert=>assert_true( req->has_input_responses( ) ).
  ENDMETHOD.

  METHOD test_retry_resp_only.
    " A server may send inputRequests without requestState; the retry then
    " carries only inputResponses and must still count as a retry.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
                                                `{"name":"ask","inputResponses":{"q1":"yes"}}` ) ).
    cl_abap_unit_assert=>assert_true( req->is_retry( ) ).
    cl_abap_unit_assert=>assert_true( req->has_input_responses( ) ).
    cl_abap_unit_assert=>assert_initial( req->get_request_state( ) ).
  ENDMETHOD.

  METHOD test_task_opt_in.
    " Legacy 2025-11-25 per-request task augmentation: params.task with ttl (ms).
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
                                                `{"name":"long","task":{"ttl":60000}}` ) ).
    cl_abap_unit_assert=>assert_true( req->has_task_request( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 60000
                                        act = req->get_task_ttl_ms( ) ).

    " task without ttl still opts in
    DATA(req_no_ttl) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
                                                       `{"name":"long","task":{}}` ) ).
    cl_abap_unit_assert=>assert_true( req_no_ttl->has_task_request( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = req_no_ttl->get_task_ttl_ms( ) ).
  ENDMETHOD.

  METHOD test_no_task_opt_in.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"t"}` ) ).
    cl_abap_unit_assert=>assert_false( req->has_task_request( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = req->get_task_ttl_ms( ) ).
  ENDMETHOD.

  METHOD test_missing_name.
    TRY.
        NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_empty_name.
    TRY.
        NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":""}` ) ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_with_meta.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"t","_meta":{"token":"abc"}}` ) ).
    cl_abap_unit_assert=>assert_bound( req->get_meta( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `abc`
                                        act = req->get_meta( )->get_string( '/token' ) ).
  ENDMETHOD.

  METHOD test_no_input_responses.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"t"}` ) ).
    cl_abap_unit_assert=>assert_false( req->has_input_responses( ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_input_responses( ) ).
  ENDMETHOD.

  METHOD test_arg_number.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"rate":0.1,"discount":12.75,"whole":3}}` ) ).
    " Read from the raw literal, so the decimal is exact rather than the
    " nearest binary float.
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '0.1' )
                                        act = req->get_arg_number( `rate` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '12.75' )
                                        act = req->get_arg_number( `discount` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '3' )
                                        act = req->get_arg_number( `whole` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '12.75' )
                                        act = req->require_arg_number( `discount` ) ).
  ENDMETHOD.

  METHOD test_arg_number_absent.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{}}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 0 )
                                        act = req->get_arg_number( `rate` ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = CONV decfloat34( '2.5' )
      act = req->get_arg_number_or( name = `rate` default_value = CONV decfloat34( '2.5' ) ) ).
    TRY.
        req->require_arg_number( `rate` ).
        cl_abap_unit_assert=>fail( `missing required number must raise` ).
      CATCH zcx_mcp2_error.
        " expected
    ENDTRY.
  ENDMETHOD.

  METHOD test_arg_number_bad.
    " Non-number nodes yield 0 rather than dumping. A numeric *string* is
    " deliberately not coerced - schema validation reports the type error.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"rate":"abc","quoted":"12.75","flag":true}}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 0 )
                                        act = req->get_arg_number( `rate` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 0 )
                                        act = req->get_arg_number( `quoted` ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 0 )
                                        act = req->get_arg_number( `flag` ) ).
  ENDMETHOD.

  METHOD test_arg_string_table.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"tags":["a","b","c"]}}` ) ).
    DATA(tags) = req->get_arg_string_table( `tags` ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( tags ) ).
    cl_abap_unit_assert=>assert_equals( exp = `a` act = tags[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = `c` act = tags[ 3 ] ).
    " Absent -> empty table, not an error.
    cl_abap_unit_assert=>assert_initial( req->get_arg_string_table( `missing` ) ).
  ENDMETHOD.

  METHOD test_arg_typed_tables.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"ids":[10,20,30],` &&
      `"rates":[0.1,12.75],"flags":[true,false,true]}}` ) ).

    DATA(ids) = req->get_arg_integer_table( `ids` ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( ids ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10 act = ids[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = 30 act = ids[ 3 ] ).

    " Elements keep their decimal value exactly, as get_arg_number does.
    DATA(rates) = req->get_arg_number_table( `rates` ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( rates ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '0.1' ) act = rates[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '12.75' ) act = rates[ 2 ] ).

    DATA(flags) = req->get_arg_boolean_table( `flags` ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( flags ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true  act = flags[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = flags[ 2 ] ).
  ENDMETHOD.

  METHOD test_arg_tables_absent.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{}}` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_integer_table( `ids` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_number_table( `rates` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_boolean_table( `flags` ) ).
  ENDMETHOD.

  METHOD test_arg_tables_bad.
    " A non-array argument yields an empty table rather than dumping; a
    " non-matching element contributes the initial value.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"ids":7,"rates":["x",5],"flags":"no"}}` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_integer_table( `ids` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_boolean_table( `flags` ) ).

    DATA(rates) = req->get_arg_number_table( `rates` ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( rates ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 0 ) act = rates[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 5 ) act = rates[ 2 ] ).
  ENDMETHOD.

  METHOD test_typed_arg_getters.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"label":"hi","count":7,"active":true}}` ) ).
    cl_abap_unit_assert=>assert_true( req->has_arg( `label` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`
                                        act = req->get_arg_string( `label` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = req->get_arg_integer( `count` ) ).
    cl_abap_unit_assert=>assert_true( req->get_arg_boolean( `active` ) ).
  ENDMETHOD.

  METHOD test_arg_getters_absent.
    " No arguments object at all - getters stay null-safe
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"t"}` ) ).
    cl_abap_unit_assert=>assert_false( req->has_arg( `x` ) ).
    cl_abap_unit_assert=>assert_initial( req->get_arg_string( `x` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = req->get_arg_integer( `x` ) ).
    cl_abap_unit_assert=>assert_false( req->get_arg_boolean( `x` ) ).
  ENDMETHOD.

  METHOD test_arg_getters_default.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"label":"hi","count":7,"active":false}}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`
                                        act = req->get_arg_string_or( name = `label` default_value = `fallback` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `fallback`
                                        act = req->get_arg_string_or( name = `missing` default_value = `fallback` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = req->get_arg_integer_or( name = `count` default_value = 99 ) ).
    cl_abap_unit_assert=>assert_equals( exp = 99
                                        act = req->get_arg_integer_or( name = `missing` default_value = 99 ) ).
    cl_abap_unit_assert=>assert_false( req->get_arg_boolean_or( name = `active` default_value = abap_true ) ).
    cl_abap_unit_assert=>assert_true( req->get_arg_boolean_or( name = `missing` default_value = abap_true ) ).
  ENDMETHOD.

  METHOD test_required_args.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"label":"hi","count":7,"active":true}}` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`
                                        act = req->require_arg_string( `label` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = req->require_arg_integer( `count` ) ).
    cl_abap_unit_assert=>assert_true( req->require_arg_boolean( `active` ) ).
  ENDMETHOD.

  METHOD test_required_arg_missing.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"label":"hi"}}` ) ).
    TRY.
        req->require_arg_integer( `count` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_get_arg_json.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"nested":{"x":1},"label":"hi"}}` ) ).
    DATA(nested) = req->get_arg_json( `nested` ).
    cl_abap_unit_assert=>assert_bound( nested ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = nested->get_integer( '/x' ) ).
    cl_abap_unit_assert=>assert_not_bound( req->get_arg_json( `missing` ) ).
  ENDMETHOD.

  METHOD test_bind_arguments.
    TYPES: BEGIN OF args_type,
             label TYPE string,
             count TYPE i,
           END OF args_type.
    DATA target TYPE args_type.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"calc","arguments":{"label":"hi","count":7,"extra":"ignored"}}` ) ).
    req->bind_arguments( CHANGING target = target ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`  act = target-label ).
    cl_abap_unit_assert=>assert_equals( exp = 7     act = target-count ).
  ENDMETHOD.

  METHOD test_get_input_response.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"ask","requestState":"s1","inputResponses":{"approval":{"action":"accept","content":{"reason":"ok"}}}}` ) ).
    DATA(elicit) = req->get_input_response( `approval` ).
    cl_abap_unit_assert=>assert_true( elicit->is_accept( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `ok`
                                        act = elicit->get_string( `reason` ) ).
  ENDMETHOD.

  METHOD test_input_resp_missing.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"ask","inputResponses":{"other":{"action":"accept"}}}` ) ).
    TRY.
        req->get_input_response( `approval` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_try_input_resp.
    DATA(req) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
      `{"name":"ask","inputResponses":{"approval":{"action":"accept"}}}` ) ).

    cl_abap_unit_assert=>assert_not_bound(
      req->try_get_input_response( `missing` ) ).

    DATA(elicit) = req->try_get_input_response( `approval` ).
    cl_abap_unit_assert=>assert_bound( elicit ).
    cl_abap_unit_assert=>assert_true( elicit->is_accept( ) ).
  ENDMETHOD.
ENDCLASS.
