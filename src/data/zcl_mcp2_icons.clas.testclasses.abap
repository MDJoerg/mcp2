CLASS ltcl_icons DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_empty_no_node  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_src_only       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_all_fields     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_multiple_icons FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_icons IMPLEMENTATION.
  METHOD test_empty_no_node.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_icons=>emit( json  = json
                          path  = '/icons'
                          icons = VALUE #( ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/icons' ) ).
  ENDMETHOD.

  METHOD test_src_only.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_icons=>emit(
        json  = json
        path  = '/icons'
        icons = VALUE #( ( src = `https://example.com/icon.png` ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( json->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/icon.png`
                                        act = parsed->get_string( '/icons/1/src' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/icons/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/icons/1/sizes' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/icons/1/theme' ) ).
  ENDMETHOD.

  METHOD test_all_fields.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_icons=>emit(
        json  = json
        path  = '/icons'
        icons = VALUE #( ( src       = `https://example.com/icon.svg`
                           mime_type = `image/svg+xml`
                           sizes     = VALUE #( ( `48x48` ) ( `any` ) )
                           theme     = zif_mcp2_const=>icon_themes-dark ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( json->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `image/svg+xml`
                                        act = parsed->get_string( '/icons/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `dark`
                                        act = parsed->get_string( '/icons/1/theme' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `48x48`
                                        act = parsed->get_string( '/icons/1/sizes/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `any`
                                        act = parsed->get_string( '/icons/1/sizes/2' ) ).
  ENDMETHOD.

  METHOD test_multiple_icons.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    zcl_mcp2_icons=>emit(
        json  = json
        path  = '/deep/icons'
        icons = VALUE #( ( src = `first.png` sizes = VALUE #( ( `16x16` ) ) )
                         ( src = `second.png` ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( json->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/deep/icons' ) ) ).
    " The second icon must not inherit the first icon's sy-tabix from the
    " inner sizes loop - pin both srcs.
    cl_abap_unit_assert=>assert_equals( exp = `first.png`
                                        act = parsed->get_string( '/deep/icons/1/src' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `second.png`
                                        act = parsed->get_string( '/deep/icons/2/src' ) ).
  ENDMETHOD.
ENDCLASS.
