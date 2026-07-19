"! Tests for the 7.5x DDIC adapter. Only the release-independent early-return
"! contract is exercised here: the underlying classic function modules
"! (DDIF_FIELDINFO_GET / DD_DOMVALUES_GET) are not available in the unit-test
"! runtime, so the live metadata reads are covered by the Phase-5 end-to-end run.
CLASS ltcl_ddic_75 DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_domain_values_initial FOR TESTING.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_mcp2_ddic.

    METHODS setup.
ENDCLASS.


CLASS ltcl_ddic_75 IMPLEMENTATION.
  METHOD setup.
    cut = NEW zcl_mcp2_ddic_75( ).
  ENDMETHOD.

  METHOD test_domain_values_initial.
    " Initial domain name short-circuits to an empty result before any FM call.
    cl_abap_unit_assert=>assert_initial( cut->get_domain_values( '' ) ).
  ENDMETHOD.

ENDCLASS.
