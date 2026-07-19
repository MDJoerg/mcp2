CLASS ltcl_tasks_unit DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_valid_transitions      FOR TESTING.
    METHODS test_invalid_terminal       FOR TESTING.
    METHODS test_wire_to_db_mapping     FOR TESTING.
    METHODS test_db_to_wire_mapping     FOR TESTING.
    METHODS test_invalid_cursor         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_empty_list_result      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_input_req_self_invalid FOR TESTING.
    METHODS test_wire_db_roundtrip      FOR TESTING.
    METHODS test_create_neg_poll_ms     FOR TESTING.
    METHODS test_cursor_zero_ts         FOR TESTING.
    METHODS test_cursor_bad_hex_id      FOR TESTING.

ENDCLASS.

CLASS ltcl_tasks_unit IMPLEMENTATION.

  METHOD test_valid_transitions.
    " working --> working (increment)
    cl_abap_unit_assert=>assert_true(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zif_mcp2_const=>task_statuses-working
        next    = zif_mcp2_const=>task_statuses-working ) ).

    " working --> input_req
    cl_abap_unit_assert=>assert_true(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zif_mcp2_const=>task_statuses-working
        next    = zcl_mcp2_tasks=>db_input_req ) ).

    " working --> completed
    cl_abap_unit_assert=>assert_true(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zif_mcp2_const=>task_statuses-working
        next    = zif_mcp2_const=>task_statuses-completed ) ).

    " input_req --> working
    cl_abap_unit_assert=>assert_true(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zcl_mcp2_tasks=>db_input_req
        next    = zif_mcp2_const=>task_statuses-working ) ).

    " input_req --> cancelled
    cl_abap_unit_assert=>assert_true(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zcl_mcp2_tasks=>db_input_req
        next    = zif_mcp2_const=>task_statuses-cancelled ) ).
  ENDMETHOD.

  METHOD test_invalid_terminal.
    " completed --> working (illegal)
    cl_abap_unit_assert=>assert_false(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zif_mcp2_const=>task_statuses-completed
        next    = zif_mcp2_const=>task_statuses-working ) ).

    " failed --> completed (illegal)
    cl_abap_unit_assert=>assert_false(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zif_mcp2_const=>task_statuses-failed
        next    = zif_mcp2_const=>task_statuses-completed ) ).

    " cancelled --> working (illegal)
    cl_abap_unit_assert=>assert_false(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zif_mcp2_const=>task_statuses-cancelled
        next    = zif_mcp2_const=>task_statuses-working ) ).
  ENDMETHOD.

  METHOD test_wire_to_db_mapping.
    cl_abap_unit_assert=>assert_equals(
      exp = zcl_mcp2_tasks=>db_input_req
      act = zcl_mcp2_tasks=>wire_to_db(
              zif_mcp2_const=>task_statuses-input_required ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `working`
      act = zcl_mcp2_tasks=>wire_to_db( `working` ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `completed`
      act = zcl_mcp2_tasks=>wire_to_db( `completed` ) ).
  ENDMETHOD.

  METHOD test_db_to_wire_mapping.
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>task_statuses-input_required
      act = zcl_mcp2_tasks=>db_to_wire( zcl_mcp2_tasks=>db_input_req ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `failed`
      act = zcl_mcp2_tasks=>db_to_wire( `failed` ) ).
  ENDMETHOD.

  METHOD test_invalid_cursor.
    DATA(tasks) = NEW zcl_mcp2_tasks( area = `test` server = `srv` ).
    TRY.
        DATA(r) = tasks->list( `INVALID_CURSOR` ).
        cl_abap_unit_assert=>fail( 'Expected error for invalid cursor' ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_empty_list_result.
    DATA(resp) = NEW zcl_mcp2_resp_list_tasks_lgcy( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/tasks' ) ).
  ENDMETHOD.

  METHOD test_input_req_self_invalid.
    " Unlike working->working, input_req has no self-transition - only
    " working, completed, failed, cancelled are legal next states.
    cl_abap_unit_assert=>assert_false(
      zcl_mcp2_tasks=>is_valid_transition(
        current = zcl_mcp2_tasks=>db_input_req
        next    = zcl_mcp2_tasks=>db_input_req ) ).
  ENDMETHOD.

  METHOD test_wire_db_roundtrip.
    " Cheap regression guard: every wire status must survive a
    " wire_to_db/db_to_wire round-trip unchanged.
    DATA(statuses) = VALUE string_table(
      ( zif_mcp2_const=>task_statuses-working )
      ( zif_mcp2_const=>task_statuses-completed )
      ( zif_mcp2_const=>task_statuses-failed )
      ( zif_mcp2_const=>task_statuses-cancelled )
      ( zif_mcp2_const=>task_statuses-input_required ) ).
    LOOP AT statuses INTO DATA(status).
      cl_abap_unit_assert=>assert_equals(
        exp = status
        act = zcl_mcp2_tasks=>db_to_wire( zcl_mcp2_tasks=>wire_to_db( status ) ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD test_create_neg_poll_ms.
    " poll_ms is validated before any UUID generation or DB access.
    DATA(tasks) = NEW zcl_mcp2_tasks( area = `test` server = `srv` ).
    TRY.
        tasks->create_task( poll_ms = -1 ).
        cl_abap_unit_assert=>fail( `Expected error for negative poll_ms` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_cursor_zero_ts.
    " A zero timestamp segment is explicitly rejected before the SELECT.
    DATA(tasks) = NEW zcl_mcp2_tasks( area = `test` server = `srv` ).
    TRY.
        tasks->list( `0|AABBCCDDEEFF00112233445566778899` ).
        cl_abap_unit_assert=>fail( `Expected error for zero-timestamp cursor` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_cursor_bad_hex_id.
    " A valid timestamp segment with a non-hex task-id segment is rejected
    " before the SELECT.
    DATA(tasks) = NEW zcl_mcp2_tasks( area = `test` server = `srv` ).
    TRY.
        tasks->list( `20260101120000|not-a-hex-id` ).
        cl_abap_unit_assert=>fail( `Expected error for malformed cursor task id` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = err->code ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
