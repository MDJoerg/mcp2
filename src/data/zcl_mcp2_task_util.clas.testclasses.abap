CLASS ltcl_task_util DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_iso_basic       FOR TESTING.
    METHODS test_iso_zero_pad    FOR TESTING.
    METHODS test_normalize_ok    FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_normalize_upper FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_normalize_short FOR TESTING.
    METHODS test_normalize_hex   FOR TESTING.
    METHODS test_ttl_bound       FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_ttl_overflow    FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_ms_bound        FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_ms_overflow     FOR TESTING.
    METHODS test_ttl_negative    FOR TESTING.
    METHODS test_ttl_zero        FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_ms_empty        FOR TESTING.
    METHODS test_ms_non_numeric  FOR TESTING.
    METHODS test_ms_typical      FOR TESTING RAISING zcx_mcp2_error.
    METHODS test_wtf_minimal     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_wtf_all_fields  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_wtf_ttl_overflow FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_wtf_ttl_negative FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_wtf_prefix_nested FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_task_util IMPLEMENTATION.

  METHOD test_iso_basic.
    DATA ts TYPE timestamp VALUE '20260621143000'.
    cl_abap_unit_assert=>assert_equals(
      exp = `2026-06-21T14:30:00Z`
      act = zcl_mcp2_task_util=>ts_to_iso( ts ) ).
  ENDMETHOD.

  METHOD test_iso_zero_pad.
    " A small magnitude packed value pads to 14 digits before formatting
    DATA ts TYPE timestamp VALUE '101145000'.
    cl_abap_unit_assert=>assert_equals(
      exp = `0000-01-01T14:50:00Z`
      act = zcl_mcp2_task_util=>ts_to_iso( ts ) ).
  ENDMETHOD.

  METHOD test_normalize_ok.
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = zcl_mcp2_task_util=>normalize_task_id( `AABBCCDDEEFF00112233445566778899` ) ).
  ENDMETHOD.

  METHOD test_normalize_upper.
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = zcl_mcp2_task_util=>normalize_task_id( `aabbccddeeff00112233445566778899` ) ).
  ENDMETHOD.

  METHOD test_normalize_short.
    TRY.
        zcl_mcp2_task_util=>normalize_task_id( `ABCD` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_normalize_hex.
    TRY.
        " 32 chars but contains non-hex 'G'
        zcl_mcp2_task_util=>normalize_task_id( `GGBBCCDDEEFF00112233445566778899` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ttl_bound.
    cl_abap_unit_assert=>assert_equals(
      exp = 2147483000
      act = zcl_mcp2_task_util=>ttl_s_to_ms(
        zcl_mcp2_task_util=>max_ttl_seconds ) ).
  ENDMETHOD.

  METHOD test_ttl_overflow.
    TRY.
        zcl_mcp2_task_util=>ttl_s_to_ms(
          zcl_mcp2_task_util=>max_ttl_seconds + 1 ).
        cl_abap_unit_assert=>fail( `Expected TTL overflow rejection` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ms_bound.
    cl_abap_unit_assert=>assert_equals(
      exp = zcl_mcp2_task_util=>max_milliseconds
      act = zcl_mcp2_task_util=>parse_milliseconds(
        `2147483647` ) ).
  ENDMETHOD.

  METHOD test_ms_overflow.
    TRY.
        zcl_mcp2_task_util=>parse_milliseconds( `2147483648` ).
        cl_abap_unit_assert=>fail( `Expected millisecond overflow rejection` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ttl_negative.
    TRY.
        zcl_mcp2_task_util=>validate_ttl_s( -1 ).
        cl_abap_unit_assert=>fail( `Expected negative TTL rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ttl_zero.
    " Zero means unlimited and must round-trip to zero, not raise.
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = zcl_mcp2_task_util=>ttl_s_to_ms( 0 ) ).
  ENDMETHOD.

  METHOD test_ms_empty.
    TRY.
        zcl_mcp2_task_util=>parse_milliseconds( `` ).
        cl_abap_unit_assert=>fail( `Expected empty value rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ms_non_numeric.
    TRY.
        zcl_mcp2_task_util=>parse_milliseconds( `abc` ).
        cl_abap_unit_assert=>fail( `Expected non-numeric rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ms_typical.
    cl_abap_unit_assert=>assert_equals( exp = 500
                                        act = zcl_mcp2_task_util=>parse_milliseconds( `500` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = zcl_mcp2_task_util=>parse_milliseconds( `0` ) ).
  ENDMETHOD.

  METHOD test_wtf_minimal.
    " Only task_id/status are mandatory - everything else stays absent,
    " except ttl which is required-but-null when unset.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_task_util=>write_task_fields( json    = json
                                           prefix  = ``
                                           task_id = `AABBCCDDEEFF00112233445566778899`
                                           status  = `working` ).
    cl_abap_unit_assert=>assert_equals( exp = `AABBCCDDEEFF00112233445566778899`
                                        act = json->get_string( '/taskId' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `working`
                                        act = json->get_string( '/status' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/statusMessage' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/createdAt' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/lastUpdatedAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `null`
                                        act = json->get_node_type( '/ttl' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/pollInterval' ) ).
  ENDMETHOD.

  METHOD test_wtf_all_fields.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_task_util=>write_task_fields( json         = json
                                           prefix       = ``
                                           task_id      = `AABBCCDDEEFF00112233445566778899`
                                           status       = `completed`
                                           status_msg   = `All done`
                                           created_at   = '20260101120000'
                                           last_updated = '20260101120500'
                                           ttl_s        = 60
                                           poll_ms      = 2000 ).
    cl_abap_unit_assert=>assert_equals( exp = `All done`
                                        act = json->get_string( '/statusMessage' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:00:00Z`
                                        act = json->get_string( '/createdAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:05:00Z`
                                        act = json->get_string( '/lastUpdatedAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 60000
                                        act = json->get_integer( '/ttl' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2000
                                        act = json->get_integer( '/pollInterval' ) ).
  ENDMETHOD.

  METHOD test_wtf_ttl_overflow.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    TRY.
        zcl_mcp2_task_util=>write_task_fields(
          json    = json
          prefix  = ``
          task_id = `AABBCCDDEEFF00112233445566778899`
          status  = `working`
          ttl_s   = zcl_mcp2_task_util=>max_ttl_seconds + 1 ).
        cl_abap_unit_assert=>fail( `Expected TTL overflow rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_wtf_ttl_negative.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    TRY.
        zcl_mcp2_task_util=>write_task_fields(
          json    = json
          prefix  = ``
          task_id = `AABBCCDDEEFF00112233445566778899`
          status  = `working`
          ttl_s   = -1 ).
        cl_abap_unit_assert=>fail( `Expected negative TTL rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_wtf_prefix_nested.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_task_util=>write_task_fields( json    = json
                                           prefix  = `/task`
                                           task_id = `AABBCCDDEEFF00112233445566778899`
                                           status  = `working` ).
    cl_abap_unit_assert=>assert_equals( exp = `AABBCCDDEEFF00112233445566778899`
                                        act = json->get_string( '/task/taskId' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/taskId' ) ).
  ENDMETHOD.

ENDCLASS.
