CLASS ltcl_resp_empty DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_empty_complete FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_resp_empty IMPLEMENTATION.
  METHOD test_empty_complete.
    DATA(resp) = NEW zcl_mcp2_resp_empty( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( json->members( '/' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
    cl_abap_unit_assert=>assert_false( resp->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.
ENDCLASS.
