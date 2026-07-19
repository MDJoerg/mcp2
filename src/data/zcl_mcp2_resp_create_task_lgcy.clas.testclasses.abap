CLASS ltcl_resp_create_task_lgcy DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_result_type    FOR TESTING.
    METHODS test_task_under_key FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_null_ttl       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_with_ttl       FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_resp_create_task_lgcy IMPLEMENTATION.

  METHOD test_result_type.
    " Marked as a task result so the legacy dispatcher can enforce the
    " params.task opt-in; the legacy era never writes resultType to the wire.
    DATA(r) = NEW zcl_mcp2_resp_create_task_lgcy( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-task
      act = r->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_task_under_key.
    DATA(r) = NEW zcl_mcp2_resp_create_task_lgcy( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working`
                 poll_ms = 5000 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = json->get_string( '/task/taskId' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `working`
      act = json->get_string( '/task/status' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 5000
      act = json->get_integer( '/task/pollInterval' ) ).
  ENDMETHOD.

  METHOD test_null_ttl.
    DATA(r) = NEW zcl_mcp2_resp_create_task_lgcy( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    " ttl = 0 -> null on wire
    cl_abap_unit_assert=>assert_equals(
      exp = `null`
      act = json->get_node_type( '/task/ttl' ) ).
  ENDMETHOD.

  METHOD test_with_ttl.
    DATA(r) = NEW zcl_mcp2_resp_create_task_lgcy( ).
    r->set_task( task_id = `AABBCCDDEEFF00112233445566778899`
                 status  = `working`
                 ttl_s   = 3600 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    " ttl_s = 3600 -> ttl = 3600*1000 = 3600000 ms on wire
    cl_abap_unit_assert=>assert_equals( exp = 3600000
                                        act = json->get_integer( '/task/ttl' ) ).
  ENDMETHOD.

ENDCLASS.
