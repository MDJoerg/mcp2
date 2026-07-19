CLASS ltcl_resp_complete DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_empty_values   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_add_value      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_set_values     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_total          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_has_more_true  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_has_more_false FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_has_more    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_cache_hints FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_complete IMPLEMENTATION.
  METHOD test_empty_values.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/completion/values' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( json->members( '/completion/values' ) ) ).
  ENDMETHOD.

  METHOD test_add_value.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    resp->add_value( `de` ).
    resp->add_value( `en` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/completion/values' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `de`
                                        act = parsed->get_string( '/completion/values/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `en`
                                        act = parsed->get_string( '/completion/values/2' ) ).
  ENDMETHOD.

  METHOD test_set_values.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    resp->set_values( VALUE #( ( `x` ) ( `y` ) ( `z` ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( parsed->members( '/completion/values' ) ) ).
  ENDMETHOD.

  METHOD test_total.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    resp->add_value( `a` ).
    resp->set_total( 42 ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = parsed->get_integer( '/completion/total' ) ).
  ENDMETHOD.

  METHOD test_has_more_true.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    resp->add_value( `a` ).
    resp->set_has_more( abap_true ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( parsed->get_boolean( '/completion/hasMore' ) ).
  ENDMETHOD.

  METHOD test_has_more_false.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    resp->add_value( `a` ).
    resp->set_has_more( abap_false ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_false( parsed->get_boolean( '/completion/hasMore' ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/completion/hasMore' ) ).
  ENDMETHOD.

  METHOD test_no_has_more.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    resp->add_value( `a` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/completion/hasMore' ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_no_cache_hints.
    " CompleteResult is not a CacheableResult - it never carries ttlMs/cacheScope.
    DATA resp TYPE REF TO zcl_mcp2_resp_complete.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_initial( resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.
ENDCLASS.
