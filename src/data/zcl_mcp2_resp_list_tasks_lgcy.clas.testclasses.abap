CLASS ltcl_resp_list_tasks_lgcy DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_result_type FOR TESTING.
    METHODS test_empty_list  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_task_list   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_with_cursor FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_ttl_and_timestamps FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_result_contract FOR TESTING.

ENDCLASS.

CLASS ltcl_resp_list_tasks_lgcy IMPLEMENTATION.

  METHOD test_result_type.
    DATA(r) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-complete
      act = r->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_empty_list.
    DATA(r) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/tasks' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_task_list.
    DATA(r) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    r->add_task( task_id    = `AABBCCDDEEFF00112233445566778899`
                 status     = `working`
                 status_msg = `In progress`
                 poll_ms    = 3000 ).
    r->add_task( task_id = `11223344556677889900AABBCCDDEEFF`
                 status  = `completed` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = json->get_string( '/tasks/1/taskId' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `completed`
      act = json->get_string( '/tasks/2/status' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 3000
      act = json->get_integer( '/tasks/1/pollInterval' ) ).
  ENDMETHOD.

  METHOD test_with_cursor.
    DATA(r) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    r->set_next_cursor( `tok_next_page` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `tok_next_page`
      act = json->get_string( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_ttl_and_timestamps.
    DATA(r) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    r->add_task( task_id    = `AABBCCDDEEFF00112233445566778899`
                 status     = `working`
                 created_at = '20240115120000' ).
    r->add_task( task_id = `11223344556677889900AABBCCDDEEFF`
                 status  = `completed`
                 ttl_s   = 30 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `2024-01-15T12:00:00Z`
      act = json->get_string( '/tasks/1/createdAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `null`
                                        act = json->get_node_type( '/tasks/1/ttl' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 30000
                                        act = json->get_integer( '/tasks/2/ttl' ) ).
  ENDMETHOD.

  METHOD test_result_contract.
    " Legacy shape is never a spec CacheableResult and stays private/uncached.
    DATA(r) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = r->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `private`
                                        act = r->zif_mcp2_result~cache_scope( ) ).
    cl_abap_unit_assert=>assert_false( r->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

ENDCLASS.
