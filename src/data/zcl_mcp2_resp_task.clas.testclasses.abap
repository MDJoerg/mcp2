CLASS ltcl_resp_task DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_result_type   FOR TESTING.
    METHODS test_basic_task    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_optional_ttl  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_with_message  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_set_cache     FOR TESTING.
    METHODS test_not_cacheable FOR TESTING.

ENDCLASS.

CLASS ltcl_resp_task IMPLEMENTATION.

  METHOD test_result_type.
    DATA(r) = NEW zcl_mcp2_resp_task( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-task
      act = r->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_basic_task.
    " CreateTaskResult = Result & Task (flat): fields at the root, required
    " createdAt / lastUpdatedAt, and ttlMs emitted as null when unlimited.
    DATA(r) = NEW zcl_mcp2_resp_task( ).
    r->set_task_id( `AABBCCDDEEFF00112233445566778899` ).
    r->set_status( `working` ).
    r->set_timestamps( created_at   = '20260101120000'
                       last_updated = '20260101120000' ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = json->get_string( '/taskId' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `working`
      act = json->get_string( '/status' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `2026-01-01T12:00:00Z`
      act = json->get_string( '/createdAt' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `2026-01-01T12:00:00Z`
      act = json->get_string( '/lastUpdatedAt' ) ).
    " ttlMs is required but null (unlimited): the key exists with a null node.
    cl_abap_unit_assert=>assert_true( json->exists( '/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_ajson_types=>node_type-null
      act = json->get_node_type( '/ttlMs' ) ).
  ENDMETHOD.

  METHOD test_optional_ttl.
    DATA(r) = NEW zcl_mcp2_resp_task( ).
    r->set_task_id( `AABBCCDDEEFF00112233445566778899` ).
    r->set_status( `working` ).
    r->set_ttl_ms( 30000 ).
    r->set_poll_interval_ms( 2000 ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = 30000 act = json->get_integer( '/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2000  act = json->get_integer( '/pollIntervalMs' ) ).
  ENDMETHOD.

  METHOD test_with_message.
    DATA(r) = NEW zcl_mcp2_resp_task( ).
    r->set_task_id( `AABBCCDDEEFF00112233445566778899` ).
    r->set_status( `working` ).
    r->set_status_message( `Processing...` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `Processing...`
      act = json->get_string( '/statusMessage' ) ).
  ENDMETHOD.

  METHOD test_set_cache.
    " set_cache feeds the interface's own ttl_ms/cache_scope, distinct from
    " the ttlMs written into the task JSON body via set_ttl_ms.
    DATA(r) = NEW zcl_mcp2_resp_task( ).
    r->set_cache( ttl_ms      = 15000
                  cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 15000
                                        act = r->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public`
                                        act = r->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.

  METHOD test_not_cacheable.
    " CreateTaskResult is never a spec CacheableResult.
    DATA(r) = NEW zcl_mcp2_resp_task( ).
    cl_abap_unit_assert=>assert_false( r->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

ENDCLASS.
