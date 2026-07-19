CLASS ltcl_resp_input_req DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_request_state     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_single_request    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_params       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_state          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_multiple_requests FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_cache_scope       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_ttl               FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_add_request_typed FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_fluent_state      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_state_only        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_bad_request_key   FOR TESTING RAISING zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_input_req IMPLEMENTATION.
  METHOD test_bad_request_key.
    " Keys become ajson path segments - '/' would corrupt the structure.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.
    resp = NEW #( ).
    TRY.
        resp->add_input_request( request_key = `bad/key`
                                 method      = `elicitation/create` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-internal_error
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_request_state.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->set_request_state( `tok-xyz` ).
    resp->add_input_request( request_key = `q1`
                             method      = `elicitation/create` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `tok-xyz`
                                        act = parsed->get_string( '/requestState' ) ).
  ENDMETHOD.

  METHOD test_fluent_state.
    " set_request_state chains like add_request - both return self.
    DATA elicitation TYPE REF TO zcl_mcp2_input_elicitation.
    elicitation = NEW #( ).
    elicitation->set_form( `Confirm?` ).

    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.
    resp = NEW #( ).
    resp->set_request_state( `tok-1` )->add_request( request_key = `q1`
                                                     input       = elicitation ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `tok-1`
                                        act = parsed->get_string( '/requestState' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = parsed->get_string( '/inputRequests/q1/method' ) ).
  ENDMETHOD.

  METHOD test_single_request.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->set_request_state( `s1` ).
    resp->add_input_request( request_key = `name`
                             method      = `elicitation/create` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = parsed->get_string( '/inputRequests/name/method' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/inputRequests/name/params' ) ).
  ENDMETHOD.

  METHOD test_with_params.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->set_request_state( `s2` ).
    resp->add_input_request( request_key = `q1`
                             method      = `elicitation/create`
                             params      = zcl_mcp2_ajson=>parse( `{"message":"What is your name?"}` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `What is your name?`
                                        act = parsed->get_string( '/inputRequests/q1/params/message' ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-input_required
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_no_state.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->add_input_request( request_key = `q1`
                             method      = `elicitation/create` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/requestState' ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/inputRequests' ) ).
  ENDMETHOD.

  METHOD test_multiple_requests.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->add_input_request( request_key = `q1`
                             method      = `elicitation/create` ).
    resp->add_input_request( request_key = `q2`
                             method      = `elicitation/create` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = parsed->get_string( '/inputRequests/q1/method' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = parsed->get_string( '/inputRequests/q2/method' ) ).
  ENDMETHOD.

  METHOD test_cache_scope.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = `private`
                                        act = resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.

  METHOD test_ttl.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
  ENDMETHOD.

  METHOD test_add_request_typed.
    " A typed input builder supplies both method and params through add_request.
    DATA sampling TYPE REF TO zcl_mcp2_input_sampling.
    sampling = NEW #( ).
    sampling->set_max_tokens( 128 )->add_user_text( `Pick one` ).

    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.
    resp = NEW #( ).
    resp->add_request( request_key = `sample`
                       input       = sampling ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>methods-sampling_create
                                        act = parsed->get_string( '/inputRequests/sample/method' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 128
                                        act = parsed->get_integer( '/inputRequests/sample/params/maxTokens' ) ).
  ENDMETHOD.

  METHOD test_state_only.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->set_request_state( `state-only` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `state-only`
                                        act = parsed->get_string( '/requestState' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/inputRequests' ) ).
  ENDMETHOD.
ENDCLASS.
