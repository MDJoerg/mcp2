CLASS ltcl_resp_task_get DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_result_type        FOR TESTING.
    METHODS test_working_state      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_completed_result   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_failed_error       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_input_required     FOR TESTING RAISING zcx_mcp2_ajson_error zcx_mcp2_error.
    METHODS test_bad_request_key    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_error_with_data    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_input_no_params    FOR TESTING RAISING zcx_mcp2_ajson_error zcx_mcp2_error.
    METHODS test_task_fields        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_set_cache          FOR TESTING.
    METHODS test_not_cacheable      FOR TESTING.

ENDCLASS.

CLASS ltcl_resp_task_get IMPLEMENTATION.

  METHOD test_result_type.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-complete
      act = r->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_working_state.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `working`
      act = json->get_string( '/status' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/result' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/error' ) ).
  ENDMETHOD.

  METHOD test_completed_result.
    DATA(payload) = zcl_mcp2_ajson=>parse( `{"content":[{"type":"text","text":"done"}]}` ).
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `completed` ).
    r->set_result( payload ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/result' ) ).
  ENDMETHOD.

  METHOD test_failed_error.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `failed` ).
    r->set_error( code = -32000 message = `Task failed` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = -32000 act = json->get_integer( '/error/code' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Task failed`
                                        act = json->get_string( '/error/message' ) ).
  ENDMETHOD.

  METHOD test_input_required.
    " Task input is keyed by inputRequests only - no requestState (that field
    " belongs to MRTR retries of the original request, not tasks/get).
    DATA(params) = zcl_mcp2_ajson=>parse( `{"message":"Approve?"}` ).
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `input_required` ).
    r->add_input_request( request_key = `approval`
                          method      = `elicitation/create`
                          params      = params ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_false( json->exists( '/requestState' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/inputRequests/approval' ) ).
  ENDMETHOD.

  METHOD test_bad_request_key.
    " Keys become ajson path segments - '/' would corrupt the structure.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    TRY.
        r->add_input_request( request_key = `bad/key`
                              method      = `elicitation/create` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-internal_error
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_error_with_data.
    DATA(error_data) = zcl_mcp2_ajson=>parse( `{"reason":"timeout"}` ).
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `failed` ).
    r->set_error( code    = -32000
                  message = `Task failed`
                  data    = error_data ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `timeout`
                                        act = json->get_string( '/error/data/reason' ) ).
  ENDMETHOD.

  METHOD test_input_no_params.
    " params is optional - an empty object must still be emitted so the
    " client sees inputRequests/<key>/params as a valid (if empty) object.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `input_required` ).
    r->add_input_request( request_key = `approval`
                          method      = `elicitation/create` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = json->get_node_type( '/inputRequests/approval/params' ) ).
  ENDMETHOD.

  METHOD test_task_fields.
    " status_message, timestamps, ttlMs and pollIntervalMs are all optional
    " and written into the flat DetailedTask root.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_task( task_id          = `AABBCCDDEEFF00112233445566778899`
                 status           = `working`
                 status_message   = `Still going`
                 created_at       = '20260101120000'
                 last_updated     = '20260101120500'
                 ttl_ms           = 5000
                 poll_interval_ms = 1500 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `Still going`
                                        act = json->get_string( '/statusMessage' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:00:00Z`
                                        act = json->get_string( '/createdAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:05:00Z`
                                        act = json->get_string( '/lastUpdatedAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5000
                                        act = json->get_integer( '/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1500
                                        act = json->get_integer( '/pollIntervalMs' ) ).
  ENDMETHOD.

  METHOD test_set_cache.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    r->set_cache( ttl_ms      = 8000
                  cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 8000
                                        act = r->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public`
                                        act = r->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.

  METHOD test_not_cacheable.
    DATA(r) = NEW zcl_mcp2_resp_task_get( ).
    cl_abap_unit_assert=>assert_false( r->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

ENDCLASS.
