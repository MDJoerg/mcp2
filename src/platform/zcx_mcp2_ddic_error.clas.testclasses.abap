"! Tests for the DDIC exception: the raise helper produces an instance that
"! carries the supplied message.
CLASS ltcl_ddic_error DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_raise_carries_message FOR TESTING.
ENDCLASS.


CLASS ltcl_ddic_error IMPLEMENTATION.

  METHOD test_raise_carries_message.
    TRY.
        zcx_mcp2_ddic_error=>raise( `Structure not found: ZNOPE` ).
        cl_abap_unit_assert=>fail( ).
      CATCH zcx_mcp2_ddic_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = `Structure not found: ZNOPE`
          act = error->message ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
