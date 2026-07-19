CLASS ltcl_elicit_result DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_accept_with_content FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_decline_no_content  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_cancel_action       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_invalid_action      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_missing_action      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_unbound_json        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_typed_getters       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_elicit_result IMPLEMENTATION.

  METHOD test_accept_with_content.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"action":"accept","content":{"approved":true,"comment":"looks good"}}` ).
    DATA(r) = NEW zcl_mcp2_elicit_result( json ).
    cl_abap_unit_assert=>assert_true( r->is_accept( ) ).
    cl_abap_unit_assert=>assert_false( r->is_decline( ) ).
    cl_abap_unit_assert=>assert_false( r->is_cancel( ) ).
    cl_abap_unit_assert=>assert_true( r->has_content( ) ).
    cl_abap_unit_assert=>assert_bound( r->get_content( ) ).
  ENDMETHOD.

  METHOD test_decline_no_content.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"action":"decline"}` ).
    DATA(r) = NEW zcl_mcp2_elicit_result( json ).
    cl_abap_unit_assert=>assert_false( r->is_accept( ) ).
    cl_abap_unit_assert=>assert_true( r->is_decline( ) ).
    cl_abap_unit_assert=>assert_false( r->has_content( ) ).
    cl_abap_unit_assert=>assert_bound( r->get_content( ) ).
  ENDMETHOD.

  METHOD test_cancel_action.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"action":"cancel"}` ).
    DATA(r) = NEW zcl_mcp2_elicit_result( json ).
    cl_abap_unit_assert=>assert_true( r->is_cancel( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `cancel`
                                        act = r->get_action( ) ).
  ENDMETHOD.

  METHOD test_invalid_action.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"action":"confirm"}` ).
    TRY.
        DATA(r) = NEW zcl_mcp2_elicit_result( json ).
        cl_abap_unit_assert=>fail( 'Expected error for invalid action' ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_missing_action.
    DATA(json) = zcl_mcp2_ajson=>parse( `{"content":{"x":1}}` ).
    TRY.
        DATA(r) = NEW zcl_mcp2_elicit_result( json ).
        cl_abap_unit_assert=>fail( 'Expected error for missing action' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_unbound_json.
    DATA unbound TYPE REF TO zif_mcp2_ajson.
    TRY.
        DATA(r) = NEW zcl_mcp2_elicit_result( unbound ).
        cl_abap_unit_assert=>fail( 'Expected error for unbound JSON' ).
      CATCH zcx_mcp2_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_typed_getters.
    DATA(json) = zcl_mcp2_ajson=>parse(
      `{"action":"accept","content":{"label":"hello","flag":true,"qty":42}}` ).
    DATA(r) = NEW zcl_mcp2_elicit_result( json ).
    cl_abap_unit_assert=>assert_equals( exp = `hello`
                                        act = r->get_string( `label` ) ).
    cl_abap_unit_assert=>assert_true( r->get_boolean( `flag` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = r->get_integer( `qty` ) ).
  ENDMETHOD.

ENDCLASS.
