CLASS ltcl_resp_list_res_tmpls DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_empty_list      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_single_template FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_optional_fields FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_cursor     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_set_cache       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_icons           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_list_res_tmpls IMPLEMENTATION.
  METHOD test_empty_list.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/resourceTemplates' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( json->members( '/resourceTemplates' ) ) ).
  ENDMETHOD.

  METHOD test_single_template.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    resp->add_template( VALUE #( uri_template = `file:///{path}`
                                 name         = `fs`
                                 title        = `Filesystem`
                                 description  = `Access files`
                                 mime_type    = `text/plain` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///{path}`
                                        act = parsed->get_string( '/resourceTemplates/1/uriTemplate' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `fs`
                                        act = parsed->get_string( '/resourceTemplates/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Filesystem`
                                        act = parsed->get_string( '/resourceTemplates/1/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text/plain`
                                        act = parsed->get_string( '/resourceTemplates/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_optional_fields.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    resp->add_template( VALUE #( uri_template = `db://{table}` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `db://{table}`
                                        act = parsed->get_string( '/resourceTemplates/1/uriTemplate' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/resourceTemplates/1/name' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/resourceTemplates/1/mimeType' ) ).
  ENDMETHOD.

  METHOD test_with_cursor.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    resp->add_template( VALUE #( uri_template = `x://{y}` ) ).
    resp->set_next_cursor( `next-page` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `next-page`
                                        act = parsed->get_string( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_set_cache.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    resp->set_cache( ttl_ms      = 5000
                     cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 5000
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public`
                                        act = resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.

  METHOD test_icons.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_res_tmpls.

    resp = NEW #( ).
    resp->add_template( VALUE #( uri_template = `file:///{name}`
                                 name         = `files`
                                 icons        = VALUE #( ( src = `https://example.com/t.png` ) ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/t.png`
                                        act = parsed->get_string( '/resourceTemplates/1/icons/1/src' ) ).
  ENDMETHOD.
ENDCLASS.
