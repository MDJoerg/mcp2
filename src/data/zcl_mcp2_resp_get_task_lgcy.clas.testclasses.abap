CLASS ltcl_resp_get_task_lgcy DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_result_type    FOR TESTING.
    METHODS test_fields_at_root FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_null_ttl       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_timestamp_fmt  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_nonzero_ttl    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_optional_fields FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_result_contract FOR TESTING.

ENDCLASS.

CLASS ltcl_resp_get_task_lgcy IMPLEMENTATION.

  METHOD test_result_type.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-complete
      act = r->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_fields_at_root.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = json->get_string( '/taskId' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `working`
      act = json->get_string( '/status' ) ).
  ENDMETHOD.

  METHOD test_null_ttl.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `null`
                                        act = json->get_node_type( '/ttl' ) ).
  ENDMETHOD.

  METHOD test_timestamp_fmt.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    r->set_task( task_id    = `AABBCCDDEEFF00112233445566778899`
                 status     = `completed`
                 created_at = '20240115120000' ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `2024-01-15T12:00:00Z`
      act = json->get_string( '/createdAt' ) ).
  ENDMETHOD.

  METHOD test_nonzero_ttl.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working`
                 ttl_s   = 60 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = 60000
                                        act = json->get_integer( '/ttl' ) ).
  ENDMETHOD.

  METHOD test_optional_fields.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    r->set_task( task_id      = `AABBCCDDEEFF00112233445566778899`
                 status       = `working`
                 status_msg   = `still crunching`
                 last_updated = '20240115120500'
                 poll_ms      = 2000 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `still crunching`
                                        act = json->get_string( '/statusMessage' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2024-01-15T12:05:00Z`
                                        act = json->get_string( '/lastUpdatedAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2000
                                        act = json->get_integer( '/pollInterval' ) ).
  ENDMETHOD.

  METHOD test_result_contract.
    " Legacy shape is never a spec CacheableResult and stays private/uncached.
    DATA(r) = NEW zcl_mcp2_resp_get_task_lgcy( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = r->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `private`
                                        act = r->zif_mcp2_result~cache_scope( ) ).
    cl_abap_unit_assert=>assert_false( r->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

ENDCLASS.
