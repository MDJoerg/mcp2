CLASS ltcl_resp_list_resources DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_empty_list      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_single_entry    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_optional_fields FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_cursor     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_set_cache       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_icons           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_is_cacheable    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_list_resources IMPLEMENTATION.
  METHOD test_empty_list.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/resources' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( json->members( '/resources' ) ) ).
  ENDMETHOD.

  METHOD test_single_entry.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    resp->add_resource( VALUE #( uri         = `file:///data.csv`
                                 name        = `data`
                                 title       = `Data File`
                                 description = `A CSV file`
                                 mime_type   = `text/csv` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///data.csv`
                                        act = parsed->get_string( '/resources/1/uri' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `data`
                                        act = parsed->get_string( '/resources/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Data File`
                                        act = parsed->get_string( '/resources/1/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `A CSV file`
                                        act = parsed->get_string( '/resources/1/description' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text/csv`
                                        act = parsed->get_string( '/resources/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_optional_fields.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    resp->add_resource( VALUE #( uri = `file:///bare.txt` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///bare.txt`
                                        act = parsed->get_string( '/resources/1/uri' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/resources/1/name' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/resources/1/mimeType' ) ).
  ENDMETHOD.

  METHOD test_with_cursor.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    resp->add_resource( VALUE #( uri = `file:///r1` ) ).
    resp->set_next_cursor( `tok-abc` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `tok-abc`
                                        act = parsed->get_string( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_set_cache.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    resp->set_cache( ttl_ms      = 5000
                     cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 5000
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public`
                                        act = resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.

  METHOD test_icons.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    resp->add_resource( VALUE #( uri   = `file:///a.txt`
                                 name  = `a`
                                 icons = VALUE #( ( src   = `data:image/png;base64,AAAA`
                                                    sizes = VALUE #( ( `16x16` ) ) ) ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `data:image/png;base64,AAAA`
                                        act = parsed->get_string( '/resources/1/icons/1/src' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `16x16`
                                        act = parsed->get_string( '/resources/1/icons/1/sizes/1' ) ).
  ENDMETHOD.

  METHOD test_is_cacheable.
    " resources/list is a spec CacheableResult - the modern dispatcher relies
    " on this flag (not JSON sniffing) to decide whether to stamp ttlMs/cacheScope.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_resources.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_true( resp->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.
ENDCLASS.
