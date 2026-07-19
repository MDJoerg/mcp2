CLASS ltcl_version DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_is_supported        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_is_modern           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_is_legacy           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_negotiate_legacy_ok FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_negotiate_modern    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_negotiate_unknown   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_initialize   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_discover     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_header_mod   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_header_leg   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_meta_mod     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_sym_mismatch FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_unknown_mix  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_default_leg  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_detect_unknown_hdr  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_version IMPLEMENTATION.
  METHOD test_is_supported.
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_supported( `2025-03-26` ) ).
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_supported( `2025-06-18` ) ).
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_supported( `2025-11-25` ) ).
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_supported( `2026-07-28` ) ).
    cl_abap_unit_assert=>assert_false( zcl_mcp2_version=>is_supported( `2024-01-01` ) ).
    cl_abap_unit_assert=>assert_false( zcl_mcp2_version=>is_supported( `` ) ).
  ENDMETHOD.

  METHOD test_is_modern.
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_modern( `2026-07-28` ) ).
    cl_abap_unit_assert=>assert_false( zcl_mcp2_version=>is_modern( `2025-11-25` ) ).
  ENDMETHOD.

  METHOD test_is_legacy.
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_legacy( `2025-03-26` ) ).
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_legacy( `2025-06-18` ) ).
    cl_abap_unit_assert=>assert_true( zcl_mcp2_version=>is_legacy( `2025-11-25` ) ).
    cl_abap_unit_assert=>assert_false( zcl_mcp2_version=>is_legacy( `2026-07-28` ) ).
  ENDMETHOD.


  METHOD test_negotiate_legacy_ok.
    cl_abap_unit_assert=>assert_equals(
      exp = `2025-11-25`
      act = zcl_mcp2_version=>negotiate_legacy( `2025-11-25` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2025-03-26`
                                        act = zcl_mcp2_version=>negotiate_legacy( `2025-03-26` ) ).
  ENDMETHOD.

  METHOD test_negotiate_modern.
    " A modern version in a legacy initialize gets the spec counter-offer:
    " the latest legacy version we support (modern clients use server/discover).
    cl_abap_unit_assert=>assert_equals(
      exp = `2025-11-25`
      act = zcl_mcp2_version=>negotiate_legacy( `2026-07-28` ) ).
  ENDMETHOD.

  METHOD test_negotiate_unknown.
    " Unknown/older versions are counter-offered too (spec: the server MUST
    " respond with a version it supports, preferably the latest).
    cl_abap_unit_assert=>assert_equals(
      exp = `2025-11-25`
      act = zcl_mcp2_version=>negotiate_legacy( `2024-11-05` ) ).
    " Missing protocolVersion is malformed input, not a negotiation case.
    TRY.
        zcl_mcp2_version=>negotiate_legacy( `` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_detect_initialize.
    DATA(era) = zcl_mcp2_version=>detect_era( method = `initialize` ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_mcp2_version=>era_legacy
                                        act = era ).
  ENDMETHOD.

  METHOD test_detect_discover.
    DATA(era) = zcl_mcp2_version=>detect_era( method = `server/discover` ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_mcp2_version=>era_modern
                                        act = era ).
  ENDMETHOD.

  METHOD test_detect_header_mod.
    DATA(era) = zcl_mcp2_version=>detect_era( method     = `tools/list`
                                              header_ver = `2026-07-28` ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_mcp2_version=>era_modern
                                        act = era ).
  ENDMETHOD.

  METHOD test_detect_header_leg.
    DATA(era) = zcl_mcp2_version=>detect_era( method     = `tools/list`
                                              header_ver = `2025-11-25` ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_mcp2_version=>era_legacy
                                        act = era ).
  ENDMETHOD.

  METHOD test_detect_meta_mod.
    DATA params TYPE REF TO zif_mcp2_ajson.

    params = zcl_mcp2_ajson=>parse( `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}` ).
    DATA(era) = zcl_mcp2_version=>detect_era( method = `tools/call`
                                              params = params ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_mcp2_version=>era_modern
                                        act = era ).
  ENDMETHOD.

  METHOD test_detect_sym_mismatch.
    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse(
      `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2025-11-25"}}` ).
    TRY.
        zcl_mcp2_version=>detect_era( method     = `tools/list`
                                      params     = params
                                      header_ver = `2026-07-28` ).
        cl_abap_unit_assert=>fail( `Expected symmetric version mismatch` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-header_mismatch
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_detect_unknown_mix.
    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse(
      `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28"}}` ).
    TRY.
        zcl_mcp2_version=>detect_era( method     = `tools/list`
                                      params     = params
                                      header_ver = `2099-01-01` ).
        cl_abap_unit_assert=>fail( `Expected mismatch before unsupported-version handling` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-header_mismatch
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_detect_default_leg.
    DATA(era) = zcl_mcp2_version=>detect_era( method = `tools/list` ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_mcp2_version=>era_legacy
                                        act = era ).
  ENDMETHOD.

  METHOD test_detect_unknown_hdr.
    TRY.
        zcl_mcp2_version=>detect_era( method     = `tools/list`
                                      header_ver = `1999-01-01` ).
        cl_abap_unit_assert=>fail( `Expected zcx_mcp2_error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-unsupported_version
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
