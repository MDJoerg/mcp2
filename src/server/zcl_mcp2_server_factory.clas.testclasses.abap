"! The cx_sy_create_object_error / cx_sy_move_cast_error branches are not
"! covered here: reaching CREATE OBJECT at all requires a matching row in
"! zmcp2_servers (the SELECT SINGLE gates everything before that point),
"! and this codebase has no SQL test double to fake one - see
"! zcl_mcp2_ddic_75's test file for the same class of constraint on FM calls.
CLASS ltcl_server_factory DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_missing_server FOR TESTING RAISING zcx_mcp2_error.
ENDCLASS.


CLASS ltcl_server_factory IMPLEMENTATION.
  METHOD test_missing_server.
    DATA server TYPE REF TO zif_mcp2_server.

    server = zcl_mcp2_server_factory=>get_server( area   = `__mcp2_unit_missing_area__`
                                                  server = `__mcp2_unit_missing_server__` ).

    cl_abap_unit_assert=>assert_not_bound( server ).
  ENDMETHOD.

ENDCLASS.
