"! Tests for the protocol exception: each raise_* helper carries the
"! spec-correct JSON-RPC error code, the constructor stores reason/data,
"! and get_text renders the "[code] reason" form.
CLASS ltcl_error DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_raise_parse        FOR TESTING.
    METHODS test_raise_invalid_req  FOR TESTING.
    METHODS test_raise_not_found    FOR TESTING.
    METHODS test_raise_inv_params   FOR TESTING.
    METHODS test_raise_internal     FOR TESTING.
    METHODS test_raise_res_not_found FOR TESTING.
    METHODS test_raise_header       FOR TESTING.
    METHODS test_raise_missing_cap  FOR TESTING.
    METHODS test_raise_unsupported  FOR TESTING.
    METHODS test_constructor_data   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_get_text           FOR TESTING.
    METHODS test_raise_malformed    FOR TESTING.
    METHODS test_missing_cap_tasks  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_missing_cap_multi_seg FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_missing_cap_empty_seg FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_unsupported_ver_data  FOR TESTING.
    METHODS test_ctor_optionals_omitted FOR TESTING.
ENDCLASS.


CLASS ltcl_error IMPLEMENTATION.

  METHOD test_raise_parse.
    TRY.
        zcx_mcp2_error=>raise_parse( ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-parse_error
          act = error->code ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_invalid_req.
    TRY.
        zcx_mcp2_error=>raise_invalid_req( `bad` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_request
          act = error->code ).
        cl_abap_unit_assert=>assert_equals( exp = `bad` act = error->reason ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_not_found.
    TRY.
        zcx_mcp2_error=>raise_method_not_found( `tools/call` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-method_not_found
          act = error->code ).
        cl_abap_unit_assert=>assert_char_cp(
          exp = `*tools/call*` act = error->reason ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_inv_params.
    TRY.
        zcx_mcp2_error=>raise_invalid_params( `nope` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_internal.
    TRY.
        zcx_mcp2_error=>raise_internal( `boom` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-internal_error
          act = error->code ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_res_not_found.
    TRY.
        zcx_mcp2_error=>raise_resource_not_found( `mcp2://demo/missing` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-resource_not_found
          act = error->code ).
        cl_abap_unit_assert=>assert_equals(
          exp = `mcp2://demo/missing`
          act = error->err_data->get_string( '/uri' ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_header.
    TRY.
        zcx_mcp2_error=>raise_header_mismatch( `mismatch` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-header_mismatch
          act = error->code ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_missing_cap.
    TRY.
        zcx_mcp2_error=>raise_missing_cap( `sampling` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-missing_client_cap
          act = error->code ).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_ajson_types=>node_type-object
          act = error->err_data->get_node_type( '/requiredCapabilities/sampling' ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_raise_unsupported.
    TRY.
        zcx_mcp2_error=>raise_unsupported_ver( `1999-01-01` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-unsupported_version
          act = error->code ).
    ENDTRY.
  ENDMETHOD.


  METHOD test_constructor_data.
    DATA(data) = zcl_mcp2_ajson=>parse( `{"detail":"x"}` ).
    DATA(error) = NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-invalid_params
      error_msg  = `with data`
      error_data = data ).

    cl_abap_unit_assert=>assert_equals( exp = `with data` act = error->reason ).
    cl_abap_unit_assert=>assert_bound( error->err_data ).
  ENDMETHOD.


  METHOD test_get_text.
    DATA(error) = NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-invalid_params
      error_msg  = `oops` ).

    cl_abap_unit_assert=>assert_equals(
      exp = |[{ zif_mcp2_const=>error_codes-invalid_params }] oops|
      act = error->get_text( ) ).
  ENDMETHOD.

  METHOD test_raise_malformed.
    " Same JSON-RPC code as InvalidParams, but distinguished by http_status.
    TRY.
        zcx_mcp2_error=>raise_malformed_params( `bad body` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
        cl_abap_unit_assert=>assert_equals( exp = 400 act = error->http_status ).
    ENDTRY.

    TRY.
        zcx_mcp2_error=>raise_invalid_params( `plain` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(plain_error).
        cl_abap_unit_assert=>assert_equals( exp = 0 act = plain_error->http_status ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_cap_tasks.
    " The tasks extension is the one capability whose JSON member name
    " contains a literal slash - the path must survive the TAB-escape
    " round-trip once re-parsed from the wire.
    TRY.
        zcx_mcp2_error=>raise_missing_cap( `extensions/io.modelcontextprotocol/tasks` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        DATA(wire) = error->err_data->stringify( ).
        cl_abap_unit_assert=>assert_char_cp(
          act = wire
          exp = `*"io.modelcontextprotocol/tasks"*` ).
        DATA(reparsed) = zcl_mcp2_ajson=>parse( wire ).
        DATA(path) = `/requiredCapabilities/extensions/io.modelcontextprotocol`
                   && cl_abap_char_utilities=>horizontal_tab
                   && `tasks`.
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_ajson_types=>node_type-object
          act = reparsed->get_node_type( path ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_cap_multi_seg.
    " A plain multi-segment capability (no tasks-extension special case)
    " nests one level per segment.
    TRY.
        zcx_mcp2_error=>raise_missing_cap( `elicitation/form` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_ajson_types=>node_type-object
          act = error->err_data->get_node_type( '/requiredCapabilities/elicitation/form' ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_cap_empty_seg.
    " Leading/double slashes yield empty segments that must be skipped,
    " not turned into blank path members.
    TRY.
        zcx_mcp2_error=>raise_missing_cap( `//sampling` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_ajson_types=>node_type-object
          act = error->err_data->get_node_type( '/requiredCapabilities/sampling' ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_unsupported_ver_data.
    TRY.
        zcx_mcp2_error=>raise_unsupported_ver( `1999-01-01` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = `1999-01-01`
          act = error->err_data->get_string( '/requested' ) ).
        cl_abap_unit_assert=>assert_equals(
          exp = 4
          act = lines( error->err_data->members( '/supported' ) ) ).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>protocol-v2026_07_28
          act = error->err_data->get_string( '/supported/4' ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_ctor_optionals_omitted.
    DATA(error) = NEW zcx_mcp2_error(
      error_code = zif_mcp2_const=>error_codes-internal_error
      error_msg  = `bare` ).

    cl_abap_unit_assert=>assert_not_bound( error->err_data ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = error->http_status ).
  ENDMETHOD.

ENDCLASS.
