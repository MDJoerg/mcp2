"! get_cors_mode( ) is not covered here: it is an unconditional
"! SELECT SINGLE with no WHERE clause at all, so its outcome depends
"! entirely on whatever zmcp2_config content happens to exist in the target
"! system - there is no input this class exposes to force either branch
"! deterministically, and this codebase has no SQL test double (see
"! zcl_mcp2_ddic_75's test file for the same class of constraint on FM calls).
CLASS ltcl_config DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_cors_constants FOR TESTING.
    METHODS test_no_origins_configured FOR TESTING.
ENDCLASS.


CLASS ltcl_config IMPLEMENTATION.
  METHOD test_cors_constants.
    cl_abap_unit_assert=>assert_equals( exp = 'C'
                                        act = zcl_mcp2_config=>cors_mode_check ).
    cl_abap_unit_assert=>assert_equals( exp = 'I'
                                        act = zcl_mcp2_config=>cors_mode_ignore ).
    cl_abap_unit_assert=>assert_equals( exp = 'E'
                                        act = zcl_mcp2_config=>cors_mode_enforce ).
  ENDMETHOD.

  METHOD test_no_origins_configured.
    " A garbage area/server pair cannot match any of the four fallback
    " tiers (exact, area/*, */server, */*), so this deterministically
    " exercises the "deny all" empty-result path without depending on any
    " actual zmcp2_origins content.
    DATA(config) = NEW zcl_mcp2_config( area_name   = `__mcp2_unit_missing_area__`
                                        server_name = `__mcp2_unit_missing_server__` ).
    cl_abap_unit_assert=>assert_initial( config->get_allowed_origins( ) ).
  ENDMETHOD.

ENDCLASS.
